import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:gexa/custom_clippers.dart';

class AddSensorScreen extends StatefulWidget {
  const AddSensorScreen({super.key});

  @override
  State<AddSensorScreen> createState() => _AddSensorScreenState();
}

class _AddSensorScreenState extends State<AddSensorScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Fases del provisionamiento: 0=Buscar, 1=Wi-Fi, 2=Esperando Firebase, 3=Formulario Final
  int _currentStep = 0; 

  // BLE Variables
  BluetoothDevice? _gexaDevice;
  bool _isScanning = false;
  
  // Wi-Fi Variables
  final _ssidController = TextEditingController();
  final _passController = TextEditingController();

  // Firebase / Final Form Variables
  String? _selectedSensorId;
  String _nombre = '';
  String _ubicacion = '';

  // UUIDs (Deben coincidir EXACTAMENTE con el código de tu ESP32)
  final String serviceUUID = "4fafc201-1fb5-459e-8fcc-c5c9c331914b";
  final String characteristicUUID = "beb5483e-36e1-4688-b7f5-ea07361b26a8";

  @override
  void dispose() {
    _ssidController.dispose();
    _passController.dispose();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  // --- PASO 1: Escanear BLE ---
  Future<void> _requestPermissionsAndScan() async {
    // Pedir permisos obligatorios para Android/iOS
    await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    setState(() {
      _isScanning = true;
      _currentStep = 0;
    });

    // Iniciar el escaneo de Bluetooth
    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 15));

    // Escuchar los resultados en tiempo real
    FlutterBluePlus.scanResults.listen((results) {
      for (ScanResult r in results) {
        // Buscamos el dispositivo por el nombre que le pusimos en PlatformIO
        if (r.device.advName == "GEXA_SETUP" || r.device.platformName == "GEXA_SETUP") {
          FlutterBluePlus.stopScan();
          setState(() {
            _gexaDevice = r.device;
            _isScanning = false;
            _currentStep = 1; // Pasamos a pedir Wi-Fi
          });
          break;
        }
      }
    });

    // Si pasaron 15 segundos y no lo encontró
    Future.delayed(const Duration(seconds: 15), () {
      if (mounted && _isScanning) {
        setState(() { _isScanning = false; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se encontró ningún GEXA. Verifica que el LED azul esté parpadeando.')),
        );
      }
    });
  }

  // --- PASO 2 y 3: Enviar Wi-Fi por BLE y esperar a Firebase ---
  Future<void> _sendWiFiCredentials() async {
    if (_ssidController.text.isEmpty || _gexaDevice == null) return;

    setState(() { _currentStep = 2; }); // Pantalla de carga (Esperando Firebase)

    try {
      // 1. Conectar al ESP32
      await _gexaDevice!.connect(autoConnect: false);
      
      // 2. Descubrir servicios
      List<BluetoothService> services = await _gexaDevice!.discoverServices();
      BluetoothCharacteristic? targetChar;

      for (var service in services) {
        if (service.uuid.toString().toLowerCase() == serviceUUID) {
          for (var char in service.characteristics) {
            if (char.uuid.toString().toLowerCase() == characteristicUUID) {
              targetChar = char;
            }
          }
        }
      }

      if (targetChar != null) {
        // 3. Enviar el string "Red;Contraseña"
        String payload = "${_ssidController.text.trim()};${_passController.text.trim()}";
        await targetChar.write(utf8.encode(payload), withoutResponse: false);
        
        // 4. Desconectar del Bluetooth suavemente
        await _gexaDevice!.disconnect();

        // 5. PONERNOS A ESCUCHAR A FIREBASE
        // El ESP32 encenderá su Wi-Fi y aparecerá en 'sensores_pendientes'
        _listenForDeviceInFirebase();

      } else {
        throw Exception("Servicio BLE no encontrado en el dispositivo.");
      }
    } catch (e) {
      await _gexaDevice?.disconnect();
      setState(() { _currentStep = 1; }); // Regresar al formulario si falla
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error Bluetooth: $e')),
      );
    }
  }

  void _listenForDeviceInFirebase() {
    final ref = FirebaseDatabase.instance.ref('sensores_pendientes');
    
    // Escuchamos la base de datos. Damos 20 segundos de tiempo de espera.
    bool deviceFound = false;
    
    final subscription = ref.onValue.listen((event) {
      if (event.snapshot.exists) {
        final data = Map<String, dynamic>.from(event.snapshot.value as Map);
        // Si hay al menos un sensor pendiente, asumimos que es el nuestro recién configurado
        if (data.isNotEmpty) {
          deviceFound = true;
          setState(() {
            // Tomamos el primer ID que aparezca
            _selectedSensorId = data.keys.first;
            _currentStep = 3; // Pasamos al formulario final (Nombre y Ubicación)
          });
        }
      }
    });

    // Timeout si el ESP32 puso mal la contraseña o no hay internet
    Future.delayed(const Duration(seconds: 20), () {
      if (!deviceFound && mounted) {
        subscription.cancel();
        setState(() { _currentStep = 1; });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El sensor no se conectó a Internet. Verifica la contraseña del Wi-Fi.')),
        );
      }
    });
  }

  // --- PASO 4: Tu función original adaptada ---
  Future<void> _registrarSensorFinal() async {
    if (_formKey.currentState!.validate() && _selectedSensorId != null) {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final sensorRef = FirebaseDatabase.instance.ref('usuarios/$uid/sensores/$_selectedSensorId');
      final pendingRef = FirebaseDatabase.instance.ref('sensores_pendientes/$_selectedSensorId');
      final globalRef = FirebaseDatabase.instance.ref('sensor_gas/$_selectedSensorId');

      final snapshot = await pendingRef.get();
      Map<String, dynamic> datosSensor = {};
      if (snapshot.exists) {
        datosSensor = Map<String, dynamic>.from(snapshot.value as Map);
      }

      datosSensor['nombre'] = _nombre;
      datosSensor['ubicacion'] = _ubicacion;

      await sensorRef.set(datosSensor);
      await globalRef.update({
        'userId': uid,
        'nombre': _nombre,
        'ubicacion': _ubicacion,
      });

      await pendingRef.remove();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('¡GEXA configurado y protegido con éxito!')),
        );
        Navigator.pop(context); 
      }
    }
  }

  // === UI BUILDER ===
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text('AÑADIR GEXA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          // Tus Custom Painters de fondo (Mantenemos tu diseño)
          Positioned.fill(child: CustomPaint(size: Size(width, width * 0.5), painter: RPSCustomPainter5())),
          Positioned.fill(child: CustomPaint(size: Size(width, width * 0.5), painter: RPSCustomPainter6())),
          Positioned.fill(child: CustomPaint(size: Size(width, width * 0.5), painter: RPSCustomPainter7())),

          Padding(
            padding: const EdgeInsets.only(top: 100.0, left: 16.0, right: 16.0),
            child: _buildBodyContent(),
          ),
        ],
      ),
    );
  }

  // Lógica de renderizado según el paso en el que estamos
  Widget _buildBodyContent() {
    switch (_currentStep) {
      case 0:
        return _buildPaso1Escaneo();
      case 1:
        return _buildPaso2WiFi();
      case 2:
        return _buildPaso3Cargando();
      case 3:
        return _buildPaso4FormularioFinal();
      default:
        return const SizedBox();
    }
  }

  // Vistas de cada paso
  Widget _buildPaso1Escaneo() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bluetooth_searching, size: 80, color: Colors.white),
          const SizedBox(height: 20),
          const Text(
            'Enciende tu dispositivo GEXA.\nAsegúrate de que el LED azul esté parpadeando.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 40),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00698F), padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15)),
            onPressed: _isScanning ? null : _requestPermissionsAndScan,
            child: _isScanning 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Buscar Dispositivo', style: TextStyle(color: Colors.white, fontSize: 18)),
          ),
        ],
      ),
    );
  }

  Widget _buildPaso2WiFi() {
    return Card(
      color: Colors.white.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi, size: 50, color: Color(0xFF00698F)),
            const SizedBox(height: 10),
            const Text('GEXA Encontrado', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF00698F))),
            const Text('Ingresa el Wi-Fi de tu casa para conectarlo', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextField(
              controller: _ssidController,
              decoration: const InputDecoration(labelText: 'Nombre de tu Wi-Fi (SSID)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _passController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Contraseña', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 25),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00698F), minimumSize: const Size(double.infinity, 50)),
              onPressed: _sendWiFiCredentials,
              child: const Text('Conectar GEXA a Internet', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaso3Cargando() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.white),
          SizedBox(height: 20),
          Text('Vinculando dispositivo...', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text('Enviando credenciales y conectando a Firebase.\nEsto puede tardar unos segundos.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildPaso4FormularioFinal() {
    return Form(
      key: _formKey,
      child: Card(
        color: Colors.white.withOpacity(0.95),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            shrinkWrap: true,
            children: [
              const Icon(Icons.check_circle, size: 60, color: Colors.green),
              const SizedBox(height: 10),
              const Text('¡Conectado a Internet!', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
              const Text('Personaliza tu sensor para terminar.', textAlign: TextAlign.center),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Nombre (ej. Cocina)', border: OutlineInputBorder()),
                onChanged: (value) => _nombre = value,
                validator: (value) => value == null || value.isEmpty ? 'Escribe un nombre' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Ubicación (ej. Planta Baja)', border: OutlineInputBorder()),
                onChanged: (value) => _ubicacion = value,
                validator: (value) => value == null || value.isEmpty ? 'Escribe una ubicación' : null,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Guardar Sensor'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00698F), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                onPressed: _registrarSensorFinal,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
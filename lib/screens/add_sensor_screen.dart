import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:gexa/custom_clippers.dart';

class AddSensorScreen extends StatefulWidget {
  const AddSensorScreen({super.key});

  @override
  State<AddSensorScreen> createState() => _AddSensorScreenState();
}

class _AddSensorScreenState extends State<AddSensorScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedSensorId;
  String _nombre = '';
  String _ubicacion = '';
  List<String> _sensorPendientes = [];

  @override
  void initState() {
    super.initState();
    _loadPendingSensors();
  }

  Future<void> _loadPendingSensors() async {
    final ref = FirebaseDatabase.instance.ref('sensores_pendientes');
    final snapshot = await ref.get();
    if (snapshot.exists) {
      final data = Map<String, dynamic>.from(snapshot.value as Map);
      setState(() {
        _sensorPendientes = data.keys.toList();
      });
    }
  }

  Future<void> _registrarSensor() async {
    if (_formKey.currentState!.validate() && _selectedSensorId != null) {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final sensorRef = FirebaseDatabase.instance.ref('usuarios/$uid/sensores/$_selectedSensorId');
      final pendingRef = FirebaseDatabase.instance.ref('sensores_pendientes/$_selectedSensorId');

      // Obtener datos previos del sensor
      final snapshot = await pendingRef.get();
      Map<String, dynamic> datosSensor = {};
      if (snapshot.exists) {
        datosSensor = Map<String, dynamic>.from(snapshot.value as Map);
      }

      // Agregar nombre y ubicación
      datosSensor['nombre'] = _nombre;
      datosSensor['ubicacion'] = _ubicacion;

      // Guardar en ruta del usuario
      await sensorRef.set(datosSensor);

      // Eliminar de la lista de sensores pendientes
      await pendingRef.remove();

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sensor registrado correctamente')),
        );
        Navigator.pop(context); // Regresar a la pantalla principal
      }
    }
  }
@override
Widget build(BuildContext context) {
  final width = MediaQuery.of(context).size.width;

  return Scaffold(
    extendBodyBehindAppBar: true,
    appBar: AppBar(
      title: const Text(
        'AÑADIR SENSOR',
        style: TextStyle(
          
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0, 
    ),
         
    body: Stack(
      children: [
        // 🎨 Fondo con CustomPaint
        Positioned.fill(
          child: CustomPaint(            
             size: Size(width, width * 0.5),
            painter: RPSCustomPainter5(),
          ),
        ),

        Positioned.fill(
          child: CustomPaint(
             size: Size(width, width * 0.5),
            painter: RPSCustomPainter6(),
          ),
        ),

        Positioned.fill(
          child: CustomPaint(
             size: Size(width, width * 0.5),
            painter: RPSCustomPainter7(),
          ),
        ),

        // 📋 Contenido del formulario
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: _sensorPendientes.isEmpty
              ? const Center(
                  child: Text('No hay sensores disponibles para registrar'),
                )
              : Form(
                  key: _formKey,
                  child: ListView(
                    children: [
                      const Text(
                        'Selecciona un sensor detectado:',
                        style: TextStyle(
                          fontSize: 20,            // 🔹 más grande
                          fontWeight: FontWeight.bold,
                          color: Colors.white,     // 🔹 blanco
                        ),
                      ),

                      DropdownButtonFormField<String>(
                        value: _selectedSensorId,
                        items: _sensorPendientes.map((id) {
                          return DropdownMenuItem(
                            value: id,
                            child: Text(id),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSensorId = value;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'Selecciona un sensor' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration: const InputDecoration(
                            labelText: 'Nombre del sensor'),
                        onChanged: (value) => _nombre = value,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Escribe un nombre'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        decoration:
                            const InputDecoration(labelText: 'Ubicación'),
                        onChanged: (value) => _ubicacion = value,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Escribe una ubicación'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.save),
                        label: const Text('Registrar sensor'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00698F),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _registrarSensor,
                      ),
                    ],
                  ),
                ),
        ),
      ],
    ),
  );
}
}
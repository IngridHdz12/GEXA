import 'package:flutter/material.dart';
import '../services/fcm_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:gexa/custom_clippers.dart';
import 'auth_service.dart';
import 'login_screen.dart';
import 'add_sensor_screen.dart'; // Nueva pantalla para agregar sensores
import 'package:animate_do/animate_do.dart'; // nueva librería para animaciones
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../main.dart';
import '../notifications_service.dart'; // Asegúrate de importar tu NotificationsService

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FCMService _fcmService = FCMService();

  @override
  void initState() {
    super.initState();
    // Inicializa el token FCM
    _fcmService.inicializarToken();

    // Inicializa notificaciones locales y comienza a escuchar nivel crítico
    NotificationsService.initialize();

    // Cambia 'sensor123' por el ID real de tu sensor
    escucharNivelGasCritico('sensor123');
  }

  void escucharNivelGasCritico(String sensorId) {
    final ref = FirebaseDatabase.instance.ref('sensores/$sensorId/nivel_gas');
    ref.onValue.listen((event) {
      final valor = event.snapshot.value;
      if (valor != null && valor is num) {
        if (valor >= 300) {
          NotificationsService.showNotification(
            '⚠️ Alerta de Gas Crítico',
            'Nivel detectado: $valor ppm',
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final sensoresRef = FirebaseDatabase.instance.ref('usuarios/$uid/sensores');

  return Scaffold(
    extendBodyBehindAppBar: true,
    appBar: AppBar(
      
      title: const Text(
        'SENSORES',
        style: TextStyle(
          
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async {
            await AuthService().signOut();
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          },
        ),
      ],
    ),
      body: Stack(
      children: [
              
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

        Positioned.fill(
          child: CustomPaint(            
             size: Size(width, width * 0.5),
            painter: RPSCustomPainter8(),
          ),
        ),

        Positioned.fill(
          child: CustomPaint(
             size: Size(width, width * 0.5),
            painter: RPSCustomPainter9(),
          ),
        ),

        Positioned.fill(
          child: CustomPaint(
             size: Size(width, width * 0.5),
            painter: RPSCustomPainter10(),
          ),
        ),
      
      Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<DatabaseEvent>(
          stream: sensoresRef.onValue,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Error al cargar sensores'));
            }
            if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
              return Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    const Center(child: Text('No hay sensores registrados')),
    const SizedBox(height: 16),
    Center(
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddSensorScreen()),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white, // botón blanco
          shape: const CircleBorder(),   // forma circular
          padding: const EdgeInsets.all(20), // tamaño del botón
          elevation: 4, // sombra para darle relieve, opcional
        ),
        child: const Icon(
          Icons.add,
          color: Color(0xFF00698F), // + azul
          size: 32,
        ),
      ),
    ),
  ],
);

            }
            final sensoresMap = Map<String, dynamic>.from(
              snapshot.data!.snapshot.value as Map,
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.only(top: 80.0),
                    children: sensoresMap.entries.map((entry) {
                      final id = entry.key;
                      final datos = Map<String, dynamic>.from(entry.value);
                      final nombre = datos['nombre'] ?? 'Sensor $id';
                      final ubicacion = datos['ubicacion'] ?? 'Sin ubicación';
                      final double batteryLevel = (datos['battery'] ?? 100).toDouble();                      
                      final umbral = datos['umbral'] ?? 300;
                      final estado = datos['estado'] ?? 'NORMAL';
                      final isActive = estado != 'DESCONECTADO';
                      return GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/sensor_detail',
                            arguments: {
                              'sensorId': id,
                              'datos': datos,
                            },
                          );
                        },
                        child: StreamBuilder<DatabaseEvent>(
                          stream: FirebaseDatabase.instance
                          .ref('usuarios/$uid/$id/valor')
                          // 'usuarios/{idusuario}/$id/valor'
                          .onValue,
                          builder: (context, valorSnapshot) {
                            final valor = valorSnapshot.data?.snapshot.value ?? 0;
                            
                            return _buildSensorCard(
                              context,
                              name: nombre,
                              location: ubicacion,
                              gasLevel: valor is int ? valor : int.tryParse(valor.toString()) ?? 0,
                              threshold: umbral,
                              isActive: isActive,
                              sensorId: id,
                              batteryLevel: batteryLevel,
                            );
                            
                          },
                          
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
  child: ElevatedButton(
    onPressed: () {
      // Redirige a la pantalla de agregar sensor
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AddSensorScreen(),
        ),
      );
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.white, // fondo blanco
      shape: const CircleBorder(),   // botón circular
      padding: const EdgeInsets.all(16), // tamaño del botón
      elevation: 4,
    ),
    child: const Icon(
      Icons.add,
      color: Color(0xFF00698F), // + azul
      size: 32,
    ),
  ),
),

              ],
            );
          },
        ),
      ),
      ],
      ),
    );
  }
Widget _buildSensorCard(
  BuildContext context, {
  required String name,
  required String location,
  required int gasLevel,
  required int threshold,
  required bool isActive,
  required String sensorId,
  required double batteryLevel,
}) {
  final percentage = isActive ? (gasLevel / threshold).clamp(0.0, 1.0) : 0.0;
  final isAlert = percentage > 0.7;
  bool _notified = false;

  return ZoomIn(
    duration: const Duration(milliseconds: 500),
    child: Card(
      color: isAlert ? const Color(0xFFFFEBEE) : Colors.white,
      elevation: 6,
      margin: const EdgeInsets.symmetric(vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Fila superior con título, estado y botón eliminar
            Row(
              children: [
                Expanded(
                  child: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Chip(
                  label: Text(isActive ? 'Activo' : 'Inactivo'),
                  backgroundColor: isActive ? Colors.green[100] : Colors.grey[300],
                  labelStyle: TextStyle(
                    color: isActive ? Colors.green[800] : Colors.grey[700],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Eliminar sensor',
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Confirmar eliminación'),
                        content: Text('¿Seguro que quieres eliminar "$name"?'),
                        actions: [
                          TextButton(
                            child: const Text('Cancelar'),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                          TextButton(
                            child: const Text(
                              'Eliminar',
                              style: TextStyle(color: Colors.red),
                            ),
                            onPressed: () async {
                              Navigator.pop(ctx);
                              await FirebaseDatabase.instance
                                  .ref('sensor_gas')
                                  .child(sensorId)
                                  .remove();
                              await FirebaseDatabase.instance
                                  .ref('sensores')
                                  .child(sensorId)
                                  .remove();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),





              ],
            ),

            Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [
    
    Row(
      children: [
        Icon(
          batteryLevel > 75
              ? Icons.battery_full
              : batteryLevel > 50
                  ? Icons.battery_3_bar
                  : batteryLevel > 20
                      ? Icons.battery_2_bar
                      : Icons.battery_alert,
          color: batteryLevel < 20 ? Colors.red : Colors.green,
          size: 20,
        ),
        const SizedBox(width: 4),
        Text(
          '${batteryLevel.toStringAsFixed(0)}%',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    ),
  ],
),

            const SizedBox(height: 4),
            Text(
              location,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            if (isActive) ...[
              LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey[200],
                color: isAlert ? Colors.red : Colors.blueAccent,
                minHeight: 10,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Nivel: $gasLevel ppm',
                    style: TextStyle(
                      color: isAlert ? Colors.red : Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'Umbral: $threshold ppm',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ] else
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Sensor no conectado',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}
}
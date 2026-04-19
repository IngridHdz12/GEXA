import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../main.dart';

class SensorDetailScreen extends StatefulWidget {
  const SensorDetailScreen({super.key});

  @override
  State<SensorDetailScreen> createState() => _SensorDetailScreenState();
}

class _SensorDetailScreenState extends State<SensorDetailScreen> {
  bool _notified = false;

  void _mostrarNotificacion(int gasLevel) async {
    const androidDetails = AndroidNotificationDetails(
      'canal_gas',
      'Alerta de Gas',
      channelDescription: 'Notificaciones cuando hay niveles peligrosos de gas',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const notifDetails = NotificationDetails(android: androidDetails);

    await flutterLocalNotificationsPlugin.show(
      0,
      '⚠️ Alerta de Gas',
      'Nivel crítico detectado: $gasLevel ppm',
      notifDetails,
    );
  }

  // --- NUEVA LÓGICA DE ELIMINACIÓN ---
  void _confirmarEliminacion(BuildContext context, String nombre, String uid, String sensorId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Desvincular Dispositivo'),
        content: Text('¿Estás seguro de que quieres eliminar "$nombre"? El dispositivo se desconectará de tu Wi-Fi y volverá a su modo de configuración de fábrica.'),
        actions: [
          TextButton(
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
            onPressed: () => Navigator.pop(ctx),
          ),
          TextButton(
            child: const Text('Desvincular', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            onPressed: () async {
              // 1. Cerramos el diálogo
              Navigator.pop(ctx);
              // 2. Salimos de la pantalla de detalles hacia el Home
              Navigator.pop(context); 

              try {
                // 3. Borramos los datos de Firebase (Esto disparará el reinicio en el ESP32)
                await FirebaseDatabase.instance.ref('usuarios/$uid/sensores/$sensorId').remove();
                await FirebaseDatabase.instance.ref('sensor_gas/$sensorId').remove();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('El sensor "$nombre" ha sido desvinculado exitosamente.')),
                );
              } catch (e) {
                debugPrint("Error al eliminar: $e");
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Hubo un error al intentar desvincular el sensor.')),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final String sensorId = args['sensorId'];

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final sensorRef = FirebaseDatabase.instance.ref('usuarios/$uid/sensores/$sensorId');
    final sensorGasRef = FirebaseDatabase.instance.ref('sensor_gas');

    return Scaffold(
      backgroundColor: const Color(0xFFfbf8ef),
      appBar: AppBar(
        title: Text(
          'Detalles del Sensor',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF00698F),
      ),
      body: StreamBuilder<DatabaseEvent>(
        stream: sensorRef.onValue,
        builder: (context, snapshot) {
          if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
            // Si el sensor se acaba de borrar, se mostrará esto por un instante antes de hacer el pop()
            return const Center(child: CircularProgressIndicator());
          }

          final datos = Map<String, dynamic>.from(snapshot.data!.snapshot.value as Map);
          final nombre = datos['nombre'] ?? 'Desconocido';
          final ubicacion = datos['ubicacion'] ?? 'Sin ubicación';
          final umbral = datos['umbral'] ?? 1795;

          return StreamBuilder<DatabaseEvent>(
            stream: sensorGasRef.onValue,
            builder: (context, gasSnapshot) {
              if (!gasSnapshot.hasData || gasSnapshot.data!.snapshot.value == null) {
                return const Center(child: CircularProgressIndicator());
              }

              final gasLevel = (gasSnapshot.data!.snapshot.value as Map)['valor'] as int? ?? 0;
              final porcentaje = (gasLevel / umbral).clamp(0.0, 1.0);
              final isAlert = porcentaje > 0.7;

              if (isAlert && !_notified) {
                _mostrarNotificacion(gasLevel);
                _notified = true;
              } else if (!isAlert) {
                _notified = false;
              }

              return AnimatedContainer(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isAlert ? Colors.red.shade50 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.grey),
                        const SizedBox(width: 8),
                        Text(
                          'Ubicación: $ubicacion',
                          style: GoogleFonts.poppins(fontSize: 16),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isAlert ? '⚠️ Estado: CRÍTICO' : '✅ Estado: NORMAL',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: isAlert ? Colors.red : Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Nivel de gas:',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 500),
                      opacity: 1.0,
                      child: LinearProgressIndicator(
                        value: porcentaje,
                        minHeight: 12,
                        backgroundColor: Colors.grey.shade300,
                        color: isAlert ? Colors.red : const Color(0xFF80cbc4),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nivel actual: $gasLevel ppm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isAlert ? Colors.red : Colors.black,
                      ),
                    ),
                    Text(
                      'Umbral: $umbral ppm',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const Spacer(),
                    Center(
                      child: Icon(
                        isAlert ? Icons.warning_amber : Icons.check_circle,
                        color: isAlert ? Colors.red : Colors.green,
                        size: 80,
                      ).animate().fadeIn().scale(),
                    ),
                    const Spacer(),
                    
                    // --- BOTÓN DE ELIMINAR / DESVINCULAR ---
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.delete_outline),
                        label: Text(
                          'Desvincular Dispositivo',
                          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        onPressed: () => _confirmarEliminacion(context, nombre, uid, sensorId),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
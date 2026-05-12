import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'dart:typed_data';
import 'package:volume_controller/volume_controller.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sound_mode/sound_mode.dart';
import 'package:sound_mode/utils/ringer_mode_statuses.dart';


class NotificationsService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static double _originalVolume = 0.5; // Guardamos el volumen original

  static Future<void> initialize() async {
    // Configurar notificaciones locales (Android)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    if (!await Permission.accessNotificationPolicy.isGranted) {
      await Permission.accessNotificationPolicy.request();
    }

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) async {

        
        // Manejar cuando el usuario toque la notificación
        // 1. Cancelamos la notificación para que deje de sonar/vibrar
        await flutterLocalNotificationsPlugin.cancelAll();
        
        // 2. Restauramos el volumen original
        VolumeController.instance.setVolume(_originalVolume);
        print("Alerta detenida y volumen restaurado");
      },
    );
    // Configurar Firebase Messaging
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (message.notification != null) {

        // Guardar volumen actual antes de la tragedia
        _originalVolume = await VolumeController.instance.getVolume();
      
        // 1. Forzar el volumen al máximo usando .instance
        VolumeController.instance.setVolume(0.1);
        
        // 2. Opcional: ocultar la barra de volumen para que no estorbe visualmente
        VolumeController.instance.showSystemUI = false; 

        showNotification(
          message.notification!.title ?? 'Alerta',
          message.notification!.body ?? '',
        );
      }
    });

    // Opcional: Manejar cuando la app se abre desde la notificación (background)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      // Aquí puedes navegar a alguna pantalla específica si quieres
      print('Notificación abierta: ${message.messageId}');
    });
  }

   static Future<void> showNotification(String title, String body) async {
  // Damos 500ms para que el proceso de fondo se estabilice
  await Future.delayed(const Duration(milliseconds: 500));

  try {
    // Forzamos el modo normal y volumen ANTES de crear el canal
    await SoundMode.setSoundMode(RingerModeStatus.normal);
    await VolumeController.instance.setVolume(1.0); // Al máximo para la emergencia
  } catch (e) {
    print("Error despertando hardware: $e");
  }

  // Crea un ID de canal que NUNCA hayas usado antes
  // Si usas uno viejo, Android recordará que era 'silencioso'
  String channelId = "gexa_alarm_extreme_v100"; 

  AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
    channelId,
    'Alarmas de Seguridad GEXA',
    importance: Importance.max,
    priority: Priority.max,
    fullScreenIntent: true, // Esto intenta encender la pantalla
    category: AndroidNotificationCategory.alarm,
    audioAttributesUsage: AudioAttributesUsage.alarm,
    additionalFlags: Int32List.fromList(<int>[4, 32]), // Repetitivo y persistente
    enableVibration: true,
    vibrationPattern: Int64List.fromList([0, 1000, 500, 1000]),
  );

  await flutterLocalNotificationsPlugin.show(
    101, // ID fijo para que una alerta sobrescriba a la otra y no se amontonen
    title,
    body,
    NotificationDetails(android: androidDetails),
  );
}

}


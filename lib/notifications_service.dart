import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
class NotificationsService {
  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static Future<void> initialize() async {
    // Configurar notificaciones locales (Android)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Manejar cuando el usuario toque la notificación
      },
    );
    // Configurar Firebase Messaging
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  if (message.notification != null) {
    showNotification(
      message.notification!.title ?? 'Notificacion',
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
  const AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
    'canal_alertas',
    'Alertas Importantes',
    channelDescription: 'Canal para notificaciones de alertas de gas',
    importance: Importance.max,
    priority: Priority.high,
    icon: 'ic_stat_ic_notification', // Aquí tu ícono blanco
  );
  const NotificationDetails platformChannelSpecifics =
      NotificationDetails(android: androidPlatformChannelSpecifics);
  await flutterLocalNotificationsPlugin.show(
    0,
    title,
    body,
    platformChannelSpecifics,
    payload: 'firebase_message',
  );
}

}


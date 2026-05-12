import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:gexa/notifications_service.dart';

import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/sensor_detail_screen.dart';
import 'theme/app_theme.dart';



final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

/// Maneja mensajes cuando la app está cerrada o en segundo plano
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // 1. Inicialización vital
  await Firebase.initializeApp();

  // 2. Extraer datos (priorizando el objeto 'data' que es el que nosotros controlamos)
  String titulo = message.data['title'] ?? message.notification?.title ?? "¡ALERTA CRÍTICA!";
  String cuerpo = message.data['body'] ?? message.notification?.body ?? "Detección de Gas detectada";

  // 3. Ejecutar el servicio
  // IMPORTANTE: Asegúrate de que showNotification sea static y accesible
  await NotificationsService.showNotification(titulo, cuerpo);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicializar notificaciones locales + canal
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  

  // Solicita permisos
  //FirebaseMessaging messaging = FirebaseMessaging.instance;
  //await messaging.requestPermission();

  // 📌 SUSCRIBIRSE AL TOPIC
  //await messaging.subscribeToTopic('gas_alert');

  // Mensajes en segundo plano
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);


  runApp(const MyApp());
}



class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
   _setupFirebaseMessaging();
  }

  Future<void> _setupFirebaseMessaging() async {
    try {
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      
      // Pedir permisos sin bloquear el inicio
      await messaging.requestPermission();

      // Suscribirse al tópico (si falla, la app sigue funcionando)
      await messaging.subscribeToTopic('gas_alert');
      print("Suscrito a gas_alert con éxito");
    } catch (e) {
      print("Error configurando Firebase Messaging: $e");
    }
  }

 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GEXA',
      theme: AppTheme.lightTheme,
      routes: {
        '/': (context) => StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                return snapshot.hasData ? const HomeScreen() : const LoginScreen();
              },
            ),
        '/sensor_detail': (context) => const SensorDetailScreen(),
      },
    );
  }
}

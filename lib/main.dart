import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'notifications_service.dart'; // Aquí está la configuración del canal
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'screens/register_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/sensor_detail_screen.dart';
import 'theme/app_theme.dart';
import 'screens/auth_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
final FirebaseDatabase _database = FirebaseDatabase.instance;

/// Maneja mensajes cuando la app está cerrada o en segundo plano
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Inicializar notificaciones locales + canal
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidSettings);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  

  // Solicita permisos
  FirebaseMessaging messaging = FirebaseMessaging.instance;
  await messaging.requestPermission();

  // 📌 SUSCRIBIRSE AL TOPIC
  await messaging.subscribeToTopic('gas_alert');

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

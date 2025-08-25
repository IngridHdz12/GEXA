import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class FCMService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseDatabase _database = FirebaseDatabase.instance;
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Llama esto una vez, por ejemplo desde initState
  Future<void> inicializarToken() async {
    final user = _auth.currentUser;
    if (user != null) {
      String? token = await _messaging.getToken();
      if (token != null) {
        await _guardarToken(user.uid, token);
        debugPrint("Token FCM inicial guardado: $token");
      }
    }

    _messaging.onTokenRefresh.listen((newToken) async {
      final user = _auth.currentUser;
      if (user != null) {
        await _guardarToken(user.uid, newToken);
        debugPrint("Token FCM actualizado: $newToken");
      }
    });
  }

  Future<void> _guardarToken(String uid, String token) async {
    final ref = _database.ref("tokens_fcm/$uid");
    await ref.set({"token": token});
  }
}

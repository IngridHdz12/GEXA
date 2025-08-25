import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Registrar usuario con correo y contraseña
  Future<User?> registerWithEmail(String email, String password) async {
  try {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await userCredential.user?.sendEmailVerification(); // Opcional: verificación por email
    return userCredential.user;
  } on FirebaseAuthException catch (e) {
    print('Código de error: ${e.code}'); // Ej: 'weak-password', 'email-already-in-use'
    return null;
  }
}

  // Iniciar sesión con correo y contraseña
  Future<User?> loginWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } catch (e) {
      print('Error al iniciar sesión: $e');
      return null;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Obtener usuario actual
  User? get currentUser => _auth.currentUser;
}

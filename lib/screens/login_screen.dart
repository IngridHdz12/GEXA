import 'package:flutter/material.dart';
import 'package:gexa/custom_clippers.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'auth_service.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'dart:ui' as ui;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}




class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      final user = await _authService.loginWithEmail(email, password);
      if (user != null && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  
@override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // Fondo pintado
          Positioned.fill(
            child: CustomPaint(
               size: Size(width, width * 0.5),
              painter: RPSCustomPainter(),
            ),
          ),


          Positioned.fill(
            child: CustomPaint(
               size: Size(width, width * 0.5),
              painter: RPSCustomPainter2(),
            ),
          ),


          Positioned.fill(
            child: CustomPaint(
               size: Size(width, width * 0.5),
              painter: RPSCustomPainter3(),
            ),
          ),

          Positioned.fill(
            child: CustomPaint(
               size: Size(width, width * 0.5),
              painter: RPSCustomPainter4(),
            ),
          ),




          // Contenido principal con scroll
          Center(
            child: SingleChildScrollView(
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(22),
               
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform.translate(
                        offset: const Offset(0, -25), // negativo = hacia arriba
                        child: Image.asset(
                          'assets/Logo.png',
                          height: 80,
                        ),
                      ),
                      Transform.translate(
                        offset: const Offset(0, 60), // negativo para subir el texto
                        child: const Text(
                          'BIENVENIDO',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 255, 255, 255),
                          ),
                        ),
                      ),

                Transform.translate(
                  offset: const Offset(0, 100), // o el valor que necesites
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        autocorrect: false,
                        autofillHints: const [AutofillHints.email],
                        decoration: InputDecoration(
                          labelText: 'Correo electrónico',
                          hintText: 'ejemplo@correo.com',
                          labelStyle: const TextStyle(color: Color(0xFF666666)),
                          prefixIcon: const Icon(Icons.email, color: Color(0xFF666666)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: Color.fromARGB(255, 19, 222, 26)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: Color.fromARGB(255, 19, 222, 26)),
                          ),
                          errorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: Colors.redAccent),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: const BorderSide(color: Colors.redAccent, width: 2),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Por favor ingresa tu correo';
                          }
                          // Regex simple para email válido
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                            return 'Correo electrónico inválido';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 26),

                       //expected to find ','

                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          keyboardType: TextInputType.visiblePassword,
                          textInputAction: TextInputAction.done,
                          autocorrect: false,
                          autofillHints: const [AutofillHints.password],
                          decoration: InputDecoration(
                            labelText: 'Contraseña',
                          
                            labelStyle: const TextStyle(color: Color(0xFF666666)),
                            prefixIcon: const Icon(Icons.lock, color: Color(0xFF666666)),
                            filled: true,
                            fillColor: Colors.white.withOpacity(0.8),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: Color(0xFFCCCCCC)),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color:Color.fromARGB(255, 19, 222, 26)),
                            ),
                            errorBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(6),
                              borderSide: const BorderSide(color: Colors.redAccent),
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: const Color(0xFF666666),
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor ingresa tu contraseña';
                            }
                            if (value.length < 6) {
                              return 'Debe tener al menos 6 caracteres';
                            }
                            return null;
                          },
                        ),
],
  ),
),
                        

                       

SizedBox(height: 270),
SizedBox(
  width: double.infinity,
  child: ElevatedButton(
    onPressed: _login,
    style: ElevatedButton.styleFrom(
      backgroundColor: const Color.fromARGB(255, 0, 172, 181),
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
      ),
    ),
    child: const Text(
      'Iniciar Sesión',
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
  ),
),
                        SizedBox(height: 16),
TextButton(
  onPressed: () => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const RegisterScreen(),
    ),
  ),
  child: RichText(
    text: TextSpan(
      text: '¿No tienes cuenta? ',
      style: const TextStyle(
        fontSize: 12,
        color: Color(0xFF666666),
      ),
      children: [
        TextSpan(
          text: 'Regístrate',
          style: TextStyle(
            color: Color.fromARGB(255, 4, 124, 122),
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    ),
  ),
),

                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

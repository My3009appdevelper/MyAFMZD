import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/providers/connectivity_provider.dart';
import 'package:myafmzd/screens/home_screen.dart';
import 'package:myafmzd/providers/perfil_provider.dart'; // Cambia por tu pantalla principal real

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _cargando = false;
  String? _error;

  Future<void> _iniciarSesion() async {
    setState(() {
      _cargando = true;
      _error = null;
    });

    final hayInternet = ref.read(connectivityProvider);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text;

      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 🔹 Cargar perfil del usuario desde Firestore
      final userNotifier = ref.read(perfilProvider.notifier);
      await userNotifier.cargarUsuario(hayInternet: hayInternet);

      final usuario = ref.read(perfilProvider);
      if (usuario == null) {
        // No tiene perfil en Firestore
        await FirebaseAuth.instance.signOut();

        if (!mounted) return;
        setState(() {
          _error = 'No tienes acceso autorizado (perfil no encontrado)';
        });
        return;
      }

      // 🔸 Si todo bien, redirigir
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = _traducirError(e.code);
      });
    } catch (e) {
      setState(() {
        _error = 'Ocurrió un error inesperado';
      });
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  String _traducirError(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Correo inválido';
      case 'user-not-found':
        return 'Usuario no registrado';
      case 'wrong-password':
        return 'Contraseña incorrecta';
      default:
        return 'Error: $code';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Inicio de Sesión")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Inicia sesión como administrador',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Correo'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                  ),
                  const SizedBox(height: 20),
                  if (_error != null)
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  if (_cargando)
                    const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: CircularProgressIndicator(),
                    )
                  else
                    ElevatedButton(
                      onPressed: _iniciarSesion,
                      child: const Text('Ingresar'),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

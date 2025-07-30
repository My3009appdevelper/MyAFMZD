import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/database/usuarios/usuarios_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/login/perfil_provider.dart';
import 'package:myafmzd/screens/home_screen.dart';

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

      // 🔑 Iniciar sesión con Supabase Auth
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        setState(() {
          _error = 'No se pudo iniciar sesión. Verifica tus credenciales.';
        });
        return;
      }

      // 🔹 Cargar usuarios y distribuidores primero
      await ref
          .read(usuariosProvider.notifier)
          .cargar(hayInternet: hayInternet);
      await ref
          .read(distribuidoresProvider.notifier)
          .cargar(hayInternet: hayInternet);
      // 🔹 Cargar perfil desde tu tabla "usuarios"
      await ref
          .read(perfilProvider.notifier)
          .cargarUsuario(hayInternet: hayInternet);

      final usuario = ref.read(perfilProvider);
      if (usuario == null) {
        // Si no hay perfil en la tabla, cerrar sesión
        await Supabase.instance.client.auth.signOut();

        if (!mounted) return;
        setState(() {
          _error = 'No tienes acceso autorizado (perfil no encontrado)';
        });
        return;
      }

      // 🔸 Si todo bien, redirigir a HomeScreen
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on AuthException catch (e) {
      setState(() {
        _error = _traducirError(e.message);
      });
    } catch (e) {
      setState(() {
        _error = 'Ocurrió un error inesperado';
      });
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  String _traducirError(String message) {
    if (message.contains('Invalid login credentials')) {
      return 'Credenciales incorrectas';
    }
    if (message.contains('Email not confirmed')) {
      return 'Correo no confirmado';
    }
    return 'Error: $message';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
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

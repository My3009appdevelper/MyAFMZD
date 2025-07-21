import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:myafmzd/screens/home_screen.dart';
import 'package:myafmzd/screens/login_screen.dart';

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  @override
  void initState() {
    super.initState();
    _verificarSesion();
  }

  Future<void> _verificarSesion() async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;

    if (user == null) {
      _redirigir(const LoginScreen());
      return;
    }

    try {
      await user.reload();
      final userRecargado = auth.currentUser;

      if (userRecargado == null) {
        await auth.signOut();
        _redirigir(const LoginScreen());
        return;
      }

      _redirigir(const HomeScreen());
    } catch (e) {
      print('❌ Error al verificar usuario: $e');
      await auth.signOut();
      _redirigir(const LoginScreen());
    }
  }

  void _redirigir(Widget destino) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destino),
      );
    });
  }

  void _irALogin() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  void _irAInicio() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

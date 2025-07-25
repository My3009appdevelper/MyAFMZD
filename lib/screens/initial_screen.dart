import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'
    show ConsumerStatefulWidget, ConsumerState;
import 'package:myafmzd/providers/connectivity_provider.dart';
import 'package:myafmzd/screens/home_screen.dart';
import 'package:myafmzd/screens/login_screen.dart';
import 'package:myafmzd/providers/perfil_provider.dart';

class InitialScreen extends ConsumerStatefulWidget {
  const InitialScreen({super.key});

  @override
  ConsumerState<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends ConsumerState<InitialScreen> {
  @override
  void initState() {
    super.initState();
    _verificarSesion();
  }

  Future<void> _verificarSesion() async {
    final auth = FirebaseAuth.instance;
    final user = auth.currentUser;
    final hayInternet = ref.read(connectivityProvider);

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

      // 🔹 Cargar usuario desde Firestore
      final userNotifier = ref.read(perfilProvider.notifier);
      await userNotifier.cargarUsuario(hayInternet: hayInternet, forzar: true);

      final usuario = ref.read(perfilProvider);
      if (usuario == null) {
        // El documento del usuario no existe en Firestore
        await auth.signOut();
        _redirigir(
          const LoginScreen(),
        ); // O una pantalla con mensaje personalizado
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

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

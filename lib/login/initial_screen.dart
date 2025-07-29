import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/database/usuarios/usuarios_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myafmzd/providers/connectivity_provider.dart';
import 'package:myafmzd/screens/home_screen.dart';
import 'package:myafmzd/login/login_screen.dart';
import 'package:myafmzd/login/perfil_provider.dart';

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
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;
    final hayInternet = ref.read(connectivityProvider);

    if (user == null) {
      _redirigir(const LoginScreen());
      return;
    }

    try {
      // Supabase mantiene la sesión automáticamente si los tokens son válidos
      // Aquí cargamos el perfil desde Drift/Supabase
      await ref
          .read(usuariosProvider.notifier)
          .cargar(hayInternet: hayInternet);
      await ref
          .read(distribuidoresProvider.notifier)
          .cargar(hayInternet: hayInternet);
      await ref
          .read(perfilProvider.notifier)
          .cargarUsuario(hayInternet: hayInternet);

      final usuario = ref.read(perfilProvider);
      if (usuario == null) {
        // El registro de usuario no existe en tu tabla "usuarios"
        await supabase.auth.signOut();
        _redirigir(const LoginScreen());
        return;
      }

      _redirigir(const HomeScreen());
    } catch (e) {
      print('❌ Error al verificar usuario: $e');
      await supabase.auth.signOut();
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

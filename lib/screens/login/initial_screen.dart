import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/database/usuarios/usuarios_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myafmzd/screens/home_screen.dart';
import 'package:myafmzd/screens/login/login_screen.dart';
import 'package:myafmzd/database/perfil/perfil_provider.dart';

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

    if (user == null) {
      _redirigir(const LoginScreen());
      return;
    }

    try {
      // Supabase mantiene la sesión automáticamente si los tokens son válidos
      // Aquí cargamos el perfil desde Drift/Supabase
      await ref.read(usuariosProvider.notifier).cargarOfflineFirst();
      await ref.read(distribuidoresProvider.notifier).cargarOfflineFirst();
      await ref.read(perfilProvider.notifier).cargarUsuario();

      final usuario = ref.read(perfilProvider);
      if (usuario == null) {
        // El registro de usuario no existe en tu tabla "usuarios"
        await supabase.auth.signOut();
        _redirigir(const LoginScreen());
        return;
      }

      _redirigir(const HomeScreen());
    } catch (e) {
      print('[🏁 MENSAJES INITIAL SCREEN]❌ Error al verificar usuario: $e');
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

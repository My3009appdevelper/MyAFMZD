import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';

import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/widgets/my_loader_overlay.dart';

import 'package:myafmzd/database/asignaciones_laborales/asignaciones_laborales_provider.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_provider.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/database/modelos/modelos_provider.dart';
import 'package:myafmzd/database/usuarios/usuarios_provider.dart';
import 'package:myafmzd/database/perfil/perfil_provider.dart';

import 'package:myafmzd/screens/home_screen.dart';
import 'package:myafmzd/screens/login/login_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class InitialScreen extends ConsumerStatefulWidget {
  const InitialScreen({super.key});

  @override
  ConsumerState<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends ConsumerState<InitialScreen> {
  bool _navegando = false; // guard anti-doble navegación

  @override
  void initState() {
    super.initState();
    // Garantiza que el Overlay y el BuildContext estén listos
    WidgetsBinding.instance.addPostFrameCallback((_) => _verificarSesion());
  }

  Future<void> _verificarSesion() async {
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    // Muestra overlay desde el inicio
    if (mounted) {
      context.loaderOverlay.show(progress: 'Verificando sesión…');
    }

    // Chequeo de conectividad (no bloquea: solo avisos UX)
    final hayInternet = ref.read(connectivityProvider);

    // (Opcional) tiempo mínimo de overlay para evitar parpadeos
    const duracionMinima = Duration(milliseconds: 900);
    final inicio = DateTime.now();

    try {
      if (user == null) {
        _redirigir(const LoginScreen());
        return;
      }

      // Cargas secuenciales, con mensajes de progreso consistentes
      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.progress('Sincronizando usuarios…');
      }
      await ref.read(usuariosProvider.notifier).cargarOfflineFirst();

      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.progress('Cargando distribuidores…');
      }
      await ref.read(distribuidoresProvider.notifier).cargarOfflineFirst();

      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.progress('Cargando perfil…');
      }
      await ref.read(perfilProvider.notifier).cargarUsuario();

      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.progress('Cargando modelos…');
      }
      await ref.read(modelosProvider.notifier).cargarOfflineFirst();

      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.progress('Cargando colaboradores…');
      }
      await ref.read(colaboradoresProvider.notifier).cargarOfflineFirst();

      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.progress('Cargando asignaciones…');
      }
      await ref
          .read(asignacionesLaboralesProvider.notifier)
          .cargarOfflineFirst();

      final usuario = ref.read(perfilProvider);
      if (usuario == null) {
        await supabase.auth.signOut();
        _redirigir(const LoginScreen());
        return;
      }

      // Aviso si no hay Internet (modo local)
      if (mounted && !hayInternet) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '📴 Estás sin conexión. Trabajando con datos locales.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }

      _redirigir(const HomeScreen());
    } catch (e) {
      // Log y salida segura a Login
      // ignore: avoid_print
      print('[🏁 INITIAL SCREEN]❌ Error al verificar usuario: $e');
      await supabase.auth.signOut();
      _redirigir(const LoginScreen());
    } finally {
      // Garantiza duración mínima del overlay
      final transcurrido = DateTime.now().difference(inicio);
      if (transcurrido < duracionMinima) {
        await Future.delayed(duracionMinima - transcurrido);
      }

      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
    }
  }

  void _redirigir(Widget destino) {
    if (_navegando) return;
    _navegando = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Oculta overlay antes de navegar, por UX
      if (context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => destino),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mantén mismo patrón visual que tus otras screens:
    // el overlay muestra el estado; el body puede estar vacío.
    return const MyLoaderOverlay(child: Scaffold(body: SizedBox.shrink()));
  }
}

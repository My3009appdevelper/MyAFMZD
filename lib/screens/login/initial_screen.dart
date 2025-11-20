import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/asignaciones_laborales/asignaciones_laborales_provider.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_provider.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/database/modelos/modelo_imagenes_provider.dart';
import 'package:myafmzd/database/modelos/modelos_provider.dart';
import 'package:myafmzd/database/productos/productos_provider.dart';
import 'package:myafmzd/database/reportes/reportes_provider.dart';
import 'package:myafmzd/database/usuarios/usuarios_provider.dart';
import 'package:myafmzd/database/perfil/perfil_provider.dart';
import 'package:myafmzd/screens/home_screen.dart';
import 'package:myafmzd/screens/login/login_screen.dart';
import 'package:myafmzd/session/sesion_asignacion_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class InitialScreen extends ConsumerStatefulWidget {
  const InitialScreen({super.key});

  @override
  ConsumerState<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends ConsumerState<InitialScreen> {
  bool _navegando = false; // guard anti-doble navegación
  StreamSubscription<AuthState>? _authSub;

  // ===== NUEVO: helper para esperar la sesión inicial brevemente =====
  Future<User?> _ensureUserReady({
    Duration timeout = const Duration(milliseconds: 1200),
  }) async {
    final supabase = Supabase.instance.client;
    // 1) ¿Ya hay user?
    var user = supabase.auth.currentUser;
    if (user != null) return user;

    // 2) Espera el primer evento que traiga sesión restaurada o inicio de sesión.
    try {
      final data = await supabase.auth.onAuthStateChange
          .firstWhere(
            (e) =>
                e.event == AuthChangeEvent.initialSession ||
                e.event == AuthChangeEvent.signedIn ||
                e.event == AuthChangeEvent.tokenRefreshed,
          )
          .timeout(timeout);

      // Relee el user tras el evento
      user = supabase.auth.currentUser ?? data.session?.user;
      return user;
    } catch (_) {
      // timeout o sin evento útil → no hay sesión
      return null;
    }
  }

  @override
  void initState() {
    super.initState();

    final supabase = Supabase.instance.client;
    _authSub = supabase.auth.onAuthStateChange.listen((data) async {
      final event = data.event;

      if (event == AuthChangeEvent.signedOut ||
          event == AuthChangeEvent.userDeleted) {
        if (!mounted) return;
        await supabase.auth.signOut();
        _redirigir(const LoginScreen());
      }
      // Nota: no navegamos aquí en 'initialSession'/'signedIn'; lo maneja _verificarSesion().
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _verificarSesion());
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _verificarSesion() async {
    final supabase = Supabase.instance.client;

    if (mounted) {
      context.loaderOverlay.show(progress: 'Verificando sesión…');
    }

    await ref.read(connectivityProvider.notifier).refreshNow();
    final hayInternet = ref.read(connectivityProvider);
    const duracionMinima = Duration(milliseconds: 900);
    final inicio = DateTime.now();

    try {
      // ✅ 1) Espera breve a que Supabase restaure la sesión (si existe)
      var user = await _ensureUserReady();
      print('[MENSAJES InitialScreen]: usuario (tras ensure) -> ${user?.id}');

      // 🔄 2) Si hay internet, intenta refrescar tokens (si hay sesión)
      if (hayInternet && user != null) {
        try {
          await supabase.auth.refreshSession();
          // Relee user tras refresh
          user = supabase.auth.currentUser;
          print(
            '[MENSAJES InitialScreen]: usuario (tras refresh) -> ${user?.id}',
          );
        } on AuthException {
          await supabase.auth.signOut();
          _redirigir(const LoginScreen());
          return;
        }
      }

      // ❌ 3) Si no hay sesión real → a Login
      if (user == null) {
        _redirigir(const LoginScreen());
        return;
      }

      // 👮 5) Checa soft-delete YA con usuarios en memoria
      final eliminado = await ref
          .read(usuariosProvider.notifier)
          .estaEliminado(user.id);
      print(
        '[MENSAJES InitialScreen]: estaEliminado(${user.id}) -> $eliminado',
      );

      if (eliminado) {
        await supabase.auth.signOut();
        _redirigir(const LoginScreen());
        return;
      }

      // 🕒 Registrar última conexión al restaurar sesión
      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.progress('Registrando conexión…');
      }
      await ref
          .read(usuariosProvider.notifier)
          .registrarUltimaConexion(user.id);

      // 📦 4) Cargas en tu mismo orden
      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.progress('Cargando perfil…');
      }
      await ref.read(perfilProvider.notifier).cargarUsuario();

      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.progress('Cargando modelos…');
      }
      await ref.read(modelosProvider.notifier).cargarOfflineFirst();

      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.progress('Cargando imagenes de modelos…');
      }
      await ref.read(modeloImagenesProvider.notifier).cargarOfflineFirst();

      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.progress('Cargando distribuidores…');
      }
      await ref.read(distribuidoresProvider.notifier).cargarOfflineFirst();

      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.progress('Cargando reportes…');
      }
      await ref.read(reporteProvider.notifier).cargarOfflineFirst();

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

      final asg = ref.read(assignmentSessionProvider.notifier);
      await asg.initFromStorage();
      await asg.ensureActiveForUser(
        colaboradorUid: ref.read(perfilProvider)?.colaboradorUid,
      );

      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.progress('Cargando usuarios…');
      }
      await ref.read(usuariosProvider.notifier).cargarOfflineFirst();

      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.progress('Cargando productos…');
      }
      await ref.read(productosProvider.notifier).cargarOfflineFirst();

      // UX opcional
      if (mounted && ref.read(assignmentSessionProvider) == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No tienes asignaciones registradas')),
        );
      }

      _redirigir(const HomeScreen());
    } catch (e) {
      await supabase.auth.signOut();
      _redirigir(const LoginScreen());
    } finally {
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
    return const Scaffold(body: SizedBox.shrink());
  }
}

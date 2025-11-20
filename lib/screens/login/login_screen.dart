import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:myafmzd/database/asignaciones_laborales/asignaciones_laborales_provider.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_provider.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/database/usuarios/usuarios_provider.dart';
import 'package:myafmzd/session/sesion_asignacion_provider.dart';
import 'package:myafmzd/theme/theme_provider.dart';
import 'package:myafmzd/widgets/my_elevated_button.dart';
import 'package:myafmzd/widgets/my_text_form_field.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myafmzd/database/perfil/perfil_provider.dart';
import 'package:myafmzd/screens/home_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _error;
  bool _logueando = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Inicio de Sesión",
          style: textTheme.titleLarge?.copyWith(color: colors.onPrimary),
        ),
        centerTitle: true,
        backgroundColor: colors.primary,
        elevation: 0,
        leading: IconButton(
          icon: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
          onPressed: () {
            ref.read(themeModeProvider.notifier).toggleTheme();
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: Card(
            color: colors.surface,
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Ingresa tus credenciales',
                        style: textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      MyTextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        labelText: 'Correo',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa tu correo';
                          }
                          if (!value.contains('@')) return 'Correo inválido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      MyTextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        keyboardType: TextInputType.emailAddress,
                        labelText: 'Contraseña',
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Ingresa tu contraseña';
                          }
                          if (value.length < 6) return 'Mínimo 6 caracteres';
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      if (_error != null)
                        Text(
                          _error!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colors.error,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: MyElevatedButton(
                          onPressed: () {
                            if (_formKey.currentState?.validate() ?? false) {
                              _iniciarSesion();
                            }
                          },
                          icon: Icons.login,
                          label: 'Ingresar',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _iniciarSesion() async {
    if (_logueando) return;
    _logueando = true;

    setState(() => _error = null);
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    context.loaderOverlay.show(progress: 'Autenticando…');

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user == null) {
        if (mounted) {
          setState(() {
            _error = 'No se pudo iniciar sesión. Verifica tus credenciales.';
          });
        }
        return;
      }

      // === NUEVO PASO: verificar soft-delete inmediatamente ===
      if (context.loaderOverlay.visible) {
        context.loaderOverlay.progress('Verificando acceso…');
      }

      // Cargar usuarios offline-first para tener estado fresco (local primero, luego remote diff)
      await ref.read(usuariosProvider.notifier).cargarOfflineFirst();

      final bloqueado = await ref
          .read(usuariosProvider.notifier)
          .estaEliminado(user.id);

      print('LoginScreen: estaEliminado(${user.id}) -> $bloqueado');

      if (bloqueado) {
        // Cerrar sesión y reportar error de acceso desactivado
        await Supabase.instance.client.auth.signOut();
        if (mounted) {
          setState(() {
            _error =
                'Tu acceso ha sido desactivado. Contacta al administrador.';
          });
        }
        return;
      }

      // 🕒 Registrar última conexión (offline-first; empuja si hay internet)
      if (context.loaderOverlay.visible) {
        context.loaderOverlay.progress('Registrando conexión…');
      }
      await ref
          .read(usuariosProvider.notifier)
          .registrarUltimaConexion(user.id);

      // === Continúa tu flujo normal de cargas ===
      if (context.loaderOverlay.visible) {
        context.loaderOverlay.progress('Cargando distribuidores…');
      }
      await ref.read(distribuidoresProvider.notifier).cargarOfflineFirst();

      if (context.loaderOverlay.visible) {
        context.loaderOverlay.progress('Cargando colaboradores…');
      }
      await ref.read(colaboradoresProvider.notifier).cargarOfflineFirst();

      if (context.loaderOverlay.visible) {
        context.loaderOverlay.progress('Cargando perfil…');
      }
      await ref.read(perfilProvider.notifier).cargarUsuario();

      if (context.loaderOverlay.visible) {
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

      // (Opcional) aquí podrías cargar más módulos si lo deseas

      if (!mounted) return;

      if (context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on AuthException catch (e) {
      if (mounted) setState(() => _error = _traducirError(e.message));
    } catch (_) {
      if (mounted) setState(() => _error = 'Ocurrió un error inesperado');
    } finally {
      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
      _logueando = false;
    }
  }

  String _traducirError(String message) {
    final errores = {
      'Invalid login credentials': 'Credenciales incorrectas',
      'Email not confirmed': 'Correo no confirmado',
      'User not found': 'Usuario no registrado',
    };
    return errores.entries
            .firstWhere(
              (e) => message.contains(e.key),
              orElse: () => const MapEntry('', ''),
            )
            .value
            .isNotEmpty
        ? errores.entries.firstWhere((e) => message.contains(e.key)).value
        : 'Error: $message';
  }
}

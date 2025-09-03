import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_provider.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/database/usuarios/usuarios_provider.dart';
import 'package:myafmzd/theme/theme_provider.dart';
import 'package:myafmzd/widgets/my_elevated_button.dart';
import 'package:myafmzd/widgets/my_loader_overlay.dart';
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

    return MyLoaderOverlay(
      child: Scaffold(
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
                        const SizedBox(height: 20),
                        if (_error != null)
                          Text(
                            _error!,
                            style: textTheme.bodyMedium?.copyWith(
                              color: colors.error,
                            ),
                          ),
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
      ),
    );
  }

  Future<void> _iniciarSesion() async {
    // Evitar reentradas si se presiona el botón varias veces
    if (_logueando) return;
    _logueando = true;

    setState(() => _error = null);

    // UX: cerrar teclado antes de mostrar overlay
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    // Mostrar overlay
    context.loaderOverlay.show(progress: 'Autenticando…');

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        if (mounted) {
          setState(() {
            _error = 'No se pudo iniciar sesión. Verifica tus credenciales.';
          });
        }
        return;
      }

      // Mensajes de progreso (defensivos)
      if (context.loaderOverlay.visible) {
        context.loaderOverlay.progress('Sincronizando usuarios…');
      }
      await ref.read(usuariosProvider.notifier).cargarOfflineFirst();

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

      final usuario = ref.read(perfilProvider);
      if (usuario == null) {
        await Supabase.instance.client.auth.signOut();
        if (!mounted) return;
        setState(() {
          _error = 'No tienes acceso autorizado (perfil no encontrado)';
        });
        return;
      }

      if (!mounted) return;

      // Ocultar overlay antes de navegar
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
      // Seguridad: si no navegaste, oculta overlay
      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
      _logueando = false; // libera el guardia reentrante
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

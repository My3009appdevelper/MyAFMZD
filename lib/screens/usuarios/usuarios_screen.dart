import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/usuarios/usuarios_provider.dart';
import 'package:myafmzd/screens/usuarios/usuarios_tile.dart';
import 'package:myafmzd/screens/usuarios/usuarios_form_page.dart';
import 'package:myafmzd/widgets/my_loader_overlay.dart';

class UsuariosScreen extends ConsumerStatefulWidget {
  const UsuariosScreen({super.key});
  @override
  ConsumerState<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends ConsumerState<UsuariosScreen> {
  bool _cargandoInicial = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarUsuarios();
    });
  }

  @override
  Widget build(BuildContext context) {
    final usuariosNotifier = ref.watch(usuariosProvider);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    ref.listen<bool>(connectivityProvider, (previous, next) async {
      if (!mounted || previous == next) return;
      await _cargarUsuarios();
    });

    return MyLoaderOverlay(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            "Usuarios",
            style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: _cargandoInicial
            ? const SizedBox.shrink()
            : RefreshIndicator(
                color: colorScheme.secondary,
                onRefresh: _cargarUsuarios,
                child: ListView.builder(
                  physics: const BouncingScrollPhysics(
                    parent: AlwaysScrollableScrollPhysics(),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 24,
                  ),
                  itemCount: usuariosNotifier.length,
                  itemBuilder: (context, index) {
                    final usuario = usuariosNotifier[index];
                    return Card(
                      color: colorScheme.surface,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                      child: UsuariosItemTile(
                        key: ValueKey(usuario.uid),
                        usuario: usuario,
                        onTap: () {},
                        onActualizado: () async {
                          await _cargarUsuarios();
                        },
                      ),
                    );
                  },
                ),
              ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UsuariosFormPage()),
            );
            if (result == true) {
              await _cargarUsuarios();
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Future<void> _cargarUsuarios() async {
    if (!mounted) return;

    setState(() => _cargandoInicial = true);
    FocusScope.of(context).unfocus();

    context.loaderOverlay.show(progress: 'Cargando usuarios…');

    final inicio = DateTime.now();

    try {
      final hayInternet = ref.read(connectivityProvider);

      await ref.read(usuariosProvider.notifier).cargarOfflineFirst();

      // delay mínimo (opcional)
      const duracionMinima = Duration(milliseconds: 1500);
      final duracion = DateTime.now().difference(inicio);
      if (duracion < duracionMinima) {
        await Future.delayed(duracionMinima - duracion);
      }

      if (!mounted) return;
      if (!hayInternet) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📴 Estás sin conexión. Solo información local.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
      if (mounted) {
        setState(() => _cargandoInicial = false);
      }
    }
  }
}

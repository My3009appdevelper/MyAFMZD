import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/usuarios/usuarios_provider.dart';
import 'package:myafmzd/screens/usuarios/usuarios_tile.dart';

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
    _cargarUsuarios();
  }

  @override
  Widget build(BuildContext context) {
    final usuariosNotifier = ref.watch(usuariosProvider);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    ref.listen<bool>(connectivityProvider, (previous, next) async {
      if (previous != next && mounted) {
        await _cargarUsuarios();
      }
    });

    return Scaffold(
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
          ? Center(
              child: CircularProgressIndicator(color: colorScheme.secondary),
            )
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
                      onTap:
                          () {}, // o alguna acción rápida si luego la defines
                      onActualizado: () async {
                        await _cargarUsuarios();
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }

  Future<void> _cargarUsuarios() async {
    if (!mounted) return;

    setState(() => _cargandoInicial = true);
    final inicio = DateTime.now();

    final hayInternet = ref.read(connectivityProvider);
    await ref.read(usuariosProvider.notifier).cargarOfflineFirst();

    const duracionMinima = Duration(milliseconds: 1500);
    final duracion = DateTime.now().difference(inicio);
    if (duracion < duracionMinima) {
      await Future.delayed(duracionMinima - duracion);
    }

    if (mounted) {
      setState(() => _cargandoInicial = false);

      if (!hayInternet) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📴 Estás sin conexión. Solo información local.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

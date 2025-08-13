import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/database/usuarios/usuarios_provider.dart';
import 'package:myafmzd/screens/usuarios/usuarios_form_page.dart';

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
    final usuarios = ref.watch(usuariosProvider);
    final colorsTheme = Theme.of(context).colorScheme;
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
          style: textTheme.titleLarge?.copyWith(color: colorsTheme.onSurface),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: _cargandoInicial
          ? Center(
              child: CircularProgressIndicator(color: colorsTheme.secondary),
            )
          : RefreshIndicator(
              color: colorsTheme.secondary,
              onRefresh: _cargarUsuarios,
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 24,
                ),
                itemCount: usuarios.length,
                itemBuilder: (context, index) {
                  final usuario = usuarios[index];
                  return Card(
                    color: colorsTheme.surface,
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: ListTile(
                      onLongPress: () async {
                        final resultado = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                UsuariosFormPage(usuarioEditar: usuario),
                          ),
                        );

                        if (mounted && resultado == true) {
                          await _cargarUsuarios();
                        }
                      },

                      leading: const Icon(Icons.person),
                      title: Text(
                        usuario.nombre,
                        style: textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorsTheme.onSurface,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Correo: ${usuario.correo}',
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorsTheme.onSurface,
                            ),
                          ),
                          Text(
                            'Rol: ${usuario.rol}',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorsTheme.onSurface,
                            ),
                          ),
                          Text(
                            'Distribuidora: ${_getNombreDistribuidor(usuario.uuidDistribuidora)}',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorsTheme.onSurface,
                            ),
                          ),
                          Text(
                            'Actualizado: ${usuario.updatedAt}',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorsTheme.onSurface,
                            ),
                          ),
                          Text(
                            'Eliminado: ${usuario.deleted ? "Sí" : "No"}',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorsTheme.onSurface,
                            ),
                          ),
                          Text(
                            'Sincronizado: ${usuario.isSynced ? "Sí" : "No"}',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorsTheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      isThreeLine: true,
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

    final duracion = DateTime.now().difference(inicio);
    const duracionMinima = Duration(milliseconds: 1500);
    if (duracion < duracionMinima) {
      await Future.delayed(duracionMinima - duracion);
    }

    if (mounted) {
      setState(() => _cargandoInicial = false);

      if (!hayInternet) {
        print(
          '[📄 USUARIOS SCREEN] 📴 Estás sin conexión. Solo reportes descargados disponibles.',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📴 Estás sin conexión. Solo información local.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }

  String _getNombreDistribuidor(String uuid) {
    if (uuid == 'AFMZD') return 'AFMZD';
    final distribuidor = ref
        .read(distribuidoresProvider.notifier)
        .obtenerPorId(uuid);
    if (distribuidor != null) return distribuidor.nombre;
    return 'Sin distribuidora';
  }
}

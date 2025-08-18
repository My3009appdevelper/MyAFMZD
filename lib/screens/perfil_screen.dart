import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/usuarios/usuarios_provider.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/screens/login/perfil_provider.dart';

class PerfilScreen extends ConsumerStatefulWidget {
  const PerfilScreen({super.key});

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  bool _cargandoInicial = true;

  @override
  void initState() {
    super.initState();
    _cargarPerfil();
  }

  @override
  Widget build(BuildContext context) {
    final usuario = ref.watch(perfilProvider);
    final colorsTheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    ref.listen<bool>(connectivityProvider, (previous, next) async {
      if (previous != next && mounted) {
        await _cargarPerfil();
      }
    });

    if (usuario == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Usuario no disponible',
            style: textTheme.bodyLarge?.copyWith(color: colorsTheme.onSurface),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Perfil",
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
              onRefresh: _cargarPerfil,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  // Card de perfil
                  Center(
                    child: Card(
                      color: colorsTheme.surface,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.account_circle,
                              size: 60,
                              color: colorsTheme.onSurface,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              usuario.nombre,
                              style: textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colorsTheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            _buildUserInfoRow(
                              context,
                              Icons.email_outlined,
                              usuario.correo,
                            ),
                            _buildUserInfoRow(
                              context,
                              Icons.security_outlined,
                              usuario.rol,
                            ),
                            _buildUserInfoRow(
                              context,
                              Icons.business_outlined,
                              _getNombreDistribuidor(usuario.uuidDistribuidora),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Permisos
                  Text(
                    'Permisos',
                    style: textTheme.titleMedium?.copyWith(
                      color: colorsTheme.onSurface,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ...usuario.permisos.entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            entry.value ? Icons.check_circle : Icons.cancel,
                            color: entry.value
                                ? colorsTheme.onSurface
                                : colorsTheme.error,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: textTheme.bodyLarge?.copyWith(
                                color: colorsTheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildUserInfoRow(BuildContext context, IconData icon, String text) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: colors.onSurface),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodyLarge?.copyWith(color: colors.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cargarPerfil() async {
    if (!mounted) return;
    setState(() => _cargandoInicial = true);
    final inicio = DateTime.now();

    await ref.read(usuariosProvider.notifier).cargarOfflineFirst();
    await ref.read(distribuidoresProvider.notifier).cargarOfflineFirst();
    await ref.read(perfilProvider.notifier).cargarUsuario();
    final usuario = ref.read(perfilProvider);

    final duracion = DateTime.now().difference(inicio);
    const duracionMinima = Duration(milliseconds: 1500);
    if (duracion < duracionMinima) {
      await Future.delayed(duracionMinima - duracion);
    }

    if (!mounted) return;

    if (usuario == null) {
      setState(() => _cargandoInicial = false);
      return;
    }

    final uuid = usuario.uuidDistribuidora;
    if (uuid == 'AFMZD' || uuid.isEmpty) {
      setState(() => _cargandoInicial = false);
      return;
    }

    setState(() {
      _cargandoInicial = false;
    });
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/usuarios/usuarios_provider.dart';
import 'package:myafmzd/providers/connectivity_provider.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/login/perfil_provider.dart';

class PerfilScreen extends ConsumerStatefulWidget {
  const PerfilScreen({super.key});

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  DistribuidorDb? _distribuidor;
  bool _cargandoInicial = true;

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() => _cargandoInicial = true);
    final inicio = DateTime.now();

    final hayInternet = ref.read(connectivityProvider);

    // 🔹 Actualizar Usuarios y Distribuidoras para encontrar información del perfil
    await ref.read(usuariosProvider.notifier).cargar(hayInternet: hayInternet);
    await ref
        .read(distribuidoresProvider.notifier)
        .cargar(hayInternet: hayInternet);

    // 🔹 Cargar perfil de usuario
    await ref
        .read(perfilProvider.notifier)
        .cargarUsuario(hayInternet: hayInternet);
    final usuario = ref.read(perfilProvider);

    // ⏳ Delay mínimo para UX
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

    // 🔹 Buscar el distribuidor ya sincronizado en local
    final distribuidor = ref
        .read(distribuidoresProvider.notifier)
        .obtenerPorId(uuid);

    setState(() {
      _distribuidor = distribuidor;
      _cargandoInicial = false;
    });
  }

  String _getNombreDistribuidor(String uuid) {
    if (uuid == 'AFMZD') return 'AFMZD';
    if (_distribuidor != null) return _distribuidor!.nombre;
    return 'Sin distribuidora';
  }

  @override
  Widget build(BuildContext context) {
    final usuario = ref.watch(perfilProvider);

    if (usuario == null) {
      return const Scaffold(body: Center(child: Text('Usuario no disponible')));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("P e r f i l", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: _cargandoInicial
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  // Contenedor general con datos del perfil
                  Center(
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 10,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              Icons.account_circle,
                              size: 60,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              usuario.nombre,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            _buildUserInfoRow(
                              Icons.email_outlined,
                              usuario.correo,
                            ),
                            _buildUserInfoRow(
                              Icons.security_outlined,
                              usuario.rol,
                            ),
                            _buildUserInfoRow(
                              Icons.business_outlined,
                              _getNombreDistribuidor(usuario.uuidDistribuidora),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Sección de permisos
                  const Text(
                    'Permisos',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
                            color: entry.value ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(fontSize: 16),
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

  Widget _buildUserInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: Colors.grey[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 16),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

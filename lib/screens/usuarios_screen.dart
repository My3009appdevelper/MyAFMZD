import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/usuarios/usuarios_provider.dart';

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
    _cargar();
  }

  Future<void> _cargar() async {
    if (!mounted) return;
    setState(() => _cargandoInicial = true);
    final inicio = DateTime.now();

    final hayInternet = ref.read(connectivityProvider);
    await ref.read(usuariosProvider.notifier).cargar(hayInternet: hayInternet);

    final duracion = DateTime.now().difference(inicio);
    const duracionMinima = Duration(milliseconds: 1500);
    if (duracion < duracionMinima) {
      await Future.delayed(duracionMinima - duracion);
    }

    if (!mounted) return;
    setState(() => _cargandoInicial = false);
  }

  Future<void> _crearUsuario() async {
    // 1️⃣ Confirmación inicial
    final confirmacion = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear usuario'),
        content: const Text(
          '¿Estás seguro de que deseas crear un nuevo usuario?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (confirmacion != true) return;

    try {
      // 2️⃣ Generar correo temporal de ejemplo (puedes reemplazarlo por un form)
      final email = 'ejemplo_${DateTime.now().millisecondsSinceEpoch}@mail.com';
      final password = 'password123'; // Temporal o ingresado por admin

      // 3️⃣ Crear el usuario vía Provider (que ya hace auth + tabla)
      await ref
          .read(usuariosProvider.notifier)
          .crearUsuario(
            nombre: 'Nuevo Usuario',
            correo: email,
            password: password,
            rol: 'distribuidor',
            uuidDistribuidora: 'AFMZD',
            permisos: {'Ver reportes': true, 'Ver usuarios': false},
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Usuario creado correctamente')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error al crear usuario: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuarios = ref.watch(usuariosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Usuarios", style: TextStyle(color: Colors.black)),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: _cargandoInicial
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _cargar,
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
                    margin: const EdgeInsets.only(bottom: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                    child: ListTile(
                      leading: const Icon(Icons.person),
                      title: Text(
                        usuario.nombre,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Correo: ${usuario.correo}'),
                          Text('Rol: ${usuario.rol}'),
                          Text('Distribuidora: ${usuario.uuidDistribuidora}'),
                          Text('Actualizado: ${usuario.updatedAt.toLocal()}'),
                          Text('Eliminado: ${usuario.deleted ? "Sí" : "No"}'),
                          Text(
                            'Sincronizado: ${usuario.isSynced ? "Sí" : "No"}',
                          ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _crearUsuario,
        child: const Icon(Icons.add),
      ),
    );
  }
}

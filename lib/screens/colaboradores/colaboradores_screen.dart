import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_provider.dart';
import 'package:myafmzd/screens/colaboradores/colaboradores_form_page.dart';
import 'package:myafmzd/screens/colaboradores/colaboradores_tile.dart';

class ColaboradoresScreen extends ConsumerStatefulWidget {
  const ColaboradoresScreen({super.key});

  @override
  ConsumerState<ColaboradoresScreen> createState() =>
      _ColaboradoresScreenState();
}

class _ColaboradoresScreenState extends ConsumerState<ColaboradoresScreen> {
  bool _cargandoInicial = true;

  @override
  void initState() {
    super.initState();
    _cargarColaboradores();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Reacciona a cambios de conectividad
    ref.listen<bool>(connectivityProvider, (prev, next) async {
      if (prev != next && mounted) {
        await _cargarColaboradores();
      }
    });

    final colaboradores = ref.watch(colaboradoresProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Colaboradores",
          style: tt.titleLarge?.copyWith(color: cs.onSurface),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final ok = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ColaboradorFormPage()),
          );
          if (mounted && ok == true) {
            await _cargarColaboradores();
          }
        },
        tooltip: 'Agregar colaborador',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildResumen(context, colaboradores.length),
          Expanded(
            child: _cargandoInicial
                ? Center(child: CircularProgressIndicator(color: cs.secondary))
                : RefreshIndicator(
                    color: cs.secondary,
                    onRefresh: _cargarColaboradores,
                    child: colaboradores.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 80),
                              Center(child: Text('No hay colaboradores')),
                            ],
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 24,
                            ),
                            itemCount: colaboradores.length,
                            itemBuilder: (context, index) {
                              final c = colaboradores[index];
                              return Card(
                                color: cs.surface,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                child: ColaboradorItemTile(
                                  key: ValueKey(c.uid),
                                  colaborador: c,
                                  onTap: () {},
                                  onActualizado: () async {
                                    await _cargarColaboradores();
                                  },
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumen(BuildContext context, int totalActual) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Chip(
            label: Text('Total: $totalActual'),
            backgroundColor: colorScheme.surface,
          ),
        ],
      ),
    );
  }

  Future<void> _cargarColaboradores() async {
    if (!mounted) return;

    setState(() => _cargandoInicial = true);
    final inicio = DateTime.now();

    final hayInternet = ref.read(connectivityProvider);
    await ref.read(colaboradoresProvider.notifier).cargarOfflineFirst();

    // spinner mínimo para consistencia con otras pantallas
    const duracionMinima = Duration(milliseconds: 1500);
    final duracion = DateTime.now().difference(inicio);
    if (duracion < duracionMinima) {
      await Future.delayed(duracionMinima - duracion);
    }

    if (!mounted) return;
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

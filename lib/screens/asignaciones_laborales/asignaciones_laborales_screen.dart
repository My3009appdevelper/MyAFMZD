import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/asignaciones_laborales/asignaciones_laborales_provider.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/screens/asignaciones_laborales/asignaciones_laborales_form_page.dart';
import 'package:myafmzd/screens/asignaciones_laborales/asignaciones_laborales_tile.dart';

class AsignacionesLaboralesScreen extends ConsumerStatefulWidget {
  const AsignacionesLaboralesScreen({super.key});

  @override
  ConsumerState<AsignacionesLaboralesScreen> createState() =>
      _AsignacionesLaboralesScreenState();
}

class _AsignacionesLaboralesScreenState
    extends ConsumerState<AsignacionesLaboralesScreen> {
  bool _cargandoInicial = true;

  // Filtros
  bool _soloActivas = true; // Activas (true) / Históricas (false)
  String _filtroRol = ''; // vacío => todos
  String _filtroDistribuidorUid = ''; // vacío => todos

  @override
  void initState() {
    super.initState();
    _cargarAsignaciones();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Reacciona a cambios de conectividad
    ref.listen<bool>(connectivityProvider, (prev, next) async {
      if (prev != next && mounted) {
        await _cargarAsignaciones();
      }
    });

    // Forzar rebuild ante cambios de estado
    final _ = ref.watch(asignacionesLaboralesProvider);

    // Datos auxiliares para filtros
    final roles = ref
        .read(asignacionesLaboralesProvider.notifier)
        .opcionesRol; // ['vendedor',...]
    final distribuidores =
        ref.watch(distribuidoresProvider).where((d) => !d.deleted).toList()
          ..sort((a, b) => a.nombre.compareTo(b.nombre));

    // Lista visible (derivada del provider)
    final visibles = _soloActivas
        ? ref
              .read(asignacionesLaboralesProvider.notifier)
              .listarActivas(
                rol: _filtroRol.isEmpty ? null : _filtroRol,
                distribuidorUid: _filtroDistribuidorUid.isEmpty
                    ? null
                    : _filtroDistribuidorUid,
              )
        : ref
              .read(asignacionesLaboralesProvider.notifier)
              .listarHistoricas(
                rol: _filtroRol.isEmpty ? null : _filtroRol,
                distribuidorUid: _filtroDistribuidorUid.isEmpty
                    ? null
                    : _filtroDistribuidorUid,
              );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Asignaciones laborales",
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
            MaterialPageRoute(
              builder: (_) => const AsignacionLaboralFormPage(),
            ),
          );
          if (mounted && ok == true) {
            await _cargarAsignaciones();
          }
        },
        tooltip: 'Nueva asignación',
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          _buildFiltros(context, roles, distribuidores, visibles.length),
          Expanded(
            child: _cargandoInicial
                ? Center(child: CircularProgressIndicator(color: cs.secondary))
                : RefreshIndicator(
                    color: cs.secondary,
                    onRefresh: _cargarAsignaciones,
                    child: visibles.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 80),
                              Center(child: Text('No hay asignaciones')),
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
                            itemCount: visibles.length,
                            itemBuilder: (context, index) {
                              final a = visibles[index];
                              return Card(
                                color: cs.surface,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                child: AsignacionLaboralItemTile(
                                  key: ValueKey(a.uid),
                                  asignacion: a,
                                  onTap: () {},
                                  onActualizado: () async {
                                    await _cargarAsignaciones();
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

  // ========================== Filtros UI =====================================

  Widget _buildFiltros(
    BuildContext context,
    List<String> roles,
    List<DistribuidorDb> distribuidores,
    int totalActual,
  ) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        children: [
          // Línea 1: chips Activas / Históricas + Total
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('Activas'),
                selected: _soloActivas,
                onSelected: (v) => setState(() => _soloActivas = true),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Históricas'),
                selected: !_soloActivas,
                onSelected: (v) => setState(() => _soloActivas = false),
              ),
              const SizedBox(width: 12),
              Chip(
                label: Text('Total: $totalActual'),
                backgroundColor: cs.surface,
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Línea 2: filtros por Rol y Distribuidor
          Row(
            children: [
              // Rol
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _filtroRol.isEmpty ? null : _filtroRol,
                  items: [
                    const DropdownMenuItem(value: '', child: Text('— Todos —')),
                    ...roles.map(
                      (r) => DropdownMenuItem(value: r, child: Text(r)),
                    ),
                  ],
                  onChanged: (v) => setState(() => _filtroRol = v ?? ''),
                  decoration: InputDecoration(
                    labelText: 'Rol',
                    labelStyle: tt.bodyLarge?.copyWith(color: cs.onSurface),
                    filled: true,
                    fillColor: cs.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Distribuidor
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _filtroDistribuidorUid.isEmpty
                      ? null
                      : _filtroDistribuidorUid,
                  items: [
                    const DropdownMenuItem(value: '', child: Text('— Todos —')),
                    ...distribuidores.map(
                      (d) =>
                          DropdownMenuItem(value: d.uid, child: Text(d.nombre)),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => _filtroDistribuidorUid = v ?? ''),
                  decoration: InputDecoration(
                    labelText: 'Distribuidor',
                    labelStyle: tt.bodyLarge?.copyWith(color: cs.onSurface),
                    filled: true,
                    fillColor: cs.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================ Carga ========================================

  Future<void> _cargarAsignaciones() async {
    if (!mounted) return;

    setState(() => _cargandoInicial = true);
    final inicio = DateTime.now();

    final hayInternet = ref.read(connectivityProvider);
    await ref.read(asignacionesLaboralesProvider.notifier).cargarOfflineFirst();

    // spinner mínimo para consistencia
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

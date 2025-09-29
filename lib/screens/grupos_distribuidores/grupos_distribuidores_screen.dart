import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/grupo_distribuidores/grupos_distribuidores_provider.dart';
import 'package:myafmzd/screens/grupos_distribuidores/grupos_distribuidores_form_page.dart';
import 'package:myafmzd/screens/grupos_distribuidores/grupos_distribuidores_tile.dart';

class GruposDistribuidoresScreen extends ConsumerStatefulWidget {
  const GruposDistribuidoresScreen({super.key});

  @override
  ConsumerState<GruposDistribuidoresScreen> createState() =>
      _GruposDistribuidoresScreenState();
}

class _GruposDistribuidoresScreenState
    extends ConsumerState<GruposDistribuidoresScreen> {
  bool _cargandoInicial = true;
  bool _incluirInactivos = true; // Activos (false) / Todos (true)

  @override
  void initState() {
    super.initState();
    // Disparar carga tras el primer frame (patrón consistente)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarGrupos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Listener de conectividad (igual que en otras screens)
    ref.listen<bool>(connectivityProvider, (prev, next) async {
      if (!mounted || prev == next) return;
      await _cargarGrupos();
    });

    // Estado base desde el provider
    final grupos = ref.watch(gruposDistribuidoresProvider);

    // Filtrado local (sin depender de helpers del notifier)
    final visibles =
        grupos
            .where((g) => !g.deleted)
            .where((g) => _incluirInactivos ? true : g.activo)
            .toList()
          ..sort((a, b) => a.nombre.compareTo(b.nombre));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Grupos de distribuidoras",
          style: tt.titleLarge?.copyWith(color: cs.onSurface),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      floatingActionButton: _cargandoInicial
          ? null
          : FloatingActionButton(
              onPressed: () async {
                final ok = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GrupoDistribuidorFormPage(),
                  ),
                );
                if (mounted && ok == true) {
                  await _cargarGrupos();
                }
              },
              tooltip: 'Nuevo grupo',
              child: const Icon(Icons.add),
            ),
      body: Column(
        children: [
          if (!_cargandoInicial) _buildFiltros(context, visibles.length),
          Expanded(
            child: _cargandoInicial
                ? const SizedBox.shrink() // el overlay ya muestra “Cargando…”
                : RefreshIndicator(
                    color: cs.secondary,
                    onRefresh: _cargarGrupos,
                    child: visibles.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 80),
                              Center(child: Text('No hay grupos')),
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
                              final g = visibles[index];
                              return Card(
                                color: cs.surface,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                child: GrupoDistribuidorItemTile(
                                  key: ValueKey(g.uid),
                                  grupo: g,
                                  onTap: () {},
                                  onActualizado: () async {
                                    await _cargarGrupos();
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

  Widget _buildFiltros(BuildContext context, int totalActual) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ChoiceChip(
            label: const Text('Solo activos'),
            selected: !_incluirInactivos,
            onSelected: (_) => setState(() => _incluirInactivos = false),
          ),
          const SizedBox(width: 8),
          ChoiceChip(
            label: const Text('Todos'),
            selected: _incluirInactivos,
            onSelected: (_) => setState(() => _incluirInactivos = true),
          ),
          const SizedBox(width: 12),
          Chip(
            label: Text('Total: $totalActual'),
            backgroundColor: cs.surface,
            labelStyle: tt.bodyMedium?.copyWith(color: cs.onSurface),
          ),
        ],
      ),
    );
  }

  // ============================ Carga ========================================

  Future<void> _cargarGrupos() async {
    if (!mounted) return;

    setState(() => _cargandoInicial = true);

    // UX: cerrar teclado si estaba abierto
    FocusScope.of(context).unfocus();

    // Overlay consistente
    context.loaderOverlay.show(progress: 'Cargando grupos…');
    final inicio = DateTime.now();

    try {
      final hayInternet = ref.read(connectivityProvider);

      await ref
          .read(gruposDistribuidoresProvider.notifier)
          .cargarOfflineFirst();

      // spinner mínimo para consistencia visual
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

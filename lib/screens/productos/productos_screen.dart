import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/productos/productos_provider.dart';
import 'package:myafmzd/screens/productos/productos_form_page.dart';
import 'package:myafmzd/screens/productos/productos_tile.dart';

class ProductosScreen extends ConsumerStatefulWidget {
  const ProductosScreen({super.key});

  @override
  ConsumerState<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends ConsumerState<ProductosScreen> {
  bool _cargandoInicial = true;

  @override
  void initState() {
    super.initState();
    // Asegura que el overlay ya está en el árbol antes de usarlo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarProductos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    ref.listen<bool>(connectivityProvider, (prev, next) async {
      if (!mounted || prev == next) return;
      await _cargarProductos();
    });

    // Lista filtrada desde el notifier (orden por prioridad asc + updatedAt desc)
    final visibles = ref
        .watch(productosProvider.notifier)
        .filtrar(soloVigentes: false, incluirInactivos: true, enFecha: null);

    return Scaffold(
      floatingActionButton: _cargandoInicial
          ? null
          : FloatingActionButton(
              onPressed: () async {
                final ok = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProductoFormPage()),
                );
                if (mounted && ok == true) {
                  await _cargarProductos();
                }
              },
              tooltip: 'Agregar producto',
              child: const Icon(Icons.add),
            ),
      body: Column(
        children: [
          if (!_cargandoInicial) _buildFiltros(context, visibles.length),
          Expanded(
            child: _cargandoInicial
                ? const SizedBox.shrink() // overlay se encarga del “Cargando…”
                : RefreshIndicator(
                    color: cs.secondary,
                    onRefresh: _cargarProductos,
                    child: visibles.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 80),
                              Center(child: Text('No hay productos')),
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
                              final p = visibles[index];
                              return Card(
                                color: cs.surface,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                child: ProductoItemTile(
                                  key: ValueKey(p.uid),
                                  producto: p,
                                  onTap: () {},
                                  onActualizado: () async {
                                    await _cargarProductos();
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
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 8),
          Chip(
            label: Text('Total: $totalActual'),
            backgroundColor: colorScheme.surface,
          ),
        ],
      ),
    );
  }

  // ============================ Carga ========================================

  Future<void> _cargarProductos() async {
    if (!mounted) return;

    setState(() => _cargandoInicial = true);

    // UX: ocultar teclado si estaba abierto
    FocusScope.of(context).unfocus();

    // Mostrar overlay consistente
    context.loaderOverlay.show(progress: 'Cargando productos…');

    final inicio = DateTime.now();

    try {
      final hayInternet = ref.read(connectivityProvider);

      await ref.read(productosProvider.notifier).cargarOfflineFirst();

      // Mantener consistencia visual (mismo mínimo que otras screens)
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

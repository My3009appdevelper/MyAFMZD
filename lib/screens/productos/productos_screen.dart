import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    _cargarProductos();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Reacciona a cambios de conectividad
    ref.listen<bool>(connectivityProvider, (prev, next) async {
      if (prev != next && mounted) {
        await _cargarProductos();
      }
    });

    // Lista filtrada desde el notifier (orden por prioridad asc + updatedAt desc)
    final visibles = ref
        .watch(productosProvider.notifier)
        .filtrar(
          soloVigentes: false, // ← sin vigencia
          incluirInactivos: true,
          enFecha: null, // ← sin vigencia
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Productos",
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
          _buildFiltros(context, visibles.length),
          Expanded(
            child: _cargandoInicial
                ? Center(child: CircularProgressIndicator(color: cs.secondary))
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
                                  onTap:
                                      () {}, // acción rápida futura si quieres
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
    final inicio = DateTime.now();

    final hayInternet = ref.read(connectivityProvider);
    await ref.read(productosProvider.notifier).cargarOfflineFirst();

    // spinner mínimo para mantener consistencia visual
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

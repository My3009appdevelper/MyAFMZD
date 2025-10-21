import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/estatus/estatus_provider.dart';
import 'package:myafmzd/screens/estatus/estatus_form_page.dart';
import 'package:myafmzd/screens/estatus/estatus_tile.dart';
import 'package:myafmzd/widgets/my_expandable_fab_options.dart';

class EstatusScreen extends ConsumerStatefulWidget {
  const EstatusScreen({super.key});

  @override
  ConsumerState<EstatusScreen> createState() => _EstatusScreenState();
}

class _EstatusScreenState extends ConsumerState<EstatusScreen> {
  bool _cargandoInicial = true;

  // Filtro: solo categoría
  String _categoriaSel = ''; // vacío => todas

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarEstatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    ref.listen<bool>(connectivityProvider, (prev, next) async {
      if (!mounted || prev == next) return;
      await _cargarEstatus();
    });

    final estatus = ref.watch(estatusProvider);

    // Categorías para el dropdown
    final categorias =
        estatus
            .where((e) => !e.deleted)
            .map((e) => e.categoria.trim())
            .where((c) => c.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    // Visibles: solo no eliminados + visibles; filtra por categoría si aplica
    final visibles =
        estatus
            .where((e) => !e.deleted)
            .where((e) => e.visible)
            .where(
              (e) =>
                  _categoriaSel.isEmpty ? true : e.categoria == _categoriaSel,
            )
            .toList()
          ..sort((a, b) {
            final byOrden = a.orden.compareTo(b.orden);
            if (byOrden != 0) return byOrden;
            return a.nombre.compareTo(b.nombre);
          });

    return Scaffold(
      floatingActionButton: _cargandoInicial
          ? null
          : FabConMenuAnchor(
              onAgregar: _abrirFormNuevoEstatus,
              onImportar: _importarEstatus,
              onExportar: _exportarEstatus,
              txtAgregar: 'Agregar estatus',
              txtImportar: 'Importar desde CSV',
              txtExportar: 'Exportar a CSV',
              iconMain: Icons.apps,
              iconAgregar: Icons.add,
              iconImportar: Icons.upload,
              iconExportar: Icons.download,
              fabTooltip: 'Acciones de estatus',
            ),
      body: Column(
        children: [
          if (!_cargandoInicial) _buildFiltroCategoria(context, categorias),
          Expanded(
            child: _cargandoInicial
                ? const SizedBox.shrink()
                : RefreshIndicator(
                    color: cs.secondary,
                    onRefresh: _cargarEstatus,
                    child: visibles.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 80),
                              Center(child: Text('No hay estatus')),
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
                              final e = visibles[index];
                              return Card(
                                color: cs.surface,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                child: EstatusItemTile(
                                  key: ValueKey(e.uid),
                                  estatus: e,
                                  onTap: () {},
                                  onActualizado: () async {
                                    await _cargarEstatus();
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

  // ========================== Filtro: categoría ===============================
  Widget _buildFiltroCategoria(BuildContext context, List<String> categorias) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        children: [
          Expanded(
            child: DropdownButtonFormField<String>(
              isExpanded: true,
              value: _categoriaSel.isEmpty ? null : _categoriaSel,
              items: [
                const DropdownMenuItem(value: '', child: Text('— Todas —')),
                ...categorias.map(
                  (c) => DropdownMenuItem(value: c, child: Text(c)),
                ),
              ],
              onChanged: (v) => setState(() => _categoriaSel = v ?? ''),
              decoration: InputDecoration(
                labelText: 'Categoría',
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
    );
  }

  // ============================ Carga ========================================
  Future<void> _cargarEstatus() async {
    if (!mounted) return;

    setState(() => _cargandoInicial = true);
    FocusScope.of(context).unfocus();

    context.loaderOverlay.show(progress: 'Cargando estatus…');
    final inicio = DateTime.now();

    try {
      final hayInternet = ref.read(connectivityProvider);

      await ref.read(estatusProvider.notifier).cargarOfflineFirst();

      const minSpin = Duration(milliseconds: 1500);
      final elapsed = DateTime.now().difference(inicio);
      if (elapsed < minSpin) {
        await Future.delayed(minSpin - elapsed);
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
      if (mounted) setState(() => _cargandoInicial = false);
    }
  }

  Future<void> _abrirFormNuevoEstatus() async {
    final ok = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EstatusFormPage()),
    );
    if (mounted && ok == true) {
      await _cargarEstatus();
    }
  }

  Future<void> _importarEstatus() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (res == null || res.files.single.bytes == null) return;

    context.loaderOverlay.show(progress: 'Importando estatus…');
    try {
      final (ins, skip) = await ref
          .read(estatusProvider.notifier)
          .importarCsvEstatus(csvBytes: res.files.single.bytes!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Importados: $ins • Saltados (duplicados): $skip'),
        ),
      );
      await _cargarEstatus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al importar CSV: $e')));
      }
    } finally {
      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
    }
  }

  Future<void> _exportarEstatus() async {
    context.loaderOverlay.show(progress: 'Generando CSV…');
    try {
      final path = await ref
          .read(estatusProvider.notifier)
          .exportarCsvAArchivo();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CSV guardado en:\n$path')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al exportar: $e')));
      }
    } finally {
      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
    }
  }
}

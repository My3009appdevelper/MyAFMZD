// lib/screens/ventas/ventas_screen.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/ventas/ventas_provider.dart';
import 'package:myafmzd/widgets/my_expandable_fab_options.dart';

class VentasScreen extends ConsumerStatefulWidget {
  const VentasScreen({super.key});

  @override
  ConsumerState<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends ConsumerState<VentasScreen> {
  bool _cargandoInicial = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarVentas());
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    ref.listen<bool>(connectivityProvider, (prev, next) async {
      if (!mounted || prev == next) return;
      await _cargarVentas();
    });

    final ventas = ref.watch(ventasProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Ventas',
          style: tt.titleLarge?.copyWith(color: cs.onSurface),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      floatingActionButton: FabConMenuAnchor(
        onAgregar: null, // por ahora no hay alta desde aquí
        onImportar: _importarVentas,
        onExportar: _exportarVentas,
        txtAgregar: 'Agregar venta',
        txtImportar: 'Importar desde CSV',
        txtExportar: 'Exportar a CSV',
        iconMain: Icons.apps,
        iconAgregar: Icons.playlist_add,
        iconImportar: Icons.upload,
        iconExportar: Icons.download,
        fabTooltip: 'Acciones de ventas',
      ),
      body: Column(
        children: [
          if (!_cargandoInicial) _buildResumen(context, ventas.length),
          Expanded(
            child: _cargandoInicial
                ? const SizedBox.shrink()
                : RefreshIndicator(
                    color: cs.secondary,
                    onRefresh: _cargarVentas,
                    child: ventas.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 80),
                              Center(child: Text('No hay ventas')),
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
                            itemCount: ventas.length,
                            itemBuilder: (context, index) {
                              final v = ventas[index];
                              return Card(
                                color: cs.surface,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                child: ListTile(
                                  title: Text(
                                    v.folioContrato.isEmpty
                                        ? '(sin folio)'
                                        : v.folioContrato,
                                  ),
                                  subtitle: Text(
                                    'Vendedor: ${v.vendedorUid} • Modelo: ${v.modeloUid}',
                                  ),
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

  Future<void> _cargarVentas() async {
    if (!mounted) return;
    setState(() => _cargandoInicial = true);
    FocusScope.of(context).unfocus();
    context.loaderOverlay.show(progress: 'Cargando ventas…');

    final inicio = DateTime.now();
    try {
      final hayInternet = ref.read(connectivityProvider);
      await ref.read(ventasProvider.notifier).cargarOfflineFirst();

      const duracionMin = Duration(milliseconds: 1500);
      final trans = DateTime.now().difference(inicio);
      if (trans < duracionMin) {
        await Future.delayed(duracionMin - trans);
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

  // IMPORTAR (solo inserta; muestra duplicados saltados)
  Future<void> _importarVentas() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (res == null || res.files.single.bytes == null) return;

    context.loaderOverlay.show(progress: 'Importando ventas…');
    try {
      final (ins, skip) = await ref
          .read(ventasProvider.notifier)
          .importarCsvVentas(csvBytes: res.files.single.bytes!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Importadas: $ins • Saltadas (duplicadas): $skip'),
        ),
      );
      await _cargarVentas();
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

  // EXPORTAR
  Future<void> _exportarVentas() async {
    context.loaderOverlay.show(progress: 'Generando CSV…');
    try {
      final path = await ref
          .read(ventasProvider.notifier)
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

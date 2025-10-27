import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/modelos/modelo_imagenes_provider.dart';
import 'package:myafmzd/database/modelos/modelos_provider.dart';
import 'package:myafmzd/screens/modelos/modelo_detalle_page.dart';
import 'package:myafmzd/screens/modelos/modelos_form_page.dart';
import 'package:myafmzd/screens/modelos/modelos_tile.dart';
import 'package:myafmzd/widgets/my_expandable_fab_options.dart';

class ModelosScreen extends ConsumerStatefulWidget {
  const ModelosScreen({super.key});

  @override
  ConsumerState<ModelosScreen> createState() => _ModelosScreenState();
}

class _ModelosScreenState extends ConsumerState<ModelosScreen> {
  bool _cargandoInicial = true;

  int? _anioSeleccionado; // null => Todos
  bool _soloActivos = false;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    // Misma mecánica que en las otras screens: lanzar carga tras el primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarModelos();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Conectividad (mismo listener que en el resto)
    ref.listen<bool>(connectivityProvider, (prev, next) async {
      if (!mounted || prev == next) return;
      await _cargarModelos();
    });

    final tipos = ref
        .watch(modelosProvider.notifier)
        .tiposUnicos; // incluye "Todos"
    final anios = [...ref.watch(modelosProvider.notifier).aniosUnicos.reversed];

    // 🛡️ Si cambia la longitud de tabs, ajusta _tabIndex
    final tabsLen = tipos.isEmpty ? 1 : tipos.length;
    if (_tabIndex >= tabsLen) {
      _tabIndex = tabsLen - 1;
      if (_tabIndex < 0) _tabIndex = 0;
    }

    final Map<String, List<ModeloDb>> grupos = {
      for (final t in tipos)
        t: ref
            .read(modelosProvider.notifier)
            .filtrar(
              tipo: t == 'Todos' ? null : t,
              incluirInactivos: !_soloActivos,
              anio: _anioSeleccionado,
            ),
    };

    return DefaultTabController(
      initialIndex: _tabIndex,
      length: tabsLen,
      child: Scaffold(
        floatingActionButton: _cargandoInicial
            ? null
            : FabConMenuAnchor(
                onAgregar: _abrirFormNuevoModelo,
                onExportar: _exportarModelos,
                txtAgregar: 'Agregar modelo',
                txtExportar: 'Exportar a CSV',
                iconMain: Icons.apps,
                iconAgregar: Icons.directions_car_filled_outlined,
                iconExportar: Icons.download,
                fabTooltip: 'Acciones de modelos',
              ),
        body: _cargandoInicial
            ? const SizedBox.shrink()
            : Column(
                children: [
                  TabBar(
                    isScrollable: true,
                    indicatorColor: cs.onSurface,
                    labelColor: cs.onSurface,
                    unselectedLabelColor: cs.secondary.withOpacity(0.6),
                    // ✅ Persiste selección del tab
                    onTap: (i) => setState(() => _tabIndex = i),
                    tabs: [
                      for (final t in tipos)
                        Tab(text: '$t (${grupos[t]?.length ?? 0})'),
                    ],
                  ),
                  _buildFiltros(context, anios, grupos['Todos']?.length ?? 0),
                  Expanded(
                    child: tipos.isEmpty
                        ? Center(
                            child: Text(
                              'No hay modelos para mostrar',
                              style: tt.bodyLarge?.copyWith(
                                color: cs.onSurface,
                              ),
                            ),
                          )
                        : TabBarView(
                            children: [
                              for (final t in tipos)
                                RefreshIndicator(
                                  color: cs.secondary,
                                  onRefresh: _cargarModelos,
                                  child: _buildListaTab(
                                    context,
                                    grupos[t] ?? const [],
                                  ),
                                ),
                            ],
                          ),
                  ),
                ],
              ),
      ),
    );
  }

  // ========================== Widgets auxiliares ==============================

  Widget _buildFiltros(BuildContext context, List<int> anios, int totalActual) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        children: [
          // Línea 1: chips de año
          SizedBox(
            height: 44,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const labelPad = EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                );
                final textTheme = Theme.of(context).textTheme;
                final colorScheme = Theme.of(context).colorScheme;

                final chips = <Widget>[
                  // Resto de años
                  for (final y in anios)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Builder(
                        builder: (context) {
                          final sel = _anioSeleccionado == y;
                          return ChoiceChip(
                            label: Text(
                              y.toString(),
                              style: textTheme.labelLarge?.copyWith(
                                color: sel
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurface,
                              ),
                            ),
                            selected: sel,
                            onSelected: (_) =>
                                setState(() => _anioSeleccionado = y),
                            showCheckmark: false,
                            side: BorderSide(
                              color: colorScheme.outlineVariant.withOpacity(
                                0.45,
                              ),
                              width: 1,
                            ),
                            shape: const StadiumBorder(),
                            labelPadding: labelPad,
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            backgroundColor: colorScheme.surface,
                            selectedColor: colorScheme.primaryContainer,
                          );
                        },
                      ),
                    ),
                ];

                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: chips,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildListaTab(BuildContext context, List<ModeloDb> modelos) {
    final cs = Theme.of(context).colorScheme;

    if (modelos.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 80),
          Center(child: Text('No hay modelos para este filtro')),
        ],
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: modelos.length,
      itemBuilder: (context, index) {
        final m = modelos[index];
        return Card(
          color: cs.surface,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: ModeloItemTile(
            key: ValueKey(m.uid),
            modelo: m,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ModeloDetallePage(modeloUid: m.uid),
                ),
              );
            },
            onActualizado: () async {
              await _cargarModelos();
            },
          ),
        );
      },
    );
  }

  bool updatedHasLocal(ModeloDb? m) {
    if (m == null) return false;
    return m.fichaRutaLocal.isNotEmpty && File(m.fichaRutaLocal).existsSync();
  }

  // ============================ Carga con Overlay ==============================

  Future<void> _cargarModelos() async {
    if (!mounted) return;

    setState(() => _cargandoInicial = true);
    FocusScope.of(context).unfocus();

    // Mostrar overlay (idéntico patrón)
    context.loaderOverlay.show(progress: 'Cargando modelos…');

    final inicio = DateTime.now();

    // Capturar refs antes de await (buenas prácticas)
    final hayInternet = ref.read(connectivityProvider);
    final modelosN = ref.read(modelosProvider.notifier);
    final imgsN = ref.read(modeloImagenesProvider.notifier);

    try {
      await modelosN.cargarOfflineFirst();

      if (!mounted) return;
      if (context.loaderOverlay.visible) {
        context.loaderOverlay.progress('Cargando imágenes…');
      }

      await imgsN.cargarOfflineFirst();

      // delay mínimo para UX consistente
      const minSpin = Duration(milliseconds: 1500);
      final elapsed = DateTime.now().difference(inicio);
      if (elapsed < minSpin) {
        await Future.delayed(minSpin - elapsed);
      }

      if (!mounted) return;

      if (!hayInternet) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '📴 Estás sin conexión. Solo fichas descargadas disponibles.',
            ),
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

  Future<void> _abrirFormNuevoModelo() async {
    final ok = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ModelosFormPage()),
    );
    if (mounted && ok == true) {
      await _cargarModelos();
    }
  }

  // ignore: unused_element
  Future<void> _importarModelos() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (res == null || res.files.single.bytes == null) return;

    context.loaderOverlay.show(progress: 'Importando modelos…');
    try {
      final (ins, skip) = await ref
          .read(modelosProvider.notifier)
          .importarCsvModelos(csvBytes: res.files.single.bytes!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Importados: $ins • Saltados (duplicados): $skip'),
        ),
      );
      await _cargarModelos();
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

  Future<void> _exportarModelos() async {
    context.loaderOverlay.show(progress: 'Generando CSV…');
    try {
      final path = await ref
          .read(modelosProvider.notifier)
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

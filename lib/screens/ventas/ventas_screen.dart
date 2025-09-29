// lib/screens/ventas/ventas_screen.dart
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/asignaciones_laborales/asignaciones_laborales_provider.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_provider.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/database/estatus/estatus_provider.dart';
import 'package:myafmzd/database/ventas/ventas_provider.dart';
import 'package:myafmzd/screens/ventas/ventas_tile.dart';
import 'package:myafmzd/widgets/my_expandable_fab_options.dart';
import 'dart:math' as math;

class VentasScreen extends ConsumerStatefulWidget {
  const VentasScreen({super.key});

  @override
  ConsumerState<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends ConsumerState<VentasScreen> {
  bool _cargandoInicial = true;

  // ----- Estado de filtros -----
  int? _filtroAnio;
  int? _filtroMes;
  String _filtroDistribuidoraUid = '';
  String _filtroVendedorAsignacionUid = '';

  // Mostrar/ocultar panel de filtros
  bool _mostrarFiltros = false;

  // ----- Estado de paginación -----
  final int _pageSize = 1000;
  int _page = 0;

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

    // Fuente base
    final ventas = ref.watch(ventasProvider);

    // Catálogos para filtros
    final anios = ref.watch(ventasProvider.notifier).aniosDisponibles;
    final meses = ref.watch(ventasProvider.notifier).mesesDisponibles;

    final distribuidores =
        ref.watch(distribuidoresProvider).where((d) => !d.deleted).toList()
          ..sort((a, b) => a.nombre.compareTo(b.nombre));

    // Construir opciones de vendedores (asignación -> colaborador nombre)
    final asignaciones = ref.watch(asignacionesLaboralesProvider);
    final colaboradores = ref.watch(colaboradoresProvider);

    String resolveVendedorNombre(String asignacionUid) {
      if (asignacionUid.isEmpty) return '';
      try {
        final asg = asignaciones.firstWhere(
          (a) => a.uid == asignacionUid && !a.deleted,
        );
        final colab = colaboradores.firstWhere(
          (c) => c.uid == asg.colaboradorUid && !c.deleted,
        );
        return ('${colab.nombres} ${colab.apellidoPaterno} ${colab.apellidoMaterno}')
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
      } catch (_) {
        try {
          final colab = colaboradores.firstWhere(
            (c) => c.uid == asignacionUid && !c.deleted,
          );
          return ('${colab.nombres} ${colab.apellidoPaterno} ${colab.apellidoMaterno}')
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
        } catch (_) {
          return '';
        }
      }
    }

    // ---------- VENDEDORES DEPENDIENTES (DISTRIBUIDORA + PERIODO) ----------
    bool coincideDistribuidora(v) =>
        _filtroDistribuidoraUid.isEmpty ||
        v.distribuidoraUid == _filtroDistribuidoraUid ||
        v.distribuidoraOrigenUid == _filtroDistribuidoraUid;

    bool coincidePeriodo(v) {
      int? a = v.anioVenta;
      int? m = v.mesVenta;
      if (a == null || m == null) {
        final fv = v.fechaVenta?.toUtc();
        if (fv != null) {
          a ??= fv.year;
          m ??= fv.month;
        }
      }
      final okAnio = (_filtroAnio == null) || (_filtroAnio == a);
      final okMes = (_filtroMes == null) || (_filtroMes == m);
      return okAnio && okMes;
    }

    final vendedorUidsUsados = <String>{
      for (final v in ventas)
        if (!v.deleted &&
            v.vendedorUid.isNotEmpty &&
            coincideDistribuidora(v) &&
            coincidePeriodo(v))
          v.vendedorUid,
    };

    // Opciones de vendedores ordenadas por nombre
    final vendedoresOpciones =
        vendedorUidsUsados
            .map((uid) => MapEntry(uid, resolveVendedorNombre(uid)))
            .toList()
          ..sort((a, b) => a.value.compareTo(b.value));

    // -------- Valor seguro para el Dropdown, sin tocar el filtro real --------
    final vendedorSeleccionValido =
        _filtroVendedorAsignacionUid.isNotEmpty &&
        vendedoresOpciones.any((e) => e.key == _filtroVendedorAsignacionUid);

    final valueVendedorDropdown = vendedorSeleccionValido
        ? _filtroVendedorAsignacionUid
        : ''; // evita assert pero NO cambia el filtro

    // ---------- APLICAR FILTROS ----------
    final ventasFiltradas = ref
        .watch(ventasProvider.notifier)
        .filtrar(
          distribuidoraUid: _filtroDistribuidoraUid.isEmpty
              ? null
              : _filtroDistribuidoraUid,
          vendedorUid: _filtroVendedorAsignacionUid.isEmpty
              ? null
              : _filtroVendedorAsignacionUid,
          estatusUid: null,
          mes: _filtroMes,
          anio: _filtroAnio,
          incluirEliminados: false,
        );

    // Paginación
    final total = ventasFiltradas.length;
    final totalPages = (total == 0) ? 1 : ((total - 1) ~/ _pageSize) + 1;
    _page = math.min(_page, totalPages - 1);
    final start = _page * _pageSize;
    final end = math.min(start + _pageSize, total);
    final pagina = (start < end) ? ventasFiltradas.sublist(start, end) : [];

    // Mensaje vacío contextual cuando hay vendedora filtrada y no hay ventas
    final hayVendedoraFiltrada = _filtroVendedorAsignacionUid.isNotEmpty;
    final nombreVendedora = resolveVendedorNombre(
      _filtroVendedorAsignacionUid,
    ).trim();
    final emptyMsg = hayVendedoraFiltrada
        ? (nombreVendedora.isNotEmpty
              ? 'No hay ventas para $nombreVendedora en el periodo seleccionado.'
              : 'Para esta vendedora en estas fechas no hay ventas.')
        : 'No hay ventas';

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
        actions: [
          Center(
            child: IconButton(
              tooltip: _mostrarFiltros ? 'Ocultar filtros' : 'Mostrar filtros',
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                setState(() {
                  _mostrarFiltros = !_mostrarFiltros;
                });
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FabConMenuAnchor(
        onAgregar: null,
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
          if (!_cargandoInicial)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Align(
                alignment: Alignment.center,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.filter_list),
                  label: Text(_mostrarFiltros ? 'Ocultar filtros' : 'Filtros'),
                  onPressed: () {
                    setState(() {
                      _mostrarFiltros = !_mostrarFiltros;
                    });
                  },
                ),
              ),
            ),
          if (!_cargandoInicial && _mostrarFiltros)
            Center(
              child: _buildFiltros(
                context: context,
                cs: cs,
                anios: anios,
                meses: meses,
                distribuidores: distribuidores,
                vendedoresOpciones: vendedoresOpciones,
                valueVendedorDropdown: valueVendedorDropdown, // seguro
              ),
            ),
          if (!_cargandoInicial) _buildResumen(context, total),
          Expanded(
            child: _cargandoInicial
                ? const SizedBox.shrink()
                : RefreshIndicator(
                    color: cs.secondary,
                    onRefresh: _cargarVentas,
                    child: pagina.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 80),
                              Center(child: Text(emptyMsg)),
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
                            itemCount: pagina.length,
                            itemBuilder: (context, index) {
                              final v = pagina[index];
                              return Card(
                                color: cs.surface,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                child: VentaItemTile(
                                  venta: v,
                                  onTap: () {},
                                  onActualizado: () async {
                                    await _cargarVentas();
                                  },
                                ),
                              );
                            },
                          ),
                  ),
          ),
          if (!_cargandoInicial)
            _buildPaginador(
              context,
              ventasFiltradas.length,
              total,
              start,
              end,
              totalPages,
              mostrados: pagina.length,
            ),
        ],
      ),
    );
  }

  // ----- UI: Filtros -----
  Widget _buildFiltros({
    required BuildContext context,
    required ColorScheme cs,
    required List<int> anios,
    required List<int> meses,
    required List distribuidores,
    required List<MapEntry<String, String>> vendedoresOpciones,
    required String valueVendedorDropdown,
  }) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Card(
        color: cs.surface,
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Filtros', style: tt.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  // Año
                  SizedBox(
                    width: 140,
                    child: DropdownButtonFormField<int>(
                      isDense: true,
                      decoration: const InputDecoration(
                        labelText: 'Año',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      value: _filtroAnio,
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('Todos'),
                        ),
                        ...anios.map(
                          (a) => DropdownMenuItem<int>(
                            value: a,
                            child: Text(a.toString()),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _filtroAnio = val;
                          _page = 0;
                        });
                      },
                    ),
                  ),

                  // Mes
                  SizedBox(
                    width: 140,
                    child: DropdownButtonFormField<int>(
                      isDense: true,
                      decoration: const InputDecoration(
                        labelText: 'Mes',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      value: _filtroMes,
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('Todos'),
                        ),
                        ...meses.map(
                          (m) => DropdownMenuItem<int>(
                            value: m,
                            child: Text(m.toString().padLeft(2, '0')),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _filtroMes = val;
                          _page = 0;
                        });
                      },
                    ),
                  ),

                  // Distribuidora
                  SizedBox(
                    width: 260,
                    child: DropdownButtonFormField<String>(
                      isDense: true,
                      decoration: const InputDecoration(
                        labelText: 'Distribuidora',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      value: _filtroDistribuidoraUid.isEmpty
                          ? ''
                          : _filtroDistribuidoraUid,
                      items: [
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('Todas'),
                        ),
                        ...distribuidores.map(
                          (d) => DropdownMenuItem<String>(
                            value: d.uid,
                            child: Text(_sinPrefijoMazda(d.nombre)),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _filtroDistribuidoraUid = (val ?? '');
                          // al cambiar distribuidora, reiniciamos vendedor visible pero NO tocamos el filtro real del ID
                          _filtroVendedorAsignacionUid = '';
                          _page = 0;
                        });
                      },
                    ),
                  ),

                  // Vendedor (asignación → colaborador)
                  SizedBox(
                    width: 280,
                    child: DropdownButtonFormField<String>(
                      isDense: true,
                      decoration: const InputDecoration(
                        labelText: 'Vendedor',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      value:
                          valueVendedorDropdown, // valor seguro para evitar assert
                      items: [
                        const DropdownMenuItem<String>(
                          value: '',
                          child: Text('Todos'),
                        ),
                        ...vendedoresOpciones.map(
                          (e) => DropdownMenuItem<String>(
                            value: e.key,
                            child: Text(e.value.isEmpty ? e.key : e.value),
                          ),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _filtroVendedorAsignacionUid = (val ?? '');
                          _page = 0;
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
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

  Widget _buildPaginador(
    BuildContext context,
    int totalFiltradas,
    int total,
    int start,
    int end,
    int totalPages, {
    required int mostrados,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          Text(
            '$mostrados de $totalFiltradas',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          IconButton(
            tooltip: 'Anterior',
            onPressed: (_page > 0) ? () => setState(() => _page--) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('${_page + 1} / $totalPages'),
          IconButton(
            tooltip: 'Siguiente',
            onPressed: (_page < totalPages - 1)
                ? () => setState(() => _page++)
                : null,
            icon: const Icon(Icons.chevron_right),
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
      await ref.read(estatusProvider.notifier).cargarOfflineFirst();
      await ref
          .read(asignacionesLaboralesProvider.notifier)
          .cargarOfflineFirst();
      await ref.read(colaboradoresProvider.notifier).cargarOfflineFirst();
      await ref.read(distribuidoresProvider.notifier).cargarOfflineFirst();

      _setDefaultPeriodoSiVacio();

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

  // IMPORTAR
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

      if (mounted) {
        setState(() => _page = 0);
      }
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

  // ----- Helpers locales -----
  String _sinPrefijoMazda(String s) {
    if (s.isEmpty) return '';
    final reg = RegExp(r'^\s*mazda\b[\s\-–—:]*', caseSensitive: false);
    final out = s.replaceFirst(reg, '');
    return out.trimLeft();
  }

  void _setDefaultPeriodoSiVacio() {
    if (_filtroAnio != null || _filtroMes != null) return;

    final vs = ref.read(ventasProvider);
    int? bestAnio;
    int? bestMes;

    for (final v in vs) {
      if (v.deleted) continue;
      int? a = v.anioVenta;
      int? m = v.mesVenta;
      if (a == null || m == null) {
        final fv = v.fechaVenta?.toUtc();
        if (fv != null) {
          a ??= fv.year;
          m ??= fv.month;
        }
      }
      if (a == null || m == null) continue;

      if (bestAnio == null) {
        bestAnio = a;
        bestMes = m;
      } else {
        if (a > bestAnio || (a == bestAnio && m > (bestMes ?? 0))) {
          bestAnio = a;
          bestMes = m;
        }
      }
    }

    if (bestAnio != null && bestMes != null && mounted) {
      setState(() {
        _filtroAnio = bestAnio;
        _filtroMes = bestMes;
        _page = 0;
      });
    }
  }
}

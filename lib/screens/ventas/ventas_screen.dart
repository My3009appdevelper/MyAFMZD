// lib/screens/ventas/ventas_screen.dart
import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/asignaciones_laborales/asignaciones_laborales_provider.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_provider.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/database/estatus/estatus_provider.dart';
import 'package:myafmzd/database/ventas/ventas_provider.dart';
import 'package:myafmzd/screens/ventas/ventas_form_page.dart';
import 'package:myafmzd/screens/ventas/ventas_tile.dart';
import 'package:myafmzd/widgets/my_expandable_fab_options.dart';
import 'dart:math' as math;

import 'package:myafmzd/widgets/my_picker_search_field.dart';
import 'package:myafmzd/widgets/my_text_field.dart';

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

  // 🔎 Búsqueda libre (folio, vendedor, distribuidora origen o concentradora)
  String _filtroQuery = '';
  final _queryController = TextEditingController();
  Timer? _debounce;

  // Mostrar/ocultar panel de filtros
  bool _mostrarFiltros = false;

  // ----- Estado de paginación -----
  final int _pageSize = 1000;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarVentas());

    // === Listener con debounce para la búsqueda (igual que ColaboradoresScreen) ===
    _queryController.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        setState(() {
          _filtroQuery = _queryController.text;
          _page = 0;
        });
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

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

    // Construir índice de distribuidores por uid y nombre de concentradora
    final distByUid = {for (final d in distribuidores) d.uid: d};
    String _nombreDistribuidora(String? uid) {
      if (uid == null || uid.isEmpty) return '';
      final d = distByUid[uid];
      return d == null ? '' : _sinPrefijoMazda(d.nombre);
    }

    String _nombreConcentradoraDe(String? uid) {
      if (uid == null || uid.isEmpty) return '';
      final d = distByUid[uid];
      if (d == null) return '';
      final rootUid = (d.concentradoraUid.isNotEmpty)
          ? d.concentradoraUid
          : d.uid;
      final root = distByUid[rootUid];
      return root == null ? '' : _sinPrefijoMazda(root.nombre);
    }

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

    // ---------- APLICAR FILTROS ----------
    final ventasFiltradasBase = ref
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

    // 🔎 Filtro por texto libre: folio, nombre vendedor, distribuidora origen, concentradora
    final q = _fold(_filtroQuery);
    final ventasFiltradas = (q.isEmpty)
        ? ventasFiltradasBase
        : ventasFiltradasBase.where((v) {
            final folio = _fold(
              (() {
                try {
                  return (v.folioContrato).toString();
                } catch (_) {
                  return '';
                }
              })(),
            );
            final vendNombre = _fold(resolveVendedorNombre(v.vendedorUid));
            final distOrigenNombre = _fold(
              _nombreDistribuidora(v.distribuidoraOrigenUid),
            );
            final distVentaNombre = _fold(
              _nombreDistribuidora(v.distribuidoraUid),
            );
            final concOrigenNombre = _fold(
              _nombreConcentradoraDe(v.distribuidoraOrigenUid),
            );
            final concVentaNombre = _fold(
              _nombreConcentradoraDe(v.distribuidoraUid),
            );

            return folio.contains(q) ||
                vendNombre.contains(q) ||
                distOrigenNombre.contains(q) ||
                distVentaNombre.contains(q) ||
                concOrigenNombre.contains(q) ||
                concVentaNombre.contains(q);
          }).toList();

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
      floatingActionButton: FabConMenuAnchor(
        onAgregar: _abrirFormNuevaVenta,
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: MyTextField(
                controller: _queryController,
                textInputAction: TextInputAction.search,
                showClearButton: _filtroQuery.isNotEmpty,
                labelText:
                    'Buscar por folio, vendedor, distribuidora o concentradora',
                hintText: 'Ej. FOL123, Ana Pérez, Mazda Centro…',
                onClear: () {
                  _queryController.clear();
                  setState(() {
                    _filtroQuery = '';
                    _page = 0;
                  });
                },
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
              ),
            ),
          if (!_cargandoInicial)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Align(
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.filter_list),
                      label: Text(
                        _mostrarFiltros ? 'Ocultar filtros' : 'Filtros',
                      ),
                      onPressed: () {
                        setState(() {
                          _mostrarFiltros = !_mostrarFiltros;
                        });
                      },
                    ),
                    _buildResumen(context, total),
                  ],
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
              ),
            ),
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
    required List<DistribuidorDb> distribuidores,
    required List<MapEntry<String, String>> vendedoresOpciones,
  }) {
    final tt = Theme.of(context).textTheme;

    // Valores iniciales para los pickers
    final distInicial = _filtroDistribuidoraUid.isEmpty
        ? null
        : (() {
            try {
              return distribuidores.firstWhere(
                (d) => d.uid == _filtroDistribuidoraUid,
              );
            } catch (_) {
              return null;
            }
          })();

    final vendInicial = _filtroVendedorAsignacionUid.isEmpty
        ? null
        : (() {
            try {
              return vendedoresOpciones.firstWhere(
                (e) => e.key == _filtroVendedorAsignacionUid,
              );
            } catch (_) {
              return null;
            }
          })();

    // Sincroniza controller del campo de búsqueda con el estado actual
    if (_queryController.text != _filtroQuery) {
      _queryController.text = _filtroQuery;
      _queryController.selection = TextSelection.fromPosition(
        TextPosition(offset: _queryController.text.length),
      );
    }

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

                  // Distribuidora -> MyPickerSearchField
                  SizedBox(
                    width: 260,
                    child: MyPickerSearchField<DistribuidorDb>(
                      items: distribuidores,
                      initialValue: distInicial,
                      itemAsString: (d) => _sinPrefijoMazda(d.nombre),
                      compareFn: (a, b) => a.uid == b.uid,
                      labelText: 'Distribuidora',
                      hintText: 'Toca para buscar…',
                      bottomSheetTitle: 'Buscar distribuidora',
                      searchHintText: 'Nombre del distribuidor',
                      onChanged: (d) {
                        setState(() {
                          _filtroDistribuidoraUid = d?.uid ?? '';
                          // Al cambiar distribuidora, limpia vendedor seleccionado
                          _filtroVendedorAsignacionUid = '';
                          _page = 0;
                        });
                      },
                    ),
                  ),

                  // Vendedor/Asesor -> MyPickerSearchField
                  SizedBox(
                    width: 280,
                    child: MyPickerSearchField<MapEntry<String, String>>(
                      items: vendedoresOpciones,
                      initialValue: vendInicial,
                      itemAsString: (e) => (e.value.isEmpty ? e.key : e.value),
                      compareFn: (a, b) => a.key == b.key,
                      labelText: 'Vendedor',
                      hintText: 'Toca para buscar…',
                      bottomSheetTitle: 'Buscar vendedor',
                      searchHintText: 'Nombre o UID',
                      onChanged: (sel) {
                        setState(() {
                          _filtroVendedorAsignacionUid = sel?.key ?? '';
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

  Future<void> _abrirFormNuevaVenta() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const VentasFormPage()),
    );
    if (!mounted) return;
    if (ok == true) {
      await _cargarVentas();
      setState(() => _page = 0);
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

  // Normaliza para búsqueda (minúsculas + sin acentos/espacios dobles)
  String _fold(String s) {
    var out = s.toLowerCase();
    const repl = {
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'â': 'a',
      'ã': 'a',
      'é': 'e',
      'è': 'e',
      'ë': 'e',
      'ê': 'e',
      'í': 'i',
      'ì': 'i',
      'ï': 'i',
      'î': 'i',
      'ó': 'o',
      'ò': 'o',
      'ö': 'o',
      'ô': 'o',
      'õ': 'o',
      'ú': 'u',
      'ù': 'u',
      'ü': 'u',
      'û': 'u',
      'ñ': 'n',
      'ç': 'c',
    };
    repl.forEach((k, v) => out = out.replaceAll(k, v));
    return out.replaceAll(RegExp(r'\s+'), ' ').trim();
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

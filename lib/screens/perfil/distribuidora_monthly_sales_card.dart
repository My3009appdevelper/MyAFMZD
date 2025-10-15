import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/database/ventas/ventas_provider.dart';
import 'package:myafmzd/session/sesion_asignacion_selectors.dart';
import 'package:myafmzd/widgets/charts/my_timeline_bar_chart.dart';

import 'package:myafmzd/widgets/my_picker_search_field.dart';

class DistribuidoraMonthlySalesCard extends ConsumerStatefulWidget {
  const DistribuidoraMonthlySalesCard({
    super.key,
    required this.rolActivo, // 'vendedor' | 'gerente' | 'admin'
    this.initialYear,
    this.chartHeight = 220,
  });

  final String rolActivo;
  final int? initialYear;
  final double chartHeight;

  @override
  ConsumerState<DistribuidoraMonthlySalesCard> createState() =>
      _DistribuidoraMonthlySalesCardState();
}

class _DistribuidoraMonthlySalesCardState
    extends ConsumerState<DistribuidoraMonthlySalesCard> {
  late int _selectedYear;
  String _selectedDistribuidoraUid = ''; // solo ADMIN

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear ?? DateTime.now().year;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // === Estado base ===
    final ventasState = ref.watch(ventasProvider);
    final distribuidores = ref.watch(distribuidoresProvider);
    final asignacionActiva = ref.watch(activeAssignmentProvider);

    final rol = widget.rolActivo.toLowerCase().trim();
    final esAdmin = rol == 'admin';

    // Años disponibles
    final availableYears = () {
      final set = <int>{};
      for (final v in ventasState) {
        final y = v.anioVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().year;
        set.add(y);
      }
      if (!set.contains(_selectedYear)) set.add(_selectedYear);
      final list = set.toList()..sort();
      return list;
    }();

    // Base distribuidora (para vendedor/gerente)
    final distOrigen = () {
      if (asignacionActiva == null) return null;
      try {
        return distribuidores.firstWhere(
          (d) => !d.deleted && d.uid == asignacionActiva.distribuidorUid,
        );
      } catch (_) {
        return null;
      }
    }();

    final distConcentradora = () {
      if (distOrigen == null) return null;
      final concUid = (distOrigen.concentradoraUid.isNotEmpty == true)
          ? distOrigen.concentradoraUid
          : distOrigen.uid;
      try {
        return distribuidores.firstWhere((d) => !d.deleted && d.uid == concUid);
      } catch (_) {
        return null;
      }
    }();

    // ===========================
    // Opciones de distribuidoras (solo ADMIN)
    // ===========================
    final distribuidorasOpciones = <MapEntry<String, String>>[];
    if (esAdmin) {
      final porUid = {
        for (final d in distribuidores)
          if (!d.deleted) d.uid: d,
      };

      final rootsConVentas = <String>{};
      for (final v in ventasState) {
        if (v.deleted == true) continue;

        final y = v.anioVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().year;
        if (y != _selectedYear) continue;

        final posiblesUids = <String>{
          (v.distribuidoraUid).trim(),
          (v.distribuidoraOrigenUid).trim(),
        }..removeWhere((s) => s.isEmpty);

        for (final uid in posiblesUids) {
          final d = porUid[uid];
          if (d == null) continue;
          final rootUid = d.concentradoraUid.isNotEmpty
              ? d.concentradoraUid
              : d.uid;
          final root = porUid[rootUid];
          if (root == null || root.deleted == true) continue;
          rootsConVentas.add(rootUid);
        }
      }

      for (final rootUid in rootsConVentas) {
        final root = porUid[rootUid];
        if (root == null) continue;
        distribuidorasOpciones.add(
          MapEntry(root.uid, _sinPrefijoMazda(root.nombre)),
        );
      }

      // Ordenar por nombre
      distribuidorasOpciones.sort(
        (a, b) => _fold(a.value).compareTo(_fold(b.value)),
      );

      // 👉 Agregar opción sintética "Todas"
      distribuidorasOpciones.insert(0, const MapEntry('', 'Todas (total)'));

      // ❌ Quitar la auto-selección de la primera opción
      // (El bloque con addPostFrameCallback que asignaba el primer UID se elimina)
    } else {
      if (_selectedDistribuidoraUid.isNotEmpty) _selectedDistribuidoraUid = '';
    }

    // Serie mensual de la distribuidora (cluster por concentradora)
    final serieDistribuidora = () {
      String? baseUid;
      if (esAdmin) {
        baseUid = _selectedDistribuidoraUid.isEmpty
            ? null
            : _selectedDistribuidoraUid;
      } else {
        baseUid = distConcentradora?.uid ?? distOrigen?.uid;
      }
      return _serieClusterDistribuidora(
        ventas: ventasState,
        distribuidores: distribuidores,
        baseDistribuidoraUid: baseUid,
        anio: _selectedYear,
      );
    }();

    // Total anual
    final totalAnual = serieDistribuidora.fold<int>(
      0,
      (acc, mes) => acc + (mes),
    );

    // Título dinámico con total
    final tituloBase = esAdmin
        ? 'Ventas por mes (distribuidora)'
        : 'Nuestras ventas mensuales';
    final titulo = esAdmin
        ? (_selectedDistribuidoraUid.isNotEmpty
              ? '$tituloBase : $totalAnual'
              : tituloBase)
        : '$tituloBase : $totalAnual';

    // Valor seleccionado para MyPicker (distribuidora)
    MapEntry<String, String>? selectedDistEntry;
    try {
      selectedDistEntry = distribuidorasOpciones.firstWhere(
        (e) => e.key == _selectedDistribuidoraUid,
        orElse: () => distribuidorasOpciones.isNotEmpty
            ? distribuidorasOpciones.first
            : const MapEntry('', 'Todas (total)'),
      );
    } catch (_) {
      selectedDistEntry = distribuidorasOpciones.isNotEmpty
          ? distribuidorasOpciones.first
          : null;
    }

    // === UI ===
    return Card(
      elevation: 1,
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Encabezado con título + picker de año
            Row(
              children: [
                Icon(Icons.bar_chart_rounded, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titulo,
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedYear,
                    items: availableYears
                        .map(
                          (y) => DropdownMenuItem<int>(
                            value: y,
                            child: Text(
                              '$y',
                              style: tt.bodyMedium?.copyWith(
                                color: cs.onSurface,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val == null) return;
                      setState(() {
                        _selectedYear = val;
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),

            // Selector de Distribuidora (solo ADMIN)
            if (esAdmin) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.store_mall_directory_outlined,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MyPickerSearchField<MapEntry<String, String>>(
                      items: distribuidorasOpciones,
                      itemAsString: (e) => e.value,
                      compareFn: (a, b) => a.key == b.key,
                      initialValue: selectedDistEntry,
                      labelText: 'Distribuidora',
                      hintText: 'Seleccione una distribuidora',
                      bottomSheetTitle: 'Distribuidoras',
                      onChanged: (val) {
                        setState(() {
                          _selectedDistribuidoraUid = val?.key ?? '';
                        });
                      },
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 12),

            // Chart de barras
            SizedBox(
              height: widget.chartHeight,
              child: MyTimelineBarChart(
                serie: serieDistribuidora,
                year: _selectedYear,
                style: TimelineBarChartStyle.avgLine,
                compact: true,
                highlightCurrentMonth: true,
              ),
            ),

            if (esAdmin && _selectedDistribuidoraUid.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Mostrando TOTAL (todas las distribuidoras). Seleccione una distribuidora para ver sus ventas.',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===== Helpers =====

  List<int> _serieClusterDistribuidora({
    required List ventas,
    required List distribuidores,
    required String? baseDistribuidoraUid,
    required int anio,
  }) {
    // 👉 TOTAL (todas las distribuidoras) si no hay selección
    if (baseDistribuidoraUid == null || baseDistribuidoraUid.isEmpty) {
      final serieTotal = List<int>.filled(12, 0);
      for (final v in ventas) {
        if (v.deleted == true) continue;
        final y = v.anioVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().year;
        if (y != anio) continue;
        final m = v.mesVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().month;
        if (m >= 1 && m <= 12) {
          serieTotal[m - 1] += 1;
        }
      }
      return serieTotal;
    }

    // ====== Caso con base seleccionada (cluster por concentradora) ======
    var base;
    try {
      base = distribuidores.firstWhere(
        (d) => !d.deleted && d.uid == baseDistribuidoraUid,
      );
    } catch (_) {
      base = null;
    }
    if (base == null) return List<int>.filled(12, 0);

    final rootUid = (base.concentradoraUid?.isNotEmpty == true)
        ? base.concentradoraUid
        : base.uid;

    final clusterUids = <String>{};
    for (final d in distribuidores) {
      if (d.deleted == true) continue;
      final conc = (d.concentradoraUid?.isNotEmpty == true)
          ? d.concentradoraUid
          : d.uid;
      if (conc == rootUid) clusterUids.add(d.uid);
    }
    if (clusterUids.isEmpty) clusterUids.add(base.uid);

    final serie = List<int>.filled(12, 0);
    for (final v in ventas) {
      if (v.deleted == true) continue;

      final y = v.anioVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().year;
      if (y != anio) continue;

      final m = v.mesVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().month;
      if (m < 1 || m > 12) continue;

      final du = (v.distribuidoraUid ?? '');
      final doU = (v.distribuidoraOrigenUid ?? '');
      if (clusterUids.contains(du) || clusterUids.contains(doU)) {
        serie[m - 1] += 1;
      }
    }
    return serie;
  }

  String _sinPrefijoMazda(String s) {
    if (s.isEmpty) return '';
    final reg = RegExp(r'^\s*mazda\b[\s\-–—:]*', caseSensitive: false);
    final out = s.replaceFirst(reg, '');
    return out.trimLeft();
  }

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
}

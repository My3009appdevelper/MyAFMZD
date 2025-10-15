import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_provider.dart';
import 'package:myafmzd/database/ventas/ventas_provider.dart';
import 'package:myafmzd/database/asignaciones_laborales/asignaciones_laborales_provider.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/session/sesion_asignacion_selectors.dart';
import 'package:myafmzd/widgets/charts/my_timeline_bar_chart.dart';
import 'package:myafmzd/widgets/my_picker_search_field.dart';

class AsesorMonthlySalesCard extends ConsumerStatefulWidget {
  const AsesorMonthlySalesCard({
    super.key,
    required this.rolActivo,
    this.initialYear,
    this.chartHeight = 220,
  });

  /// 'vendedor' | 'gerente' | 'admin'
  final String rolActivo;

  /// Año inicial del card (por defecto: DateTime.now().year)
  final int? initialYear;

  /// Alto del chart
  final double chartHeight;

  @override
  ConsumerState<AsesorMonthlySalesCard> createState() =>
      _AsesorMonthlySalesCardState();
}

class _AsesorMonthlySalesCardState
    extends ConsumerState<AsesorMonthlySalesCard> {
  late int _selectedYear;

  /// Ahora guardamos **colaboradorUid** (no la asignación)
  String _selectedColaboradorUid = ''; // solo gerente/admin

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear ?? DateTime.now().year;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // === Datos base ===
    final ventasState = ref.watch(ventasProvider);
    final asignacionActiva = ref.watch(activeAssignmentProvider);
    final colaboradores = ref.watch(colaboradoresProvider);
    final asignaciones = ref.watch(asignacionesLaboralesProvider);
    final distribuidores = ref.watch(distribuidoresProvider);

    final rol = widget.rolActivo.toLowerCase().trim();
    final esGerente = rol == 'gerente';
    final esAdmin = rol == 'admin';
    final esVendedor = rol == 'vendedor';

    // === Años disponibles (derivados de ventas) ===
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

    // === Ámbito de gerente: cluster de su distribuidora/concentradora ===
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

    final clusterUids = () {
      if (!esGerente || distOrigen == null) return <String>{};
      final rootUid = distOrigen.concentradoraUid.isNotEmpty
          ? distOrigen.concentradoraUid
          : distOrigen.uid;
      final set = <String>{};
      for (final d in distribuidores) {
        if (d.deleted == true) continue;
        final conc = (d.concentradoraUid.isNotEmpty)
            ? d.concentradoraUid
            : d.uid;
        if (conc == rootUid) set.add(d.uid);
      }
      // fallback (por si no hubiera coincidencias)
      if (set.isEmpty) set.add(distOrigen.uid);
      return set;
    }();

    // Índice rápido de asignación por uid (para resolver colaborador de cada venta)
    final asigByUid = {for (final a in asignaciones) a.uid: a};

    // === Picker: SOLO colaboradores con ≥1 venta en el año seleccionado ===
    // - Admin: cualquier venta del año
    // - Gerente: ventas del año **dentro de su cluster**
    final vendedoresOpciones = <MapEntry<String, String>>[];
    if (esGerente || esAdmin) {
      final colabsConVentas = <String, int>{}; // colaboradorUid -> conteo
      for (final v in ventasState) {
        if (v.deleted == true) continue;
        final y = v.anioVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().year;
        if (y != _selectedYear) continue;

        final asig = asigByUid[v.vendedorUid];
        if (asig == null) continue; // venta huérfana sin asignación conocida
        final colabUid = asig.colaboradorUid;

        // Si es gerente, limitar por cluster (distribuidoraUid o distribuidoraOrigenUid)
        if (esGerente) {
          final du = (v.distribuidoraUid).trim();
          final doU = (v.distribuidoraOrigenUid).trim();
          final inCluster =
              (du.isNotEmpty && clusterUids.contains(du)) ||
              (doU.isNotEmpty && clusterUids.contains(doU));
          if (!inCluster) continue;
        }

        if (colabUid.isEmpty) continue;
        colabsConVentas.update(colabUid, (c) => c + 1, ifAbsent: () => 1);
      }

      // mapear a nombres (sin filtrar por deleted para no perder el nombre)
      for (final colabUid in colabsConVentas.keys) {
        final colab = _colaboradorPorUidSinDeleted(colaboradores, colabUid);
        final nombre = _nombreColaboradorNullSafe(colab);
        vendedoresOpciones.add(
          MapEntry(colabUid, nombre.isEmpty ? colabUid : nombre),
        );
      }

      vendedoresOpciones.sort(
        (a, b) => _fold(a.value).compareTo(_fold(b.value)),
      );

      // validar selección actual vs opciones
      final valido =
          _selectedColaboradorUid.isNotEmpty &&
          vendedoresOpciones.any((e) => e.key == _selectedColaboradorUid);
      if (!valido && _selectedColaboradorUid.isNotEmpty) {
        _selectedColaboradorUid = '';
      }
    } else {
      if (_selectedColaboradorUid.isNotEmpty) _selectedColaboradorUid = '';
    }

    // === Serie del asesor (por colaborador) ===
    final serieAsesor = () {
      // Vendedor: sus propias ventas (por colaborador)
      if (esVendedor) {
        if (asignacionActiva == null) return List<int>.filled(12, 0);
        final myColabUid = asignacionActiva.colaboradorUid;
        return _seriePorColaborador(
          ventas: ventasState,
          asigByUid: asigByUid,
          colaboradorUid: myColabUid,
          anio: _selectedYear,
          limitarPorClusterUids: null, // vendedor ve todas sus ventas
        );
      }

      // Gerente/Admin: requiere colaborador seleccionado
      if (_selectedColaboradorUid.isEmpty) {
        return List<int>.filled(12, 0);
      }

      return _seriePorColaborador(
        ventas: ventasState,
        asigByUid: asigByUid,
        colaboradorUid: _selectedColaboradorUid,
        anio: _selectedYear,
        limitarPorClusterUids: esGerente ? clusterUids : null,
      );
    }();

    // === Total anual (acumulado del año) ===
    final totalAnual = serieAsesor.fold<int>(0, (acc, mes) => acc + (mes));

    // Título dinámico con total
    final tituloBase = esVendedor
        ? 'Mis ventas mensuales'
        : 'Ventas por mes (por asesor)';
    final titulo = esVendedor
        ? '$tituloBase : $totalAnual'
        : (_selectedColaboradorUid.isNotEmpty
              ? '$tituloBase : $totalAnual'
              : tituloBase);

    // Valor seleccionado para MyPicker (vendedor)
    MapEntry<String, String>? selectedVendedorEntry;
    if (_selectedColaboradorUid.isNotEmpty) {
      try {
        selectedVendedorEntry = vendedoresOpciones.firstWhere(
          (e) => e.key == _selectedColaboradorUid,
        );
      } catch (_) {
        selectedVendedorEntry = null;
      }
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
                        // No limpiamos manualmente; la validación de opciones ya lo hace.
                      });
                    },
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),

            // Selector de Vendedor (solo gerente/admin)
            if (esGerente || esAdmin) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(
                    Icons.person_search_outlined,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: MyPickerSearchField<MapEntry<String, String>>(
                      items: vendedoresOpciones,
                      itemAsString: (e) => e.value, // nombre limpio
                      compareFn: (a, b) => a.key == b.key,
                      initialValue: selectedVendedorEntry,
                      labelText: 'Vendedor',
                      hintText: 'Seleccione un vendedor',
                      bottomSheetTitle: 'Vendedores',
                      onChanged: (val) {
                        setState(() {
                          _selectedColaboradorUid = val?.key ?? '';
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
                serie: serieAsesor,
                year: _selectedYear,
                style: TimelineBarChartStyle.avgLine,
                compact: true,
                highlightCurrentMonth: true,
              ),
            ),

            if ((esGerente || esAdmin) && _selectedColaboradorUid.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Seleccione un vendedor para ver sus ventas.',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ===== Helpers de datos/series =====

  /// Serie mensual (12) por colaborador.
  /// Si [limitarPorClusterUids] != null, solo cuenta ventas cuyo distribuidoraUid o distribuidoraOrigenUid
  /// estén en ese cluster (escenario de gerente).
  List<int> _seriePorColaborador({
    required List ventas,
    required Map<String, dynamic> asigByUid,
    required String colaboradorUid,
    required int anio,
    Set<String>? limitarPorClusterUids,
  }) {
    if (colaboradorUid.isEmpty) return List<int>.filled(12, 0);

    final serie = List<int>.filled(12, 0);
    for (final v in ventas) {
      if (v.deleted == true) continue;

      final y = v.anioVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().year;
      if (y != anio) continue;

      final m = v.mesVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().month;
      if (m < 1 || m > 12) continue;

      final asig = asigByUid[v.vendedorUid];
      if (asig == null) continue;
      if (asig.colaboradorUid != colaboradorUid) continue;

      if (limitarPorClusterUids != null) {
        final du = (v.distribuidoraUid).trim();
        final doU = (v.distribuidoraOrigenUid).trim();
        final inCluster =
            (du.isNotEmpty && limitarPorClusterUids.contains(du)) ||
            (doU.isNotEmpty && limitarPorClusterUids.contains(doU));
        if (!inCluster) continue;
      }

      serie[m - 1] += 1;
    }
    return serie;
  }

  // 👉 NO filtramos por deleted aquí, para no perder el nombre.
  dynamic _colaboradorPorUidSinDeleted(List colabs, String uid) {
    try {
      return colabs.firstWhere((c) => c.uid == uid);
    } catch (_) {
      return null;
    }
  }

  // Null-safe para evitar “null” en pantalla si algún campo viene vacío.
  String _nombreColaboradorNullSafe(colab) {
    if (colab == null) return '';
    final s =
        '${colab.nombres ?? ''} ${colab.apellidoPaterno ?? ''} ${colab.apellidoMaterno ?? ''}';
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
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

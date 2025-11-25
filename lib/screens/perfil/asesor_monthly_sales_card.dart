import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_provider.dart';
import 'package:myafmzd/database/ventas/ventas_provider.dart';
import 'package:myafmzd/database/asignaciones_laborales/asignaciones_laborales_provider.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/session/sesion_asignacion_selectors.dart';
import 'package:myafmzd/widgets/charts/my_timeline_bar_chart.dart';
import 'package:myafmzd/widgets/charts/my_pie_chart.dart';
import 'package:myafmzd/widgets/my_picker_search_field.dart';

class AsesorMonthlySalesCard extends ConsumerStatefulWidget {
  const AsesorMonthlySalesCard({
    super.key,
    required this.rolActivo,
    this.initialYear,
    this.chartHeight = 220,
  });

  /// 'vendedor' | 'gerente' | 'gerente de grupo' | 'admin'
  final String rolActivo;
  final int? initialYear;
  final double chartHeight;

  @override
  ConsumerState<AsesorMonthlySalesCard> createState() =>
      _AsesorMonthlySalesCardState();
}

class _AsesorMonthlySalesCardState extends ConsumerState<AsesorMonthlySalesCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ------------ Estado mínimo controlado por UI ------------
  late int _selectedYear;
  String _selectedColaboradorUid = ''; // solo gerente/admin
  late int _selectedMonth;
  String? _selectedBaseDistribuidoraUid; // solo admin con múltiples bases

  static const String _allBasesKey = '__ALL__';

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear ?? DateTime.now().year;
    _recomputeSelectedMonth();
  }

  @override
  void didUpdateWidget(covariant AsesorMonthlySalesCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialYear != null && widget.initialYear != _selectedYear) {
      setState(() => _selectedYear = widget.initialYear!);
      _recomputeSelectedMonth();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // -------- Datos base (Riverpod) --------
    final ventas = ref.watch(ventasProvider);
    final asignacionActiva = ref.watch(activeAssignmentProvider);
    final colaboradores = ref.watch(colaboradoresProvider);
    final asignaciones = ref.watch(asignacionesLaboralesProvider);
    final distribuidores = ref.watch(distribuidoresProvider);

    // -------- Rol / flags --------
    final rol = widget.rolActivo.toLowerCase().trim();
    final esGerenteGrupo = rol == 'gerente de grupo';
    final esGerente = rol == 'gerente' || esGerenteGrupo;
    final esAdmin = rol == 'admin';
    final esVendedor = rol == 'vendedor';

    final esRolConBases = esAdmin || esGerenteGrupo;

    // -------- Índices rápidos --------
    final asigByUid = {for (final a in asignaciones) a.uid: a};
    final colabByUid = {for (final c in colaboradores) c.uid: c};

    // -------- Dist y cluster del contexto (gerente/vendedor) --------
    final distOrigen = _SalesSelectors.distOrigen(
      distribuidores,
      asignacionActiva,
    );

    final clusterUids = () {
      if (!esGerente) return <String>{};

      // 🔹 Caso GERENTE DE GRUPO: usar TODAS sus distribuidoras asignadas
      if (esGerenteGrupo && asignacionActiva != null) {
        return _SalesSelectors.clusterGerenteGrupo(
          gerenteColaboradorUid: asignacionActiva.colaboradorUid,
          asignaciones: asignaciones,
          distribuidores: distribuidores,
        );
      }

      // 🔹 Caso GERENTE normal: igual que antes (cluster de su base/concentradora)
      if (distOrigen != null) {
        return _SalesSelectors.clusterFromBaseDistribuidora(
          baseUid: distOrigen.concentradoraUid.isNotEmpty
              ? distOrigen.concentradoraUid
              : distOrigen.uid,
          distribuidores: distribuidores,
          isRootConcentradora: true,
        );
      }

      return <String>{};
    }();

    // -------- Opciones de vendedores (gerente/admin) --------
    final vendedoresOpciones = (esGerente || esAdmin)
        ? _SalesSelectors.vendedoresConVentasEnAnio(
            ventas: ventas,
            asigByUid: asigByUid,
            colaboradores: colaboradores,
            anio: _selectedYear,
            limitarPorClusterUids: esGerente ? clusterUids : null,
          )
        : <MapEntry<String, String>>[];
    debugPrint(
      'ROL: $rol  esGerenteGrupo=$esGerenteGrupo  clusterUids=${clusterUids.length}  vendedoresOpciones=${vendedoresOpciones.length}',
    );
    //Listar las distribuidoras
    debugPrint(
      'Clusters: ${clusterUids.map((uid) {
        try {
          final d = distribuidores.firstWhere((d) => !d.deleted && d.uid == uid);
          return d.nombre;
        } catch (_) {
          return uid;
        }
      }).join(', ')}',
    );

    // -------- Serie del asesor --------
    final Set<String>? seriesScope = () {
      if (esVendedor && distOrigen != null) {
        return _SalesSelectors.clusterFromBaseDistribuidora(
          baseUid: distOrigen.uid,
          distribuidores: distribuidores,
        );
      }

      // Gerente "normal" (no de grupo): todo su cluster
      if (esGerente && !esGerenteGrupo) {
        return clusterUids;
      }

      // Admin o Gerente de grupo con vendedor ya seleccionado:
      // usan la misma lógica de "adminScopeElegido" (dropdown de bases).
      if ((esAdmin || esGerenteGrupo) && _selectedColaboradorUid.isNotEmpty) {
        return _SalesSelectors.adminScopeElegido(
          colaboradorUid: _selectedColaboradorUid,
          anio: _selectedYear,
          ventas: ventas,
          asigByUid: asigByUid,
          asignaciones: asignaciones,
          distribuidores: distribuidores,
          selectedBaseDistribuidoraUid: _selectedBaseDistribuidoraUid,
          allBasesKey: _allBasesKey,
        );
      }

      // Gerente de grupo sin vendedor seleccionado: usa su scope completo
      if (esGerenteGrupo) {
        return clusterUids;
      }

      return null;
    }();

    final colaboradorTarget = esVendedor
        ? (asignacionActiva?.colaboradorUid ?? '')
        : _selectedColaboradorUid;

    final serieAsesor = (esVendedor || _selectedColaboradorUid.isNotEmpty)
        ? _SalesSelectors.seriePorColaborador(
            ventas: ventas,
            asigByUid: asigByUid,
            colaboradorUid: colaboradorTarget,
            anio: _selectedYear,
            limitarPorClusterUids: seriesScope,
          )
        : List<int>.filled(12, 0);

    final totalAnual = serieAsesor.fold<int>(0, (acc, v) => acc + v);

    // -------- Bases del asesor (admin y gerente de grupo con asesor) --------
    final basesOpciones = (esRolConBases && _selectedColaboradorUid.isNotEmpty)
        ? _SalesSelectors.basesDelColaboradorEnAnio(
            colaboradorUid: _selectedColaboradorUid,
            anio: _selectedYear,
            asignaciones: asignaciones,
            ventas: ventas,
            asigByUid: asigByUid,
            distribuidores: distribuidores,
            allBasesKey: _allBasesKey,
            selectedBaseDistribuidoraUid: _selectedBaseDistribuidoraUid,
            onNormalized: (normalized) {
              if (_selectedBaseDistribuidoraUid != normalized) {
                setState(() => _selectedBaseDistribuidoraUid = normalized);
              }
            },
          )
        : <MapEntry<String, String>>[];

    // -------- Texto dinámico para admin: base seleccionada --------
    String? baseSeleccionadaLabel;
    if (esRolConBases &&
        _selectedColaboradorUid.isNotEmpty &&
        basesOpciones.isNotEmpty) {
      MapEntry<String, String>? seleccion;
      try {
        if (_selectedBaseDistribuidoraUid != null) {
          seleccion = basesOpciones.firstWhere(
            (e) => e.key == _selectedBaseDistribuidoraUid,
          );
        }
      } catch (_) {
        seleccion = null;
      }
      seleccion ??= basesOpciones.first;

      if (seleccion.key == _allBasesKey) {
        final basesSinAll = basesOpciones
            .where((e) => e.key != _allBasesKey)
            .map((e) => e.value)
            .toList();
        final nombres = basesSinAll.join(', ');
        baseSeleccionadaLabel = basesSinAll.isEmpty
            ? 'Todas sus distribuidoras'
            : 'Todas sus distribuidoras: $nombres';
      } else {
        baseSeleccionadaLabel = 'Distribuidora: ${seleccion.value}';
      }
    }

    // -------- Ranking (scope consistente con pies) --------
    final scopeParaRanking = seriesScope;
    final ranking = _SalesSelectors.rankingAnual(
      ventas: ventas,
      asigByUid: asigByUid,
      anio: _selectedYear,
      scopeClusterUids: scopeParaRanking,
      colaboradorUidSeleccionado: colaboradorTarget,
    );
    final rankingTxt = (ranking.rank == null || ranking.total == 0)
        ? '—'
        : '#${ranking.rank} de ${ranking.total}';

    // -------- PIES (datos + visibilidad) --------
    final puedeVerPies =
        esVendedor ||
        ((esGerente || esAdmin) && _selectedColaboradorUid.isNotEmpty);
    final piesScope = () {
      if (esVendedor && distOrigen != null) {
        return _SalesSelectors.clusterFromBaseDistribuidora(
          baseUid: distOrigen.concentradoraUid.isNotEmpty
              ? distOrigen.concentradoraUid
              : distOrigen.uid,
          distribuidores: distribuidores,
          isRootConcentradora: true,
        );
      }

      // Gerente "normal": todo su cluster
      if (esGerente && !esGerenteGrupo) return clusterUids;

      // Admin o Gerente de grupo con vendedor seleccionado:
      // usamos el mismo scope que en barras (seriesScope)
      if ((esAdmin || esGerenteGrupo) && _selectedColaboradorUid.isNotEmpty) {
        return seriesScope;
      }

      // Gerente de grupo sin vendedor seleccionado → su scope completo
      if (esGerenteGrupo) return clusterUids;

      return null;
    }();

    final piesData = puedeVerPies
        ? _SalesSelectors.piesData(
            ventas: ventas,
            anio: _selectedYear,
            scopeClusterUids: piesScope,
            asigByUid: asigByUid,
            colabByUid: colabByUid,
            selectedMonth: _selectedMonth,
            distOrigen: distOrigen,
            esVendedor: esVendedor,
            selectedColaboradorUid:
                colaboradorTarget, // ✅ ahora siempre llega el UID correcto
          )
        : const _PiesData.empty();

    // -------- selectedVendedorEntry para el picker --------
    MapEntry<String, String>? selectedVendedorEntry;
    if (_selectedColaboradorUid.isNotEmpty) {
      try {
        selectedVendedorEntry = vendedoresOpciones.firstWhere(
          (e) => e.key == _selectedColaboradorUid,
        );
      } catch (_) {}
    }

    final concNombre = _SalesSelectors.concentradoraNombreParaPies(
      esVendedor: esVendedor,
      esGerente: esGerente,
      esAdmin: esAdmin || esGerenteGrupo,
      distOrigen: distOrigen,
      selectedColaboradorUid: _selectedColaboradorUid,
      asignaciones: asignaciones,
      distribuidores: distribuidores,
      ventas: ventas,
      anio: _selectedYear,
      selectedBaseDistribuidoraUid: _selectedBaseDistribuidoraUid,
      allBasesKey: _allBasesKey,
    );

    // Si no se puede resolver, dejamos un genérico
    final concLabel = (concNombre == null || concNombre.isEmpty)
        ? 'DISTRIBUIDORA'
        : concNombre.toUpperCase();

    final rawSubtitulo = _SalesSelectors.contextoDistribuidoraNombre(
      esVendedor: esVendedor,
      esGerente: esGerente,
      esAdmin: esAdmin,
      esGerenteGrupo: esGerenteGrupo,
      distOrigen: distOrigen,
      clusterUids: clusterUids,
      selectedColaboradorUid: _selectedColaboradorUid,
      asignaciones: asignaciones,
      distribuidores: distribuidores,
      ventas: ventas,
      anio: _selectedYear,
    );

    final showBasesDropdown =
        esRolConBases &&
        _selectedColaboradorUid.isNotEmpty &&
        basesOpciones.length > 1;

    final subtituloHeader = showBasesDropdown ? null : rawSubtitulo;

    // =================== UI ===================
    return Card(
      elevation: 1,
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderControls(
              titulo: () {
                if (esVendedor) {
                  // Mismo comportamiento de siempre para vendedor
                  return 'MIS VENTAS EN EL AÑO';
                }

                // Si hay asesor seleccionado, mostramos su nombre
                if (_selectedColaboradorUid.isNotEmpty) {
                  final col = _SalesSelectors.colaboradorPorUidSinDeleted(
                    colaboradores,
                    _selectedColaboradorUid,
                  );
                  final nombre = _SalesSelectors.nombreColaboradorNullSafe(
                    col,
                  ).toUpperCase();
                  return 'VENTAS DE $nombre';
                }

                // Sin asesor seleccionado:
                if (esGerenteGrupo) {
                  // Análogo a "VENTAS TOTALES POR MES (MIS DISTRIBUIDORAS)"
                  return 'VENTAS TOTALES POR MES (MI EQUIPO)';
                }

                if (esGerente) {
                  // Gerente normal, sin filtro de asesor concreto
                  return 'VENTAS POR MES (POR ASESOR)';
                }

                if (esAdmin) {
                  // Admin viendo el total de asesores
                  return 'VENTAS TOTALES POR MES (ASESORES)';
                }

                // Fallback genérico
                return 'VENTAS POR MES (POR ASESOR)';
              }(),
              subtitulo: subtituloHeader,
              showBasesDropdown: showBasesDropdown,
              basesOpciones: basesOpciones,
              selectedBaseUid: _selectedBaseDistribuidoraUid,
              onBaseChanged: (v) {
                setState(() => _selectedBaseDistribuidoraUid = v);
                _recomputeSelectedMonth();
              },
              selectedBaseLabel: baseSeleccionadaLabel,
            ),

            if (esGerente || esAdmin) ...[
              const SizedBox(height: 12),
              _VendedorPicker(
                opciones: vendedoresOpciones,
                selected: selectedVendedorEntry,
                onChanged: (val) {
                  setState(() => _selectedColaboradorUid = val?.key ?? '');
                  _recomputeSelectedMonth();
                },
              ),
            ],

            const SizedBox(height: 8),
            _KpisRow(
              yearLabel: '$_selectedYear',
              totalAnual: totalAnual,
              rankingTxt: rankingTxt,
              promedio: _SalesSelectors.avgCorriente(
                serieAsesor,
                _selectedYear,
                DateTime.now(),
              ),
              esGerenteGrupo: esGerenteGrupo,
            ),

            const SizedBox(height: 12),

            _BarsSection(
              height: widget.chartHeight,
              serie: serieAsesor,
              year: _selectedYear,
            ),

            if ((esGerente || esAdmin) && _selectedColaboradorUid.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Seleccione un vendedor para ver sus ventas y su aportación en el cluster.',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),

            if (puedeVerPies)
              _PiesSection(
                data: piesData,
                selectedMonth: _selectedMonth,
                onMonthChanged: (m) => setState(() => _selectedMonth = m),
                title: esVendedor
                    ? 'MI APORTACIÓN EN $concLabel'
                    : (_selectedColaboradorUid.isNotEmpty
                          ? 'APORTACIÓN EN $concLabel'
                          : 'APORTACIÓN POR ASESOR EN $concLabel'),
              ),
          ],
        ),
      ),
    );
  }

  // Mantiene tu comportamiento actual (mes más reciente con venta dentro del scope real)
  void _recomputeSelectedMonth() {
    final ventas = ref.read(ventasProvider);
    final asignaciones = ref.read(asignacionesLaboralesProvider);
    final distribuidores = ref.read(distribuidoresProvider);
    final asignacionActiva = ref.read(activeAssignmentProvider);

    final asigByUid = {for (final a in asignaciones) a.uid: a};

    final rol = widget.rolActivo.toLowerCase().trim();
    final esGerenteGrupo = rol == 'gerente de grupo';
    final esGerente = rol == 'gerente' || esGerenteGrupo;
    final esAdmin = rol == 'admin';
    final esVendedor = rol == 'vendedor';

    final distOrigen = _SalesSelectors.distOrigen(
      distribuidores,
      asignacionActiva,
    );

    Set<String>? scopeClusterUids;
    if (esVendedor && distOrigen != null) {
      scopeClusterUids = _SalesSelectors.clusterFromBaseDistribuidora(
        baseUid: distOrigen.uid,
        distribuidores: distribuidores,
      );
    } else if (esGerente) {
      if (esGerenteGrupo && asignacionActiva != null) {
        // 🔹 mismo scope que en build, pero para el cálculo de meses
        scopeClusterUids = _SalesSelectors.clusterGerenteGrupo(
          gerenteColaboradorUid: asignacionActiva.colaboradorUid,
          asignaciones: asignaciones,
          distribuidores: distribuidores,
        );
      } else if (distOrigen != null) {
        scopeClusterUids = _SalesSelectors.clusterFromBaseDistribuidora(
          baseUid: distOrigen.concentradoraUid.isNotEmpty
              ? distOrigen.concentradoraUid
              : distOrigen.uid,
          distribuidores: distribuidores,
          isRootConcentradora: true,
        );
      }
    } else if ((esAdmin || esGerenteGrupo) &&
        _selectedColaboradorUid.isNotEmpty) {
      scopeClusterUids = _SalesSelectors.adminScopeElegido(
        colaboradorUid: _selectedColaboradorUid,
        anio: _selectedYear,
        ventas: ventas,
        asigByUid: asigByUid,
        asignaciones: asignaciones,
        distribuidores: distribuidores,
        selectedBaseDistribuidoraUid: _selectedBaseDistribuidoraUid,
        allBasesKey: _allBasesKey,
      );
    }

    final colaboradorUid = esVendedor
        ? (asignacionActiva?.colaboradorUid ?? '')
        : _selectedColaboradorUid;

    final meses = _SalesSelectors.mesesConVentas(
      ventas: ventas,
      anio: _selectedYear,
      asigByUid: asigByUid,
      colaboradorUid: colaboradorUid,
      scopeClusterUids: scopeClusterUids,
    );

    setState(() {
      _selectedMonth = meses.isNotEmpty
          ? meses.reduce((a, b) => a > b ? a : b)
          : DateTime.now().month;
    });
  }
}

// =======================================================
// ================== SUB-WIDGETS UI =====================
// =======================================================

class _HeaderControls extends StatelessWidget {
  const _HeaderControls({
    required this.titulo,
    required this.subtitulo,
    required this.showBasesDropdown,
    required this.basesOpciones,
    required this.selectedBaseUid,
    required this.onBaseChanged,
    this.selectedBaseLabel,
  });

  final String titulo;
  final String? subtitulo;

  final bool showBasesDropdown;
  final List<MapEntry<String, String>> basesOpciones;
  final String? selectedBaseUid;
  final ValueChanged<String?> onBaseChanged;
  final String? selectedBaseLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showBasesDropdown)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedBaseUid,
                    items: [
                      for (final e in basesOpciones)
                        DropdownMenuItem(
                          value: e.key,
                          child: Text(
                            e.value,
                            style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                          ),
                        ),
                    ],
                    onChanged: onBaseChanged,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ],
            ),
          Text(
            titulo,
            style: tt.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitulo != null && subtitulo!.isNotEmpty)
            Text(
              subtitulo!.replaceFirst("Cluster ", '').trimLeft(),
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),

          // 👇 NUEVO: etiqueta dinámica según selección de base
          if (selectedBaseLabel != null && selectedBaseLabel!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                selectedBaseLabel!,
                style: tt.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

class _VendedorPicker extends StatelessWidget {
  const _VendedorPicker({
    required this.opciones,
    required this.selected,
    required this.onChanged,
  });

  final List<MapEntry<String, String>> opciones;
  final MapEntry<String, String>? selected;
  final ValueChanged<MapEntry<String, String>?> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.person_search_outlined, color: cs.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: MyPickerSearchField<MapEntry<String, String>>(
            items: opciones,
            itemAsString: (e) => e.value,
            compareFn: (a, b) => a.key == b.key,
            initialValue: selected,
            labelText: 'Vendedor',
            hintText: 'Seleccione un vendedor',
            bottomSheetTitle: 'Vendedores',
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _KpisRow extends StatelessWidget {
  const _KpisRow({
    required this.yearLabel,
    required this.totalAnual,
    required this.rankingTxt,
    required this.promedio,
    required this.esGerenteGrupo,
  });

  final String yearLabel;
  final int totalAnual;
  final String rankingTxt;
  final double? promedio;
  final bool esGerenteGrupo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    Widget _tile(String label, String value) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: cs.surface,
          border: Border.all(color: cs.onSurface.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              label,
              style: tt.labelMedium?.copyWith(color: cs.onSurface),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: tt.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ],
        ),
      );
    }

    final avgTxt = (promedio == null)
        ? '—'
        : promedio! >= 10
        ? promedio!.toStringAsFixed(0)
        : promedio!.toStringAsFixed(1);

    print(esGerenteGrupo);
    final rankingLabel = esGerenteGrupo
        ? 'Ranking mis vendedores'
        : 'Ranking en distribuidora';

    return Row(
      children: [
        Expanded(child: _tile(yearLabel, totalAnual.toString())),
        const SizedBox(width: 12),
        Expanded(child: _tile(rankingLabel, rankingTxt)),
        const SizedBox(width: 12),
        Expanded(child: _tile('Promedio', avgTxt)),
      ],
    );
  }
}

class _BarsSection extends StatelessWidget {
  const _BarsSection({
    required this.height,
    required this.serie,
    required this.year,
  });

  final double height;
  final List<int> serie;
  final int year;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: MyTimelineBarChart(
        serie: serie,
        year: year,
        style: TimelineBarChartStyle.avgLine,
        compact: true,
        highlightCurrentMonth: true,
      ),
    );
  }
}

class _PiesSection extends StatelessWidget {
  const _PiesSection({
    required this.data,
    required this.selectedMonth,
    required this.onMonthChanged,
    required this.title,
  });

  final _PiesData data;
  final int selectedMonth;
  final ValueChanged<int> onMonthChanged;
  final String title;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final screenWidth = MediaQuery.of(context).size.width;

    const meses = [
      'Enero',
      'Febrero',
      'Marzo',
      'Abril',
      'Mayo',
      'Junio',
      'Julio',
      'Agosto',
      'Septiembre',
      'Octubre',
      'Noviembre',
      'Diciembre',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 16),
        Text(
          title,
          style: tt.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Total anual
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  height: 48,
                  child: Center(child: Text('Total anual')),
                ),
                const SizedBox(height: 8),
                MyPieChart(
                  data: data.datosAnual,
                  style: ProportionsPieChartStyle.minimal,
                  compact: true,
                  highlightId: data.highlightId,
                  highlightColor: cs.primary,
                  dimOthersOpacity: 0.45,
                  widthFraction: 1.0,
                  minDiameter: screenWidth / 3,
                  maxDiameter: screenWidth / 3,
                ),
              ],
            ),
            const SizedBox(width: 12),
            // Mes
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 48,
                  child: Center(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        isDense: true,
                        value: selectedMonth,
                        items: List.generate(
                          12,
                          (i) => DropdownMenuItem(
                            value: i + 1,
                            child: Text(
                              meses[i],
                              style: tt.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        onChanged: (v) => onMonthChanged(v ?? selectedMonth),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                MyPieChart(
                  data: data.datosMensual,
                  style: ProportionsPieChartStyle.minimal,
                  compact: true,
                  highlightId: data.highlightId,
                  highlightColor: cs.primary,
                  dimOthersOpacity: 0.45,
                  widthFraction: 1.0,
                  minDiameter: screenWidth / 3,
                  maxDiameter: screenWidth / 3,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

// =======================================================
// ==============  SELECTORES / HELPERS  =================
// =======================================================

class _SalesSelectors {
  static dynamic distOrigen(List distribuidores, dynamic asignacionActiva) {
    if (asignacionActiva == null) return null;
    try {
      return distribuidores.firstWhere(
        (d) => !d.deleted && d.uid == asignacionActiva.distribuidorUid,
      );
    } catch (_) {
      return null;
    }
  }

  /// Si [isRootConcentradora]=true, toma el **root** (concentradora o sí misma).
  static Set<String> clusterFromBaseDistribuidora({
    required String baseUid,
    required List distribuidores,
    bool isRootConcentradora = false,
  }) {
    var base;
    try {
      base = distribuidores.firstWhere((d) => !d.deleted && d.uid == baseUid);
    } catch (_) {
      base = null;
    }
    if (base == null) return <String>{};

    final rootUid = isRootConcentradora && base.concentradoraUid.isNotEmpty
        ? base.concentradoraUid
        : (base.concentradoraUid.isNotEmpty ? base.concentradoraUid : base.uid);

    final out = <String>{};
    for (final d in distribuidores) {
      if (d.deleted == true) continue;
      final conc = d.concentradoraUid.isNotEmpty ? d.concentradoraUid : d.uid;
      if (conc == rootUid) out.add(d.uid);
    }
    if (out.isEmpty) out.add(base.uid);
    return out;
  }

  // ------- Scope específico para GERENTE DE GRUPO -------
  static Set<String> clusterGerenteGrupo({
    required String gerenteColaboradorUid,
    required List asignaciones,
    required List distribuidores,
  }) {
    // 🔹 Queremos SOLO las distribuidoras activas que tiene asignadas
    //    sin expandir a cluster / concentradora.
    final bases = <String>{};
    for (final a in asignaciones) {
      if (a.deleted == true) continue;
      if (a.fechaFin != null) continue;
      if (a.rol != "gerente de grupo") continue;

      if (a.colaboradorUid == gerenteColaboradorUid &&
          (a.distribuidorUid ?? '').toString().isNotEmpty) {
        bases.add(a.distribuidorUid);
      }
    }

    // devolvemos directamente esas distribuidoras como scope
    return bases;
  }

  // ------- Opciones de vendedores -------
  static List<MapEntry<String, String>> vendedoresConVentasEnAnio({
    required List ventas,
    required Map<String, dynamic> asigByUid,
    required List colaboradores,
    required int anio,
    Set<String>? limitarPorClusterUids,
  }) {
    final colabsConVentas = <String, int>{}; // colaboradorUid -> conteo
    for (final v in ventas) {
      if (v.deleted == true) continue;
      final y = v.anioVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().year;
      if (y != anio) continue;

      final asig = asigByUid[v.vendedorUid];
      if (asig == null) continue;
      if (limitarPorClusterUids != null) {
        final du = (v.distribuidoraUid).trim();
        final doU = (v.distribuidoraOrigenUid).trim();
        final inCluster =
            (du.isNotEmpty && limitarPorClusterUids.contains(du)) ||
            (doU.isNotEmpty && limitarPorClusterUids.contains(doU));
        if (!inCluster) continue;
      }
      final colabUid = asig.colaboradorUid;
      if (colabUid.isEmpty) continue;
      colabsConVentas.update(colabUid, (c) => c + 1, ifAbsent: () => 1);
    }
    final out = <MapEntry<String, String>>[];
    for (final colabUid in colabsConVentas.keys) {
      final colab = colaboradorPorUidSinDeleted(colaboradores, colabUid);
      final nombre = nombreColaboradorNullSafe(colab);
      out.add(MapEntry(colabUid, nombre.isEmpty ? colabUid : nombre));
    }
    out.sort((a, b) => _fold(a.value).compareTo(_fold(b.value)));
    return out;
  }

  // ------- Serie, ranking, meses -------
  static List<int> seriePorColaborador({
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

  static ({int? rank, int total}) rankingAnual({
    required List ventas,
    required Map<String, dynamic> asigByUid,
    required int anio,
    required Set<String>? scopeClusterUids,
    required String colaboradorUidSeleccionado,
  }) {
    if (colaboradorUidSeleccionado.isEmpty) return (rank: null, total: 0);

    final totalesPorColab = <String, int>{};
    for (final v in ventas) {
      if (v.deleted == true) continue;
      final y = v.anioVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().year;
      if (y != anio) continue;

      if (scopeClusterUids != null) {
        final du = (v.distribuidoraUid).trim();
        final doU = (v.distribuidoraOrigenUid).trim();
        final inCluster =
            (du.isNotEmpty && scopeClusterUids.contains(du)) ||
            (doU.isNotEmpty && scopeClusterUids.contains(doU));
        if (!inCluster) continue;
      }

      final asig = asigByUid[v.vendedorUid];
      if (asig == null) continue;
      final colabUid = asig.colaboradorUid;
      if (colabUid.isEmpty) continue;

      totalesPorColab.update(colabUid, (c) => c + 1, ifAbsent: () => 1);
    }

    if (totalesPorColab.isEmpty) return (rank: null, total: 0);

    final entries = totalesPorColab.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    int? rankSeleccionado;
    int lastValue = -1;
    int lastRank = 0;
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final currentRank = (e.value == lastValue) ? lastRank : (i + 1);
      if (e.key == colaboradorUidSeleccionado) {
        rankSeleccionado = currentRank;
        break;
      }
      lastValue = e.value;
      lastRank = currentRank;
    }
    return (rank: rankSeleccionado, total: entries.length);
  }

  static Set<int> mesesConVentas({
    required List ventas,
    required int anio,
    required Map<String, dynamic> asigByUid,
    required String colaboradorUid,
    Set<String>? scopeClusterUids,
  }) {
    final meses = <int>{};
    for (final v in ventas) {
      if (v.deleted == true) continue;

      final y = v.anioVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().year;
      if (y != anio) continue;

      final asig = asigByUid[v.vendedorUid];
      if (asig == null) continue;
      if (colaboradorUid.isNotEmpty && asig.colaboradorUid != colaboradorUid) {
        continue;
      }

      if (scopeClusterUids != null) {
        final du = (v.distribuidoraUid).trim();
        final doU = (v.distribuidoraOrigenUid).trim();
        final inScope =
            (du.isNotEmpty && scopeClusterUids.contains(du)) ||
            (doU.isNotEmpty && scopeClusterUids.contains(doU));
        if (!inScope) continue;
      }

      final m = v.mesVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().month;
      if (m >= 1 && m <= 12) meses.add(m);
    }
    return meses;
  }

  // ------- PIES -------
  static _PiesData piesData({
    required List ventas,
    required int anio,
    required Set<String>? scopeClusterUids,
    required Map<String, dynamic> asigByUid,
    required Map<String, dynamic> colabByUid,
    required int selectedMonth,
    required dynamic distOrigen,
    required bool esVendedor,
    required String selectedColaboradorUid,
  }) {
    // Filtrar ventas por anio/scope
    final ventasAnio = <dynamic>[];
    for (final v in ventas) {
      if (v.deleted == true) continue;
      final y = v.anioVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().year;
      if (y != anio) continue;

      if (scopeClusterUids != null) {
        final du = (v.distribuidoraUid).trim();
        final doU = (v.distribuidoraOrigenUid).trim();
        final inCluster =
            (du.isNotEmpty && scopeClusterUids.contains(du)) ||
            (doU.isNotEmpty && scopeClusterUids.contains(doU));
        if (!inCluster) continue;
      }
      ventasAnio.add(v);
    }

    // Agrupar por vendedorUid
    final porVendedor = <String, int>{};
    for (final v in ventasAnio) {
      final uidAsig = v.vendedorUid;
      if (uidAsig.isEmpty) continue;
      porVendedor.update(uidAsig, (c) => c + 1, ifAbsent: () => 1);
    }

    // highlightId
    String? highlightId;

    // El colaborador "target" para resaltar es el que recibimos por argumento.
    // (Para vendedor ya viene del asignacionActiva; para gerente/admin del picker).
    final targetColabUid = selectedColaboradorUid.trim();

    // Si hay target: 1) preferimos su asignación en la base actual (si distOrigen != null)
    //                2) si no, cualquiera de sus asignaciones presentes en el pie
    if (targetColabUid.isNotEmpty) {
      if (distOrigen != null) {
        try {
          highlightId = porVendedor.keys.firstWhere((idAsig) {
            final a = asigByUid[idAsig];
            return a != null &&
                a.colaboradorUid == targetColabUid &&
                a.distribuidorUid == distOrigen.uid;
          });
        } catch (_) {
          /* no encontrada en esa base */
        }
      }

      // Fallback: cualquier asignación del colaborador presente en el pie
      highlightId ??= porVendedor.keys.cast<String?>().firstWhere((idAsig) {
        final a = asigByUid[idAsig];
        return a != null && a.colaboradorUid == targetColabUid;
      }, orElse: () => null);
    } else {
      for (final idAsig in porVendedor.keys) {
        final asig = asigByUid[idAsig];
        if (asig != null && asig.colaboradorUid == selectedColaboradorUid) {
          highlightId = idAsig;
          break;
        }
      }
    }

    // datos anual
    final datosAnual = porVendedor.entries.map((e) {
      final asig = asigByUid[e.key];
      final colab = asig != null ? colabByUid[asig.colaboradorUid] : null;
      final nombre = _primerNombre(colab?.nombres);
      return PieDatum(label: nombre, value: e.value.toDouble(), id: e.key);
    }).toList()..sort((a, b) => b.value.compareTo(a.value));

    // datos mensual
    final porVendedorMes = <String, int>{};
    for (final v in ventasAnio) {
      final m = v.mesVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().month;
      if (m != selectedMonth) continue;
      final uidAsig = v.vendedorUid;
      if (uidAsig.isEmpty) continue;
      porVendedorMes.update(uidAsig, (c) => c + 1, ifAbsent: () => 1);
    }
    final datosMensual = porVendedorMes.entries.map((e) {
      final asig = asigByUid[e.key];
      final colab = asig != null ? colabByUid[asig.colaboradorUid] : null;
      final nombre = _primerNombre(colab?.nombres);
      return PieDatum(label: nombre, value: e.value.toDouble(), id: e.key);
    }).toList()..sort((a, b) => b.value.compareTo(a.value));

    return _PiesData(
      datosAnual: datosAnual,
      datosMensual: datosMensual,
      highlightId: highlightId,
    );
  }

  // ------- ADMIN: bases/scope -------
  static Set<String> _adminScopeForColaborador({
    required String colaboradorUid,
    required int anio,
    required List ventas,
    required Map<String, dynamic> asigByUid,
    required List asignaciones,
    required List distribuidores,
  }) {
    final bases = <String>{};
    for (final a in asignaciones) {
      if (a.deleted == true) continue;
      if (a.colaboradorUid == colaboradorUid &&
          (a.distribuidorUid ?? '').toString().isNotEmpty) {
        bases.add(a.distribuidorUid);
      }
    }
    for (final v in ventas) {
      if (v.deleted == true) continue;
      final y = v.anioVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().year;
      if (y != anio) continue;
      final asigVenta = asigByUid[v.vendedorUid];
      if (asigVenta == null) continue;
      if (asigVenta.colaboradorUid != colaboradorUid) continue;

      final du = (v.distribuidoraUid ?? '').toString().trim();
      final doU = (v.distribuidoraOrigenUid ?? '').toString().trim();
      if (du.isNotEmpty) bases.add(du);
      if (doU.isNotEmpty) bases.add(doU);
    }

    final scope = <String>{};
    for (final baseUid in bases) {
      scope.addAll(
        clusterFromBaseDistribuidora(
          baseUid: baseUid,
          distribuidores: distribuidores,
        ),
      );
    }
    return scope;
  }

  static Set<String>? adminScopeElegido({
    required String colaboradorUid,
    required int anio,
    required List ventas,
    required Map<String, dynamic> asigByUid,
    required List asignaciones,
    required List distribuidores,
    required String? selectedBaseDistribuidoraUid,
    required String allBasesKey,
  }) {
    if (colaboradorUid.isEmpty) return null;

    if (selectedBaseDistribuidoraUid == allBasesKey) {
      return _adminScopeForColaborador(
        colaboradorUid: colaboradorUid,
        anio: anio,
        ventas: ventas,
        asigByUid: asigByUid,
        asignaciones: asignaciones,
        distribuidores: distribuidores,
      );
    }

    if (selectedBaseDistribuidoraUid != null &&
        selectedBaseDistribuidoraUid.isNotEmpty) {
      return clusterFromBaseDistribuidora(
        baseUid: selectedBaseDistribuidoraUid,
        distribuidores: distribuidores,
      );
    }

    // Si solo hay una base, úsala; si no, total
    final bases = basesDelColaboradorUids(
      colaboradorUid: colaboradorUid,
      anio: anio,
      asignaciones: asignaciones,
      ventas: ventas,
      asigByUid: asigByUid,
    );
    if (bases.length == 1) {
      return clusterFromBaseDistribuidora(
        baseUid: bases.first,
        distribuidores: distribuidores,
      );
    }
    return null;
  }

  static List<MapEntry<String, String>> basesDelColaboradorEnAnio({
    required String colaboradorUid,
    required int anio,
    required List asignaciones,
    required List ventas,
    required Map<String, dynamic> asigByUid,
    required List distribuidores,
    required String allBasesKey,
    required String? selectedBaseDistribuidoraUid,
    required ValueChanged<String?> onNormalized,
  }) {
    final basesUids = basesDelColaboradorUids(
      colaboradorUid: colaboradorUid,
      anio: anio,
      asignaciones: asignaciones,
      ventas: ventas,
      asigByUid: asigByUid,
    );

    String nombreBase(String uid) {
      try {
        final d = distribuidores.firstWhere((x) => !x.deleted && x.uid == uid);
        final reg = RegExp(r'^\s*mazda\b[\s\-–—:]*', caseSensitive: false);
        return d.nombre.replaceFirst(reg, '').trim();
      } catch (_) {
        return uid;
      }
    }

    var items = basesUids.map((u) => MapEntry(u, nombreBase(u))).toList()
      ..sort((a, b) => _fold(a.value).compareTo(_fold(b.value)));

    if (items.length > 1) {
      items.insert(0, MapEntry(allBasesKey, 'Todas sus distribuidoras'));
    }

    // Normalizar selección
    if (items.isEmpty) {
      if (selectedBaseDistribuidoraUid != null) onNormalized(null);
    } else if (selectedBaseDistribuidoraUid == null) {
      onNormalized(items.first.key);
    } else if (!items.any((e) => e.key == selectedBaseDistribuidoraUid)) {
      onNormalized(items.first.key);
    }

    return items;
  }

  static List<String> basesDelColaboradorUids({
    required String colaboradorUid,
    required int anio,
    required List asignaciones,
    required List ventas,
    required Map<String, dynamic> asigByUid,
  }) {
    final bases = <String>{};
    for (final a in asignaciones) {
      if (a.deleted == true) continue;
      if (a.colaboradorUid == colaboradorUid &&
          (a.distribuidorUid ?? '').toString().isNotEmpty) {
        bases.add(a.distribuidorUid);
      }
    }
    for (final v in ventas) {
      if (v.deleted == true) continue;
      final y = v.anioVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().year;
      if (y != anio) continue;

      final asigVenta = asigByUid[v.vendedorUid];
      if (asigVenta == null) continue;
      if (asigVenta.colaboradorUid != colaboradorUid) continue;

      final du = (v.distribuidoraUid ?? '').toString().trim();
      final doU = (v.distribuidoraOrigenUid ?? '').toString().trim();
      if (du.isNotEmpty) bases.add(du);
      if (doU.isNotEmpty) bases.add(doU);
    }
    return bases.toList();
  }

  // ------- Contexto -------
  static String? contextoDistribuidoraNombre({
    required bool esVendedor,
    required bool esGerente,
    required bool esAdmin,
    required bool esGerenteGrupo,
    required dynamic distOrigen,
    required Set<String> clusterUids,
    required String selectedColaboradorUid,
    required List asignaciones,
    required List distribuidores,
    required List ventas,
    required int anio,
  }) {
    String _sinPrefijoMazdaLocal(String s) {
      if (s.isEmpty) return '';
      final reg = RegExp(r'^\s*mazda\b[\s\-–—:]*', caseSensitive: false);
      return s.replaceFirst(reg, '').trimLeft();
    }

    if (esVendedor && distOrigen != null) {
      try {
        final concUid = distOrigen.concentradoraUid.isNotEmpty
            ? distOrigen.concentradoraUid
            : distOrigen.uid;
        final conc = distribuidores.firstWhere(
          (d) => !d.deleted && d.uid == concUid,
        );
        return 'Cluster ${_sinPrefijoMazdaLocal(conc.nombre)}';
      } catch (_) {
        return null;
      }
    }

    if (esGerente && distOrigen != null) {
      try {
        final concUid = distOrigen.concentradoraUid.isNotEmpty
            ? distOrigen.concentradoraUid
            : distOrigen.uid;
        final conc = distribuidores.firstWhere(
          (d) => !d.deleted && d.uid == concUid,
        );
        return 'Cluster ${_sinPrefijoMazdaLocal(conc.nombre)}';
      } catch (_) {
        return null;
      }
    }

    if ((esAdmin || esGerenteGrupo) && selectedColaboradorUid.isNotEmpty) {
      String? baseDistribuidoraUid;
      try {
        final asigColab = asignaciones.firstWhere(
          (a) => !a.deleted && a.colaboradorUid == selectedColaboradorUid,
        );
        baseDistribuidoraUid = asigColab.distribuidorUid;
      } catch (_) {
        baseDistribuidoraUid = null;
      }

      if (baseDistribuidoraUid == null || baseDistribuidoraUid.isEmpty) {
        for (final v in ventas) {
          if (v.deleted == true) continue;
          final y = v.anioVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().year;
          if (y != anio) continue;

          final vendedorUid = v.vendedorUid;
          try {
            final asigVenta = asignaciones.firstWhere(
              (a) => a.uid == vendedorUid,
            );
            if (asigVenta.colaboradorUid != selectedColaboradorUid) continue;
            final du = (v.distribuidoraUid).trim();
            final doU = (v.distribuidoraOrigenUid).trim();
            baseDistribuidoraUid = du.isNotEmpty
                ? du
                : (doU.isNotEmpty ? doU : null);
            if (baseDistribuidoraUid != null) break;
          } catch (_) {}
        }
      }

      if (baseDistribuidoraUid != null && baseDistribuidoraUid.isNotEmpty) {
        try {
          final base = distribuidores.firstWhere(
            (d) => !d.deleted && d.uid == baseDistribuidoraUid,
          );
          final concUid = base.concentradoraUid.isNotEmpty
              ? base.concentradoraUid
              : base.uid;
          final conc = distribuidores.firstWhere(
            (d) => !d.deleted && d.uid == concUid,
          );
          return 'Cluster ${_sinPrefijoMazdaLocal(conc.nombre)}';
        } catch (_) {
          return null;
        }
      }
    }
    return null;
  }

  // ------- Otros helpers puros -------
  static dynamic colaboradorPorUidSinDeleted(List colabs, String uid) {
    try {
      return colabs.firstWhere((c) => c.uid == uid);
    } catch (_) {
      return null;
    }
  }

  static String nombreColaboradorNullSafe(colab) {
    if (colab == null) return '';
    final s =
        '${colab.nombres ?? ''} ${colab.apellidoPaterno ?? ''} ${colab.apellidoMaterno ?? ''}';
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static double? avgCorriente(List<int> serie, int year, DateTime now) {
    final cutoffExclusive = () {
      if (year != now.year) return 12;
      var lastIdx = -1;
      for (var i = 0; i < 12; i++) {
        if (serie[i] > 0) lastIdx = i;
      }
      if (lastIdx < 0) return (now.month - 1).clamp(0, 12);
      return (lastIdx + 1).clamp(0, 12);
    }();

    if (cutoffExclusive <= 0) return null;
    int? firstIdx;
    for (var i = 0; i < cutoffExclusive; i++) {
      if (serie[i] > 0) {
        firstIdx = i;
        break;
      }
    }
    if (firstIdx == null) return null;

    final months = cutoffExclusive - firstIdx;
    if (months <= 0) return null;

    var sum = 0;
    for (var i = firstIdx; i < cutoffExclusive; i++) {
      sum += serie[i];
    }
    return sum / months;
  }

  static String _primerNombre(String? nombres) {
    if (nombres == null || nombres.trim().isEmpty) return '—';
    final parts = nombres.trim().split(RegExp(r'\s+'));
    return parts.first;
  }

  static String _fold(String s) => s
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('à', 'a')
      .replaceAll('ä', 'a')
      .replaceAll('â', 'a')
      .replaceAll('ã', 'a')
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ë', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ì', 'i')
      .replaceAll('ï', 'i')
      .replaceAll('î', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ò', 'o')
      .replaceAll('ö', 'o')
      .replaceAll('ô', 'o')
      .replaceAll('õ', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ù', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('û', 'u')
      .replaceAll('ñ', 'n')
      .replaceAll('ç', 'c')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  // Devuelve el nombre de la CONCENTRADORA usada en el análisis de pies,
  // o múltiples separadas por " / " si aplica (admin con varias bases).
  static String? concentradoraNombreParaPies({
    required bool esVendedor,
    required bool esGerente,
    required bool esAdmin,
    required dynamic
    distOrigen, // distribuidora base del contexto (vendedor/gerente)
    required String selectedColaboradorUid,
    required List asignaciones,
    required List distribuidores,
    required List ventas,
    required int anio,
    required String? selectedBaseDistribuidoraUid,
    required String allBasesKey,
  }) {
    String? _concentradoraNombreDeBase(String baseUid) {
      try {
        final base = distribuidores.firstWhere(
          (d) => !d.deleted && d.uid == baseUid,
        );
        final concUid = base.concentradoraUid.isNotEmpty
            ? base.concentradoraUid
            : base.uid;
        final conc = distribuidores.firstWhere(
          (d) => !d.deleted && d.uid == concUid,
        );
        return conc.nombre;
      } catch (_) {
        return null;
      }
    }

    // Vendedor / Gerente: siempre es la concentradora de su distOrigen
    if ((esVendedor || esGerente) && distOrigen != null) {
      final concUid = distOrigen.concentradoraUid.isNotEmpty
          ? distOrigen.concentradoraUid
          : distOrigen.uid;
      try {
        final conc = distribuidores.firstWhere(
          (d) => !d.deleted && d.uid == concUid,
        );
        return conc.nombre;
      } catch (_) {
        return null;
      }
    }

    // Admin con asesor seleccionado
    if (esAdmin && selectedColaboradorUid.isNotEmpty) {
      // Si eligió una base específica en el dropdown → esa concentradora
      if (selectedBaseDistribuidoraUid != null &&
          selectedBaseDistribuidoraUid.isNotEmpty &&
          selectedBaseDistribuidoraUid != allBasesKey) {
        return _concentradoraNombreDeBase(selectedBaseDistribuidoraUid);
      }

      // Si eligió "todas": determinar todas las bases y sus concentradoras
      final bases = basesDelColaboradorUids(
        colaboradorUid: selectedColaboradorUid,
        anio: anio,
        asignaciones: asignaciones,
        ventas: ventas,
        asigByUid: {for (final a in asignaciones) a.uid: a},
      );

      final concNombres = <String>{};
      for (final b in bases) {
        final n = _concentradoraNombreDeBase(b);
        if (n != null && n.isNotEmpty) concNombres.add(n);
      }

      if (concNombres.isEmpty) return null;
      if (concNombres.length == 1) return concNombres.first;

      // Varias concentradoras (unión de clusters) → las mostramos juntas
      return concNombres.join(' / ');
    }

    return null;
  }
}

// =======================================================
// =================== TIPOS AUXILIARES ==================
// =======================================================

class _PiesData {
  final List<PieDatum> datosAnual;
  final List<PieDatum> datosMensual;
  final String? highlightId;
  const _PiesData({
    required this.datosAnual,
    required this.datosMensual,
    required this.highlightId,
  });
  const _PiesData.empty()
    : datosAnual = const [],
      datosMensual = const [],
      highlightId = null;
}

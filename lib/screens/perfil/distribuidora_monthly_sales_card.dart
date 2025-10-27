import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/database/grupo_distribuidores/grupos_distribuidores_provider.dart';
import 'package:myafmzd/database/ventas/ventas_provider.dart';
import 'package:myafmzd/session/sesion_asignacion_selectors.dart';
import 'package:myafmzd/widgets/charts/my_timeline_bar_chart.dart';
import 'package:myafmzd/widgets/charts/my_pie_chart.dart';
import 'package:myafmzd/widgets/my_picker_search_field.dart';

enum _RankingScope { grupo, total }

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
    extends ConsumerState<DistribuidoraMonthlySalesCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // ---- Estado mínimo (paridad con Asesor) ----
  late int _selectedYear;
  late int _selectedMonth;

  /// Picker de concentradora (root). Para vendedor se fija en su concentradora de contexto.
  String? _selectedConcentradoraUid;

  _RankingScope _scope = _RankingScope.grupo;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear ?? DateTime.now().year;
    _recomputeSelectedMonth();
  }

  @override
  void didUpdateWidget(covariant DistribuidoraMonthlySalesCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialYear != null && widget.initialYear != _selectedYear) {
      setState(() => _selectedYear = widget.initialYear!);
      _recomputeSelectedMonth();
    }
  }

  // Igual que en Asesor: toma el último mes con ventas dentro del scope real
  void _recomputeSelectedMonth() {
    final ventas = ref.read(ventasProvider);
    final distribuidores = ref.read(distribuidoresProvider);
    final asignacionActiva = ref.read(activeAssignmentProvider);

    final rol = widget.rolActivo.toLowerCase().trim();
    final esGerente = rol == 'gerente';
    final esVendedor = rol == 'vendedor';

    // Dist / root de contexto (para vendedor/gerente)
    final distOrigen = _DistSelectors.distOrigen(
      distribuidores,
      asignacionActiva,
    );
    final rootDeContexto = _DistSelectors.rootUidFromBase(
      distOrigen,
      distribuidores,
    );

    // Root objetivo (la que define el scope del card)
    final rootObjetivo = () {
      if (esVendedor || esGerente) return rootDeContexto;
      return _selectedConcentradoraUid; // admin elige con el picker
    }();

    final nuevoMes = _DistSelectors.recomputeSelectedMonth(
      ventas: ventas,
      distribuidores: distribuidores,
      anio: _selectedYear,
      rootUid: rootObjetivo,
      fallback: DateTime.now().month,
    );

    setState(() => _selectedMonth = nuevoMes);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;

    final ventas = ref.watch(ventasProvider);
    final distribuidores = ref.watch(distribuidoresProvider);
    final asignacionActiva = ref.watch(activeAssignmentProvider);
    final grupos = ref.watch(gruposDistribuidoresProvider);

    final rol = widget.rolActivo.toLowerCase().trim();
    final esAdmin = rol == 'admin';
    final esGerente = rol == 'gerente';
    final esVendedor = rol == 'vendedor';

    // Contexto (para vendedor/gerente)
    final distOrigen = _DistSelectors.distOrigen(
      distribuidores,
      asignacionActiva,
    );
    final rootDeContexto = _DistSelectors.rootUidFromBase(
      distOrigen,
      distribuidores,
    );

    // Opciones del picker: TODAS las concentradoras (roots), no bases
    final opcionesConcentradoras = _DistSelectors.opcionesConcentradoras(
      distribuidores,
    );

    // Selección por defecto según rol
    if (_selectedConcentradoraUid == null) {
      if (esVendedor || esGerente) {
        _selectedConcentradoraUid = _DistSelectors.rootUidFromBase(
          distOrigen,
          distribuidores,
        );
      } else {
        // Admin: sin selección => barras muestran TOTAL por mes, pies ocultos
        _selectedConcentradoraUid = null;
      }
    }

    // Root objetivo (cluster a graficar)
    final rootObjetivo = () {
      if (esVendedor || esGerente) return rootDeContexto;
      return _selectedConcentradoraUid;
    }();

    final grupoNombre = _DistSelectors.grupoNombreParaConcentradora(
      distribuidores: distribuidores,
      grupos: grupos,
      rootUid: rootObjetivo,
    );

    // Serie mensual
    final serie = () {
      final sinSeleccionAdmin =
          esAdmin && (rootObjetivo == null || rootObjetivo.isEmpty);
      if (sinSeleccionAdmin) {
        return _DistSelectors.serieTotalPorMes(
          ventas: ventas,
          anio: _selectedYear,
        ); // TOTAL por mes
      }
      return _DistSelectors.seriePorRootCluster(
        ventas: ventas,
        distribuidores: distribuidores,
        anio: _selectedYear,
        rootUid: rootObjetivo,
      );
    }();

    final totalAnual = serie.fold<int>(0, (a, b) => a + b);
    final promedio = _DistSelectors.avgCorriente(
      serie,
      _selectedYear,
      DateTime.now(),
    );

    // Rankings: grupo vs total (ambos calculados; usamos el que diga _scope)
    final rankingTotal = (rootObjetivo == null)
        ? (rank: null as int?, total: 0)
        : _DistSelectors.rankingAnualRoot(
            ventas: ventas,
            distribuidores: distribuidores,
            anio: _selectedYear,
            rootUidSeleccionada: rootObjetivo,
          );

    final rankingGrupo = (rootObjetivo == null)
        ? (rank: null as int?, total: 0)
        : _DistSelectors.rankingAnualRootEnGrupo(
            ventas: ventas,
            distribuidores: distribuidores,
            anio: _selectedYear,
            rootUidSeleccionada: rootObjetivo,
          );

    final isGrupo = _scope == _RankingScope.grupo;
    final rankingActual = isGrupo ? rankingGrupo : rankingTotal;

    final rankingTxt = (rankingActual.rank == null || rankingActual.total == 0)
        ? '—'
        : '#${rankingActual.rank} de ${rankingActual.total}';
    ;

    // Subtítulo tipo “Cluster X”
    final subtitulo = _DistSelectors.subtituloCluster(
      esAdmin: esAdmin,
      rootUid: rootObjetivo,
      distribuidores: distribuidores,
      totalKeySeleccionado: false, // ya no usamos TOTAL
    );

    // ===== PIES =====
    final puedeVerPies = rootObjetivo != null && rootObjetivo.isNotEmpty;

    final piesData = puedeVerPies
        ? (isGrupo
              ? _DistSelectors.piesConcentradorasPorGrupo(
                  ventas: ventas,
                  distribuidores: distribuidores,
                  anio: _selectedYear,
                  selectedMonth: _selectedMonth,
                  concentradoraSeleccionadaUid: rootObjetivo,
                )
              : _DistSelectors.piesConcentradorasGlobal(
                  ventas: ventas,
                  distribuidores: distribuidores,
                  anio: _selectedYear,
                  selectedMonth: _selectedMonth,
                  concentradoraSeleccionadaUid: rootObjetivo,
                ))
        : const _PiesData.empty();

    final piesTitle = isGrupo
        ? (() {
            final distName = _DistSelectors.nombreRootPorUid(
              distribuidores,
              rootObjetivo,
            );
            return 'APORTACIÓN DE ${distName?.toUpperCase()} EN GRUPO ${grupoNombre.toUpperCase()}';
          })()
        : 'APORTACIÓN EN TOTAL (ACTIVAS)';

    return Card(
      elevation: 1,
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ===== Header (solo año + títulos) =====
            _HeaderControls(
              titulo: () {
                if (esVendedor || esGerente) {
                  final name = _DistSelectors.nombreRootPorUid(
                    distribuidores,
                    rootObjetivo,
                  );
                  return (name == null)
                      ? 'VENTAS POR MES (DISTRIBUIDORA)'
                      : 'VENTAS DE ${name.toUpperCase()}';
                }
                // Admin:
                final sel = _selectedConcentradoraUid ?? '';
                if (sel.isEmpty) return 'VENTAS TOTALES POR MES';
                final name = _DistSelectors.entryByKey(
                  opcionesConcentradoras,
                  sel,
                )?.value;
                return (name == null || name.isEmpty)
                    ? 'VENTAS POR MES (DISTRIBUIDORA)'
                    : 'VENTAS DE ${name.toUpperCase()}';
              }(),
              subtitulo: subtitulo,
            ),

            // ===== Picker de CONCENTRADORA (como en Asesor) =====
            if (esAdmin) ...[
              const SizedBox(height: 12),
              _ConcentradoraPicker(
                opciones: opcionesConcentradoras,
                selected: _DistSelectors.entryByKey(
                  opcionesConcentradoras,
                  _selectedConcentradoraUid ?? '',
                ),
                onChanged: (val) => setState(() {
                  _selectedConcentradoraUid = val?.key;
                  _selectedMonth = _DistSelectors.recomputeSelectedMonth(
                    ventas: ventas,
                    distribuidores: distribuidores,
                    anio: _selectedYear,
                    rootUid: _selectedConcentradoraUid,
                    fallback: _selectedMonth,
                  );
                }),
              ),
            ],

            const SizedBox(height: 8),

            // ===== KPIs =====
            _KpisRow(
              yearLabel: '$_selectedYear',
              totalAnual: totalAnual,
              rankingTxt: rankingTxt,
              promedio: promedio,
              rankingLabel: isGrupo ? 'Ranking en grupo' : 'Ranking total',
            ),

            const SizedBox(height: 12),

            // ===== Barras mensuales =====
            _BarsSection(
              height: widget.chartHeight,
              serie: serie,
              year: _selectedYear,
            ),

            if (puedeVerPies)
              _PiesSection(
                data: piesData,
                selectedMonth: _selectedMonth,
                onMonthChanged: (m) => setState(() => _selectedMonth = m),
                title: piesTitle,
                scope: _scope,
                onToggleScope: () => setState(() {
                  _scope = (_scope == _RankingScope.grupo)
                      ? _RankingScope.total
                      : _RankingScope.grupo;
                }),
              ),
          ],
        ),
      ),
    );
  }
}

/* ================== SUB-WIDGETS ================== */

class _HeaderControls extends StatelessWidget {
  const _HeaderControls({required this.titulo, required this.subtitulo});

  final String titulo;
  final String? subtitulo;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
        ],
      ),
    );
  }
}

class _ConcentradoraPicker extends StatelessWidget {
  const _ConcentradoraPicker({
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
        Icon(Icons.apartment_outlined, color: cs.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: MyPickerSearchField<MapEntry<String, String>>(
            items: opciones,
            itemAsString: (e) => e.value,
            compareFn: (a, b) => a.key == b.key,
            initialValue: selected,
            labelText: 'Concentradora',
            hintText: 'Seleccione una concentradora',
            bottomSheetTitle: 'Concentradoras',
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
    required this.rankingLabel,
  });

  final String yearLabel;
  final int totalAnual;
  final String rankingTxt;
  final double? promedio;
  final String rankingLabel;

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
              maxLines: 2,
            ),
          ],
        ),
      );
    }

    final avgTxt = (promedio == null)
        ? '—'
        : (promedio! >= 10
              ? promedio!.toStringAsFixed(0)
              : promedio!.toStringAsFixed(1));

    return Row(
      children: [
        Expanded(child: _tile(yearLabel, totalAnual.toString())),
        const SizedBox(width: 4),
        Expanded(child: _tile(rankingLabel, rankingTxt)),
        const SizedBox(width: 4),
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
    required this.scope,
    required this.onToggleScope,
  });

  final _PiesData data;
  final int selectedMonth;
  final ValueChanged<int> onMonthChanged;
  final String title;
  final _RankingScope scope;
  final VoidCallback onToggleScope;

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
        TextButton.icon(
          onPressed: onToggleScope,
          icon: Icon(
            scope == _RankingScope.grupo
                ? Icons.groups_2_outlined
                : Icons.public_outlined,
            color: cs.onPrimary,
          ),
          label: Text(
            scope == _RankingScope.total
                ? 'TOTAL (activas)'
                : 'GRUPO automotriz',
            style: tt.labelSmall?.copyWith(color: cs.onPrimary),
          ),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            foregroundColor: cs.primary,
            backgroundColor: cs.primary,
          ),
        ),
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

/* ================== SELECTORES / HELPERS ================== */

class _DistSelectors {
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

  static String? rootUidFromBase(dynamic base, List distribuidores) {
    if (base == null) return null;
    try {
      final conc = (base.concentradoraUid?.isNotEmpty == true)
          ? base.concentradoraUid
          : base.uid;
      final exists = distribuidores.any((d) => !d.deleted && d.uid == conc);
      return exists ? conc : null;
    } catch (_) {
      return null;
    }
  }

  static String _sinPrefijoMazda(String s) {
    if (s.isEmpty) return '';
    final reg = RegExp(r'^\s*mazda\b[\s\-–—:]*', caseSensitive: false);
    return s.replaceFirst(reg, '').trimLeft();
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

  // Serie mensual por cluster (rootUid != null). Si null, devuelve ceros.
  static List<int> seriePorRootCluster({
    required List ventas,
    required List distribuidores,
    required int anio,
    required String? rootUid,
  }) {
    if (rootUid == null || rootUid.isEmpty) {
      return List<int>.filled(12, 0);
    }

    final cluster = clusterUids(
      rootUid: rootUid,
      distribuidores: distribuidores,
    );
    final serie = List<int>.filled(12, 0);
    for (final v in ventas) {
      if (v.deleted == true) continue;
      final y = v.anioVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().year;
      if (y != anio) continue;

      final m = v.mesVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().month;
      if (m < 1 || m > 12) continue;

      final du = (v.distribuidoraUid ?? '').toString().trim();
      final doU = (v.distribuidoraOrigenUid ?? '').toString().trim();
      if (cluster.contains(du) || cluster.contains(doU)) {
        serie[m - 1] += 1;
      }
    }
    return serie;
  }

  // UIDs del cluster (todas las bases bajo la root)
  static Set<String> clusterUids({
    required String rootUid,
    required List distribuidores,
  }) {
    final out = <String>{};
    for (final d in distribuidores) {
      if (d.deleted == true) continue;
      final conc = (d.concentradoraUid?.isNotEmpty == true)
          ? d.concentradoraUid
          : d.uid;
      if (conc == rootUid) out.add(d.uid);
    }
    if (out.isEmpty) out.add(rootUid);
    return out;
  }

  /// Todas las concentradoras (roots) para el picker (sin duplicados).
  static List<MapEntry<String, String>> opcionesConcentradoras(
    List distribuidores,
  ) {
    final rootIds = <String>{};
    for (final d in distribuidores) {
      if (d.deleted == true || d.activo == false) continue;
      final rootUid = (d.concentradoraUid?.isNotEmpty == true)
          ? d.concentradoraUid
          : d.uid;
      rootIds.add(rootUid);
    }

    final porUid = {
      for (final d in distribuidores)
        if (!d.deleted) d.uid: d,
    };

    final items = <MapEntry<String, String>>[];
    for (final rid in rootIds) {
      final root = porUid[rid];
      if (root == null) continue;
      items.add(MapEntry(root.uid, _sinPrefijoMazda(root.nombre)));
    }

    items.sort((a, b) => _fold(a.value).compareTo(_fold(b.value)));
    return items;
  }

  /// Conjunto de concentradoras (roots) que pertenecen al MISMO grupo automotriz (uuidGrupo)
  static Set<String> concentradorasDelMismoGrupo({
    required String concentradoraUid,
    required List distribuidores,
  }) {
    final porUid = {
      for (final d in distribuidores)
        if (!d.deleted) d.uid: d,
    };

    final conc = porUid[concentradoraUid];
    if (conc == null) return <String>{};

    final grupoId = (conc.uuidGrupo ?? '').toString().trim();
    if (grupoId.isEmpty) {
      return {concentradoraUid};
    }

    final rootsEnGrupo = <String>{};
    for (final d in distribuidores) {
      if (d.deleted == true) continue;
      final rootUid = (d.concentradoraUid?.isNotEmpty == true)
          ? d.concentradoraUid
          : d.uid;
      final root = porUid[rootUid];
      if (root == null) continue;

      final g = (root.uuidGrupo ?? '').toString().trim();
      if (g == grupoId) rootsEnGrupo.add(rootUid);
    }
    return rootsEnGrupo;
  }

  /// Pies por grupo: cada porción es una CONCENTRADORA (root) del mismo grupo que la seleccionada.
  static _PiesData piesConcentradorasPorGrupo({
    required List ventas,
    required List distribuidores,
    required int anio,
    required int selectedMonth,
    required String concentradoraSeleccionadaUid,
  }) {
    final porUid = {
      for (final d in distribuidores)
        if (!d.deleted) d.uid: d,
    };

    final rootsGrupo = concentradorasDelMismoGrupo(
      concentradoraUid: concentradoraSeleccionadaUid,
      distribuidores: distribuidores,
    );
    if (rootsGrupo.isEmpty) {
      return const _PiesData.empty();
    }

    String nombreRoot(String uid) {
      final r = porUid[uid];
      return r == null ? uid : _sinPrefijoMazda(r.nombre);
    }

    final anual = <String, int>{};
    final mensual = <String, int>{};

    for (final v in ventas) {
      if (v.deleted == true) continue;
      final y = v.anioVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().year;
      if (y != anio) continue;

      final du = (v.distribuidoraUid ?? '').toString().trim();
      final doU = (v.distribuidoraOrigenUid ?? '').toString().trim();

      String? rootFrom(String uid) {
        if (uid.isEmpty) return null;
        final d = porUid[uid];
        if (d == null) return null;
        return (d.concentradoraUid?.isNotEmpty == true)
            ? d.concentradoraUid
            : d.uid;
      }

      final root = rootFrom(du) ?? rootFrom(doU);
      if (root == null) continue;
      if (!rootsGrupo.contains(root)) continue;

      anual.update(root, (c) => c + 1, ifAbsent: () => 1);

      final m = v.mesVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().month;
      if (m == selectedMonth) {
        mensual.update(root, (c) => c + 1, ifAbsent: () => 1);
      }
    }

    final datosAnual =
        anual.entries
            .map(
              (e) => PieDatum(
                label: nombreRoot(e.key),
                value: e.value.toDouble(),
                id: e.key,
              ),
            )
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final datosMensual =
        mensual.entries
            .map(
              (e) => PieDatum(
                label: nombreRoot(e.key),
                value: e.value.toDouble(),
                id: e.key,
              ),
            )
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final highlightId = rootsGrupo.contains(concentradoraSeleccionadaUid)
        ? concentradoraSeleccionadaUid
        : null;

    return _PiesData(
      datosAnual: datosAnual,
      datosMensual: datosMensual,
      highlightId: highlightId,
    );
  }

  // Ranking de la root seleccionada vs todas las roots (por total anual)
  static ({int? rank, int total}) rankingAnualRoot({
    required List ventas,
    required List distribuidores,
    required int anio,
    required String? rootUidSeleccionada,
  }) {
    if (rootUidSeleccionada == null || rootUidSeleccionada.isEmpty) {
      return (rank: null, total: 0);
    }

    final rootsTotales = <String, int>{}; // rootUid -> total anual
    for (final v in ventas) {
      if (v.deleted == true) continue;
      final y = v.anioVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().year;
      if (y != anio) continue;

      final du = (v.distribuidoraUid ?? '').toString().trim();
      final doU = (v.distribuidoraOrigenUid ?? '').toString().trim();
      if (du.isEmpty && doU.isEmpty) continue;

      for (final uid in [du, doU]) {
        if (uid.isEmpty) continue;
        final root = _rootFromUid(uid, distribuidores);
        if (root == null) continue;
        rootsTotales.update(root, (c) => c + 1, ifAbsent: () => 1);
      }
    }
    if (rootsTotales.isEmpty) return (rank: null, total: 0);

    final entries = rootsTotales.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    int? rankSeleccionado;
    int lastValue = -1;
    int lastRank = 0;
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final currentRank = (e.value == lastValue) ? lastRank : (i + 1);
      if (e.key == rootUidSeleccionada) {
        rankSeleccionado = currentRank;
        break;
      }
      lastValue = e.value;
      lastRank = currentRank;
    }
    return (rank: rankSeleccionado, total: entries.length);
  }

  /// Ranking de la concentradora seleccionada **dentro de su grupo automotriz**.
  static ({int? rank, int total}) rankingAnualRootEnGrupo({
    required List ventas,
    required List distribuidores,
    required int anio,
    required String? rootUidSeleccionada,
  }) {
    if (rootUidSeleccionada == null || rootUidSeleccionada.isEmpty) {
      return (rank: null, total: 0);
    }

    // 1) Determinar el conjunto de roots del mismo grupo
    final rootsGrupo = concentradorasDelMismoGrupo(
      concentradoraUid: rootUidSeleccionada,
      distribuidores: distribuidores,
    );
    if (rootsGrupo.isEmpty) return (rank: null, total: 0);

    // 2) Contabilizar ventas por root **solo** dentro del grupo
    final totalesPorRoot = <String, int>{};
    for (final v in ventas) {
      if (v.deleted == true) continue;
      final y = v.anioVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().year;
      if (y != anio) continue;

      final du = (v.distribuidoraUid ?? '').toString().trim();
      final doU = (v.distribuidoraOrigenUid ?? '').toString().trim();
      for (final uid in [du, doU]) {
        if (uid.isEmpty) continue;
        final root = _rootFromUid(uid, distribuidores);
        if (root == null) continue;
        if (!rootsGrupo.contains(root)) continue;

        totalesPorRoot.update(root, (c) => c + 1, ifAbsent: () => 1);
      }
    }
    if (totalesPorRoot.isEmpty) return (rank: null, total: 0);

    // 3) Ordenar por total y calcular rank con empates
    final entries = totalesPorRoot.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    int? rankSeleccionado;
    int lastValue = -1;
    int lastRank = 0;
    for (var i = 0; i < entries.length; i++) {
      final e = entries[i];
      final currentRank = (e.value == lastValue) ? lastRank : (i + 1);
      if (e.key == rootUidSeleccionada) {
        rankSeleccionado = currentRank;
        break;
      }
      lastValue = e.value;
      lastRank = currentRank;
    }

    return (rank: rankSeleccionado, total: entries.length);
  }

  static String? _rootFromUid(String uid, List distribuidores) {
    try {
      final d = distribuidores.firstWhere((x) => !x.deleted && x.uid == uid);
      final root = (d.concentradoraUid?.isNotEmpty == true)
          ? d.concentradoraUid
          : d.uid;
      return root;
    } catch (_) {
      return null;
    }
  }

  static MapEntry<String, String>? entryByKey(
    List<MapEntry<String, String>> items,
    String key,
  ) {
    try {
      return items.firstWhere((e) => e.key == key);
    } catch (_) {
      return null;
    }
  }

  /// Recalcula el último mes con ventas dentro del scope actual.
  /// - rootUid == null  => no hay scope (retorna fallback)
  static int recomputeSelectedMonth({
    required List ventas,
    required List distribuidores,
    required int anio,
    required String? rootUid,
    required int fallback,
  }) {
    final cluster = (rootUid == null || rootUid.isEmpty)
        ? null
        : clusterUids(rootUid: rootUid, distribuidores: distribuidores);

    final meses = <int>{};
    for (final v in ventas) {
      if (v.deleted == true) continue;
      final y = v.anioVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().year;
      if (y != anio) continue;

      if (cluster != null) {
        final du = (v.distribuidoraUid ?? '').toString().trim();
        final doU = (v.distribuidoraOrigenUid ?? '').toString().trim();
        final inScope = cluster.contains(du) || cluster.contains(doU);
        if (!inScope) continue;
      }

      final m = v.mesVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().month;
      if (m >= 1 && m <= 12) meses.add(m);
    }
    if (meses.isEmpty) return fallback;
    return meses.reduce((a, b) => a > b ? a : b);
  }

  /// Promedio “corriente” como en Asesor:
  /// desde el primer mes con ventas hasta el último con ventas (o mes actual si no hay ventas en el año actual).
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

  /// Subtítulo "Cluster X"
  static String? subtituloCluster({
    required bool esAdmin,
    required String? rootUid,
    required List distribuidores,
    required bool totalKeySeleccionado,
  }) {
    if (totalKeySeleccionado) return 'Cluster TOTAL';
    if (rootUid == null || rootUid.isEmpty) return null;
    try {
      final root = distribuidores.firstWhere(
        (d) => !d.deleted && d.uid == rootUid,
      );
      return 'Cluster ${_sinPrefijoMazda(root.nombre)}';
    } catch (_) {
      return null;
    }
  }

  /// Devuelve el nombre del Grupo para una concentradora (root).
  /// Reglas:
  /// - uuidGrupo vacío => "AFMZD" (tu default histórico)
  /// - grupo no encontrado => "—"
  static String grupoNombreParaConcentradora({
    required List distribuidores, // List<DistribuidorDb>
    required List grupos, // List<GrupoDistribuidorDb>
    required String? rootUid,
  }) {
    if (rootUid == null || rootUid.trim().isEmpty) return '—';

    // 1) Buscar la concentradora
    dynamic root;
    try {
      root = distribuidores.firstWhere((d) => !d.deleted && d.uid == rootUid);
    } catch (_) {
      root = null;
    }
    if (root == null) return '—';

    // 2) Resolver uuidGrupo
    final gid = (root.uuidGrupo ?? '').toString().trim();
    if (gid.isEmpty) return 'AFMZD';

    // 3) Buscar el grupo por uid
    try {
      final g = grupos.firstWhere((gg) => !gg.deleted && gg.uid == gid);
      final nombre = (g.nombre ?? '').toString().trim();
      return nombre.isEmpty ? '—' : nombre;
    } catch (_) {
      return '—';
    }
  }

  /// Pies globales: cada porción es una CONCENTRADORA (root) **activa** en todo el universo.
  static _PiesData piesConcentradorasGlobal({
    required List ventas,
    required List distribuidores,
    required int anio,
    required int selectedMonth,
    required String concentradoraSeleccionadaUid,
  }) {
    // Mapas de consulta rápida
    final porUid = {
      for (final d in distribuidores)
        if (!d.deleted) d.uid: d,
    };

    bool rootActiva(String rootUid) {
      final r = porUid[rootUid];
      if (r == null) return false;
      return (r.activo == true) && (r.deleted != true);
    }

    String? rootFrom(String uid) {
      if (uid.isEmpty) return null;
      final d = porUid[uid];
      if (d == null) return null;
      return (d.concentradoraUid?.isNotEmpty == true)
          ? d.concentradoraUid
          : d.uid;
    }

    String nombreRoot(String uid) {
      final r = porUid[uid];
      return r == null ? uid : _sinPrefijoMazda(r.nombre);
    }

    final anual = <String, int>{};
    final mensual = <String, int>{};

    for (final v in ventas) {
      if (v.deleted == true) continue;
      final y = v.anioVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().year;
      if (y != anio) continue;

      final du = (v.distribuidoraUid ?? '').toString().trim();
      final doU = (v.distribuidoraOrigenUid ?? '').toString().trim();

      final root = rootFrom(du) ?? rootFrom(doU);
      if (root == null) continue;
      if (!rootActiva(root)) continue; // solo activas

      anual.update(root, (c) => c + 1, ifAbsent: () => 1);

      final m = v.mesVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().month;
      if (m == selectedMonth) {
        mensual.update(root, (c) => c + 1, ifAbsent: () => 1);
      }
    }

    final datosAnual =
        anual.entries
            .map(
              (e) => PieDatum(
                label: nombreRoot(e.key),
                value: e.value.toDouble(),
                id: e.key,
              ),
            )
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final datosMensual =
        mensual.entries
            .map(
              (e) => PieDatum(
                label: nombreRoot(e.key),
                value: e.value.toDouble(),
                id: e.key,
              ),
            )
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    final highlightId = (concentradoraSeleccionadaUid.isNotEmpty)
        ? concentradoraSeleccionadaUid
        : null;

    return _PiesData(
      datosAnual: datosAnual,
      datosMensual: datosMensual,
      highlightId: highlightId,
    );
  }

  static String? nombreRootPorUid(List distribuidores, String? uid) {
    final id = (uid ?? '').trim();
    if (id.isEmpty) return null;
    try {
      final d = distribuidores.firstWhere((x) => !x.deleted && x.uid == id);
      final nombre = _sinPrefijoMazda(d.nombre);
      return (nombre.isEmpty) ? null : nombre;
    } catch (_) {
      return null;
    }
  }

  /// Serie TOTAL del año (todas las ventas del año, sin filtrar por concentradora/cluster).
  static List<int> serieTotalPorMes({required List ventas, required int anio}) {
    final serie = List<int>.filled(12, 0);
    for (final v in ventas) {
      if (v.deleted == true) continue;
      final y = v.anioVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().year;
      if (y != anio) continue;

      final m = v.mesVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().month;
      if (m >= 1 && m <= 12) {
        serie[m - 1] += 1;
      }
    }
    return serie;
  }
}

/* =================== TIPOS AUXILIARES =================== */

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

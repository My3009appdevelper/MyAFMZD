import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/app_database.dart';

import 'package:myafmzd/database/ventas/ventas_provider.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/database/asignaciones_laborales/asignaciones_laborales_provider.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_provider.dart';
import 'package:myafmzd/session/sesion_asignacion_selectors.dart';
import 'package:myafmzd/widgets/charts/my_horizontal_ranking_bar_chart.dart';

/// ======================= HELPERS GLOBALES =======================

int _mesesCorridosEnAnio(List<VentaDb> ventas, int anio) {
  int? minMes;
  int? maxMes;

  for (final v in ventas) {
    if (v.deleted == true) continue;

    final y = v.anioVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().year;
    if (y != anio) continue;

    final m = v.mesVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().month;
    if (m < 1 || m > 12) continue;

    if (minMes == null || m < minMes) minMes = m;
    if (maxMes == null || m > maxMes) maxMes = m;
  }

  if (minMes == null || maxMes == null) {
    // Sin ventas ese año
    return 0;
  }

  return maxMes - minMes + 1;
}

/// Acumulado anual por distribuidora CONCENTRADORA.
/// Usa sólo distribuidoras activas del mapa [activosByUid].
Map<String, int> _acumuladoPorConcentradoraEnAnio({
  required List<VentaDb> ventas,
  required Map<String, DistribuidorDb> activosByUid,
  required int anio,
}) {
  String rootConcentradoraUid(DistribuidorDb d) {
    return d.concentradoraUid.isNotEmpty ? d.concentradoraUid : d.uid;
  }

  final Map<String, int> acumulado = {};

  for (final v in ventas) {
    if (v.deleted == true) continue;

    final y = v.anioVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().year;
    if (y != anio) continue;

    final origenUid = v.distribuidoraOrigenUid.trim();
    if (origenUid.isEmpty) continue;

    // Distribuidora origen debe estar activa
    final distOrigen = activosByUid[origenUid];
    if (distOrigen == null) continue;

    // Uid de la concentradora raíz (si no tiene, ella misma)
    final concentradoraUid = rootConcentradoraUid(distOrigen);

    // Aseguramos que la concentradora también esté activa
    if (!activosByUid.containsKey(concentradoraUid)) continue;

    acumulado.update(concentradoraUid, (prev) => prev + 1, ifAbsent: () => 1);
  }

  return acumulado;
}

/// Card comparativo de ventas (distribuidoras, gerentes de grupo y vendedores)
/// Pensado para:
/// - Vendedor: ver su distribuidora / cluster en contexto.
/// - Gerente: ver su cluster.
/// - Gerente de grupo: ver su grupo vs otros.
/// - Admin: ver todo el universo.
class ComparisonSalesCard extends ConsumerStatefulWidget {
  const ComparisonSalesCard({
    super.key,
    required this.rolActivo,
    this.initialYear,
    this.chartHeight = 220,
  });

  final String rolActivo;
  final int? initialYear;
  final double chartHeight;

  @override
  ConsumerState<ComparisonSalesCard> createState() =>
      _ComparisonSalesCardState();
}

class _ComparisonSalesCardState extends ConsumerState<ComparisonSalesCard>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late int _selectedYear;

  String? _selectedGerenteGrupoUidForHighlight;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear ?? DateTime.now().year;
  }

  @override
  void didUpdateWidget(covariant ComparisonSalesCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialYear != null && widget.initialYear != _selectedYear) {
      setState(() => _selectedYear = widget.initialYear!);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // ---------- Datos base ----------
    final ventas = ref.watch(ventasProvider);
    final distribuidores = ref.watch(distribuidoresProvider);
    final asignaciones = ref.watch(asignacionesLaboralesProvider);
    final colaboradores = ref.watch(colaboradoresProvider);
    final asignacionActiva = ref.watch(activeAssignmentProvider);

    // Mapa rápido de colaboradores por uid (para nombres de gerentes)
    final colaboradoresByUid = <String, ColaboradorDb>{
      for (final c in colaboradores)
        if (!c.deleted) c.uid: c,
    };

    String nombreCortoColaborador(String uid) {
      final c = colaboradoresByUid[uid];
      if (c == null) return 'Gerente sin nombre';

      final apPat = c.apellidoPaterno ?? '';

      final buffer = StringBuffer(c.nombres);
      if (apPat.isNotEmpty) buffer.write(' $apPat');

      return buffer.toString();
    }

    // ---------- Roles ----------
    final rol = widget.rolActivo.toLowerCase().trim();
    final esVendedor = rol == 'vendedor';
    final esGerenteGrupo = rol == 'gerente de grupo';
    final esGerente = rol == 'gerente' || esGerenteGrupo;
    final esAdmin = rol == 'admin';

    // ---------- KPIs muy generales ----------
    final totalDistribuidorasActivas = distribuidores
        .where((d) => !d.deleted && d.activo == true)
        .length;

    final totalGerentesGrupoActivos = asignaciones
        .where(
          (a) =>
              !a.deleted &&
              a.fechaFin == null &&
              (a.rol.toLowerCase().trim() == 'gerente de grupo'),
        )
        .map((a) => a.colaboradorUid)
        .toSet()
        .length;

    // Lista de gerentes de grupo activos (colaboradorUid únicos)
    final gerentesGrupoColabUids = <String>[];
    final gerentesVistos = <String>{};
    for (final a in asignaciones) {
      if (a.deleted) continue;
      if (a.fechaFin != null) continue;
      if (a.rol.toLowerCase().trim() != 'gerente de grupo') continue;
      if (gerentesVistos.add(a.colaboradorUid)) {
        gerentesGrupoColabUids.add(a.colaboradorUid);
      }
    }
    gerentesGrupoColabUids.sort(); // orden estable cualquiera

    final totalVendedoresConVentas = () {
      final anio = _selectedYear;
      final asigByUid = {for (final a in asignaciones) a.uid: a};
      final colabsConVentas = <String>{};

      for (final v in ventas) {
        if (v.deleted == true) continue;
        final y = v.anioVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().year;
        if (y != anio) continue;
        final asig = asigByUid[v.vendedorUid];
        if (asig == null) continue;
        if (asig.colaboradorUid.isEmpty) continue;
        colabsConVentas.add(asig.colaboradorUid);
      }
      return colabsConVentas.length;
    }();

    // ---------- KPIs específicos: ventas anuales y promedio mensual por distribuidora ----------

    // Mapa de distribuidoras activas (uid -> distribuidor), igual que en el ranking
    final activosByUid = <String, DistribuidorDb>{
      for (final d in distribuidores)
        if (!d.deleted && d.activo == true) d.uid: d,
    };

    // Acumulado anual por CONCENTRADORA (mismo que usa el ranking)
    final acumuladoPorConcentradora = _acumuladoPorConcentradoraEnAnio(
      ventas: ventas,
      activosByUid: activosByUid,
      anio: _selectedYear,
    );

    // 1) VENTAS ANUALES = TODAS LAS VENTAS DEL AÑO (sin filtrar por distribuidora)
    int totalVentasAnuales = 0;
    for (final v in ventas) {
      if (v.deleted == true) continue;
      final y = v.anioVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().year;
      if (y != _selectedYear) continue;
      totalVentasAnuales++;
    }

    // 2) PROMEDIO MENSUAL POR DISTRIBUIDORA = mismo universo que el ranking
    final int totalContratosConcentradoras = acumuladoPorConcentradora.values
        .fold<int>(0, (sum, v) => sum + v);

    final int totalDistribuidorasConVentas = acumuladoPorConcentradora.length;
    final int mesesCorridos = _mesesCorridosEnAnio(ventas, _selectedYear);

    double? promedioMensualPorDistribuidora;
    if (totalDistribuidorasConVentas > 0 && mesesCorridos > 0) {
      final promedioAnualPorDistribuidora =
          totalContratosConcentradoras / totalDistribuidorasConVentas;
      promedioMensualPorDistribuidora =
          promedioAnualPorDistribuidora / mesesCorridos;
    }

    // ---------- Títulos dinámicos ----------
    final titulo = () {
      if (esVendedor) return 'COMPARACIÓN DE VENTAS EN MI ENTORNO';
      if (esGerenteGrupo) return 'COMPARACIÓN DE VENTAS – GERENTES DE GRUPO';
      if (esGerente) return 'COMPARACIÓN DE VENTAS – DISTRIBUIDORAS Y EQUIPOS';
      if (esAdmin) return 'COMPARACIÓN GLOBAL DE VENTAS';
      return 'COMPARACIÓN DE VENTAS';
    }();

    final subtitulo = () {
      if (esVendedor) return 'Mi distribuidora y vendedores en contexto';
      if (esGerenteGrupo) return 'Distribuidoras, equipo y gerentes de grupo';
      if (esGerente) return 'Cluster de distribuidoras y sus equipos';
      if (esAdmin) return 'Visión general de distribuidoras y gerentes';
      return null;
    }();

    final yearLabel = '$_selectedYear';

    return Card(
      elevation: 1,
      color: cs.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HeaderComparison(
              titulo: titulo,
              subtitulo: subtitulo,
              yearLabel: yearLabel,
            ),

            const SizedBox(height: 8),

            _KpisComparisonRow(
              totalDistribuidoras: totalDistribuidorasActivas,
              totalGerentesGrupo: totalGerentesGrupoActivos,
              totalVendedoresConVentas: totalVendedoresConVentas,
              totalVentasAnuales: totalVentasAnuales,
              promedioMensualPorDistribuidora: promedioMensualPorDistribuidora,
            ),

            const SizedBox(height: 12),

            // ===================== SECCIÓN 1 =====================
            // Barras horizontales por distribuidora (ranking)
            _DistribuidorasRankingSection(
              height: widget.chartHeight,
              year: _selectedYear,
              rol: rol,
              esVendedor: esVendedor,
              esGerente: esGerente,
              esGerenteGrupo: esGerenteGrupo,
              esAdmin: esAdmin,
              ventas: ventas,
              distribuidores: distribuidores,
              asignaciones: asignaciones,
              asignacionActiva: asignacionActiva,
              // NUEVO: solo aplica cuando eres admin
              gerenteGrupoHighlightColabUid: esAdmin
                  ? _selectedGerenteGrupoUidForHighlight
                  : null,
              adminGerenteSelector:
                  (esAdmin && gerentesGrupoColabUids.isNotEmpty)
                  ? Card(
                      color: cs.surface,
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            if (gerentesGrupoColabUids.isEmpty) {
                              _selectedGerenteGrupoUidForHighlight = null;
                              return;
                            }
                            if (_selectedGerenteGrupoUidForHighlight == null) {
                              _selectedGerenteGrupoUidForHighlight =
                                  gerentesGrupoColabUids.first;
                            } else {
                              final currentIndex = gerentesGrupoColabUids
                                  .indexOf(
                                    _selectedGerenteGrupoUidForHighlight!,
                                  );
                              final nextIndex = currentIndex == -1
                                  ? 0
                                  : (currentIndex + 1) %
                                        gerentesGrupoColabUids.length;
                              _selectedGerenteGrupoUidForHighlight =
                                  gerentesGrupoColabUids[nextIndex];
                            }
                          });
                        },
                        icon: const Icon(Icons.swap_horiz),
                        label: Text(
                          overflow: TextOverflow.ellipsis,
                          style: tt.labelSmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                          () {
                            if (gerentesGrupoColabUids.isEmpty) {
                              return 'Sin gerentes de grupo';
                            }

                            String uidSeleccionado =
                                _selectedGerenteGrupoUidForHighlight ??
                                gerentesGrupoColabUids.first;

                            if (!gerentesGrupoColabUids.contains(
                              uidSeleccionado,
                            )) {
                              uidSeleccionado = gerentesGrupoColabUids.first;
                            }

                            final idx =
                                gerentesGrupoColabUids.indexOf(
                                  uidSeleccionado,
                                ) +
                                1;
                            final nombre = nombreCortoColaborador(
                              uidSeleccionado,
                            );

                            return '$nombre ($idx de ${gerentesGrupoColabUids.length})';
                          }(),
                        ),
                      ),
                    )
                  : null,
            ),

            const SizedBox(height: 16),

            // ===================== SECCIÓN 2 =====================
            // Pie de gerentes de grupo (Admin + Gerente de grupo)
            if (esAdmin || esGerenteGrupo)
              _GerentesGrupoPieSection(
                height: widget.chartHeight * 0.9,
                year: _selectedYear,
                esGerenteGrupo: esGerenteGrupo,
                esAdmin: esAdmin,
                ventas: ventas,
                asignaciones: asignaciones,
                colaboradores: colaboradores,
                asignacionActiva: asignacionActiva,
              ),

            // ===================== SECCIÓN 3 =====================
            // Ranking de vendedores / ventas promedio por asesor
            const SizedBox(height: 16),
            _VendedoresRankingSection(
              height: widget.chartHeight,
              year: _selectedYear,
              rol: rol,
              esVendedor: esVendedor,
              esGerente: esGerente,
              esGerenteGrupo: esGerenteGrupo,
              esAdmin: esAdmin,
              ventas: ventas,
              asignaciones: asignaciones,
              colaboradores: colaboradores,
              asignacionActiva: asignacionActiva,
            ),
          ],
        ),
      ),
    );
  }
}

// =======================================================
// ===================== SUBWIDGETS ======================
// =======================================================

class _HeaderComparison extends StatelessWidget {
  const _HeaderComparison({
    required this.titulo,
    required this.subtitulo,
    required this.yearLabel,
  });

  final String titulo;
  final String? subtitulo;
  final String yearLabel;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
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
        if (subtitulo != null && subtitulo!.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitulo!,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 4),
        Text(
          yearLabel,
          style: tt.labelMedium?.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _KpisComparisonRow extends StatelessWidget {
  const _KpisComparisonRow({
    required this.totalDistribuidoras,
    required this.totalGerentesGrupo,
    required this.totalVendedoresConVentas,
    required this.totalVentasAnuales,
    required this.promedioMensualPorDistribuidora,
  });

  final int totalDistribuidoras;
  final int totalGerentesGrupo;
  final int totalVendedoresConVentas;

  final int totalVentasAnuales;
  final double? promedioMensualPorDistribuidora;

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

    String _formatPromedioMensual() {
      final v = promedioMensualPorDistribuidora;
      if (v == null) return '—';
      if (v >= 10) return v.toStringAsFixed(0);
      return v.toStringAsFixed(1);
    }

    final promedioMensualTxt = _formatPromedioMensual();

    return Column(
      children: [
        // Fila 1: KPIs generales
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SizedBox(width: 12),
            Expanded(
              child: _tile('Gerentes de grupo', totalGerentesGrupo.toString()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _tile(
                'Asesores con ventas',
                totalVendedoresConVentas.toString(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Fila 2: Ventas anuales y promedio mensual por distribuidora
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: _tile('Ventas anuales', totalVentasAnuales.toString()),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _tile(
                'Promedio mensual por distribuidora',
                promedioMensualTxt,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Ranking de distribuidoras (barras horizontales).
/// Usa las DISTRIBUIDORAS ORIGEN para el conteo anual, agregadas en CONCENTRADORA.
class _DistribuidorasRankingSection extends StatelessWidget {
  const _DistribuidorasRankingSection({
    required this.height,
    required this.year,
    required this.rol,
    required this.esVendedor,
    required this.esGerente,
    required this.esGerenteGrupo,
    required this.esAdmin,
    required this.ventas,
    required this.distribuidores,
    required this.asignaciones,
    required this.asignacionActiva,
    required this.gerenteGrupoHighlightColabUid,
    this.adminGerenteSelector,
  });

  final double height;
  final int year;
  final String rol;
  final bool esVendedor;
  final bool esGerente;
  final bool esGerenteGrupo;
  final bool esAdmin;

  final List<VentaDb> ventas;
  final List<DistribuidorDb> distribuidores;
  final List<AsignacionLaboralDb> asignaciones;
  final dynamic asignacionActiva;
  final String? gerenteGrupoHighlightColabUid;
  final Widget? adminGerenteSelector;

  String _sinPrefijoMazda(String s) {
    if (s.isEmpty) return s;
    // Primero intenta quitar "Mazda Zapata"
    var reg = RegExp(r'^\s*mazda\s+zapata\b[\s\-–—:]*', caseSensitive: false);
    var out = s.replaceFirst(reg, '');

    // Si no cambió, intenta quitar solo "Mazda"
    if (out == s) {
      reg = RegExp(r'^\s*mazda\b[\s\-–—:]*', caseSensitive: false);
      out = s.replaceFirst(reg, '');
    }

    return out.trimLeft();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // ====================================================
    // 1) Mapa de distribuidoras activas (uid -> distribuidor)
    // ====================================================
    final activosByUid = <String, DistribuidorDb>{
      for (final d in distribuidores)
        if (!d.deleted && d.activo) d.uid: d,
    };

    // Si no hay distribuidoras activas, salimos bonito
    if (activosByUid.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ranking de distribuidoras',
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: height,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: cs.surface,
                border: Border.all(color: cs.onSurface.withOpacity(0.08)),
              ),
              alignment: Alignment.center,
              child: Text(
                'No hay distribuidoras activas para mostrar.',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    // =========================================
    // 2) Agregación anual por distribuidora CONCENTRADORA
    // =========================================
    final anio = year;

    final Map<String, int> acumuladoPorConcentradora =
        _acumuladoPorConcentradoraEnAnio(
          ventas: ventas,
          activosByUid: activosByUid,
          anio: anio,
        );

    if (acumuladoPorConcentradora.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Ranking de distribuidoras',
            style: tt.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: height,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: cs.surface,
                border: Border.all(color: cs.onSurface.withOpacity(0.08)),
              ),
              alignment: Alignment.center,
              child: Text(
                'Sin ventas registradas en $anio por distribuidora concentradora.',
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    // =====================================
    // 3) Distribuidoras a resaltar (highlight) por CONCENTRADORA
    // =====================================
    final highlightConcentradoraUids = <String>{};

    String rootConcentradoraUid(DistribuidorDb d) {
      return d.concentradoraUid.isNotEmpty ? d.concentradoraUid : d.uid;
    }

    // Caso 1: ADMIN → se usa el gerente seleccionado con el botón
    if (esAdmin && gerenteGrupoHighlightColabUid != null) {
      final asignacionesGerente = asignaciones.where(
        (a) =>
            !a.deleted &&
            a.fechaFin == null &&
            a.rol.toLowerCase().trim() == 'gerente de grupo' &&
            a.colaboradorUid == gerenteGrupoHighlightColabUid &&
            a.distribuidorUid.trim().isNotEmpty,
      );

      for (final a in asignacionesGerente) {
        final dist = activosByUid[a.distribuidorUid.trim()];
        if (dist == null) continue;

        final concUid = rootConcentradoraUid(dist);
        if (activosByUid.containsKey(concUid)) {
          highlightConcentradoraUids.add(concUid);
        }
      }
    }
    // Caso 2: GERENTE DE GRUPO → solo la distribuidora de la asignación actual
    else if (esGerenteGrupo && asignacionActiva is AsignacionLaboralDb) {
      if (asignacionActiva is AsignacionLaboralDb) {
        final asigActiva = asignacionActiva as AsignacionLaboralDb;
        final colaboradorUid = asigActiva.colaboradorUid;

        // TODAS las distribuidoras donde este colaborador tiene asignación activa
        final asignacionesDelColaborador = asignaciones.where(
          (a) =>
              !a.deleted &&
              a.fechaFin == null &&
              a.colaboradorUid == colaboradorUid &&
              a.distribuidorUid.trim().isNotEmpty,
        );

        for (final a in asignacionesDelColaborador) {
          final dist = activosByUid[a.distribuidorUid.trim()];
          if (dist == null) continue;

          final concUid = rootConcentradoraUid(dist);
          if (activosByUid.containsKey(concUid)) {
            highlightConcentradoraUids.add(concUid);
          }
        }

        // Fallback por si algo sale raro
        if (highlightConcentradoraUids.isEmpty) {
          final distActual = activosByUid[asigActiva.distribuidorUid.trim()];
          if (distActual != null) {
            final concActual = rootConcentradoraUid(distActual);
            if (activosByUid.containsKey(concActual)) {
              highlightConcentradoraUids.add(concActual);
            }
          }
        }

        debugPrint(
          '[DistribuidorasRanking] highlightConcentradoraUids: $highlightConcentradoraUids',
        );
      }
    }
    // Caso 3: otros roles (vendedor, gerente “normal”) → comportamiento anterior:
    // resaltar todas sus distribuidoras activas
    else if (asignacionActiva is AsignacionLaboralDb) {
      final asigActiva = asignacionActiva as AsignacionLaboralDb;
      final colaboradorUid = asigActiva.colaboradorUid;

      final asignacionesDelColaborador = asignaciones.where(
        (a) =>
            !a.deleted &&
            a.fechaFin == null &&
            a.colaboradorUid == colaboradorUid &&
            a.distribuidorUid.trim().isNotEmpty,
      );

      for (final a in asignacionesDelColaborador) {
        final dist = activosByUid[a.distribuidorUid.trim()];
        if (dist == null) continue;

        final concUid = rootConcentradoraUid(dist);
        if (activosByUid.containsKey(concUid)) {
          highlightConcentradoraUids.add(concUid);
        }
      }
    }

    debugPrint(
      '[DistribuidorasRanking] highlightConcentradoraUids: '
      '$highlightConcentradoraUids',
    );

    // ===========================================
    // 4) Construir items para MyHorizontalRankingBarChart
    // ===========================================
    final entriesOrdenadas = acumuladoPorConcentradora.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final items = <HorizontalRankingItem>[];

    for (var i = 0; i < entriesOrdenadas.length; i++) {
      final e = entriesOrdenadas[i];
      final uid = e.key;
      final total = e.value;

      final dist = activosByUid[uid];
      if (dist == null) continue;

      final nombreCorto = _sinPrefijoMazda(dist.nombre);
      final label = '${i + 1}. $nombreCorto';
      final isHighlighted = highlightConcentradoraUids.contains(uid);

      items.add(
        HorizontalRankingItem(
          label: label,
          value: total.toDouble(),
          isHighlighted: isHighlighted,
        ),
      );
    }

    // ---- Promedio de contratos por distribuidora (mismo que la línea) ----
    double? promedioPorDistribuidora;
    if (items.isNotEmpty) {
      final totalContratos = items.fold<double>(0, (sum, i) => sum + i.value);
      promedioPorDistribuidora = totalContratos / items.length;
    }

    // Meses "corridos" en el año seleccionado (mismo helper que arriba)
    final int mesesCorridos = _mesesCorridosEnAnio(ventas, year);

    double? promedioMensualPorDistribuidora;
    if (promedioPorDistribuidora != null && mesesCorridos > 0) {
      promedioMensualPorDistribuidora =
          promedioPorDistribuidora / mesesCorridos;
    }

    String _fmt(double v) {
      if (v >= 10) return v.toStringAsFixed(0);
      return v.toStringAsFixed(1);
    }

    final avgTxt = (promedioPorDistribuidora == null)
        ? '—'
        : _fmt(promedioPorDistribuidora);

    final avgMensualTxt = (promedioMensualPorDistribuidora == null)
        ? '—'
        : _fmt(promedioMensualPorDistribuidora);

    // =====================
    // 5) UI con scroll suave
    // =====================
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          textAlign: TextAlign.center,
          'Ranking de distribuidoras',
          style: tt.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        // 👇 Aquí insertamos el selector SOLO si viene algo desde el padre
        if (adminGerenteSelector != null) ...[
          const SizedBox(height: 4),
          Align(alignment: Alignment.centerRight, child: adminGerenteSelector!),
        ],

        const SizedBox(height: 8),
        SizedBox(
          height: height, // altura fija del card
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: cs.surface,
              border: Border.all(color: cs.onSurface.withOpacity(0.08)),
            ),
            padding: const EdgeInsets.all(8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxHeight = constraints.maxHeight;
                const double perItemHeight = 22.0;

                final double contentHeight = (items.length * perItemHeight)
                    .clamp(maxHeight, 1000.0);

                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: SizedBox(
                    height: contentHeight,
                    child: MyHorizontalRankingBarChart(
                      style: HorizontalRankingChartStyle.avgLine,
                      compact: false,
                      items: items,
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        const SizedBox(height: 8),
        // KPI de promedio anual y mensual por distribuidora
        if (promedioPorDistribuidora != null)
          Align(
            alignment: Alignment.center,
            child: Text(
              'Promedio por distribuidora:\n$avgTxt contratos ($avgMensualTxt contratos mensuales)',
              style: tt.bodySmall?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }
}

/// Pie de gerentes de grupo (participación por contratos).
/// Admin ve el universo; el gerente de grupo se ve resaltado.
class _GerentesGrupoPieSection extends StatelessWidget {
  const _GerentesGrupoPieSection({
    required this.height,
    required this.year,
    required this.esGerenteGrupo,
    required this.esAdmin,
    required this.ventas,
    required this.asignaciones,
    required this.colaboradores,
    required this.asignacionActiva,
  });

  final double height;
  final int year;
  final bool esGerenteGrupo;
  final bool esAdmin;

  final List ventas;
  final List asignaciones;
  final List colaboradores;
  final dynamic asignacionActiva;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // TODO:
    // - Agrupar ventas por gerente de grupo.
    // - Cada slice = gerente de grupo (total anual).
    // - highlight = gerente actual si esGerenteGrupo, o ninguno si esAdmin.
    // - Usar MyPieChart con style ProportionsPieChartStyle.minimalRanking.

    final titulo = esAdmin
        ? 'Participación por gerente de grupo'
        : 'Mi participación vs otros gerentes de grupo';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          titulo,
          style: tt.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: height,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: cs.surface,
              border: Border.all(color: cs.onSurface.withOpacity(0.08)),
            ),
            alignment: Alignment.center,
            child: Text(
              'Próximamente: pie chart de gerentes de grupo\n'
              '(${year.toString()})',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

/// Ranking de vendedores y métricas de eficiencia (ventas por asesor).
/// Se usará para ver competencia sana entre vendedores,
/// con highlight según el rol (propio vendedor / equipo / etc.).
class _VendedoresRankingSection extends StatelessWidget {
  const _VendedoresRankingSection({
    required this.height,
    required this.year,
    required this.rol,
    required this.esVendedor,
    required this.esGerente,
    required this.esGerenteGrupo,
    required this.esAdmin,
    required this.ventas,
    required this.asignaciones,
    required this.colaboradores,
    required this.asignacionActiva,
  });

  final double height;
  final int year;
  final String rol;
  final bool esVendedor;
  final bool esGerente;
  final bool esGerenteGrupo;
  final bool esAdmin;

  final List ventas;
  final List asignaciones;
  final List colaboradores;
  final dynamic asignacionActiva;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // TODO:
    // - Construir ranking de vendedores (total anual).
    // - Opcional: métricas de eficiencia (ventas / #asesores) por gerente.
    // - Highlight: vendedor logueado / equipo del gerente / etc.
    // - Usar barras horizontales o combinación con MyPieChart.

    final titulo = () {
      if (esVendedor) return 'Ranking de vendedores (mi posición)';
      if (esGerenteGrupo) return 'Ranking de vendedores de mi grupo';
      if (esGerente) return 'Ranking de vendedores de mi cluster';
      if (esAdmin) return 'Ranking global de vendedores';
      return 'Ranking de vendedores';
    }();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          titulo,
          style: tt.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: height,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: cs.surface,
              border: Border.all(color: cs.onSurface.withOpacity(0.08)),
            ),
            alignment: Alignment.center,
            child: Text(
              'Próximamente: ranking de vendedores y métricas de eficiencia\n'
              '(${year.toString()})',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}

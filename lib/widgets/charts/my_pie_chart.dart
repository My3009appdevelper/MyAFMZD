import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

/// Dato de entrada para el pie
class PieDatum {
  const PieDatum({
    required this.label,
    required this.value,
    this.color,
    this.id, // opcional: útil para identificar al asesor/distribuidora
  });

  final String label;
  final double value;
  final Color? color;
  final String? id;
}

/// Estilos disponibles
enum ProportionsPieChartStyle {
  labelsOutside, // títulos empujados hacia el borde (porcentaje y label)
  minimal, // sin labels sobre el pastel; info al tocar (badge)
  minimalRanking, // muestra #ranking; info al tocar (badge)
}

class MyPieChart extends StatefulWidget {
  const MyPieChart({
    super.key,
    required this.data,
    this.compact = false,
    this.style = ProportionsPieChartStyle.labelsOutside,
    this.minLabelPercent = 0.06,
    this.rotateStartAtTop = true,

    /// Resalta un id (o ninguno)
    this.highlightId,
    this.highlightColor,
    this.dimOthersOpacity = 0.45,

    // Tamaño responsivo
    this.widthFraction = 0.9, // % del ancho disponible
    this.minDiameter = 140.0, // piso
    this.maxDiameter, // techo (null = sin techo)
  });

  /// Lista de datos (label + valor [+ color opcional])
  final List<PieDatum> data;

  /// Estilo visual
  final ProportionsPieChartStyle style;

  /// Layout compacto (reduce radios y paddings)
  final bool compact;

  /// Umbral mínimo para *label + %* (solo aplica a labelsOutside)
  final double minLabelPercent;

  /// Coloca el inicio del gráfico en -90° si true (arriba)
  final bool rotateStartAtTop;

  /// Highlight
  final String? highlightId;
  final Color? highlightColor;
  final double dimOthersOpacity;

  /// Tamaño responsivo
  final double widthFraction;
  final double minDiameter;
  final double? maxDiameter;

  @override
  State<MyPieChart> createState() => _MyPieChartState();
}

class _MyPieChartState extends State<MyPieChart> {
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Filtra valores no positivos
    final filtered = widget.data.where((d) => d.value > 0).toList();
    final total = filtered.fold<double>(0, (acc, d) => acc + d.value);
    if (filtered.isEmpty || total <= 0) return const _EmptyState();

    // Ordenar de mayor → menor
    filtered.sort((a, b) => b.value.compareTo(a.value));

    // Ranking tras ordenar
    final ranks = <String?, int>{};
    for (var i = 0; i < filtered.length; i++) {
      ranks[filtered[i].id] = i + 1; // 1-based
    }

    // Paleta
    final palette = _buildPalette(cs);

    return LayoutBuilder(
      builder: (context, constraints) {
        // diámetro responsivo
        final availableW = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final target = availableW * widget.widthFraction;
        final diameter = target.clamp(
          widget.minDiameter,
          (widget.maxDiameter ?? double.infinity),
        );

        // radios base / espacio entre secciones
        final baseRadius = (widget.compact ? 0.43 : 0.5) * diameter;
        const sectionsSpace = 2.0;

        // Construye secciones
        final sections = List<PieChartSectionData>.generate(filtered.length, (
          i,
        ) {
          final d = filtered[i];
          final pct = d.value / total;
          final pctStr = _fmtPct(pct);
          final isSmall = pct < widget.minLabelPercent;

          final baseColor = d.color ?? palette[i % palette.length];
          final isHighlighted =
              (widget.highlightId != null && widget.highlightId == d.id);

          // Color con highlight / dim
          final sliceColor = isHighlighted
              ? (widget.highlightColor ?? cs.primary).withOpacity(0.95)
              : baseColor.withOpacity(widget.dimOthersOpacity);

          // ---- TÍTULO SEGÚN ESTILO ----
          final rank = ranks[d.id] ?? (i + 1);
          String title;
          double titleOffset;
          TextStyle? titleStyle;

          switch (widget.style) {
            case ProportionsPieChartStyle.labelsOutside:
              title = isSmall ? pctStr : '${d.label} • $pctStr';
              titleOffset = diameter < 200 ? 0.90 : 0.96;
              titleStyle = tt.labelSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurface,
              );
              break;

            case ProportionsPieChartStyle.minimal:
              // 👇 Sólo el resaltado muestra título SIEMPRE (con ranking); los demás sin texto fijo.
              if (isHighlighted) {
                title = '#$rank • ${d.label} • ${d.value.toInt()} \n $pctStr';
              } else {
                title = '';
              }
              titleOffset = 0.75; // un poco más adentro para legibilidad
              titleStyle = tt.labelSmall?.copyWith(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.primary.withOpacity(0.85),
                fontWeight: FontWeight.w800,
                // para que contraste bien sobre el slice resaltado (primary)
                color: Theme.of(context).colorScheme.onPrimary,
              );
              break;

            case ProportionsPieChartStyle.minimalRanking:
              // 👇 Todos muestran #ranking como antes, pero el resaltado añade el nombre.
              title = isHighlighted ? '#$rank · ${d.label}' : '#$rank';
              titleOffset = 0.75;
              titleStyle = tt.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onPrimary,
              );
              break;
          }

          // ---- Badge (solo cuando está tocado en estilos minimal/minimalRanking) ----
          Widget? badge;
          double badgeOffset = 1.15;
          if (_touchedIndex == i &&
              (widget.style == ProportionsPieChartStyle.minimal ||
                  widget.style == ProportionsPieChartStyle.minimalRanking)) {
            final rank = ranks[d.id] ?? (i + 1);
            final badgeText =
                (widget.style == ProportionsPieChartStyle.minimalRanking)
                ? '#$rank ${d.label}\n$pctStr • ${d.value.toInt()}'
                : '${d.label}\n$pctStr • ${d.value.toInt()}';

            badge = Material(
              elevation: 4,
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: cs.surface.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: cs.onInverseSurface.withOpacity(0.08),
                  ),
                ),
                child: Text(
                  badgeText,
                  textAlign: TextAlign.center,
                  style: tt.labelSmall?.copyWith(
                    color: cs.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            );
            // en tamaños pequeños, acercamos un poco el badge
            if (diameter < 200) badgeOffset = 1.05;
          }

          return PieChartSectionData(
            value: d.value,
            title: title,
            titleStyle: titleStyle,
            titlePositionPercentageOffset: titleOffset,
            color: sliceColor,
            radius: baseRadius,
            borderSide: BorderSide(
              color: cs.onSurface.withOpacity(0.05),
              width: 1,
            ),
            badgeWidget: badge,
            badgePositionPercentageOffset: badgeOffset,
          );
        });

        return Padding(
          padding: const EdgeInsets.all(4),
          child: Center(
            child: SizedBox(
              width: diameter,
              height: diameter,
              child: PieChart(
                PieChartData(
                  startDegreeOffset: widget.rotateStartAtTop ? -90 : 0,
                  sectionsSpace: sectionsSpace,
                  centerSpaceRadius: 0,
                  sections: sections,
                  pieTouchData: PieTouchData(
                    enabled: true,
                    touchCallback: (event, response) {
                      final idx = response?.touchedSection?.touchedSectionIndex;
                      // Cuando suelta o sale, limpiamos selección
                      if (!event.isInterestedForInteractions || idx == null) {
                        setState(() => _touchedIndex = null);
                      } else {
                        setState(() => _touchedIndex = idx);
                      }
                    },
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // === Helpers ===

  List<Color> _buildPalette(ColorScheme cs) {
    // Paleta neutra + vivos del theme (rota bien con cualquier Material 3)
    return [cs.secondary].map((c) => c.withOpacity(0.95)).toList();
  }

  String _fmtPct(double p) {
    final v = (p * 100);
    if (v >= 99.5) return '100%';
    if (v < 1) return '${v.toStringAsFixed(1)}%';
    return '${v.round()}%';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Container(
      height: 140,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: cs.surface,
        border: Border.all(color: cs.onSurface.withOpacity(0.12)),
      ),
      alignment: Alignment.center,
      child: Text(
        'Sin datos',
        style: tt.bodyMedium?.copyWith(color: cs.onSurface.withOpacity(0.65)),
      ),
    );
  }
}

// lib/widgets/my_timeline_line_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

enum TimelineLineChartStyle {
  solid,
  minimal,
  pillGradient,
  goalLine, // línea de meta (etiqueta en el área superior del chart)
  avgLine, // línea de promedio (etiqueta en el área superior del chart)
  labelsTop, // etiquetas siempre visibles encima de cada punto
}

class MyTimelineLineChart extends StatelessWidget {
  const MyTimelineLineChart({
    super.key,
    required this.serie,
    required this.year,
    this.compact = false,
    this.highlightCurrentMonth = true,
    this.style = TimelineLineChartStyle.solid,
    this.monthlyGoal,
  }) : assert(serie.length == 12, 'serie debe tener 12 valores');

  final List<int> serie;
  final int year;
  final bool compact;
  final bool highlightCurrentMonth;
  final TimelineLineChartStyle style;

  /// Meta mensual (objetivo). Se usa para goalLine.
  final double? monthlyGoal;

  @override
  Widget build(BuildContext context) {
    return _buildChart(context);
  }

  // ---------- Core chart ----------
  Widget _buildChart(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final maxVal = (serie.isEmpty ? 0 : serie.reduce((a, b) => a > b ? a : b));
    final baseMaxY = (maxVal == 0) ? 1.0 : (maxVal + 1).toDouble();

    if (maxVal == 0) return _EmptyState(year: year);

    // headroom para labelsTop (que no se corten las etiquetas arriba)
    final headroom = style == TimelineLineChartStyle.labelsTop
        ? _labelsTopHeadroom(baseMaxY)
        : 0.0;
    final maxY = baseMaxY + headroom;

    final now = DateTime.now();
    final currentMonthIdx = now.year == year ? (now.month - 1) : -1;

    // Spots (0..11)
    final spots = List<FlSpot>.generate(
      12,
      (i) => FlSpot(i.toDouble(), serie[i].toDouble()),
    );

    // Estética compartida con barras:
    // minimal, goalLine y avgLine → sin grid ni borde.
    final isMinimalLike =
        style == TimelineLineChartStyle.minimal ||
        style == TimelineLineChartStyle.goalLine ||
        style == TimelineLineChartStyle.avgLine;

    final showGrid = !isMinimalLike;
    final showBorder = !isMinimalLike;
    final showLeftAxis = true;

    // Líneas extra (meta/promedio)
    final extraLines = <HorizontalLine>[];
    if (style == TimelineLineChartStyle.goalLine && monthlyGoal != null) {
      extraLines.add(
        HorizontalLine(
          y: monthlyGoal!.clamp(0, maxY),
          color: colors.tertiary.withOpacity(0.95),
          strokeWidth: 1.8,
          dashArray: const [6, 6],
        ),
      );
    }
    double? avgForLabel;
    if (style == TimelineLineChartStyle.avgLine) {
      final avg = _computeTrailingMonthlyAverage(serie, year, now);
      if (avg != null) {
        avgForLabel = avg;
        extraLines.add(
          HorizontalLine(
            y: avg.clamp(0, maxY),
            color: colors.secondary.withOpacity(0.95),
            strokeWidth: 1.8,
            dashArray: const [4, 6],
          ),
        );
      }
    }

    // Etiqueta superior (dentro del área del chart) usando axisNameWidget
    Widget? topAxisName;
    if (style == TimelineLineChartStyle.goalLine && monthlyGoal != null) {
      topAxisName = Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 8, top: 2),
          child: Text(
            'Meta ${monthlyGoal!.toStringAsFixed(0)}',
            style: text.labelSmall?.copyWith(color: colors.tertiary),
          ),
        ),
      );
    } else if (style == TimelineLineChartStyle.avgLine && avgForLabel != null) {
      topAxisName = Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 8, top: 2),
          child: Text(
            'Promedio ${avgForLabel.toStringAsFixed(1)}',
            style: text.labelSmall?.copyWith(color: colors.secondary),
          ),
        ),
      );
    }

    final aspectRatio = switch (style) {
      TimelineLineChartStyle.minimal => compact ? 1.8 : 2.0,
      _ => compact ? 1.6 : 1.8,
    };

    // ===== Line bars builder según estilo =====
    final lineBarsData = <LineChartBarData>[
      _buildLineData(
        context: context,
        spots: spots,
        currentMonthIdx: currentMonthIdx,
      ),
    ];

    // ===== Touch / Tooltips =====
    // labelsTop: etiquetas fijas en cada punto válido + hover/tap
    final lineTouchData = (style == TimelineLineChartStyle.labelsTop)
        ? LineTouchData(
            enabled: true,
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              tooltipPadding: EdgeInsets.zero,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((ts) {
                  final v = ts.y.toInt();
                  if (v == 0) return null; // oculta “0”
                  return LineTooltipItem(
                    '$v',
                    (text.labelSmall ??
                            const TextStyle(fontSize: 12, height: 1.0))
                        .copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  );
                }).toList();
              },
            ),
          )
        : LineTouchData(
            enabled: true,
            handleBuiltInTouches: true,
            touchTooltipData: LineTouchTooltipData(
              fitInsideHorizontally: true,
              fitInsideVertically: true,
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((ts) {
                  final i = ts.x.toInt();
                  final month = _mesLargo(i);
                  final v = ts.y.toInt();
                  return LineTooltipItem(
                    '$month $year\n',
                    TextStyle(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onInverseSurface,
                    ),
                    children: [
                      TextSpan(
                        text: '$v venta${v == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onInverseSurface,
                        ),
                      ),
                    ],
                  );
                }).toList();
              },
            ),
          );

    // ===== Titles / Grid / Border =====
    final horizontalStep = _niceStep(maxY);

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Padding(
        padding: EdgeInsets.all(
          style == TimelineLineChartStyle.minimal ? 4 : 8,
        ),
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: 11,
            minY: 0,
            maxY: maxY,
            lineBarsData: lineBarsData,
            gridData: FlGridData(
              show: showGrid,
              drawVerticalLine: false,
              horizontalInterval: horizontalStep,
              getDrawingHorizontalLine: (value) => FlLine(
                color: colors.onSurface.withOpacity(0.08),
                strokeWidth: 0.6,
              ),
            ),
            borderData: FlBorderData(
              show: showBorder,
              border: Border.all(color: colors.onSurface.withOpacity(0.12)),
            ),
            titlesData: FlTitlesData(
              topTitles: AxisTitles(
                axisNameSize: topAxisName != null ? 22 : 0,
                axisNameWidget: topAxisName,
                sideTitles: const SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: showLeftAxis,
                  reservedSize: 36,
                  interval: horizontalStep,
                  getTitlesWidget: (value, meta) {
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        value.toInt().toString(),
                        style: text.bodySmall?.copyWith(
                          color: colors.onSurface.withOpacity(0.65),
                        ),
                      ),
                    );
                  },
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: compact ? 22 : 28,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i > 11) return const SizedBox.shrink();
                    return SideTitleWidget(
                      meta: meta,
                      child: Text(
                        _mesCorto(i),
                        style: text.bodySmall?.copyWith(
                          color: colors.onSurface.withOpacity(0.65),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            extraLinesData: ExtraLinesData(horizontalLines: extraLines),
            lineTouchData: lineTouchData,
            clipData: const FlClipData.all(),
          ),
        ),
      ),
    );
  }

  // ---------- Line builder por estilo ----------
  LineChartBarData _buildLineData({
    required BuildContext context,
    required List<FlSpot> spots,
    required int currentMonthIdx,
  }) {
    final colors = Theme.of(context).colorScheme;

    // Color/estética base por estilo
    late final List<Color> strokeColors;
    late final double strokeWidth;
    late final bool isCurved;
    late final bool showAreaFill;
    late final bool showGradientStroke;

    switch (style) {
      case TimelineLineChartStyle.minimal:
      case TimelineLineChartStyle.goalLine:
      case TimelineLineChartStyle.avgLine:
        strokeColors = [colors.onSurface.withOpacity(0.65)];
        strokeWidth = 1.6;
        isCurved = true;
        showAreaFill = false;
        showGradientStroke = false;
        break;

      case TimelineLineChartStyle.solid:
        strokeColors = [colors.secondary];
        strokeWidth = 2.2;
        isCurved = true;
        showAreaFill = true; // sutil, para emular el “fondo” del sólido
        showGradientStroke = false;
        break;

      case TimelineLineChartStyle.pillGradient:
        strokeColors = [colors.secondaryContainer, colors.secondary];
        strokeWidth = 2.2;
        isCurved = true;
        showAreaFill = true;
        showGradientStroke = true;
        break;

      case TimelineLineChartStyle.labelsTop:
        strokeColors = [colors.secondary];
        strokeWidth = 2.0;
        isCurved = true;
        showAreaFill = false;
        showGradientStroke = false;
        break;
    }

    // Dots: resalta el mes actual si aplica
    final dotRadius = style == TimelineLineChartStyle.minimal ? 2.6 : 3.2;

    final dotData = FlDotData(
      show: true,
      getDotPainter: (spot, percent, bar, index) {
        final isCurrent =
            highlightCurrentMonth &&
            index == currentMonthIdx &&
            currentMonthIdx >= 0;
        final color = isCurrent ? colors.primary : strokeColors.first;
        return FlDotCirclePainter(
          radius: dotRadius,
          color: color,
          strokeWidth: 0,
        );
      },
    );

    // Áreas (relleno bajo la línea)
    final belowBarData = showAreaFill
        ? BarAreaData(
            show: true,
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                (showGradientStroke
                        ? strokeColors.first
                        : colors.surfaceVariant)
                    .withOpacity(0.18),
                colors.surface.withOpacity(0.0),
              ],
            ),
          )
        : BarAreaData(show: false);

    // Indicadores siempre visibles (labelsTop)
    final showingIndicatorIndexes = (style == TimelineLineChartStyle.labelsTop)
        ? List<int>.generate(spots.length, (i) => i).where((i) {
            // oculta meses futuros si el año es el actual y oculta “0”
            final isFuture = currentMonthIdx >= 0 ? i > currentMonthIdx : false;
            if (isFuture) return false;
            return spots[i].y > 0;
          }).toList()
        : <int>[];

    return LineChartBarData(
      spots: spots,
      isCurved: isCurved,
      barWidth: strokeWidth,
      color: showGradientStroke ? null : strokeColors.first,
      gradient: showGradientStroke
          ? LinearGradient(
              colors: strokeColors.map((c) => c.withOpacity(0.95)).toList(),
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            )
          : null,
      dotData: dotData,
      belowBarData: belowBarData,
      aboveBarData: BarAreaData(show: false),
      isStrokeCapRound: true,
      showingIndicators: showingIndicatorIndexes,
    );
  }

  // promedio “corriente”
  double? _computeTrailingMonthlyAverage(
    List<int> serie,
    int year,
    DateTime now,
  ) {
    final cutoffExclusive = (year == now.year)
        ? (now.month - 1).clamp(0, 12)
        : 12;
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

  static String _mesCorto(int idx) {
    const m = ['E', 'F', 'M', 'A', 'M', 'J', 'J', 'A', 'S', 'O', 'N', 'D'];
    return m[idx];
  }

  static String _mesLargo(int x) {
    const m = [
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
    return m[x.clamp(0, 11)];
  }

  double _niceStep(double maxY) {
    if (maxY <= 5) return 1;
    if (maxY <= 10) return 2;
    if (maxY <= 20) return 5;
    if (maxY <= 50) return 10;
    return 20;
  }

  double _labelsTopHeadroom(double currentMaxY) {
    final step = _niceStep(currentMaxY);
    return step.toDouble(); // un intervalo de la grilla como aire superior
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.year});
  final int year;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      height: 160,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colors.surface,
        border: Border.all(color: colors.onSurface.withOpacity(0.12)),
      ),
      alignment: Alignment.center,
      child: Text(
        'Sin ventas registradas en $year',
        style: text.bodyMedium?.copyWith(
          color: colors.onSurface.withOpacity(0.65),
        ),
      ),
    );
  }
}

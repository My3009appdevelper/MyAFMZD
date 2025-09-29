// lib/widgets/my_timeline_chart.dart
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

enum TimelineBarChartStyle {
  solid,
  minimal,
  pillGradient,
  goalLine, // línea de meta (etiqueta en el área superior del chart)
  avgLine, // línea de promedio (etiqueta en el área superior del chart)
  labelsTop, // etiquetas siempre visibles encima de cada barra
}

class MyTimelineBarChart extends StatelessWidget {
  const MyTimelineBarChart({
    super.key,
    required this.serie,
    required this.year,
    this.compact = false,
    this.highlightCurrentMonth = true,
    this.style = TimelineBarChartStyle.solid,
    this.monthlyGoal,
  }) : assert(serie.length == 12, 'serie debe tener 12 valores');

  final List<int> serie;
  final int year;
  final bool compact;
  final bool highlightCurrentMonth;
  final TimelineBarChartStyle style;

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

    // headroom para labelsTop (barra queda un poco más corta y cabe el texto)
    final headroom = style == TimelineBarChartStyle.labelsTop
        ? _labelsTopHeadroom(baseMaxY)
        : 0.0;
    final maxY = baseMaxY + headroom;

    final now = DateTime.now();
    final currentMonthIdx = now.year == year ? (now.month - 1) : -1;

    final bars = _buildBars(
      context: context,
      maxY: maxY,
      currentMonthIdx: currentMonthIdx,
    );

    final horizontalStep = _niceStep(maxY);

    // ✅ minimal, goalLine y avgLine comparten estética: sin grid ni borde
    final isMinimalLike =
        style == TimelineBarChartStyle.minimal ||
        style == TimelineBarChartStyle.goalLine ||
        style == TimelineBarChartStyle.avgLine;

    final showGrid = !isMinimalLike;
    final showBorder = !isMinimalLike;
    final showLeftAxis = true;

    // Líneas extra (meta / promedio) – sin labels en la línea
    final extraLines = <HorizontalLine>[];
    if (style == TimelineBarChartStyle.goalLine && monthlyGoal != null) {
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
    if (style == TimelineBarChartStyle.avgLine) {
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
    if (style == TimelineBarChartStyle.goalLine && monthlyGoal != null) {
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
    } else if (style == TimelineBarChartStyle.avgLine && avgForLabel != null) {
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
      TimelineBarChartStyle.minimal => compact ? 1.8 : 2.0,
      _ => compact ? 1.6 : 1.8,
    };

    // labelsTop: hover/tap habilitado + etiquetas fijas
    final barTouchData = (style == TimelineBarChartStyle.labelsTop)
        ? BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.transparent,
              tooltipPadding: EdgeInsets.zero,
              tooltipMargin: 6,
              fitInsideVertically: true,
              fitInsideHorizontally: true,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                if (rod.toY.round() == 0) return null; // no muestres “0”
                return BarTooltipItem(
                  rod.toY.round().toString(),
                  (text.labelSmall ?? const TextStyle(fontSize: 12, height: 1))
                      .copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                );
              },
            ),
          )
        : BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final month = _mesLargo(group.x);
                final v = rod.toY.toInt();
                return BarTooltipItem(
                  '$month $year\n',
                  TextStyle(
                    fontWeight: FontWeight.w600,
                    color: colors.onInverseSurface,
                  ),
                  children: [
                    TextSpan(
                      text: '$v venta${v == 1 ? '' : 's'}',
                      style: TextStyle(color: colors.onInverseSurface),
                    ),
                  ],
                );
              },
            ),
          );

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Padding(
        padding: EdgeInsets.all(style == TimelineBarChartStyle.minimal ? 4 : 8),
        child: BarChart(
          BarChartData(
            minY: 0,
            maxY: maxY,
            barGroups: bars,
            gridData: FlGridData(
              show: showGrid,
              drawVerticalLine: false,
              horizontalInterval: horizontalStep,
              // 🎨 Grid sutil usando tu theme
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
            barTouchData: barTouchData,
            extraLinesData: ExtraLinesData(horizontalLines: extraLines),
          ),
        ),
      ),
    );
  }

  // ---------- Builders por estilo ----------
  List<BarChartGroupData> _buildBars({
    required BuildContext context,
    required double maxY,
    required int currentMonthIdx,
  }) {
    switch (style) {
      case TimelineBarChartStyle.minimal:
        return _buildBarsMinimal(context, maxY, currentMonthIdx);
      case TimelineBarChartStyle.pillGradient:
        return _buildBarsPillGradient(context, maxY, currentMonthIdx);

      // ✅ goalLine y avgLine ahora usan el mismo builder que minimal
      case TimelineBarChartStyle.goalLine:
      case TimelineBarChartStyle.avgLine:
      case TimelineBarChartStyle.labelsTop:
        return _buildBarsMinimal(context, maxY, currentMonthIdx);

      case TimelineBarChartStyle.solid:
        return _buildBarsSolid(
          context,
          maxY,
          currentMonthIdx,
          useSurfaceBg: true,
        );
    }
  }

  bool _shouldShowTopLabel({
    required int monthIndex,
    required int currentMonthIdx,
  }) {
    // Si el año es el actual, oculta meses futuros; también oculta los 0.
    final isFutureMonth = currentMonthIdx >= 0
        ? monthIndex > currentMonthIdx
        : false;
    if (isFutureMonth) return false;
    return serie[monthIndex] > 0;
  }

  List<BarChartGroupData> _buildBarsSolid(
    BuildContext context,
    double maxY,
    int currentMonthIdx, {
    required bool useSurfaceBg,
  }) {
    final colors = Theme.of(context).colorScheme;
    final isCompact = compact;

    return List.generate(12, (i) {
      final value = serie[i].toDouble();
      final isCurrent = highlightCurrentMonth && i == currentMonthIdx;

      return BarChartGroupData(
        x: i,
        barsSpace: 0,
        barRods: [
          BarChartRodData(
            toY: value,
            width: isCompact ? 12 : 16,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            color: isCurrent ? colors.primary : colors.secondary,
            backDrawRodData: useSurfaceBg
                ? BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: colors.onSurface.withOpacity(0.06),
                  )
                : BackgroundBarChartRodData(show: false),
          ),
        ],
        showingTooltipIndicators:
            style == TimelineBarChartStyle.labelsTop &&
                _shouldShowTopLabel(
                  monthIndex: i,
                  currentMonthIdx: currentMonthIdx,
                )
            ? const [0]
            : const [],
      );
    });
  }

  List<BarChartGroupData> _buildBarsMinimal(
    BuildContext context,
    double maxY,
    int currentMonthIdx,
  ) {
    final colors = Theme.of(context).colorScheme;

    return List.generate(12, (i) {
      final value = serie[i].toDouble();
      final isCurrent = highlightCurrentMonth && i == currentMonthIdx;

      return BarChartGroupData(
        x: i,
        barsSpace: 0,
        barRods: [
          BarChartRodData(
            toY: value,
            width: compact ? 8 : 10,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            color: isCurrent
                ? colors.primary
                : colors.onSurface.withOpacity(0.65),
            backDrawRodData: BackgroundBarChartRodData(show: false),
          ),
        ],
        showingTooltipIndicators:
            style == TimelineBarChartStyle.labelsTop &&
                _shouldShowTopLabel(
                  monthIndex: i,
                  currentMonthIdx: currentMonthIdx,
                )
            ? const [0]
            : const [],
      );
    });
  }

  List<BarChartGroupData> _buildBarsPillGradient(
    BuildContext context,
    double maxY,
    int currentMonthIdx,
  ) {
    final colors = Theme.of(context).colorScheme;

    return List.generate(12, (i) {
      final value = serie[i].toDouble();
      final isCurrent = highlightCurrentMonth && i == currentMonthIdx;

      final baseA = isCurrent ? colors.primary : colors.secondaryContainer;
      final baseB = isCurrent ? colors.primaryContainer : colors.secondary;

      return BarChartGroupData(
        x: i,
        barsSpace: 0,
        barRods: [
          BarChartRodData(
            toY: value,
            width: compact ? 12 : 16,
            borderRadius: BorderRadius.circular(999),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [baseA.withOpacity(0.95), baseB.withOpacity(0.90)],
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxY,
              color: colors.onSurface.withOpacity(0.04),
            ),
          ),
        ],
        showingTooltipIndicators:
            style == TimelineBarChartStyle.labelsTop &&
                _shouldShowTopLabel(
                  monthIndex: i,
                  currentMonthIdx: currentMonthIdx,
                )
            ? const [0]
            : const [],
      );
    });
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

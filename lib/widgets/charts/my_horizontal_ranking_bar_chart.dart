import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

enum HorizontalRankingChartStyle {
  minimal,
  avgLine, // agrega línea de promedio
}

class HorizontalRankingItem {
  const HorizontalRankingItem({
    required this.label,
    required this.value,
    this.isHighlighted = false,
  });

  final String label;
  final double value;
  final bool isHighlighted;
}

class MyHorizontalRankingBarChart extends StatelessWidget {
  const MyHorizontalRankingBarChart({
    super.key,
    required this.items,
    this.style = HorizontalRankingChartStyle.minimal,
    this.compact = false,
  });

  final List<HorizontalRankingItem> items;
  final HorizontalRankingChartStyle style;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    // Si no hay datos, mostramos un estado vacío similar al tuyo
    if (items.isEmpty) {
      return _EmptyHorizontalState();
    }

    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final maxVal = items
        .map((e) => e.value)
        .fold<double>(0, (prev, v) => v > prev ? v : prev);

    // 1) Máximo "real"
    final rawMax = maxVal <= 0 ? 1.0 : maxVal;

    // 2) Escogemos un step bonito en función del máximo
    final step = _niceStep(rawMax);

    // 3) Redondeamos maxX al múltiplo superior de step (ej. 401 → 500, 397 → 400)
    final maxX = (rawMax / step).ceil() * step;

    // Promedio (para la línea vertical)
    final avg = (style == HorizontalRankingChartStyle.avgLine)
        ? (items.isEmpty
              ? null
              : items.map((e) => e.value).reduce((a, b) => a + b) /
                    items.length)
        : null;

    final extraLines = <HorizontalLine>[];
    if (avg != null) {
      extraLines.add(
        HorizontalLine(
          y: avg.clamp(0, maxX),
          color: colors.secondary.withOpacity(0.95),
          strokeWidth: 1.8,
          dashArray: const [4, 6],
        ),
      );
    }

    // Chart "normal" (barras verticales), lo rotamos luego para verlas horizontales
    final barGroups = List.generate(items.length, (index) {
      final item = items[index];
      final val = item.value;
      final isHighlighted = item.isHighlighted;

      return BarChartGroupData(
        x: index,
        barsSpace: 0,
        barRods: [
          BarChartRodData(
            toY: val,
            width: compact ? 10 : 14,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            color: isHighlighted
                ? colors.primary
                : colors.onSurface.withOpacity(0.65),
            backDrawRodData: BackgroundBarChartRodData(show: false),
          ),
        ],
      );
    });

    // Para que visualmente las barras queden horizontales, rotamos TODO el chart 90°
    return RotatedBox(
      quarterTurns: 1, // 90° clockwise
      child: Padding(
        padding: EdgeInsets.only(top: 16),
        child: BarChart(
          BarChartData(
            minY: 0,
            maxY: maxX,
            barGroups: barGroups,
            gridData: FlGridData(
              show: false, // minimal
            ),
            borderData: FlBorderData(
              show: false, // minimal
            ),
            titlesData: FlTitlesData(
              // Eje "inferior" (que al rotar se verá a la izquierda/derecha)
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: compact ? 70 : 95,
                  getTitlesWidget: (value, meta) {
                    final idx = value.toInt();
                    if (idx < 0 || idx >= items.length) {
                      return const SizedBox.shrink();
                    }
                    final label = items[idx].label;
                    return SideTitleWidget(
                      meta: meta,
                      child: RotatedBox(
                        quarterTurns:
                            -1, // para que se lea correctamente tras el giro del chart
                        child: Text(
                          label,
                          style: text.bodySmall?.copyWith(
                            color: colors.onSurface.withOpacity(0.75),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Eje "izquierdo" (que al rotar se verá abajo/arriba) -> valores numéricos
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 32,
                  interval: step,
                  getTitlesWidget: (value, meta) {
                    if (value < 0 || value > maxX) {
                      return const SizedBox.shrink();
                    }
                    return SideTitleWidget(
                      meta: meta,
                      space: 4,
                      child: RotatedBox(
                        quarterTurns: -1,
                        child: Text(
                          value.toInt().toString(),
                          style: text.bodySmall?.copyWith(
                            color: colors.onSurface.withOpacity(0.65),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
            ),
            barTouchData: BarTouchData(
              enabled: true,
              touchTooltipData: BarTouchTooltipData(
                // 👇 hace que el tooltip nunca se salga del área del chart
                fitInsideHorizontally: true,
                fitInsideVertically: true,
                getTooltipColor: (_) => colors.inverseSurface,
                tooltipPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 6,
                ),
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  final item = items[groupIndex];
                  final v = rod.toY.toInt();
                  return BarTooltipItem(
                    '${item.label}\n',
                    TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colors.onInverseSurface,
                    ),
                    children: [
                      TextSpan(
                        text: '$v venta${v == 1 ? '' : 's'}',
                        style: TextStyle(
                          color: colors.onInverseSurface,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            extraLinesData: ExtraLinesData(horizontalLines: extraLines),
          ),
        ),
      ),
    );
  }

  double _niceStep(double maxX) {
    if (maxX <= 5) return 1;
    if (maxX <= 10) return 2;
    if (maxX <= 20) return 5;
    if (maxX <= 50) return 10;
    if (maxX <= 100) return 20;
    if (maxX <= 500) return 100;
    if (maxX <= 1000) return 200;
    if (maxX <= 2000) return 500;
    if (maxX <= 5000) return 1000;
    if (maxX <= 10000) return 2000;
    return 2000;
  }
}

class _EmptyHorizontalState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colors.surface,
        border: Border.all(color: colors.onSurface.withOpacity(0.12)),
      ),
      alignment: Alignment.center,
      child: Text(
        'Sin datos para mostrar',
        style: text.bodyMedium?.copyWith(
          color: colors.onSurface.withOpacity(0.65),
        ),
      ),
    );
  }
}

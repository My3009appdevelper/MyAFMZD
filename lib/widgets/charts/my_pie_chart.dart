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

/// Único estilo activo: etiquetas empujadas hacia el borde
enum ProportionsPieChartStyle {
  labelsOutside, // títulos empujados hacia el borde
}

class MyPieChart extends StatelessWidget {
  const MyPieChart({
    super.key,
    required this.data,
    this.compact = false,
    this.style = ProportionsPieChartStyle.labelsOutside,
    this.minLabelPercent = 0.06, // porcentaje mínimo para mostrar label+%
    this.rotateStartAtTop = true,
  });

  /// Lista de datos (label + valor [+ color opcional])
  final List<PieDatum> data;

  /// Único estilo soportado (labelsOutside), conservado por simetría futura
  final ProportionsPieChartStyle style;

  /// Layout compacto (reduce radios y paddings)
  final bool compact;

  /// Umbral mínimo para mostrar *label + %*; si es menor, muestra solo el %
  final double minLabelPercent;

  /// Coloca el inicio del gráfico en -90° si true (arriba)
  final bool rotateStartAtTop;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Filtra valores no positivos
    final filtered = data.where((d) => d.value > 0).toList();
    final total = filtered.fold<double>(0, (acc, d) => acc + d.value);

    if (filtered.isEmpty || total <= 0) {
      return const _EmptyState();
    }

    // Paleta: rota por los items si no traen color
    final palette = _buildPalette(cs);

    // Radios base (usamos pie “sólido” sin hueco central)
    final baseRadius = compact ? 56.0 : 66.0;
    final sectionsSpace = 2.0;

    // Construye secciones con etiquetas empujadas hacia el borde
    final sections = List<PieChartSectionData>.generate(filtered.length, (i) {
      final d = filtered[i];
      final pct = d.value / total;
      final pctStr = _fmtPct(pct);
      final isSmall = pct < minLabelPercent;

      final baseColor = d.color ?? palette[i % palette.length];

      // Texto: si la porción es pequeña, muestra solo el porcentaje
      final title = isSmall ? pctStr : '${d.label} • $pctStr';

      return PieChartSectionData(
        value: d.value,
        title: title,
        titleStyle: Theme.of(context).textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        // Empuja el texto hacia el borde interno (lo “más afuera” posible)
        titlePositionPercentageOffset: 0.96,
        color: baseColor,
        radius: baseRadius,
        borderSide: BorderSide(color: cs.onSurface.withOpacity(0.05), width: 1),
      );
    });

    final aspect = compact ? 1.05 : 1.15;

    return Padding(
      padding: const EdgeInsets.all(4),
      child: AspectRatio(
        aspectRatio: aspect,
        child: PieChart(
          PieChartData(
            startDegreeOffset: rotateStartAtTop ? -90 : 0,
            sectionsSpace: sectionsSpace,
            centerSpaceRadius: 0, // sin hueco central
            sections: sections,
          ),
        ),
      ),
    );
  }

  // === Helpers ===

  List<Color> _buildPalette(ColorScheme cs) {
    // Paleta neutra + vivos del theme (rota bien con cualquier Material 3)
    return [
      cs.secondary,
      cs.primary,
      cs.tertiary,
      cs.secondaryContainer,
      cs.primaryContainer,
      cs.tertiaryContainer,
      cs.outline,
      cs.outlineVariant,
      cs.surfaceTint,
      cs.inversePrimary,
    ].map((c) => c.withOpacity(0.95)).toList();
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

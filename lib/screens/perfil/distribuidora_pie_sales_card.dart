import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/ventas/ventas_provider.dart';
import 'package:myafmzd/widgets/charts/my_pie_chart.dart';

class DistribuidoraPieChartsCard extends ConsumerStatefulWidget {
  const DistribuidoraPieChartsCard({
    super.key,
    required this.rolActivo,
    required this.distribuidorUid,
    this.initialYear,
  });

  final String rolActivo;
  final String? distribuidorUid; // del vendedor actual
  final int? initialYear;

  @override
  ConsumerState<DistribuidoraPieChartsCard> createState() =>
      _DistribuidoraPieChartsCardState();
}

class _DistribuidoraPieChartsCardState
    extends ConsumerState<DistribuidoraPieChartsCard> {
  late int _selectedYear;
  int _selectedMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _selectedYear = widget.initialYear ?? DateTime.now().year;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final ventas = ref.watch(ventasProvider);

    // === Ventas del año y del mes (solo dentro de la misma distribuidora) ===
    final distribUid = widget.distribuidorUid ?? '';
    if (distribUid.isEmpty) {
      return const SizedBox.shrink();
    }

    // Filtra ventas de la distribuidora actual en el año seleccionado
    final ventasAnio = ventas.where((v) {
      if (v.deleted == true) return false;
      final y = v.anioVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().year;
      if (y != _selectedYear) return false;
      final du = (v.distribuidoraUid);
      final doU = (v.distribuidoraOrigenUid);
      return du == distribUid || doU == distribUid;
    }).toList();

    // Agrupa por asesorUid
    final mapaPorVendedor = <String, int>{};
    for (final v in ventasAnio) {
      final uid = v.vendedorUid;
      if (uid.isEmpty) continue;
      mapaPorVendedor[uid] = (mapaPorVendedor[uid] ?? 0) + 1;
    }

    // === Pie anual ===
    final datosAnual = mapaPorVendedor.entries.map((e) {
      final asesor = e.key.isEmpty ? 'Sin asesor' : e.key;
      return PieDatum(label: asesor, value: e.value.toDouble());
    }).toList();

    // === Pie mensual (filtro mes dentro del mismo año) ===
    final mapaMes = <String, int>{};
    for (final v in ventasAnio) {
      final m = v.mesVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().month;
      if (m != _selectedMonth) continue;
      final uid = v.vendedorUid;
      if (uid.isEmpty) continue;
      mapaMes[uid] = (mapaMes[uid] ?? 0) + 1;
    }
    final datosMensual = mapaMes.entries.map((e) {
      final asesor = e.key.isEmpty ? 'Sin asesor' : e.key;
      return PieDatum(label: asesor, value: e.value.toDouble());
    }).toList();

    final meses = const [
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

    return Card(
      elevation: 1,
      color: cs.surface,
      margin: const EdgeInsets.only(bottom: 24),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Encabezado
            Row(
              children: [
                Icon(Icons.pie_chart_rounded, color: cs.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Aportación por asesor',
                    style: tt.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                  ),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedYear,
                    items: [
                      for (final y in {
                        DateTime.now().year,
                        DateTime.now().year - 1,
                      })
                        DropdownMenuItem(value: y, child: Text('$y')),
                    ],
                    onChanged: (v) =>
                        setState(() => _selectedYear = v ?? _selectedYear),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _selectedMonth,
                    items: List.generate(12, (i) {
                      return DropdownMenuItem(
                        value: i + 1,
                        child: Text(meses[i]),
                      );
                    }),
                    onChanged: (v) =>
                        setState(() => _selectedMonth = v ?? _selectedMonth),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Dos gráficos en una fila
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        'Total anual',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      MyPieChart(data: datosAnual, compact: true),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        meses[_selectedMonth - 1],
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      MyPieChart(data: datosMensual, compact: true),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

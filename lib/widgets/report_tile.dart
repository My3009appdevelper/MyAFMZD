import 'package:flutter/material.dart';
import 'package:myafmzd/models/reporte_pdf_model.dart';

class ReporteItemTile extends StatelessWidget {
  final ReportePdf reporte;
  final VoidCallback onTap;

  const ReporteItemTile({
    super.key,
    required this.reporte,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.picture_as_pdf),
      title: Text(reporte.nombre),
      subtitle: Text(
        '${reporte.fecha.year}-${reporte.fecha.month.toString().padLeft(2, '0')}',
      ),
      onTap: onTap,
    );
  }
}

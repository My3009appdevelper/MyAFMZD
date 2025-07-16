import 'package:flutter/material.dart';
import 'package:myafmzd/models/reporte_pdf_model.dart';
import 'package:myafmzd/screens/reportes/visor_pdf.dart';
import 'package:myafmzd/services/reporte_service.dart';
import 'package:myafmzd/widgets/report_tile.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final ReportesService _service = ReportesService();
  List<ReportePdf> _todos = [];
  List<ReportePdf> _filtrados = [];
  List<String> _mesesDisponibles = ['Todos'];
  String _mesSeleccionado = 'Todos';

  @override
  void initState() {
    super.initState();
    _cargarReportes();
  }

  void _cargarReportes() async {
    final reportes = await _service.listarReportes();
    final meses = await _service.listarFechasUnicas(reportes);
    setState(() {
      _todos = reportes;
      _filtrados = reportes;
      _mesesDisponibles = meses;
    });
  }

  void _filtrar(String mes) {
    setState(() {
      _mesSeleccionado = mes;
      if (mes == 'Todos') {
        _filtrados = _todos;
      } else {
        _filtrados = _todos.where((r) {
          final formatoMes =
              '${r.fecha.year.toString().padLeft(4, '0')}-${r.fecha.month.toString().padLeft(2, '0')}';
          return formatoMes == mes;
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_mesesDisponibles.length > 1)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              value: _mesSeleccionado,
              onChanged: (value) => _filtrar(value!),
              items: _mesesDisponibles.map((mes) {
                return DropdownMenuItem(value: mes, child: Text(mes));
              }).toList(),
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: _filtrados.length,
            itemBuilder: (context, index) {
              final reporte = _filtrados[index];
              return ReporteItemTile(
                reporte: reporte,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VisorPdfScreen(reporte: reporte),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

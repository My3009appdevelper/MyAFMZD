import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:myafmzd/models/reporte_pdf_model.dart';

class ReportesService {
  Future<List<ReportePdf>> listarReportes() async {
    final data = await rootBundle.loadString(
      'assets/reportes/reportes_index.json',
    );
    final List<dynamic> jsonList = json.decode(data);

    return jsonList.map((e) {
      return ReportePdf(
        nombre: e['nombre'],
        rutaLocal: e['ruta'],
        fecha: DateTime.parse(e['fecha']),
      );
    }).toList();
  }

  Future<List<String>> listarFechasUnicas(List<ReportePdf> reportes) async {
    final meses = reportes
        .map((r) {
          return '${r.fecha.year.toString().padLeft(4, '0')}-${r.fecha.month.toString().padLeft(2, '0')}';
        })
        .toSet()
        .toList();

    meses.sort();
    return ['Todos', ...meses];
  }
}

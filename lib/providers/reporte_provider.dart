import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/models/reporte_pdf_model.dart';
import 'package:myafmzd/services/reporte_service.dart';

final reporteProvider =
    StateNotifierProvider<ReporteNotifier, List<ReportePdf>>((ref) {
      return ReporteNotifier();
    });

class ReporteNotifier extends StateNotifier<List<ReportePdf>> {
  ReporteNotifier() : super([]);

  final _servicio = ReporteFirebaseService();

  bool _yaCargado = false;
  bool get yaCargado => _yaCargado;

  String? _mesSeleccionado;
  String? get mesSeleccionado => _mesSeleccionado;
  List<String> get mesesDisponibles => listarMesesDisponibles();

  List<ReportePdf> get filtrados =>
      filtrarPorMesYTipo(mes: _mesSeleccionado ?? '');

  bool _hayInternet = true;
  bool get hayInternet => _hayInternet;

  /// Carga todos los reportes desde Firestore o local (SharedPreferences).
  Future<void> cargar({required bool hayInternet, bool forzar = false}) async {
    _hayInternet = hayInternet;

    if (_yaCargado && !forzar) {
      print(
        '🛑 ARCHIVOS[Provider] Ya estaba cargado y no se fuerza. Cancelando lectura.',
      );
      return;
    }

    List<ReportePdf> lista = hayInternet
        ? await _servicio.listarReportesDesdeFirestore()
        : await _servicio.cargarSoloDescargados();

    // Si NO hay internet, filtra aún más para que solo muestre los que existen en disco
    if (!hayInternet) {
      lista = lista.where((r) {
        return r.rutaLocal != null && File(r.rutaLocal!).existsSync();
      }).toList();
    }

    state = lista;
    _yaCargado = true;

    if (_mesSeleccionado == null) {
      final meses = listarMesesDisponibles();
      if (meses.isNotEmpty) {
        _mesSeleccionado = meses.first;
        state = [...state];
      }
    }
  }

  void reiniciar() {
    _yaCargado = false;
    state = [];
  }

  ReportePdf? obtenerPorNombre(String nombre) {
    return state.firstWhere((r) => r.nombre == nombre);
  }

  List<ReportePdf> filtrarPorMesYTipo({required String mes, String? tipo}) {
    return state.where((r) {
      final fechaOk =
          '${r.fecha.year.toString().padLeft(4, '0')}-${r.fecha.month.toString().padLeft(2, '0')}' ==
          mes;
      final tipoOk = tipo == null || r.tipo == tipo;
      final descargadoOk =
          _hayInternet ||
          (r.rutaLocal != null && File(r.rutaLocal!).existsSync());
      return fechaOk && tipoOk && descargadoOk;
    }).toList()..sort((a, b) => b.fecha.compareTo(a.fecha));
  }

  List<String> listarMesesDisponibles() {
    final meses = state
        .map((r) {
          return '${r.fecha.year.toString().padLeft(4, '0')}-${r.fecha.month.toString().padLeft(2, '0')}';
        })
        .toSet()
        .toList();

    meses.sort((a, b) => b.compareTo(a));
    return meses;
  }

  /// Actualiza la lista en memoria tras descargar o eliminar.
  void actualizarRutaLocal(String rutaRemota, String? nuevaRutaLocal) {
    state = [
      for (final r in state)
        if (r.rutaRemota == rutaRemota)
          ReportePdf(
            nombre: r.nombre,
            fecha: r.fecha,
            rutaRemota: r.rutaRemota,
            rutaLocal: nuevaRutaLocal,
            tipo: r.tipo,
          )
        else
          r,
    ];
  }

  void seleccionarMes(String mes) {
    _mesSeleccionado = mes;
  }
}

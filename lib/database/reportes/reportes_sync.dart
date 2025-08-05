// ignore_for_file: avoid_print
import 'dart:io';

import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/reportes/reportes_dao.dart';
import 'package:myafmzd/database/reportes/reportes_service.dart';

class ReportesSync {
  final ReportesDao _dao;
  final ReportesService _service;

  ReportesSync(AppDatabase db)
    : _dao = ReportesDao(db),
      _service = ReportesService(db);

  // ---------------------------------------------------------------------------
  // 📌 PUSH: Subir cambios locales pendientes
  // ---------------------------------------------------------------------------

  Future<void> pushReportesOffline() async {
    final pendientes = await _dao.obtenerPendientesSyncDrift();
    if (pendientes.isEmpty) {
      print('[📤 REPORTES SYNC] ✅ No hay reportes pendientes');
      return;
    }

    for (final reporte in pendientes) {
      try {
        // 1️⃣ Subir PDF si hay rutaLocal válida y el archivo existe
        if (reporte.rutaLocal.isNotEmpty &&
            File(reporte.rutaLocal).existsSync()) {
          await _service.uploadPDFOnline(
            File(reporte.rutaLocal),
            reporte.rutaRemota,
          );
          print('[📤 REPORTES SYNC] PDF subido: ${reporte.rutaRemota}');
        } else {
          print(
            '[📤 REPORTES SYNC] ⚠️ PDF local no encontrado para ${reporte.uid}',
          );
        }

        // 2️⃣ Subir metadata a Supabase
        await _service.upsertReporteOnline(reporte);

        // 3️⃣ Marcar como sincronizado
        await _dao.marcarComoSincronizadoDrift([reporte.uid]);
      } catch (e) {
        print('[❌ REPORTES SYNC] Error subiendo ${reporte.uid}: $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 PULL: Descargar cambios online y aplicarlos localmente
  // ---------------------------------------------------------------------------

  Future<void> pullReportesOnline({DateTime? ultimaSync}) async {
    try {
      final lista = await _service.obtenerFiltradosOnline(
        ultimaSync: ultimaSync,
      );

      await _dao.upsertReportesDrift(lista);
      print('[REPORTES SYNC] ✅ Descargados ${lista.length} reportes');
    } catch (e) {
      print('[REPORTES SYNC] ❌ Error al descargar reportes: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 SYNC COMPLETO: Push + Pull
  // ---------------------------------------------------------------------------

  Future<void> syncReportes({DateTime? ultimaSync}) async {
    print('[REPORTES SYNC] 🔄 Iniciando sincronización de reportes...');
    await pullReportesOnline(ultimaSync: ultimaSync);
    await pushReportesOffline();

    print('[REPORTES SYNC] ✅ Sincronización de reportes finalizada');
  }
}

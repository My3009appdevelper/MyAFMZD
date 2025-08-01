// ignore_for_file: avoid_print
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
      print('[REPORTES SYNC] ✅ No hay reportes pendientes de subida');
      return;
    }

    print(
      '[REPORTES SYNC] ⬆️ Subiendo ${pendientes.length} reportes offline...',
    );

    for (final rep in pendientes) {
      try {
        await _service.upsertReporteOnline(rep);
        await _dao.marcarComoSincronizadoDrift([rep.uid]);
        print('[REPORTES SYNC] ✅ Reporte ${rep.uid} sincronizado');
      } catch (e) {
        print('[REPORTES SYNC] ❌ Error subiendo ${rep.uid}: $e');
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
    await pushReportesOffline();
    await pullReportesOnline(ultimaSync: ultimaSync);
    print('[REPORTES SYNC] ✅ Sincronización de reportes finalizada');
  }
}

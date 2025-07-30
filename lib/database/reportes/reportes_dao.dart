import 'package:drift/drift.dart';
import 'package:myafmzd/database/app_database.dart';
import 'reportes_table.dart';

part 'reportes_dao.g.dart';

@DriftAccessor(tables: [Reportes])
class ReportesDao extends DatabaseAccessor<AppDatabase>
    with _$ReportesDaoMixin {
  ReportesDao(super.db);

  // ---------------------------------------------------------------------------
  // 📌 CRUD BÁSICO
  // ---------------------------------------------------------------------------

  /// Insertar o actualizar un reporte
  Future<void> upsertReporteDrift(ReportesDb reporte) =>
      into(reportes).insertOnConflictUpdate(reporte);

  /// Insertar múltiples reportes.
  Future<void> upsertReportesDrift(List<ReportesDb> lista) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(reportes, lista);
    });
  }

  /// Soft delete: marcar reportes como eliminados.
  Future<void> marcarComoEliminadosDrift(List<String> uids) async {
    await (update(reportes)..where((r) => r.uid.isIn(uids))).write(
      ReportesCompanion(
        deleted: const Value(true),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 📌 CONSULTAS
  // ---------------------------------------------------------------------------

  /// Obtener un reporte por UID.
  Future<ReportesDb?> obtenerPorUidDrift(String uid) =>
      (select(reportes)..where((r) => r.uid.equals(uid))).getSingleOrNull();

  /// Obtener todos incluyendo eliminados (útil para sync).
  Future<List<ReportesDb>> obtenerTodosDrift() => select(reportes).get();

  /// Obtener reportes filtrados por tipo (ej: AMDA / interno).
  Future<List<ReportesDb>> obtenerPorTipoDrift(String tipo) =>
      (select(reportes)..where((r) => r.tipo.equals(tipo))).get();

  // ---------------------------------------------------------------------------
  // 📌 SINCRONIZACIÓN
  // ---------------------------------------------------------------------------

  /// Obtener reportes pendientes de sincronización.
  Future<List<ReportesDb>> obtenerPendientesSyncDrift() {
    return (select(reportes)..where((r) => r.isSynced.equals(false))).get();
  }

  /// Marcar reportes como sincronizados.
  Future<void> marcarComoSincronizadoDrift(List<String> uids) async {
    await (update(reportes)..where((r) => r.uid.isIn(uids))).write(
      ReportesCompanion(
        isSynced: const Value(true),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  /// Obtener la última fecha de actualización local para comparar con Supabase.
  Future<DateTime?> obtenerUltimaActualizacionDrift() async {
    final ultimo =
        await (select(reportes)
              ..orderBy([(r) => OrderingTerm.desc(r.updatedAt)])
              ..limit(1))
            .getSingleOrNull();
    return ultimo?.updatedAt;
  }
}

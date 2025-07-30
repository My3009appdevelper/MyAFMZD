import 'package:drift/drift.dart';
import 'package:myafmzd/database/app_database.dart';
import 'distribuidores_table.dart';

part 'distribuidores_dao.g.dart';

@DriftAccessor(tables: [Distribuidores])
class DistribuidoresDao extends DatabaseAccessor<AppDatabase>
    with _$DistribuidoresDaoMixin {
  DistribuidoresDao(super.db);

  // ---------------------------------------------------------------------------
  // 📌 CRUD BÁSICO
  // ---------------------------------------------------------------------------

  /// Insertar o reemplazar un distribuidor. actualizarDistribuidor y obtenerPorId en Distribuidor Service
  Future<void> upsertDistribuidorDrift(DistribuidorDb distribuidor) =>
      into(distribuidores).insertOnConflictUpdate(distribuidor);

  /// Insertar múltiples distribuidores.
  Future<void> upsertDistribuidoresDrift(List<DistribuidorDb> lista) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(distribuidores, lista);
    });
  }

  // Soft delete: marcar distribuidores como eliminados.
  Future<void> marcarComoEliminadosDrift(List<String> uids) async {
    await (update(distribuidores)..where((u) => u.uid.isIn(uids))).write(
      DistribuidoresCompanion(
        deleted: const Value(true),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 📌 CONSULTAS
  // ---------------------------------------------------------------------------

  /// ✅ Obtener por ID
  Future<DistribuidorDb?> obtenerPorUidDrift(String id) => (select(
    distribuidores,
  )..where((d) => d.uid.equals(id))).getSingleOrNull();

  /// ✅ Obtener todos
  Future<List<DistribuidorDb>> obtenerTodosDrift() =>
      select(distribuidores).get();

  // ---------------------------------------------------------------------------
  // 📌 SINCRONIZACIÓN
  // ---------------------------------------------------------------------------

  // Obtener distribuidores pendientes de sincronización.
  Future<List<DistribuidorDb>> obtenerPendientesSyncDrift() {
    return (select(
      distribuidores,
    )..where((u) => u.isSynced.equals(false))).get();
  }

  // Marcar distribuidores como sincronizados.
  Future<void> marcarComoSincronizadoDrift(List<String> uids) async {
    await (update(distribuidores)..where((u) => u.uid.isIn(uids))).write(
      DistribuidoresCompanion(
        isSynced: const Value(true),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  /// Obtener la última fecha de actualización de la tabla. Útil para comparar contra Supabase y decidir si hacer pull.
  Future<DateTime?> obtenerUltimaActualizacionDrift() async {
    final ultimo =
        await (select(distribuidores)
              ..orderBy([(u) => OrderingTerm.desc(u.updatedAt)])
              ..limit(1))
            .getSingleOrNull();
    return ultimo?.updatedAt;
  }
}

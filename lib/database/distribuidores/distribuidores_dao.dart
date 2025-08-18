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
  Future<void> upsertDistribuidorDrift(DistribuidoresCompanion distribuidor) =>
      into(distribuidores).insertOnConflictUpdate(distribuidor);

  /// Insertar múltiples distribuidores.
  Future<void> upsertDistribuidoresDrift(
    List<DistribuidoresCompanion> lista,
  ) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(distribuidores, lista);
    });
  }

  // Soft delete: marcar distribuidores como eliminados.
  Future<void> marcarComoEliminadosDrift(List<String> uids) async {
    await (update(distribuidores)..where((u) => u.uid.isIn(uids))).write(
      DistribuidoresCompanion(
        deleted: const Value(true),
        isSynced: const Value(false),
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

  /// Obtener NO eliminados, ordenados por nombre.
  Future<List<DistribuidorDb>> obtenerTodosNoDeletedDrift() {
    return (select(distribuidores)
          ..where((d) => d.deleted.equals(false))
          ..orderBy([
            (d) => OrderingTerm(expression: d.nombre, mode: OrderingMode.asc),
          ]))
        .get();
  }

  // ---------------------------------------------------------------------------
  // 📌 SINCRONIZACIÓN
  // ---------------------------------------------------------------------------

  // Obtener distribuidores pendientes de sincronización.
  Future<List<DistribuidorDb>> obtenerPendientesSyncDrift() {
    return (select(
      distribuidores,
    )..where((u) => u.isSynced.equals(false))).get();
  }

  /// Marcar como sincronizados
  Future<void> marcarComoSincronizadoDrift(String uid, DateTime fecha) async {
    await (update(distribuidores)..where((r) => r.uid.equals(uid))).write(
      DistribuidoresCompanion(
        isSynced: const Value(true),
        updatedAt: const Value.absent(),
      ),
    );
  }

  /// Obtener la última fecha de actualización de la tabla. Útil para comparar contra Supabase y decidir si hacer pull.
  Future<DateTime?> obtenerUltimaActualizacionDrift() async {
    final ultimo =
        await (select(distribuidores)
              ..where((r) => r.isSynced.equals(true))
              ..orderBy([
                (r) => OrderingTerm(
                  expression: r.updatedAt,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();
    return ultimo?.updatedAt;
  }
}

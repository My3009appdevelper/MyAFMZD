import 'package:drift/drift.dart';
import 'package:myafmzd/database/app_database.dart';
import 'modelos_table.dart';

part 'modelos_dao.g.dart';

@DriftAccessor(tables: [Modelos])
class ModelosDao extends DatabaseAccessor<AppDatabase> with _$ModelosDaoMixin {
  ModelosDao(super.db);

  // ---------------------------------------------------------------------------
  // 📌 CRUD BÁSICO
  // ---------------------------------------------------------------------------
  Future<void> upsertModeloDrift(ModelosCompanion m) =>
      into(modelos).insertOnConflictUpdate(m);

  Future<void> upsertModelosDrift(List<ModelosCompanion> lista) async {
    if (lista.isEmpty) return;
    await batch((b) => b.insertAllOnConflictUpdate(modelos, lista));
  }

  Future<int> actualizarParcialPorUid(String uid, ModelosCompanion cambios) {
    return (update(modelos)..where((t) => t.uid.equals(uid))).write(cambios);
  }

  Future<void> marcarComoEliminadosDrift(List<String> uids) async {
    if (uids.isEmpty) return;
    await (update(modelos)..where((t) => t.uid.isIn(uids))).write(
      ModelosCompanion(
        deleted: const Value(true),
        isSynced: const Value(false),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 📌 CONSULTAS
  // ---------------------------------------------------------------------------

  Future<List<ModeloDb>> obtenerTodosDrift() => select(modelos).get();

  Future<ModeloDb?> obtenerPorUidDrift(String uid) =>
      (select(modelos)..where((t) => t.uid.equals(uid))).getSingleOrNull();

  // ---------------------------------------------------------------------------
  // 📌 SINCRONIZACIÓN
  // ---------------------------------------------------------------------------

  Future<List<ModeloDb>> obtenerPendientesSyncDrift() =>
      (select(modelos)..where((t) => t.isSynced.equals(false))).get();

  Future<void> marcarComoSincronizadoDrift(String uid) async {
    await (update(modelos)..where((t) => t.uid.equals(uid))).write(
      const ModelosCompanion(isSynced: Value(true), updatedAt: Value.absent()),
    );
  }

  Future<DateTime?> obtenerUltimaActualizacionDrift() async {
    final row =
        await (select(modelos)
              ..where((t) => t.isSynced.equals(true))
              ..orderBy([
                (t) => OrderingTerm(
                  expression: t.updatedAt,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();
    return row?.updatedAt;
  }
}

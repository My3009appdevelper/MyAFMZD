// lib/database/sync_state/sync_state_dao.dart
import 'package:drift/drift.dart';
import 'package:myafmzd/database/app_database.dart';
import 'sync_state_table.dart';

part 'sync_state_dao.g.dart';

@DriftAccessor(tables: [SyncState])
class SyncStateDao extends DatabaseAccessor<AppDatabase>
    with _$SyncStateDaoMixin {
  SyncStateDao(super.db);

  // ────────────────────────────────────────────────────────────────────────────
  // 📌 CRUD BÁSICO (local, con Companions)
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> upsertSyncStateDrift(SyncStateCompanion row) async {
    await into(syncState).insertOnConflictUpdate(row);
  }

  Future<void> upsertSyncStatesDrift(List<SyncStateCompanion> lista) async {
    if (lista.isEmpty) return;
    await batch((b) => b.insertAllOnConflictUpdate(syncState, lista));
  }

  /// Update parcial por resource (solo columnas presentes en [cambios])
  Future<int> actualizarParcialPorResource(
    String resource,
    SyncStateCompanion cambios,
  ) {
    return (update(
      syncState,
    )..where((t) => t.resource.equals(resource))).write(cambios);
  }

  // ────────────────────────────────────────────────────────────────────────────
  // 📌 CONSULTAS (local)
  // ────────────────────────────────────────────────────────────────────────────
  Future<SyncStateDb?> obtenerPorResourceDrift(String resource) {
    return (select(
      syncState,
    )..where((t) => t.resource.equals(resource))).getSingleOrNull();
  }

  Future<List<SyncStateDb>> obtenerTodasDrift() => select(syncState).get();

  Future<List<SyncStateDb>> buscarPorResourceDrift(String prefix) {
    final like = '${prefix.trim()}%';
    return (select(syncState)
          ..where((t) => t.resource.like(like))
          ..orderBy([(t) => OrderingTerm.asc(t.resource)]))
        .get();
  }

  // ────────────────────────────────────────────────────────────────────────────
  // 📌 SINCRONIZACIÓN (estado local)
  // ────────────────────────────────────────────────────────────────────────────
  Future<List<SyncStateDb>> obtenerPendientesSyncDrift() {
    return (select(syncState)..where((t) => t.isSynced.equals(false))).get();
  }

  Future<void> marcarComoSincronizadoDrift(String resource) async {
    await (update(syncState)..where((t) => t.resource.equals(resource))).write(
      const SyncStateCompanion(
        isSynced: Value(true),
        updatedAt: Value.absent(),
      ),
    );
  }

  /// Batch para varios resources (útil si en el futuro tienes más filas)
  Future<void> marcarComoSincronizadosDrift(List<String> resources) async {
    if (resources.isEmpty) return;
    await (update(syncState)..where((t) => t.resource.isIn(resources))).write(
      const SyncStateCompanion(
        isSynced: Value(true),
        updatedAt: Value.absent(),
      ),
    );
  }

  Future<DateTime?> obtenerUltimaActualizacionDrift() async {
    final row =
        await (select(syncState)
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

  // ────────────────────────────────────────────────────────────────────────────
  // 🔧 Helpers específicos (marca/epoch/bootstrapping)
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> initIfMissingDrift({required String resource}) async {
    final existe =
        await (select(syncState)
              ..where((t) => t.resource.equals(resource))
              ..limit(1))
            .getSingleOrNull();
    if (existe != null) return;

    final epoch = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    await into(syncState).insertOnConflictUpdate(
      SyncStateCompanion(
        resource: Value(resource),
        updatedAt: Value(epoch),
        isSynced: const Value(true),
      ),
    );
  }

  Future<void> setMarcaDesdeRemotoDrift({
    required String resource,
    required DateTime remoteUpdatedAt,
  }) async {
    await (update(syncState)..where((t) => t.resource.equals(resource))).write(
      SyncStateCompanion(
        updatedAt: Value(remoteUpdatedAt.toUtc()),
        isSynced: const Value(true),
      ),
    );
  }

  Future<DateTime> obtenerMarcaLocalUtcDrift(String resource) async {
    final row = await obtenerPorResourceDrift(resource);
    if (row != null) return row.updatedAt.toUtc();
    await initIfMissingDrift(resource: resource);
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}

/// 🔧 Extensión estilo “touch pending” (igual que proponemos para otros DAOs)
extension SyncStateTouch on SyncStateDao {
  /// Marca el recurso como PENDIENTE localmente (updatedAt=now, isSynced=false).
  Future<void> touchLocalPending({
    required String resource,
    DateTime? ts,
  }) async {
    final now = (ts ?? DateTime.now()).toUtc();
    await upsertSyncStateDrift(
      SyncStateCompanion(
        resource: Value(resource),
        updatedAt: Value(now),
        isSynced: const Value(false),
      ),
    );
  }
}

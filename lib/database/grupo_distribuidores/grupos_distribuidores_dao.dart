import 'package:drift/drift.dart';
import 'package:myafmzd/database/app_database.dart';
import 'grupos_distribuidores_table.dart';

part 'grupos_distribuidores_dao.g.dart';

@DriftAccessor(tables: [GruposDistribuidores])
class GruposDistribuidoresDao extends DatabaseAccessor<AppDatabase>
    with _$GruposDistribuidoresDaoMixin {
  GruposDistribuidoresDao(super.db);

  // ---------------------------------------------------------------------------
  // 📌 CRUD BÁSICO
  // ---------------------------------------------------------------------------

  /// Insertar o actualizar un grupo (parcial o completo).
  Future<void> upsertGrupoDrift(GruposDistribuidoresCompanion grupo) =>
      into(gruposDistribuidores).insertOnConflictUpdate(grupo);

  /// Insertar/actualizar múltiples grupos.
  Future<void> upsertGruposDrift(
    List<GruposDistribuidoresCompanion> lista,
  ) async {
    if (lista.isEmpty) return;
    await batch(
      (b) => b.insertAllOnConflictUpdate(gruposDistribuidores, lista),
    );
  }

  /// Actualización parcial por uid (solo columnas presentes en [cambios]).
  Future<int> actualizarParcialPorUid(
    String uid,
    GruposDistribuidoresCompanion cambios,
  ) {
    return (update(
      gruposDistribuidores,
    )..where((t) => t.uid.equals(uid))).write(cambios);
  }

  /// Soft delete por lista de uids (marca deleted=true, isSynced=false y toca updatedAt).
  Future<void> marcarComoEliminadosDrift(List<String> uids) async {
    if (uids.isEmpty) return;
    await (update(gruposDistribuidores)..where((t) => t.uid.isIn(uids))).write(
      GruposDistribuidoresCompanion(
        deleted: const Value(true),
        isSynced: const Value(false),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 📌 CONSULTAS
  // ---------------------------------------------------------------------------

  /// Obtener un grupo por uid.
  Future<GrupoDistribuidorDb?> obtenerPorUidDrift(String uid) => (select(
    gruposDistribuidores,
  )..where((t) => t.uid.equals(uid))).getSingleOrNull();

  /// Obtener todos (incluye eliminados).
  Future<List<GrupoDistribuidorDb>> obtenerTodosDrift() =>
      select(gruposDistribuidores).get();

  /// Obtener todos NO eliminados, ordenados por nombre asc.
  Future<List<GrupoDistribuidorDb>> obtenerTodosNoDeletedDrift() {
    return (select(gruposDistribuidores)
          ..where((t) => t.deleted.equals(false))
          ..orderBy([
            (t) => OrderingTerm(expression: t.nombre, mode: OrderingMode.asc),
          ]))
        .get();
  }

  /// Buscar por nombre o abreviatura (NO eliminados).
  Future<List<GrupoDistribuidorDb>> buscarPorTextoDrift(String query) {
    final q = '%${query.trim()}%';
    return (select(gruposDistribuidores)
          ..where(
            (t) =>
                t.deleted.equals(false) &
                (t.nombre.like(q) | t.abreviatura.like(q)),
          )
          ..orderBy([
            (t) => OrderingTerm(expression: t.nombre, mode: OrderingMode.asc),
          ]))
        .get();
  }

  /// Activar / desactivar un grupo.
  Future<int> setActivoDrift(String uid, bool activo) {
    return (update(
      gruposDistribuidores,
    )..where((t) => t.uid.equals(uid))).write(
      GruposDistribuidoresCompanion(
        activo: Value(activo),
        updatedAt: Value(DateTime.now().toUtc()),
        isSynced: const Value(false),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 📌 SINCRONIZACIÓN (estado local)
  // ---------------------------------------------------------------------------

  /// Filas pendientes de sincronizar (isSynced == false).
  Future<List<GrupoDistribuidorDb>> obtenerPendientesSyncDrift() {
    return (select(
      gruposDistribuidores,
    )..where((t) => t.isSynced.equals(false))).get();
  }

  /// Marcar como sincronizado (no toca updatedAt).
  Future<void> marcarComoSincronizadoDrift(String uid) async {
    await (update(gruposDistribuidores)..where((t) => t.uid.equals(uid))).write(
      const GruposDistribuidoresCompanion(
        isSynced: Value(true),
        updatedAt: Value.absent(),
      ),
    );
  }

  /// Última actualización local considerando SOLO sincronizados.
  Future<DateTime?> obtenerUltimaActualizacionDrift() async {
    final row =
        await (select(gruposDistribuidores)
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

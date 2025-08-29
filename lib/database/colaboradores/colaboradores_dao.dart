import 'package:drift/drift.dart';
import 'package:myafmzd/database/app_database.dart';
import 'colaboradores_table.dart';

part 'colaboradores_dao.g.dart';

@DriftAccessor(tables: [Colaboradores])
class ColaboradoresDao extends DatabaseAccessor<AppDatabase>
    with _$ColaboradoresDaoMixin {
  ColaboradoresDao(super.db);

  // ---------------------------------------------------------------------------
  // 📌 CRUD BÁSICO (solo local con Companions)
  // ---------------------------------------------------------------------------

  /// Insertar o actualizar un colaborador (parcial o completo).
  Future<void> upsertColaboradorDrift(ColaboradoresCompanion colaborador) =>
      into(colaboradores).insertOnConflictUpdate(colaborador);

  /// Insertar/actualizar múltiples colaboradores.
  Future<void> upsertColaboradoresDrift(
    List<ColaboradoresCompanion> lista,
  ) async {
    if (lista.isEmpty) return;
    await batch((b) => b.insertAllOnConflictUpdate(colaboradores, lista));
  }

  // actualizarParcialPorUid
  Future<int> actualizarParcialPorUid(
    String uid,
    ColaboradoresCompanion cambios,
  ) {
    return (update(
      colaboradores,
    )..where((t) => t.uid.equals(uid))).write(cambios);
  }

  /// Soft delete: marcar colaboradores como eliminados.
  Future<void> marcarComoEliminadosDrift(List<String> uids) async {
    if (uids.isEmpty) return;
    await (update(colaboradores)..where((c) => c.uid.isIn(uids))).write(
      ColaboradoresCompanion(
        deleted: const Value(true),
        isSynced: const Value(false),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 📌 CONSULTAS (solo local)
  // ---------------------------------------------------------------------------

  /// Obtener un colaborador por UID.
  Future<ColaboradorDb?> obtenerPorUidDrift(String uid) => (select(
    colaboradores,
  )..where((c) => c.uid.equals(uid))).getSingleOrNull();

  /// Obtener por CURP (si aplica validaciones).
  Future<ColaboradorDb?> obtenerPorCurpDrift(String curp) => (select(
    colaboradores,
  )..where((c) => c.curp.equals(curp))).getSingleOrNull();

  /// Obtener todos (incluye eliminados).
  Future<List<ColaboradorDb>> obtenerTodosDrift() =>
      select(colaboradores).get();

  /// Obtener todos NO eliminados, ordenados por nombre.
  Future<List<ColaboradorDb>> obtenerTodosNoDeletedDrift() {
    return (select(colaboradores)
          ..where((c) => c.deleted.equals(false))
          ..orderBy([
            (c) => OrderingTerm(expression: c.nombres, mode: OrderingMode.asc),
          ]))
        .get();
  }

  /// Buscar colaboradores por género (ejemplo de consulta específica).
  Future<List<ColaboradorDb>> obtenerPorGeneroDrift(String genero) {
    return (select(colaboradores)
          ..where((c) => c.deleted.equals(false) & c.genero.equals(genero))
          ..orderBy([(c) => OrderingTerm.asc(c.nombres)]))
        .get();
  }

  // ---------------------------------------------------------------------------
  // 📌 SINCRONIZACIÓN (estado local)
  // ---------------------------------------------------------------------------

  /// Colaboradores pendientes de subida (isSynced == false).
  Future<List<ColaboradorDb>> obtenerPendientesSyncDrift() {
    return (select(
      colaboradores,
    )..where((c) => c.isSynced.equals(false))).get();
  }

  /// Marcar como sincronizado (no se actualiza updatedAt).
  Future<void> marcarComoSincronizadoDrift(String uid) async {
    await (update(colaboradores)..where((c) => c.uid.equals(uid))).write(
      const ColaboradoresCompanion(
        isSynced: Value(true),
        updatedAt: Value.absent(),
      ),
    );
  }

  /// Última actualización local considerando SOLO sincronizados.
  Future<DateTime?> obtenerUltimaActualizacionDrift() async {
    final ultimo =
        await (select(colaboradores)
              ..where((c) => c.isSynced.equals(true))
              ..orderBy([
                (c) => OrderingTerm(
                  expression: c.updatedAt,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();
    return ultimo?.updatedAt;
  }
}

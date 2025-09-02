import 'package:drift/drift.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/usuarios/usuarios_table.dart';

part 'usuarios_dao.g.dart';

@DriftAccessor(tables: [Usuarios])
class UsuariosDao extends DatabaseAccessor<AppDatabase>
    with _$UsuariosDaoMixin {
  UsuariosDao(super.db);

  // ---------------------------------------------------------------------------
  // 📌 CRUD BÁSICO (solo local con Companions)
  // ---------------------------------------------------------------------------

  /// Insertar o actualizar un usuario (parcial o completo).
  Future<void> upsertUsuarioDrift(UsuariosCompanion usuario) =>
      into(usuarios).insertOnConflictUpdate(usuario);

  /// Insertar/actualizar múltiples usuarios.
  Future<void> upsertUsuariosDrift(List<UsuariosCompanion> lista) async {
    if (lista.isEmpty) return;
    await batch((b) => b.insertAllOnConflictUpdate(usuarios, lista));
  }

  /// Soft delete: marca usuarios como eliminados.
  Future<void> marcarComoEliminadosDrift(List<String> uids) async {
    if (uids.isEmpty) return;
    await (update(usuarios)..where((u) => u.uid.isIn(uids))).write(
      UsuariosCompanion(
        deleted: const Value(true),
        isSynced: const Value(false),

        updatedAt: Value(DateTime.now().toUtc()),
        // isSynced lo dejamos como está; el Sync decidirá si marcar pendiente
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 📌 CONSULTAS (solo local)
  // ---------------------------------------------------------------------------

  /// Obtener un usuario por UID.
  Future<UsuarioDb?> obtenerPorUidDrift(String uid) =>
      (select(usuarios)..where((u) => u.uid.equals(uid))).getSingleOrNull();

  /// Obtener por correo (útil para validaciones/login local).
  Future<UsuarioDb?> obtenerPorCorreoDrift(String correo) => (select(
    usuarios,
  )..where((u) => u.correo.equals(correo))).getSingleOrNull();

  /// Obtener por colaborador (no eliminados).
  Future<List<UsuarioDb>> obtenerPorColaboradorDrift(String colaboradorUid) {
    return (select(usuarios)
          ..where(
            (u) =>
                u.deleted.equals(false) &
                u.colaboradorUid.equals(colaboradorUid),
          )
          ..orderBy([(u) => OrderingTerm.asc(u.userName)]))
        .get();
  }

  /// Buscar por texto en userName o emailCache (no eliminados).
  Future<List<UsuarioDb>> buscarTextoDrift(String q) {
    final like = '%${q.trim()}%';
    return (select(usuarios)
          ..where(
            (u) =>
                u.deleted.equals(false) &
                (u.userName.like(like) | u.correo.like(like)),
          )
          ..orderBy([
            (u) => OrderingTerm.asc(u.userName),
            (u) => OrderingTerm.asc(u.correo),
          ]))
        .get();
  }

  /// Obtener todos (incluye eliminados).
  Future<List<UsuarioDb>> obtenerTodosDrift() => select(usuarios).get();

  /// Obtener NO eliminados, ordenados por nombre.
  Future<List<UsuarioDb>> obtenerTodosNoDeletedDrift() {
    return (select(usuarios)
          ..where((u) => u.deleted.equals(false))
          ..orderBy([
            (u) => OrderingTerm(expression: u.userName, mode: OrderingMode.asc),
          ]))
        .get();
  }

  // ---------------------------------------------------------------------------
  // 📌 SINCRONIZACIÓN (solo estado local)
  // ---------------------------------------------------------------------------

  /// Usuarios pendientes de subida (isSynced == false).
  Future<List<UsuarioDb>> obtenerPendientesSyncDrift() {
    return (select(usuarios)..where((u) => u.isSynced.equals(false))).get();
  }

  /// Marcar como sincronizados
  Future<void> marcarComoSincronizadoDrift(String uid, DateTime fecha) async {
    await (update(usuarios)..where((r) => r.uid.equals(uid))).write(
      UsuariosCompanion(
        isSynced: const Value(true),
        updatedAt: const Value.absent(),
      ),
    );
  }

  /// Última actualización local considerando TODOS (útil para comparaciones).
  Future<DateTime?> obtenerUltimaActualizacionDrift() async {
    final ultimo =
        await (select(usuarios)
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

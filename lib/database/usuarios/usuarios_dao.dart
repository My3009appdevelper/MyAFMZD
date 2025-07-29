import 'package:drift/drift.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/usuarios/usuarios_table.dart';

part 'usuarios_dao.g.dart';

@DriftAccessor(tables: [Usuarios])
class UsuariosDao extends DatabaseAccessor<AppDatabase>
    with _$UsuariosDaoMixin {
  UsuariosDao(super.db);

  // ---------------------------------------------------------------------------
  // 📌 CRUD BÁSICO
  // ---------------------------------------------------------------------------

  // Insertar o reemplazar un usuario. crearUsuarioEnSupabase y actualizarUsuario en Usuario Service
  Future<void> upsertUsuarioDrift(UsuarioDb usuario) =>
      into(usuarios).insertOnConflictUpdate(usuario);

  // Insertar múltiples usuarios. leerDesdeSupabase en Usuario Service
  Future<void> upsertUsuariosDrift(List<UsuarioDb> lista) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(usuarios, lista);
    });
  }

  // Soft delete: marcar usuarios como eliminados. eliminarUsuario en Usuario Service
  Future<void> marcarComoEliminadosDrift(List<String> uids) async {
    await (update(usuarios)..where((u) => u.uid.isIn(uids))).write(
      UsuariosCompanion(
        deleted: const Value(true),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 📌 SINCRONIZACIÓN / UPSERTS
  // ---------------------------------------------------------------------------

  // Obtener un usuario por UID
  Future<UsuarioDb?> obtenerPorUidDrift(String uid) =>
      (select(usuarios)..where((u) => u.uid.equals(uid))).getSingleOrNull();

  // Obtener todos
  Future<List<UsuarioDb>> obtenerTodosDrift() => select(usuarios).get();

  // Obtener usuarios pendientes de sincronización. pushUsuariosOffline en UsuarioSync
  Future<List<UsuarioDb>> obtenerPendientesSyncDrift() {
    return (select(usuarios)..where((u) => u.isSynced.equals(false))).get();
  }

  // Marcar usuarios como sincronizados. pushUsuariosOffline en UsuarioSync
  Future<void> marcarComoSincronizadoDrift(List<String> uids) async {
    await (update(usuarios)..where((u) => u.uid.isIn(uids))).write(
      UsuariosCompanion(
        isSynced: const Value(true),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  /// Obtener la última fecha de actualización de la tabla. Útil para comparar contra Supabase y decidir si hacer pull.
  Future<DateTime?> obtenerUltimaActualizacionUsuariosDrift() async {
    final ultimo =
        await (select(usuarios)
              ..orderBy([(u) => OrderingTerm.desc(u.updatedAt)])
              ..limit(1))
            .getSingleOrNull();
    return ultimo?.updatedAt;
  }
}

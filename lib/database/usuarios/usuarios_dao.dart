import 'package:drift/drift.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/usuarios/usuarios_table.dart';

part 'usuarios_dao.g.dart';

@DriftAccessor(tables: [Usuarios])
class UsuariosDao extends DatabaseAccessor<AppDatabase>
    with _$UsuariosDaoMixin {
  UsuariosDao(AppDatabase db) : super(db);

  // ✅ Insertar o reemplazar un usuario
  Future<void> upsertUsuario(Usuario usuario) =>
      into(usuarios).insertOnConflictUpdate(usuario);

  // ✅ Insertar múltiples usuarios
  Future<void> upsertUsuarios(List<Usuario> lista) async {
    await batch((batch) {
      batch.insertAllOnConflictUpdate(usuarios, lista);
    });
  }

  // ✅ Obtener un usuario por UID
  Future<Usuario?> obtenerPorUid(String uid) =>
      (select(usuarios)..where((u) => u.uid.equals(uid))).getSingleOrNull();

  // ✅ Obtener todos
  Future<List<Usuario>> obtenerTodos() => select(usuarios).get();

  // ✅ Watch reactividad (todos)
  Stream<List<Usuario>> watchTodos() => select(usuarios).watch();

  // ✅ Watch reactividad (uno)
  Stream<Usuario?> watchPorUid(String uid) =>
      (select(usuarios)..where((u) => u.uid.equals(uid))).watchSingleOrNull();

  // ✅ Eliminar un usuario
  Future<int> eliminarPorUid(String uid) =>
      (delete(usuarios)..where((u) => u.uid.equals(uid))).go();

  // ✅ Eliminar lista de usuarios
  Future<int> eliminarPorUids(List<String> uids) =>
      (delete(usuarios)..where((u) => u.uid.isIn(uids))).go();

  // ✅ Eliminar todos
  Future<int> eliminarTodos() => delete(usuarios).go();
}

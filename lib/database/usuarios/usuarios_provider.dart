import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/database_provider.dart';
import 'package:myafmzd/database/usuarios/usuarios_dao.dart';
import 'package:myafmzd/database/usuarios/usuarios_service.dart';
import 'package:myafmzd/database/usuarios/usuarios_sync.dart';

final usuariosProvider =
    StateNotifierProvider<UsuariosNotifier, List<UsuarioDb>>((ref) {
      final db = ref.watch(appDatabaseProvider);
      return UsuariosNotifier(ref, db);
    });

class UsuariosNotifier extends StateNotifier<List<UsuarioDb>> {
  UsuariosNotifier(this._ref, AppDatabase db)
    : _dao = UsuariosDao(db),
      _servicio = UsuarioService(db),
      _sync = UsuariosSync(db),
      super([]);

  bool _hayInternet = true;
  bool get hayInternet => _hayInternet;

  final Ref _ref;
  final UsuariosDao _dao;
  final UsuarioService _servicio;
  final UsuariosSync _sync;

  // ---------------------------------------------------------------------------
  // ✅ Cargar distribuidores (offline-first)
  // ---------------------------------------------------------------------------
  Future<void> cargarOfflineFirst() async {
    try {
      _hayInternet = _ref.read(connectivityProvider);

      // Pintar siempre la base local primero
      final local = await _dao.obtenerTodosDrift();
      state = local;
      print(
        '[👤 MENSAJES USUARIOS PROVIDER] Local cargado -> ${local.length} usuarios',
      );

      // Si no hay internet → detenerse aquí
      if (!_hayInternet) {
        print(
          '[👤 MENSAJES USUARIOS PROVIDER] Sin internet → usando solo local',
        );
        return;
      }

      // Comparar timestamps local vs online
      final localTimestamp = await _dao.obtenerUltimaActualizacionDrift();
      final remotoTimestamp = await _servicio.comprobarActualizacionesOnline();

      print(
        '[👤 MENSAJES USUARIOS PROVIDER] Remoto:$remotoTimestamp | Local:$localTimestamp',
      );

      // Pull
      await _sync.pullUsuariosOnline();

      // Push de cambios offline primero
      await _sync.pushUsuariosOffline();

      // Cargar datos actualizados desde Drift
      final actualizados = await _dao.obtenerTodosDrift();
      state = actualizados;
    } catch (e) {
      print('[👤 MENSAJES USUARIOS PROVIDER] Error al cargar usuarios: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // CREAR (Auth + tabla online) → upsert local (isSynced=true)
  // ---------------------------------------------------------------------------
  Future<UsuarioDb?> crearUsuario({
    required String nombre,
    required String correo,
    required String password,
    required String rol,
    required String uuidDistribuidora,
    required Map<String, bool> permisos,
  }) async {
    try {
      // 1) Crear en Auth + upsert en tabla (ONLINE). El service devuelve el row.
      final row = await _servicio.crearUsuarioEnAuthYTabla(
        nombre: nombre,
        correo: correo,
        password: password,
        rol: rol,
        uuidDistribuidora: uuidDistribuidora,
        permisos: permisos,
      );

      // 2) Mapear a Companion (remoto ⇒ isSynced=true)
      final comp = UsuariosCompanion(
        uid: Value(row['uid'] as String),
        nombre: Value((row['nombre'] as String?) ?? ''),
        correo: Value((row['correo'] as String?) ?? ''),
        rol: Value((row['rol'] as String?) ?? 'usuario'),
        uuidDistribuidora: Value((row['uuid_distribuidora'] as String?) ?? ''),
        permisos: Value(Map<String, bool>.from(row['permisos'] ?? {})),
        updatedAt: Value(DateTime.parse(row['updated_at']).toUtc()),
        deleted: Value((row['deleted'] as bool?) ?? false),
        isSynced: const Value(true),
      );

      await _dao.upsertUsuarioDrift(comp);

      // 3) Refrescar estado
      final actualizados = await _dao.obtenerTodosDrift();
      state = actualizados;

      // 4) Devolver modelo recién creado
      return actualizados.firstWhere((u) => u.uid == row['uid']);
    } catch (e) {
      print('[👤 USUARIOS PROVIDER] ❌ Error al crear usuario: $e');
      rethrow;
    }
  }

  // Editar usuario
  Future<void> editarUsuario({
    required String uid,
    required String nombre,
    required String correo,
    required String rol,
    required String uuidDistribuidora,
    required Map<String, bool> permisos,
  }) async {
    try {
      final actualizado = UsuariosCompanion(
        uid: Value(uid),
        nombre: Value(nombre),
        correo: Value(correo),
        rol: Value(rol),
        uuidDistribuidora: Value(uuidDistribuidora),
        permisos: Value(permisos),
        updatedAt: Value(DateTime.now().toUtc()),
        deleted: const Value.absent(),
        isSynced: Value(false),
      );

      await _dao.upsertUsuarioDrift(actualizado);

      final actualizados = await _dao.obtenerTodosDrift();
      state = actualizados;

      print('[👤 MENSAJES USUARIOS PROVIDER] Usuario $uid editado localmente');
    } catch (e) {
      print('[👤 MENSAJES USUARIOS PROVIDER] ❌ Error al editar usuario: $e');
      rethrow;
    }
  }

  bool existeDuplicado({
    required String uidActual,
    required String nombre,
    required String correo,
  }) {
    return state.any(
      (u) =>
          u.uid != uidActual &&
          (u.nombre.trim().toLowerCase() == nombre.trim().toLowerCase() ||
              u.correo.trim().toLowerCase() == correo.trim().toLowerCase()),
    );
  }
}

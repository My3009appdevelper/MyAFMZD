import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/usuarios/usuarios_dao.dart';
import 'package:myafmzd/database/usuarios/usuarios_service.dart';
import 'package:myafmzd/database/usuarios/usuarios_sync.dart';
import 'package:myafmzd/main.dart';

final usuariosProvider =
    StateNotifierProvider<UsuariosNotifier, List<UsuarioDb>>((ref) {
      final db = ref.watch(appDatabaseProvider);
      return UsuariosNotifier(db);
    });

class UsuariosNotifier extends StateNotifier<List<UsuarioDb>> {
  UsuariosNotifier(AppDatabase db)
    : _dao = UsuariosDao(db),
      _servicio = UsuarioService(db),
      _sync = UsuarioSync(db),
      super([]);

  final UsuariosDao _dao;
  final UsuarioService _servicio;
  final UsuarioSync _sync;

  /// ✅ Cargar usuarios (offline-first)
  Future<void> cargar({required bool hayInternet}) async {
    try {
      // Pintar siempre la base local primero
      final local = await _dao.obtenerTodosDrift();
      state = local;
      print('[📴 USUARIOS PROVIDER] Local cargado -> ${local.length} usuarios');

      // Si no hay internet → detenerse aquí
      if (!hayInternet) {
        print('[📴 USUARIOS PROVIDER] Sin internet → usando solo local');
        return;
      }

      // Comparar timestamps local vs online
      final localTimestamp = await _dao
          .obtenerUltimaActualizacionUsuariosDrift();
      final remoto = await _servicio.comprobarActualizacionesOnline();

      print('[⏱️ USUARIOS PROVIDER] Remoto:$remoto | Local:$localTimestamp');

      // Si Supabase está vacío → solo usar local
      if (remoto == null) {
        print('[📴 USUARIOS PROVIDER] ⚠️ Supabase vacío → usar solo local');
        return;
      }

      // Si no hay cambios → mantener local y salir
      if (localTimestamp != null) {
        final diff = remoto.difference(localTimestamp).inSeconds.abs();
        if (diff <= 1) {
          print('[📴 USUARIOS PROVIDER] Sin cambios → mantener local');
          return;
        }
      }

      // Pull
      await _sync.pullUsuariosOnline(ultimaSync: localTimestamp);

      // Push de cambios offline primero
      await _sync.pushUsuariosOffline();

      // Cargar datos actualizados desde Drift
      final actualizados = await _dao.obtenerTodosDrift();
      state = actualizados;
    } catch (e) {
      print('[📴 USUARIOS PROVIDER] Error al cargar usuarios: $e');
    }
  }

  /// ✅ Crear usuario (Supabase)
  Future<void> crearUsuario({
    required String nombre,
    required String correo,
    required String password,
    required String rol,
    required String uuidDistribuidora,
    required Map<String, bool> permisos,
  }) async {
    final nuevo = await _servicio.crearUsuarioEnSupabase(
      nombre: nombre,
      correo: correo,
      password: password,
      rol: rol,
      uuidDistribuidora: uuidDistribuidora,
      permisos: permisos,
    );
    state = [...state, nuevo];
  }

  // Editar usuario
  Future<void> editarUsuario({
    required String uid,
    required String nombre,
    required String correo,
    required String rol,
    required String uuidDistribuidora,
    required Map<String, bool> permisos,
    required bool hayInternet, // 👈 nuevo parámetro
  }) async {
    try {
      final actualizado = UsuarioDb(
        uid: uid,
        nombre: nombre,
        correo: correo,
        rol: rol,
        uuidDistribuidora: uuidDistribuidora,
        permisos: permisos,
        updatedAt: DateTime.now().toUtc(),
        deleted: false,
        isSynced: false,
      );

      await _dao.upsertUsuarioDrift(actualizado);

      final nuevos = [...state];
      final index = nuevos.indexWhere((u) => u.uid == uid);
      if (index != -1) {
        nuevos[index] = actualizado;
        state = nuevos;
      }

      print('[📴 USUARIOS PROVIDER] Usuario $uid editado localmente');

      // 🔁 Hacer sync justo después
      await cargar(hayInternet: hayInternet);
    } catch (e) {
      print('[📴 USUARIOS PROVIDER] ❌ Error al editar usuario: $e');
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

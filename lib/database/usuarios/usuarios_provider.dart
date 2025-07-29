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
      // 1️⃣ Pintar siempre la base local primero
      final local = await _dao.obtenerTodosDrift();
      state = local;
      print(
        '[📴 MENSAJE USUARIOS PROVIDER] Local cargado -> ${local.length} usuarios',
      );

      // 2️⃣ Si no hay internet → detenerse aquí
      if (!hayInternet) {
        print(
          '[📴 MENSAJE USUARIOS PROVIDER] Sin internet → usando solo local',
        );
        return;
      }

      // 3️⃣ Push de cambios offline primero
      await _sync.pushUsuariosOffline();

      // 4️⃣ Comparar timestamps local vs online
      final localTimestamp = await _dao
          .obtenerUltimaActualizacionUsuariosDrift();
      final remoto = await _servicio.comprobarActualizacionesOnline();

      print(
        '[⏱️ MENSAJE USUARIOS PROVIDER] Remoto:$remoto | Local:$localTimestamp',
      );

      // 5️⃣ Si Supabase está vacío → solo usar local
      if (remoto == null) {
        print(
          '[📴 MENSAJE USUARIOS PROVIDER] ⚠️ Supabase vacío → usar solo local',
        );
        return;
      }

      // 6️⃣ Si no hay cambios → mantener local y salir
      if (localTimestamp != null) {
        final diff = remoto.difference(localTimestamp).inSeconds.abs();
        if (diff <= 1) {
          print('[📴 MENSAJE USUARIOS PROVIDER] Sin cambios → mantener local');
          return;
        }
      }

      // 7️⃣ Hacer sync completo (pull + push)
      await _sync.pullUsuariosOnline(ultimaSync: localTimestamp);

      // 8️⃣ Cargar datos actualizados desde Drift
      final actualizados = await _dao.obtenerTodosDrift();
      state = actualizados;
    } catch (e) {
      print('[📴 MENSAJE USUARIOS PROVIDER] Error al cargar usuarios: $e');
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
}

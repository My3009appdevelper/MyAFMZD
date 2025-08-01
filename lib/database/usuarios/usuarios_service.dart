// ignore_for_file: avoid_print
import 'package:myafmzd/database/usuarios/usuarios_dao.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsuarioService {
  final UsuariosDao _dao;
  final SupabaseClient _client;

  UsuarioService(AppDatabase db)
    : _dao = UsuariosDao(db),
      _client = Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // 📌 COMPROBAR ACTUALIZACIONES ONLINE
  // ---------------------------------------------------------------------------

  /// ✅ Comprobar la última fecha de actualización en Supabase.
  Future<DateTime?> comprobarActualizacionesOnline() async {
    try {
      final response = await _client
          .from('usuarios')
          .select('updated_at')
          .order('updated_at', ascending: false)
          .limit(1);

      if (response.isEmpty || response.first['updated_at'] == null) {
        print('[🔍 USUARIOS SERVICE] ❌ No se encontró updated_at en Supabase');
        return null;
      }

      final ts = DateTime.parse(response.first['updated_at']).toUtc();
      print('[🔍 USUARIOS SERVICE] ⏱️ Última actualización online: $ts');
      return ts;
    } catch (e) {
      print('[🔍 USUARIOS SERVICE] ❌ Error comprobando actualizaciones: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 OBTENER TODOS ONLINE
  // ---------------------------------------------------------------------------

  /// ✅ Obtener todos los usuarios desde Supabase y sincronizar Drift.
  Future<List<UsuarioDb>> obtenerFiltradosOnline({DateTime? ultimaSync}) async {
    try {
      print('[📡 USUARIOS SERVICE] Obteniendo usuarios online...');

      var query = _client.from('usuarios').select();

      if (ultimaSync != null) {
        query = query.gte('updated_at', ultimaSync.toUtc().toIso8601String());
      }

      final data = await query;

      final lista = (data as List)
          .map(
            (row) => UsuarioDb(
              uid: row['uid'],
              nombre: row['nombre'] ?? '',
              correo: row['correo'] ?? '',
              rol: row['rol'] ?? 'usuario',
              uuidDistribuidora: row['uuid_distribuidora'] ?? '',
              permisos: Map<String, bool>.from(row['permisos'] ?? {}),
              updatedAt: DateTime.parse(row['updated_at']).toUtc(),
              deleted: row['deleted'] ?? false,
              isSynced: true,
            ),
          )
          .toList();

      print('[📡 USUARIOS SERVICE] Sincronizados ${lista.length} usuarios');
      return lista;
    } catch (e) {
      print('[📡 USUARIOS SERVICE] ❌ Error obteniendo usuarios online: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 CREAR / ACTUALIZAR / ELIMINAR ONLINE
  // ---------------------------------------------------------------------------

  /// ✅ Crear usuario en Auth + tabla usuarios y sincronizar Drift.
  Future<UsuarioDb> crearUsuarioEnSupabase({
    required String nombre,
    required String correo,
    required String password,
    required String rol,
    required String uuidDistribuidora,
    required Map<String, bool> permisos,
  }) async {
    try {
      final authResponse = await _client.auth.signUp(
        email: correo,
        password: password,
      );
      final user = authResponse.user;
      if (user == null) throw Exception('No se pudo crear el usuario en Auth');

      print(
        '[👤 USUARIOS SERVICE] ✅ Usuario ${user.email} creado en Autenticación',
      );

      final usuario = UsuarioDb(
        uid: user.id,
        nombre: nombre,
        correo: correo,
        rol: rol,
        uuidDistribuidora: uuidDistribuidora,
        permisos: permisos,
        updatedAt: DateTime.now().toUtc(),
        deleted: false,
        isSynced: true,
      );

      await _client.from('usuarios').upsert({
        'uid': usuario.uid,
        'nombre': usuario.nombre,
        'correo': usuario.correo,
        'rol': usuario.rol,
        'uuid_distribuidora': usuario.uuidDistribuidora,
        'permisos': usuario.permisos,
        'deleted': usuario.deleted,
        'updated_at': usuario.updatedAt.toUtc().toIso8601String(),
      });
      print('[👤 USUARIOS SERVICE] ✅ Usuario ${usuario.uid} creado en online');

      await _dao.upsertUsuarioDrift(usuario);
      print('[👤 USUARIOS SERVICE] ✅ Usuario ${usuario.uid} creado offline');
      return usuario;
    } catch (e) {
      print('[👤 USUARIOS SERVICE] ❌ Error creando usuario online: $e');
      rethrow;
    }
  }

  /// ✅ Crear/actualizar usuario sin pasar por Auth (sync/offline).
  Future<void> upsertUsuarioOnline(UsuarioDb usuario) async {
    try {
      await _client.from('usuarios').upsert({
        'uid': usuario.uid,
        'nombre': usuario.nombre,
        'correo': usuario.correo,
        'rol': usuario.rol,
        'uuid_distribuidora': usuario.uuidDistribuidora,
        'permisos': usuario.permisos,
        'deleted': usuario.deleted,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      print('[⬆️ USUARIOS SERVICE] Usuario ${usuario.uid} upsert online');
    } catch (e) {
      print('[⬆️ USUARIOS SERVICE] ❌ Error subiendo usuario: $e');
      rethrow;
    }
  }

  /// ✅ Soft delete online + sincronización local.
  Future<void> eliminarUsuarioOnline(String uid) async {
    try {
      await _client
          .from('usuarios')
          .update({'deleted': true, 'updated_at': DateTime.now().toUtc()})
          .eq('uid', uid);

      print(
        '[🗑️ USUARIOS SERVICE] Usuario $uid marcado como eliminado online',
      );
    } catch (e) {
      print('[🗑️ USUARIOS SERVICE] ❌ Error eliminando usuario: $e');
      rethrow;
    }
  }
}

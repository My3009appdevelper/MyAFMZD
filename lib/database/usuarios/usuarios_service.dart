// ignore_for_file: avoid_print
import 'package:myafmzd/database/app_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UsuarioService {
  final SupabaseClient supabase;

  UsuarioService(AppDatabase db) : supabase = Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // 📌 COMPROBAR ACTUALIZACIONES ONLINE
  // ---------------------------------------------------------------------------

  /// ✅ Comprobar la última fecha de actualización en Supabase.
  Future<DateTime?> comprobarActualizacionesOnline() async {
    try {
      final response = await supabase
          .from('usuarios')
          .select('updated_at')
          .order('updated_at', ascending: false)
          .limit(1);

      if (response.isEmpty || response.first['updated_at'] == null) {
        print(
          '[👤 MENSAJES USUARIOS SERVICE] ❌ No se encontró updated_at en Supabase',
        );
        return null;
      }

      final fecha = DateTime.parse(response.first['updated_at']).toUtc();

      return fecha;
    } catch (e) {
      print(
        '[👤 MENSAJES USUARIOS SERVICE] ❌ Error comprobando actualizaciones: $e',
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 OBTENER TODOS ONLINE
  // ---------------------------------------------------------------------------

  /// 🔄 Obtener todos los usuarios desde Supabase.
  Future<List<Map<String, dynamic>>> obtenerTodosOnline() async {
    print(
      '[👤 MENSAJES USUARIOS SERVICE] 📥 Obteniendo TODOS los usuarios online...',
    );
    try {
      final response = await supabase.from('usuarios').select();
      print(
        '[👤 MENSAJES USUARIOS SERVICE] ✅ ${response.length} usuarios obtenidos',
      );
      return response;
    } catch (e) {
      print('[👤 MENSAJES USUARIOS SERVICE] ❌ Error al obtener todos: $e');
      rethrow;
    }
  }

  /// ✅ Obtener todos los usuarios desde Supabase y sincronizar Drift.
  Future<List<Map<String, dynamic>>> obtenerFiltradosOnline(
    DateTime ultimaSync,
  ) async {
    print('[👤 MENSAJES USUARIOS SERVICE] 📥 Filtrando > $ultimaSync (UTC)');
    try {
      final res = await supabase
          .from('usuarios')
          .select()
          .gt('updated_at', ultimaSync.toUtc().toIso8601String());
      print(
        '[👤 MENSAJES USUARIOS SERVICE] ✅ ${res.length} usuarios filtrados',
      );
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print('[👤 MENSAJES USUARIOS SERVICE] ❌ Error filtrados: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 HEADS (uid, updated_at) → diff barato (igual a ReportesService)
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> obtenerCabecerasOnline() async {
    try {
      final res = await supabase.from('usuarios').select('uid, updated_at');
      return res;
    } catch (e) {
      print('[👤 MENSAJES USUARIOS SERVICE] ❌ Error en cabeceras: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 FETCH selectivo por UIDs (lote) (igual a ReportesService)
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> obtenerPorUidsOnline(
    List<String> uids,
  ) async {
    if (uids.isEmpty) return [];
    try {
      final res = await supabase
          .from('usuarios')
          .select()
          .inFilter('uid', uids);
      return res;
    } catch (e) {
      print('[👤 MENSAJES USUARIOS SERVICE] ❌ Error fetch por UIDs: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 CREAR / ACTUALIZAR / ELIMINAR ONLINE
  // ---------------------------------------------------------------------------

  // 🔐 Crear en Auth + insertar en tabla `usuarios` (con tu nuevo esquema).
  // - Idempotente a nivel de llamada: si Auth dice user_already_exists, no se inserta en tabla y se lanza excepción clara.
  // - No toca Drift; devuelve el payload para que tu Provider lo persista local.
  Future<Map<String, dynamic>> crearUsuarioEnAuthYTabla({
    required String userName,
    required String correo,
    required String password,
    String? colaboradorUid,
  }) async {
    try {
      // 1) Crear en Auth
      final authRes = await supabase.auth.signUp(
        email: correo,
        password: password,
      );
      final user = authRes.user;
      if (user == null) {
        // En SDK modernos, si falla signUp, suele venir con excepción; este guard es por seguridad.
        throw AuthException('No se pudo crear el usuario en Auth');
      }
      print('[👤 USUARIOS SERVICE] ✅ Auth creado: ${user.email}');

      // 2) Insertar/actualizar fila en la tabla `usuarios`
      final nowIso = DateTime.now().toUtc().toIso8601String();
      final row = <String, dynamic>{
        'uid': user.id,
        'colaborador_uid': colaboradorUid, // puede ser null
        'user_name': userName,
        'correo': correo,
        'updated_at': nowIso,
        'deleted': false,
      };

      // 3) Devolver payload para persistir local (Drift)
      return row;
    } on AuthApiException catch (e) {
      // Errores que vienen del endpoint de Auth con código
      if (e.code == 'user_already_exists') {
        // ⚠️ NO insertar en tabla. Propagamos un mensaje claro de negocio.
        print('[👤 USUARIOS SERVICE] ❌ Auth: correo ya registrado');
        throw Exception('El correo ya está registrado en Auth');
      }
      print('[👤 USUARIOS SERVICE] ❌ AuthApiException: ${e.message}');
      rethrow;
    } on AuthException catch (e) {
      // Errores genéricos de Auth
      print('[👤 USUARIOS SERVICE] ❌ AuthException: ${e.message}');
      rethrow;
    } catch (e) {
      print('[👤 USUARIOS SERVICE] ❌ Error crear en Auth+Tabla: $e');
      rethrow;
    }
  }

  /// ✅ Crear/actualizar usuario sin pasar por Auth (sync/offline).
  /// Espera llaves acordes al esquema remoto (snake_case).
  /// Ej: { uid, colaborador_uid, user_name, correo, updated_at, deleted }
  Future<void> upsertUsuarioOnline(Map<String, dynamic> data) async {
    final uid = data['uid'];
    print('[👤 MENSAJES USUARIOS SERVICE] ⬆️ Upsert online usuario: $uid');
    try {
      await supabase.from('usuarios').upsert(data);
      print('[👤 MENSAJES USUARIOS SERVICE] ✅ Upsert $uid OK');
    } catch (e) {
      print('[👤 MENSAJES USUARIOS SERVICE] ❌ Error upsert $uid: $e');
      rethrow;
    }
  }

  /// ✅ Soft delete online + sincronización local.
  Future<void> eliminarUsuarioOnline(String uid) async {
    try {
      await supabase
          .from('usuarios')
          .update({
            'deleted': true,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('uid', uid);

      print(
        '[👤 MENSAJES USUARIOS SERVICE] Usuario $uid marcado como eliminado online',
      );
    } catch (e) {
      print('[👤 MENSAJES USUARIOS SERVICE] ❌ Error eliminando usuario: $e');
      rethrow;
    }
  }
}

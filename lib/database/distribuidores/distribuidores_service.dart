// ignore_for_file: avoid_print

import 'package:myafmzd/database/app_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DistribuidoresService {
  final SupabaseClient supabase;

  DistribuidoresService(AppDatabase db) : supabase = Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // 📌 COMPROBAR ACTUALIZACIONES ONLINE
  // ---------------------------------------------------------------------------

  Future<DateTime?> comprobarActualizacionesOnline() async {
    try {
      final response = await supabase
          .from('distribuidores')
          .select('updated_at')
          .order('updated_at', ascending: false)
          .limit(1);

      if (response.isEmpty || response.first['updated_at'] == null) {
        print(
          '[🏢 MENSAJES DISTRIBUIDORES SERVICE] ❌ No hay updated_at en Supabase',
        );
        return null;
      }

      final fecha = DateTime.parse(response.first['updated_at']);

      return fecha;
    } catch (e) {
      print(
        '[🏢 MENSAJES DISTRIBUIDORES SERVICE] ❌ Error comprobando actualizaciones: $e',
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 OBTENER TODOS ONLINE
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> obtenerTodosOnline() async {
    print('[🏢 MENSAJES DISTRIBUIDORES SERVICE] 📥 Obteniendo TODOS online…');
    try {
      final res = await supabase.from('distribuidores').select();
      print('[🏢 MENSAJES DISTRIBUIDORES SERVICE] ✅ ${res.length} filas');
      return res;
    } catch (e) {
      print('[🏢 MENSAJES DISTRIBUIDORES SERVICE] ❌ Error obtener todos: $e');
      rethrow;
    }
  }

  /// 🔄 Obtener estrictamente los modificados DESPUÉS de `ultimaSync` (UTC)
  Future<List<Map<String, dynamic>>> obtenerFiltradosOnline(
    DateTime ultimaSync,
  ) async {
    print(
      '[🏢 MENSAJES DISTRIBUIDORES SERVICE] 📥 Filtrando > $ultimaSync (UTC)',
    );
    try {
      final res = await supabase
          .from('distribuidores')
          .select()
          .gt('updated_at', ultimaSync.toUtc().toIso8601String());
      print('[🏢 MENSAJES DISTRIBUIDORES SERVICE] ✅ ${res.length} filtrados');
      return res;
    } catch (e) {
      print('[🏢 MENSAJES DISTRIBUIDORES SERVICE] ❌ Error filtrados: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 HEADS (uid, updated_at) → diff barato
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> obtenerCabecerasOnline() async {
    try {
      final res = await supabase
          .from('distribuidores')
          .select('uid, updated_at');
      return res;
    } catch (e) {
      print('[🏢 MENSAJES DISTRIBUIDORES SERVICE] ❌ Error en cabeceras: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 FETCH selectivo por UIDs (lote)
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> obtenerPorUidsOnline(
    List<String> uids,
  ) async {
    if (uids.isEmpty) return [];
    try {
      final res = await supabase
          .from('distribuidores')
          .select()
          .inFilter('uid', uids);
      return res;
    } catch (e) {
      print('[🏢 MENSAJES DISTRIBUIDORES SERVICE] ❌ Error fetch por UIDs: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 CREAR / ACTUALIZAR / ELIMINAR ONLINE
  // ---------------------------------------------------------------------------

  Future<void> upsertDistribuidorOnline(Map<String, dynamic> data) async {
    final uid = data['uid'];
    print('[🏢 MENSAJES DISTRIBUIDORES SERVICE] ⬆️ Upsert online: $uid');
    try {
      await supabase.from('distribuidores').upsert(data);
      print('[🏢 MENSAJES DISTRIBUIDORES SERVICE] ✅ Upsert $uid OK');
    } catch (e) {
      print('[🏢 MENSAJES DISTRIBUIDORES SERVICE] ❌ Error upsert $uid: $e');
      rethrow;
    }
  }

  Future<void> eliminarDistribuidorOnline(String uid) async {
    try {
      await supabase
          .from('distribuidores')
          .update({
            'deleted': true,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('uid', uid);

      print(
        '[🏢 MENSAJES DISTRIBUIDORES SERVICE] Distribuidor $uid marcado como eliminado online',
      );
    } catch (e) {
      print(
        '[🏢 MENSAJES DISTRIBUIDORES SERVICE] ❌ Error eliminando distribuidor: $e',
      );
      rethrow;
    }
  }
}

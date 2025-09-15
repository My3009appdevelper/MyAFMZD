// ignore_for_file: avoid_print

import 'package:myafmzd/database/app_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GruposDistribuidoresService {
  final SupabaseClient supabase;

  GruposDistribuidoresService(AppDatabase db)
    : supabase = Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // 📌 COMPROBAR ACTUALIZACIONES ONLINE
  // ---------------------------------------------------------------------------
  Future<DateTime?> comprobarActualizacionesOnline() async {
    try {
      final response = await supabase
          .from('grupos_distribuidores')
          .select('updated_at')
          .order('updated_at', ascending: false)
          .limit(1);

      if (response.isEmpty || response.first['updated_at'] == null) {
        print(
          '[🧑‍🤝‍🧑 MENSAJES GRUPOS SERVICE] ❌ No hay updated_at en Supabase',
        );
        return null;
      }

      return DateTime.parse(response.first['updated_at']).toUtc();
    } catch (e) {
      print(
        '[🧑‍🤝‍🧑 MENSAJES GRUPOS SERVICE] ❌ Error comprobando actualizaciones: $e',
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 OBTENER TODOS / FILTRADOS ONLINE
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> obtenerTodosOnline() async {
    print(
      '[🧑‍🤝‍🧑 MENSAJES GRUPOS SERVICE] 📥 Obteniendo TODOS los grupos online…',
    );
    try {
      final res = await supabase.from('grupos_distribuidores').select();
      print('[🧑‍🤝‍🧑 MENSAJES GRUPOS SERVICE] ✅ ${res.length} filas');
      return res;
    } catch (e) {
      print('[🧑‍🤝‍🧑 MENSAJES GRUPOS SERVICE] ❌ Error obtener todos: $e');
      rethrow;
    }
  }

  /// 🔄 Obtener estrictamente los modificados DESPUÉS de `ultimaSync` (UTC)
  Future<List<Map<String, dynamic>>> obtenerFiltradosOnline(
    DateTime ultimaSync,
  ) async {
    print(
      '[🧑‍🤝‍🧑 MENSAJES GRUPOS SERVICE] 📥 Filtrando > $ultimaSync (UTC)',
    );
    try {
      final res = await supabase
          .from('grupos_distribuidores')
          .select()
          .gt('updated_at', ultimaSync.toUtc().toIso8601String());
      print('[🧑‍🤝‍🧑 MENSAJES GRUPOS SERVICE] ✅ ${res.length} filtrados');
      return res;
    } catch (e) {
      print('[🧑‍🤝‍🧑 MENSAJES GRUPOS SERVICE] ❌ Error filtrados: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 HEADS (uid, updated_at) → diff barato
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> obtenerCabecerasOnline() async {
    try {
      final res = await supabase
          .from('grupos_distribuidores')
          .select('uid, updated_at');
      return res;
    } catch (e) {
      print('[🧑‍🤝‍🧑 MENSAJES GRUPOS SERVICE] ❌ Error en cabeceras: $e');
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
          .from('grupos_distribuidores')
          .select()
          .inFilter('uid', uids);
      return res;
    } catch (e) {
      print('[🧑‍🤝‍🧑 MENSAJES GRUPOS SERVICE] ❌ Error fetch por UIDs: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 CREAR / ACTUALIZAR / ELIMINAR ONLINE
  // ---------------------------------------------------------------------------

  Future<void> upsertGrupoOnline(Map<String, dynamic> data) async {
    final uid = data['uid'];
    print('[🧑‍🤝‍🧑 MENSAJES GRUPOS SERVICE] ⬆️ Upsert online grupo: $uid');
    try {
      await supabase.from('grupos_distribuidores').upsert(data);
      print('[🧑‍🤝‍🧑 MENSAJES GRUPOS SERVICE] ✅ Upsert $uid OK');
    } catch (e) {
      print('[🧑‍🤝‍🧑 MENSAJES GRUPOS SERVICE] ❌ Error upsert $uid: $e');
      rethrow;
    }
  }

  Future<void> eliminarGrupoOnline(String uid) async {
    try {
      await supabase
          .from('grupos_distribuidores')
          .update({
            'deleted': true,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('uid', uid);

      print(
        '[🧑‍🤝‍🧑 MENSAJES GRUPOS SERVICE] Grupo $uid marcado como eliminado online',
      );
    } catch (e) {
      print('[🧑‍🤝‍🧑 MENSAJES GRUPOS SERVICE] ❌ Error eliminando grupo: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 🔎 Consultas ONLINE específicas (opcionales)
  // ---------------------------------------------------------------------------

  /// Buscar NO eliminados por nombre/abreviatura (ilike)
  Future<List<Map<String, dynamic>>> buscarPorTextoOnline(String query) async {
    final q = '%${query.trim()}%';
    try {
      final res = await supabase
          .from('grupos_distribuidores')
          .select()
          .eq('deleted', false)
          .or('nombre.ilike.$q,abreviatura.ilike.$q')
          .order('nombre', ascending: true);
      return res;
    } catch (e) {
      print('[🧑‍🤝‍🧑 MENSAJES GRUPOS SERVICE] ❌ Error buscar por texto: $e');
      rethrow;
    }
  }

  /// Activar / desactivar online
  Future<void> setActivoOnline(String uid, bool activo) async {
    try {
      await supabase
          .from('grupos_distribuidores')
          .update({
            'activo': activo,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('uid', uid);
      print(
        '[🧑‍🤝‍🧑 MENSAJES GRUPOS SERVICE] 🔄 setActivo uid=$uid -> $activo',
      );
    } catch (e) {
      print('[🧑‍🤝‍🧑 MENSAJES GRUPOS SERVICE] ❌ Error setActivo: $e');
      rethrow;
    }
  }
}

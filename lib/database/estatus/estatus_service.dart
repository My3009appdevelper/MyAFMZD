// lib/database/estatus/estatus_service.dart
// ignore_for_file: avoid_print

import 'package:myafmzd/database/app_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EstatusService {
  final SupabaseClient supabase;

  EstatusService(AppDatabase db) : supabase = Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // 📌 COMPROBAR ACTUALIZACIONES ONLINE
  // ---------------------------------------------------------------------------
  Future<DateTime?> comprobarActualizacionesOnline() async {
    try {
      final res = await supabase
          .from('estatus')
          .select('updated_at')
          .order('updated_at', ascending: false)
          .limit(1);

      if (res.isEmpty || res.first['updated_at'] == null) {
        print('[🏷️ MENSAJES ESTATUS SERVICE] ❌ No hay updated_at en Supabase');
        return null;
      }
      return DateTime.parse(res.first['updated_at']).toUtc();
    } catch (e) {
      print(
        '[🏷️ MENSAJES ESTATUS SERVICE] ❌ Error comprobando actualizaciones: $e',
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 OBTENER TODOS / FILTRADOS ONLINE
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> obtenerTodosOnline() async {
    print('[🏷️ MENSAJES ESTATUS SERVICE] 📥 Obteniendo TODOS los estatus…');
    try {
      final res = await supabase.from('estatus').select();
      print('[🏷️ MENSAJES ESTATUS SERVICE] ✅ ${res.length} filas');
      return res;
    } catch (e) {
      print('[🏷️ MENSAJES ESTATUS SERVICE] ❌ Error obtener todos: $e');
      rethrow;
    }
  }

  /// 🔄 Obtener estrictamente los modificados DESPUÉS de `ultimaSync` (UTC)
  Future<List<Map<String, dynamic>>> obtenerFiltradosOnline(
    DateTime ultimaSync,
  ) async {
    print('[🏷️ MENSAJES ESTATUS SERVICE] 📥 Filtrando > $ultimaSync (UTC)');
    try {
      final res = await supabase
          .from('estatus')
          .select()
          .gt('updated_at', ultimaSync.toUtc().toIso8601String());
      print('[🏷️ MENSAJES ESTATUS SERVICE] ✅ ${res.length} filtrados');
      return res;
    } catch (e) {
      print('[🏷️ MENSAJES ESTATUS SERVICE] ❌ Error filtrados: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 HEADS (uid, updated_at) → diff barato
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> obtenerCabecerasOnline() async {
    try {
      final res = await supabase.from('estatus').select('uid, updated_at');
      return res;
    } catch (e) {
      print('[🏷️ MENSAJES ESTATUS SERVICE] ❌ Error en cabeceras: $e');
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
      final res = await supabase.from('estatus').select().inFilter('uid', uids);
      return res;
    } catch (e) {
      print('[🏷️ MENSAJES ESTATUS SERVICE] ❌ Error fetch por UIDs: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 🔎 Consultas ONLINE específicas (opcionales)
  // ---------------------------------------------------------------------------

  /// Buscar NO eliminados por nombre/categoría (ilike)
  Future<List<Map<String, dynamic>>> buscarPorTextoOnline(String query) async {
    final q = '%${query.trim()}%';
    try {
      final res = await supabase
          .from('estatus')
          .select()
          .eq('deleted', false)
          .or('nombre.ilike.$q,categoria.ilike.$q')
          .order('categoria', ascending: true)
          .order('orden', ascending: true)
          .order('nombre', ascending: true);
      return res;
    } catch (e) {
      print('[🏷️ MENSAJES ESTATUS SERVICE] ❌ Error buscar por texto: $e');
      rethrow;
    }
  }

  /// Obtener por categoría (NO eliminados)
  Future<List<Map<String, dynamic>>> obtenerPorCategoriaOnline(
    String categoria,
  ) async {
    try {
      final res = await supabase
          .from('estatus')
          .select()
          .eq('deleted', false)
          .eq('categoria', categoria)
          .order('orden', ascending: true)
          .order('nombre', ascending: true);
      return res;
    } catch (e) {
      print('[🏷️ MENSAJES ESTATUS SERVICE] ❌ Error por categoría: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 CREAR / ACTUALIZAR / ELIMINAR ONLINE
  // ---------------------------------------------------------------------------

  Future<void> upsertEstatusOnline(Map<String, dynamic> data) async {
    final uid = data['uid'];
    print('[🏷️ MENSAJES ESTATUS SERVICE] ⬆️ Upsert online estatus: $uid');
    try {
      await supabase.from('estatus').upsert(data);
      print('[🏷️ MENSAJES ESTATUS SERVICE] ✅ Upsert $uid OK');
    } catch (e) {
      print('[🏷️ MENSAJES ESTATUS SERVICE] ❌ Error upsert $uid: $e');
      rethrow;
    }
  }

  Future<void> eliminarEstatusOnline(String uid) async {
    try {
      await supabase
          .from('estatus')
          .update({
            'deleted': true,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('uid', uid);
      print(
        '[🏷️ MENSAJES ESTATUS SERVICE] Estatus $uid marcado como eliminado online',
      );
    } catch (e) {
      print('[🏷️ MENSAJES ESTATUS SERVICE] ❌ Error eliminando estatus: $e');
      rethrow;
    }
  }

  /// Cambiar visibilidad (toca updated_at para propagar a clientes)
  Future<void> setVisibleOnline(String uid, bool visible) async {
    try {
      await supabase
          .from('estatus')
          .update({
            'visible': visible,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('uid', uid);
      print(
        '[🏷️ MENSAJES ESTATUS SERVICE] 🔄 setVisible uid=$uid -> $visible',
      );
    } catch (e) {
      print('[🏷️ MENSAJES ESTATUS SERVICE] ❌ Error setVisible: $e');
      rethrow;
    }
  }

  /// Cambiar campo 'orden' (para ordenar en UI)
  Future<void> setOrdenOnline(String uid, int orden) async {
    try {
      await supabase
          .from('estatus')
          .update({
            'orden': orden,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('uid', uid);
      print('[🏷️ MENSAJES ESTATUS SERVICE] 🔄 setOrden uid=$uid -> $orden');
    } catch (e) {
      print('[🏷️ MENSAJES ESTATUS SERVICE] ❌ Error setOrden: $e');
      rethrow;
    }
  }
}

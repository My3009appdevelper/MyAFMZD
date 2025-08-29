// ignore_for_file: avoid_print
import 'package:myafmzd/database/app_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProductosService {
  final SupabaseClient supabase;

  ProductosService(AppDatabase db) : supabase = Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // 📌 COMPROBAR ACTUALIZACIONES ONLINE
  // ---------------------------------------------------------------------------

  Future<DateTime?> comprobarActualizacionesOnline() async {
    try {
      final response = await supabase
          .from('productos')
          .select('updated_at')
          .order('updated_at', ascending: false)
          .limit(1);

      if (response.isEmpty || response.first['updated_at'] == null) {
        print(
          '[🧮 MENSAJES PRODUCTOS SERVICE] ❌ No hay updated_at en Supabase',
        );
        return null;
      }

      return DateTime.parse(response.first['updated_at']).toUtc();
    } catch (e) {
      print(
        '[🧮 MENSAJES PRODUCTOS SERVICE] ❌ Error comprobando actualizaciones: $e',
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 OBTENER TODOS ONLINE
  // ---------------------------------------------------------------------------

  Future<List<Map<String, dynamic>>> obtenerTodosOnline() async {
    print(
      '[🧮 MENSAJES PRODUCTOS SERVICE] 📥 Obteniendo TODOS los productos online…',
    );
    try {
      final res = await supabase.from('productos').select();
      print('[🧮 MENSAJES PRODUCTOS SERVICE] ✅ ${res.length} filas');
      return res;
    } catch (e) {
      print('[🧮 MENSAJES PRODUCTOS SERVICE] ❌ Error obtener todos: $e');
      rethrow;
    }
  }

  /// 🔄 Obtener estrictamente los modificados DESPUÉS de `ultimaSync` (UTC)
  Future<List<Map<String, dynamic>>> obtenerFiltradosOnline(
    DateTime ultimaSync,
  ) async {
    print('[🧮 MENSAJES PRODUCTOS SERVICE] 📥 Filtrando > $ultimaSync (UTC)');
    try {
      final res = await supabase
          .from('productos')
          .select()
          .gt('updated_at', ultimaSync.toUtc().toIso8601String());
      print('[🧮 MENSAJES PRODUCTOS SERVICE] ✅ ${res.length} filtrados');
      return res;
    } catch (e) {
      print('[🧮 MENSAJES PRODUCTOS SERVICE] ❌ Error filtrados: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 HEADS (uid, updated_at) → diff barato
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> obtenerCabecerasOnline() async {
    try {
      final res = await supabase.from('productos').select('uid, updated_at');
      return res;
    } catch (e) {
      print('[🧮 MENSAJES PRODUCTOS SERVICE] ❌ Error en cabeceras: $e');
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
          .from('productos')
          .select()
          .inFilter('uid', uids);
      return res;
    } catch (e) {
      print('[🧮 MENSAJES PRODUCTOS SERVICE] ❌ Error fetch por UIDs: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 CREAR / ACTUALIZAR / ELIMINAR ONLINE
  // ---------------------------------------------------------------------------

  Future<void> upsertProductoOnline(Map<String, dynamic> data) async {
    final uid = data['uid'];
    print('[🧮 MENSAJES PRODUCTOS SERVICE] ⬆️ Upsert online producto: $uid');
    try {
      await supabase.from('productos').upsert(data);
      print('[🧮 MENSAJES PRODUCTOS SERVICE] ✅ Upsert $uid OK');
    } catch (e) {
      print('[🧮 MENSAJES PRODUCTOS SERVICE] ❌ Error upsert $uid: $e');
      rethrow;
    }
  }

  Future<void> eliminarProductoOnline(String uid) async {
    try {
      await supabase
          .from('productos')
          .update({
            'deleted': true,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('uid', uid);

      print(
        '[🧮 MENSAJES PRODUCTOS SERVICE] Producto $uid marcado como eliminado online',
      );
    } catch (e) {
      print('[🧮 MENSAJES PRODUCTOS SERVICE] ❌ Error eliminando producto: $e');
      rethrow;
    }
  }
}

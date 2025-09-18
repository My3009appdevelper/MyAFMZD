// lib/database/ventas/ventas_service.dart
// ignore_for_file: avoid_print

import 'package:myafmzd/database/app_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service exclusivo de acceso ONLINE (Supabase) para `ventas`.
/// - No toca Drift.
/// - Devuelve payloads (Map) para que el Sync/Provider decidan la persistencia local.
/// - Campos en snake_case, alineados a la tabla remota `ventas`.
class VentasService {
  final SupabaseClient supabase;

  VentasService(AppDatabase db) : supabase = Supabase.instance.client;

  String _iso(DateTime d) => d.toUtc().toIso8601String();

  // ---------------------------------------------------------------------------
  // 📌 COMPROBAR ACTUALIZACIONES ONLINE
  // ---------------------------------------------------------------------------

  /// Último `updated_at` en la tabla `ventas` (UTC).
  Future<DateTime?> comprobarActualizacionesOnline() async {
    try {
      final res = await supabase
          .from('ventas')
          .select('updated_at')
          .order('updated_at', ascending: false)
          .limit(1);

      if (res.isEmpty || res.first['updated_at'] == null) {
        print('[💸 MENSAJES VENTAS SERVICE] ❌ No hay updated_at en Supabase');
        return null;
      }
      final dt = DateTime.parse(res.first['updated_at'].toString()).toUtc();
      return dt;
    } catch (e) {
      print(
        '[💸 MENSAJES VENTAS SERVICE] ❌ Error comprobando actualizaciones: $e',
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 OBTENER ONLINE
  // ---------------------------------------------------------------------------

  /// Obtener TODAS las ventas (usa con cautela).
  Future<List<Map<String, dynamic>>> obtenerTodosOnline() async {
    print('[💸 MENSAJES VENTAS SERVICE] 📥 Obteniendo TODAS las ventas…');
    try {
      final res = await supabase.from('ventas').select();
      print('[💸 MENSAJES VENTAS SERVICE] ✅ ${res.length} ventas');
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print('[💸 MENSAJES VENTAS SERVICE] ❌ Error obtener todos: $e');
      rethrow;
    }
  }

  /// Pull incremental simple: filas con `updated_at` estrictamente posterior.
  Future<List<Map<String, dynamic>>> obtenerFiltradasOnline(
    DateTime ultimaSync,
  ) async {
    print('[💸 MENSAJES VENTAS SERVICE] 📥 Filtrando > ${_iso(ultimaSync)}');
    try {
      final res = await supabase
          .from('ventas')
          .select()
          .gt('updated_at', _iso(ultimaSync));
      print('[💸 MENSAJES VENTAS SERVICE] ✅ ${res.length} ventas filtradas');
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print('[💸 MENSAJES VENTAS SERVICE] ❌ Error filtradas: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 HEADS (uid, updated_at) → diff barato
  // ---------------------------------------------------------------------------

  /// Heads remotos: `uid, updated_at` para hacer diff barato.
  Future<List<Map<String, dynamic>>> obtenerCabecerasOnline() async {
    try {
      final res = await supabase.from('ventas').select('uid, updated_at');
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print('[💸 MENSAJES VENTAS SERVICE] ❌ Error en cabeceras: $e');
      rethrow;
    }
  }

  /// Fetch selectivo por UIDs (lotes).
  Future<List<Map<String, dynamic>>> obtenerPorUidsOnline(
    List<String> uids,
  ) async {
    if (uids.isEmpty) return [];
    try {
      final res = await supabase.from('ventas').select().inFilter('uid', uids);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print('[💸 MENSAJES VENTAS SERVICE] ❌ Error fetch por UIDs: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📤 CREAR / ACTUALIZAR / ELIMINAR ONLINE
  // ---------------------------------------------------------------------------

  /// Upsert de UNA venta (idempotente por `uid`).
  /// Espera llaves en snake_case, p. ej.:
  /// {
  ///   'uid': '...', 'distribuidora_origen_uid': '...', 'distribuidora_uid': '...',
  ///   'gerente_grupo_uid': '...', 'vendedor_uid': '...', 'folio_contrato': '...',
  ///   'modelo_uid': '...', 'estatus_uid': '...', 'grupo': 1, 'integrante': 3,
  ///   'fecha_contrato': '2025-01-01T00:00:00Z', 'fecha_venta': '...',
  ///   'mes_venta': 1, 'anio_venta': 2025, 'created_at': '...', 'updated_at': '...',
  ///   'deleted': false
  /// }
  Future<void> upsertVentaOnline(Map<String, dynamic> data) async {
    final uid = data['uid'];
    print('[💸 MENSAJES VENTAS SERVICE] ⬆️ Upsert venta: $uid');
    try {
      await supabase.from('ventas').upsert(data);
      print('[💸 MENSAJES VENTAS SERVICE] ✅ Upsert $uid OK');
    } catch (e) {
      print('[💸 MENSAJES VENTAS SERVICE] ❌ Error upsert $uid: $e');
      rethrow;
    }
  }

  /// Upsert en lote (más eficiente para sincronizaciones grandes).
  Future<void> upsertVentasOnline(List<Map<String, dynamic>> lista) async {
    if (lista.isEmpty) return;
    print(
      '[💸 MENSAJES VENTAS SERVICE] ⬆️ Upsert lote: ${lista.length} ventas',
    );
    try {
      await supabase.from('ventas').upsert(lista);
      print('[💸 MENSAJES VENTAS SERVICE] ✅ Lote OK');
    } catch (e) {
      print('[💸 MENSAJES VENTAS SERVICE] ❌ Error upsert lote: $e');
      rethrow;
    }
  }

  /// Soft-delete remoto (marca `deleted=true` y toca `updated_at`).
  Future<void> eliminarVentaOnline(String uid) async {
    print('[💸 MENSAJES VENTAS SERVICE] 🗑️ Soft delete venta: $uid');
    try {
      await supabase
          .from('ventas')
          .update({'deleted': true, 'updated_at': _iso(DateTime.now())})
          .eq('uid', uid);
      print('[💸 MENSAJES VENTAS SERVICE] ✅ Marcado eliminado: $uid');
    } catch (e) {
      print('[💸 MENSAJES VENTAS SERVICE] ❌ Error eliminar $uid: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 🔎 UTILIDADES (validaciones remotas)
  // ---------------------------------------------------------------------------

  /// Verificar existencia de folio en remoto (útil para evitar duplicados).
  /// Si [excluirUid] viene, lo excluye del set (ediciones).
  Future<bool> existeFolioOnline(
    String folioContrato, {
    String? excluirUid,
  }) async {
    try {
      final q = supabase
          .from('ventas')
          .select('uid')
          .eq('folio_contrato', folioContrato)
          .eq('deleted', false);

      final res = excluirUid == null || excluirUid.isEmpty
          ? await q
          : await q.neq('uid', excluirUid);

      final rows = List<Map<String, dynamic>>.from(res);
      return rows.isNotEmpty;
    } catch (e) {
      print('[💸 MENSAJES VENTAS SERVICE] ❌ Error existeFolioOnline: $e');
      rethrow;
    }
  }
}

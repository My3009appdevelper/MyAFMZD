// ignore_for_file: avoid_print

import 'package:myafmzd/database/app_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AsignacionesLaboralesService {
  final SupabaseClient supabase;

  // Nombre de la tabla en Supabase (recomendado snake_case)

  AsignacionesLaboralesService(AppDatabase db)
    : supabase = Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // 📌 COMPROBAR ACTUALIZACIONES ONLINE
  // ---------------------------------------------------------------------------
  Future<DateTime?> comprobarActualizacionesOnline() async {
    try {
      final response = await supabase
          .from('asignaciones_laborales')
          .select('updated_at')
          .order('updated_at', ascending: false)
          .limit(1);

      if (response.isEmpty || response.first['updated_at'] == null) {
        print(
          '[👔 MENSAJES ASIGNACIONES SERVICE] ❌ No hay updated_at en Supabase',
        );
        return null;
      }

      final fecha = DateTime.parse(response.first['updated_at']).toUtc();
      return fecha;
    } catch (e) {
      print(
        '[👔 MENSAJES ASIGNACIONES SERVICE] ❌ Error comprobando actualizaciones: $e',
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 OBTENER TODOS / FILTRADOS ONLINE
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> obtenerTodosOnline() async {
    print(
      '[👔 MENSAJES ASIGNACIONES SERVICE] 📥 Obteniendo TODAS las asignaciones online…',
    );
    try {
      final res = await supabase.from('asignaciones_laborales').select();
      print('[👔 MENSAJES ASIGNACIONES SERVICE] ✅ ${res.length} filas');
      return res;
    } catch (e) {
      print('[👔 MENSAJES ASIGNACIONES SERVICE] ❌ Error obtener todos: $e');
      rethrow;
    }
  }

  /// 🔄 Obtener estrictamente las modificadas DESPUÉS de `ultimaSync` (UTC)
  Future<List<Map<String, dynamic>>> obtenerFiltradasOnline(
    DateTime ultimaSync,
  ) async {
    print(
      '[👔 MENSAJES ASIGNACIONES SERVICE] 📥 Filtrando > $ultimaSync (UTC)',
    );
    try {
      final res = await supabase
          .from('asignaciones_laborales')
          .select()
          .gt('updated_at', ultimaSync.toUtc().toIso8601String());
      print('[👔 MENSAJES ASIGNACIONES SERVICE] ✅ ${res.length} filtradas');
      return res;
    } catch (e) {
      print('[👔 MENSAJES ASIGNACIONES SERVICE] ❌ Error filtradas: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 HEADS (uid, updated_at) → diff barato
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> obtenerCabecerasOnline() async {
    try {
      final res = await supabase
          .from('asignaciones_laborales')
          .select('uid, updated_at');
      return res;
    } catch (e) {
      print('[👔 MENSAJES ASIGNACIONES SERVICE] ❌ Error en cabeceras: $e');
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
          .from('asignaciones_laborales')
          .select()
          .inFilter('uid', uids);
      return res;
    } catch (e) {
      print('[👔 MENSAJES ASIGNACIONES SERVICE] ❌ Error fetch por UIDs: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 CREAR / ACTUALIZAR / ELIMINAR ONLINE
  // ---------------------------------------------------------------------------

  /// Upsert genérico (envía el mapa tal cual; asume naming snake_case en Supabase).
  Future<void> upsertAsignacionLaboralOnline(Map<String, dynamic> data) async {
    final uid = data['uid'];
    print('[👔 MENSAJES ASIGNACIONES SERVICE] ⬆️ Upsert online: $uid');
    try {
      await supabase.from('asignaciones_laborales').upsert(data);
      print('[👔 MENSAJES ASIGNACIONES SERVICE] ✅ Upsert $uid OK');
    } catch (e) {
      print('[👔 MENSAJES ASIGNACIONES SERVICE] ❌ Error upsert $uid: $e');
      rethrow;
    }
  }

  /// Soft delete por UID.
  Future<void> eliminarAsignacionOnline(String uid) async {
    try {
      await supabase
          .from('asignaciones_laborales')
          .update({
            'deleted': true,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('uid', uid);

      print(
        '[👔 MENSAJES ASIGNACIONES SERVICE] Asignación $uid marcada como eliminada online',
      );
    } catch (e) {
      print('[👔 MENSAJES ASIGNACIONES SERVICE] ❌ Error eliminando: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 🔧 Helpers ONLINE (propios de este dominio)
  // ---------------------------------------------------------------------------

  /// Cierra TODAS las asignaciones ACTIVAS (fecha_fin IS NULL) de un colaborador.
  Future<int> cerrarActivasDeColaboradorOnline({
    required String colaboradorUid,
    DateTime? fechaFin,
    String? closedByUsuarioUid,
  }) async {
    final fin = (fechaFin ?? DateTime.now().toUtc()).toIso8601String();
    try {
      final res = await supabase
          .from('asignaciones_laborales')
          .update({
            'fecha_fin': fin,
            if (closedByUsuarioUid != null)
              'closed_by_usuario_uid': closedByUsuarioUid,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .match({'colaborador_uid': colaboradorUid, 'deleted': false});
      // Supabase devuelve las filas afectadas; puedes inferir count
      final count = (res as List).length;
      print(
        '[👔 MENSAJES ASIGNACIONES SERVICE] 🔒 Cerradas $count activas de colaborador=$colaboradorUid',
      );
      return count;
    } catch (e) {
      print('[👔 MENSAJES ASIGNACIONES SERVICE] ❌ Error cerrando activas: $e');
      rethrow;
    }
  }

  /// Cierra una asignación específica por UID (si está activa).
  Future<void> cerrarAsignacionPorUidOnline({
    required String uid,
    DateTime? fechaFin,
    String? closedByUsuarioUid,
  }) async {
    final fin = (fechaFin ?? DateTime.now().toUtc()).toIso8601String();
    try {
      await supabase
          .from('asignaciones_laborales')
          .update({
            'fecha_fin': fin,
            if (closedByUsuarioUid != null)
              'closed_by_usuario_uid': closedByUsuarioUid,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('uid', uid);
      print(
        '[👔 MENSAJES ASIGNACIONES SERVICE] 🔒 Cerrada asignación uid=$uid',
      );
    } catch (e) {
      print('[👔 MENSAJES ASIGNACIONES SERVICE] ❌ Error cerrando uid=$uid: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 🔎 Consultas ONLINE específicas (opcionales, pero útiles)
  // ---------------------------------------------------------------------------

  /// Activa (si existe) de un colaborador.
  Future<Map<String, dynamic>?> obtenerActivaPorColaboradorOnline(
    String colaboradorUid,
  ) async {
    try {
      final res = await supabase
          .from('asignaciones_laborales')
          .select()
          .eq('colaborador_uid', colaboradorUid)
          .isFilter('fecha_fin', null)
          .eq('deleted', false)
          .order('fecha_inicio', ascending: false)
          .limit(1);
      return res.isNotEmpty ? res.first : null;
    } catch (e) {
      print(
        '[👔 MENSAJES ASIGNACIONES SERVICE] ❌ Error obtener activa por colaborador: $e',
      );
      rethrow;
    }
  }

  /// Activas por distribuidor y rol (rol opcional).
  Future<List<Map<String, dynamic>>> obtenerActivasPorDistribuidorYRolOnline({
    required String distribuidorUid,
    String? rol,
  }) async {
    try {
      final q = supabase
          .from('asignaciones_laborales')
          .select()
          .eq('distribuidor_uid', distribuidorUid)
          .isFilter('fecha_fin', null)
          .eq('deleted', false);

      final res = rol == null || rol.isEmpty ? await q : await q.eq('rol', rol);
      return res;
    } catch (e) {
      print(
        '[👔 MENSAJES ASIGNACIONES SERVICE] ❌ Error obtener activas por distribuidor/rol: $e',
      );
      rethrow;
    }
  }

  /// Vigentes en una fecha dada (fecha_inicio ≤ fecha ≤ fecha_fin o abierta).
  Future<List<Map<String, dynamic>>> obtenerVigentesEnFechaOnline(
    DateTime fecha,
  ) async {
    final f = fecha.toUtc().toIso8601String();
    try {
      final res = await supabase
          .from('asignaciones_laborales')
          .select()
          .lte('fecha_inicio', f)
          .or('fecha_fin.is.null,fecha_fin.gte.$f')
          .eq('deleted', false);
      return res;
    } catch (e) {
      print(
        '[👔 MENSAJES ASIGNACIONES SERVICE] ❌ Error obtener vigentes en fecha: $e',
      );
      rethrow;
    }
  }
}

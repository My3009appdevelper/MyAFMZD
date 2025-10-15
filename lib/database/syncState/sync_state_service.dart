// lib/database/sync_state/sync_state_service.dart
// ignore_for_file: avoid_print
import 'package:myafmzd/database/app_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SyncStateService {
  final SupabaseClient supabase;

  SyncStateService(AppDatabase db) : supabase = Supabase.instance.client;

  String _iso(DateTime d) => d.toUtc().toIso8601String();
  static const int _pageSize = 1000;

  // ────────────────────────────────────────────────────────────────────────────
  // 📌 COMPROBAR ACTUALIZACIONES ONLINE (max updated_at global)
  // ────────────────────────────────────────────────────────────────────────────
  Future<DateTime?> comprobarActualizacionesOnline() async {
    try {
      final res = await supabase
          .from('sync_state')
          .select('updated_at')
          .order('updated_at', ascending: false)
          .limit(1);
      if (res.isEmpty || res.first['updated_at'] == null) return null;
      return DateTime.parse(res.first['updated_at'].toString()).toUtc();
    } catch (e) {
      print('[💠 SYNC_STATE SERVICE] ❌ Error comprobando actualizaciones: $e');
      return null;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // 📌 OBTENER ONLINE (paginado)
  // ────────────────────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> obtenerTodosOnline() async {
    final out = <Map<String, dynamic>>[];
    try {
      int from = 0;
      while (true) {
        final to = from + _pageSize - 1;
        final page = await supabase
            .from('sync_state')
            .select()
            .order('updated_at', ascending: true)
            .range(from, to);
        final batch = List<Map<String, dynamic>>.from(page);
        out.addAll(batch);
        if (batch.length < _pageSize) break;
        from += _pageSize;
      }
      return out;
    } catch (e) {
      print('[💠 SYNC_STATE SERVICE] ❌ Error obtener todos: $e');
      rethrow;
    }
  }

  /// Filtrados estrictamente después de `ultimaSync` (UTC)
  Future<List<Map<String, dynamic>>> obtenerFiltradosOnline(
    DateTime ultimaSync,
  ) async {
    final ts = _iso(ultimaSync);
    final out = <Map<String, dynamic>>[];
    try {
      int from = 0;
      while (true) {
        final to = from + _pageSize - 1;
        final page = await supabase
            .from('sync_state')
            .select()
            .gt('updated_at', ts)
            .order('updated_at', ascending: true)
            .range(from, to);
        final batch = List<Map<String, dynamic>>.from(page);
        out.addAll(batch);
        if (batch.length < _pageSize) break;
        from += _pageSize;
      }
      return out;
    } catch (e) {
      print('[💠 SYNC_STATE SERVICE] ❌ Error filtrados: $e');
      rethrow;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // 📌 HEADS (resource, updated_at) y FETCH selectivo
  // ────────────────────────────────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> obtenerCabecerasOnline() async {
    try {
      final res = await supabase
          .from('sync_state')
          .select('resource, updated_at');
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print('[💠 SYNC_STATE SERVICE] ❌ Error en cabeceras: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> obtenerPorResourcesOnline(
    List<String> resources,
  ) async {
    if (resources.isEmpty) return [];
    try {
      final res = await supabase
          .from('sync_state')
          .select()
          .inFilter('resource', resources);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print('[💠 SYNC_STATE SERVICE] ❌ Error fetch por resources: $e');
      rethrow;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // 📤 CREAR / ACTUALIZAR / TOCAR ONLINE
  // ────────────────────────────────────────────────────────────────────────────
  Future<DateTime?> obtenerMarcaRemotaOnline({required String resource}) async {
    try {
      final res = await supabase
          .from('sync_state')
          .select('updated_at')
          .eq('resource', resource)
          .limit(1);
      if (res.isEmpty || res.first['updated_at'] == null) return null;
      return DateTime.parse(res.first['updated_at'].toString()).toUtc();
    } catch (e) {
      print('[💠 SYNC_STATE SERVICE] ❌ Error leyendo marca "$resource": $e');
      return null;
    }
  }

  Future<void> upsertMarcaRemotaOnline({
    required String resource,
    required DateTime updatedAt,
  }) async {
    try {
      await supabase.from('sync_state').upsert({
        'resource': resource,
        'updated_at': _iso(updatedAt),
      });
    } catch (e) {
      print('[💠 SYNC_STATE SERVICE] ❌ Error upsert "$resource": $e');
      rethrow;
    }
  }

  /// Batch
  Future<void> upsertMarcasRemotasOnline(
    Map<String, DateTime> resourceToUpdatedAt,
  ) async {
    if (resourceToUpdatedAt.isEmpty) return;
    final payload = resourceToUpdatedAt.entries
        .map((e) => {'resource': e.key, 'updated_at': _iso(e.value)})
        .toList();
    try {
      await supabase.from('sync_state').upsert(payload);
    } catch (e) {
      print('[💠 SYNC_STATE SERVICE] ❌ Error upsert batch: $e');
      rethrow;
    }
  }

  /// "Touch" remoto con NOW(); útil si no tienes trigger
  Future<void> touchRemotoAhora({required String resource}) async {
    try {
      await supabase
          .from('sync_state')
          .update({'updated_at': _iso(DateTime.now())})
          .eq('resource', resource);
    } catch (e) {
      print('[💠 SYNC_STATE SERVICE] ❌ Error touch "$resource": $e');
      rethrow;
    }
  }
}

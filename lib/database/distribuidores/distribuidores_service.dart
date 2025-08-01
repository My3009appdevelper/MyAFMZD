// ignore_for_file: avoid_print

import 'package:myafmzd/database/app_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DistribuidoresService {
  final SupabaseClient _client;

  DistribuidoresService(AppDatabase db) : _client = Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // 📌 COMPROBAR ACTUALIZACIONES ONLINE
  // ---------------------------------------------------------------------------

  Future<DateTime?> comprobarActualizacionesOnline() async {
    try {
      final response = await _client
          .from('distribuidores')
          .select('updated_at')
          .order('updated_at', ascending: false)
          .limit(1);

      if (response.isEmpty || response.first['updated_at'] == null) {
        print('[📡 DISTRIBUIDORES SERVICE] ❌ No hay updated_at en Supabase');
        return null;
      }

      final ts = DateTime.parse(response.first['updated_at']);
      print('[📡 DISTRIBUIDORES SERVICE] ⏱️ Última actualización online: $ts');
      return ts;
    } catch (e) {
      print(
        '[📡 DISTRIBUIDORES SERVICE] ❌ Error comprobando actualizaciones: $e',
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 OBTENER TODOS ONLINE
  // ---------------------------------------------------------------------------

  Future<List<DistribuidorDb>> obtenerFiltradosOnline({
    DateTime? ultimaSync,
  }) async {
    try {
      print('[📡 DISTRIBUIDORES SERVICE] Descargando distribuidores online...');

      var query = _client.from('distribuidores').select();

      if (ultimaSync != null) {
        query = query.gte('updated_at', ultimaSync.toUtc());
        print('[📡 DISTRIBUIDORES SERVICE] Delta Sync desde $ultimaSync');
      }

      final data = await query;

      final lista = (data as List)
          .map(
            (row) => DistribuidorDb(
              uid: row['uid'],
              nombre: row['nombre'] ?? '',
              grupo: row['grupo'] ?? 'AFMZD',
              direccion: row['direccion'] ?? '',
              activo: row['activo'] ?? true,
              latitud: (row['latitud'] ?? 0.0).toDouble(),
              longitud: (row['longitud'] ?? 0.0).toDouble(),
              updatedAt: DateTime.parse(row['updated_at']),
              deleted: row['deleted'] ?? false,
              isSynced: true,
            ),
          )
          .toList();

      print(
        '[📡 DISTRIBUIDORES SERVICE] ✅ ${lista.length} distribuidores obtenidos',
      );
      return lista;
    } catch (e) {
      print(
        '[📡 DISTRIBUIDORES SERVICE] ❌ Error obteniendo distribuidores: $e',
      );
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 CREAR / ACTUALIZAR / ELIMINAR ONLINE
  // ---------------------------------------------------------------------------

  Future<void> upsertDistribuidorOnline(DistribuidorDb distribuidor) async {
    try {
      await _client.from('distribuidores').upsert({
        'uid': distribuidor.uid,
        'nombre': distribuidor.nombre,
        'grupo': distribuidor.grupo,
        'direccion': distribuidor.direccion,
        'activo': distribuidor.activo,
        'latitud': distribuidor.latitud,
        'longitud': distribuidor.longitud,
        'deleted': distribuidor.deleted,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      print(
        '[⬆️ DISTRIBUIDORES SERVICE] Distribuidor ${distribuidor.uid} subido online',
      );
    } catch (e) {
      print('[⬆️ DISTRIBUIDORES SERVICE] ❌ Error subiendo distribuidor: $e');
      rethrow;
    }
  }

  Future<void> eliminarDistribuidorOnline(String uid) async {
    try {
      await _client
          .from('distribuidores')
          .update({
            'deleted': true,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('uid', uid);

      print(
        '[🗑️ DISTRIBUIDORES SERVICE] Distribuidor $uid marcado como eliminado online',
      );
    } catch (e) {
      print('[🗑️ DISTRIBUIDORES SERVICE] ❌ Error eliminando distribuidor: $e');
      rethrow;
    }
  }
}

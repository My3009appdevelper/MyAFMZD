// ignore_for_file: avoid_print

import 'dart:io';
import 'package:myafmzd/database/app_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';

class ReportesService {
  final SupabaseClient _client;

  ReportesService(AppDatabase db) : _client = Supabase.instance.client;

  static const _bucket =
      'reportes-pdf'; // 🔑 Ajusta el nombre de tu bucket en Supabase

  // ---------------------------------------------------------------------------
  // 📌 COMPROBAR ACTUALIZACIONES ONLINE
  // ---------------------------------------------------------------------------

  Future<DateTime?> comprobarActualizacionesOnline() async {
    try {
      final response = await _client
          .from('reportes')
          .select('updated_at')
          .order('updated_at', ascending: false)
          .limit(1);

      if (response.isEmpty || response.first['updated_at'] == null) {
        print('[📡 REPORTES SERVICE] ❌ No hay updated_at en Supabase');
        return null;
      }

      final ts = DateTime.parse(response.first['updated_at']);
      print('[📡 REPORTES SERVICE] ⏱️ Última actualización online: $ts');
      return ts;
    } catch (e) {
      print('[📡 REPORTES SERVICE] ❌ Error comprobando actualizaciones: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 OBTENER TODOS ONLINE
  // ---------------------------------------------------------------------------

  Future<List<ReportesDb>> obtenerFiltradosOnline({
    DateTime? ultimaSync,
  }) async {
    try {
      print('[📡 REPORTES SERVICE] Buscando filtrados reportes online...');

      var query = _client.from('reportes').select();

      if (ultimaSync != null) {
        query = query.gte('updated_at', ultimaSync.toUtc());
        print('[📡 REPORTES SERVICE] Delta Sync desde $ultimaSync');
      }

      final data = await query;

      final lista = (data as List)
          .map(
            (row) => ReportesDb(
              uid: row['uid'],
              nombre: row['nombre'] ?? '',
              fecha: DateTime.parse(row['fecha']).toUtc(),
              rutaRemota: row['ruta_remota'] ?? '',
              rutaLocal: row['ruta_local'] ?? '',
              tipo: row['tipo'] ?? '',
              updatedAt: DateTime.parse(row['updated_at']).toUtc(),
              deleted: row['deleted'] ?? false,
              isSynced: true,
            ),
          )
          .toList();

      print('[📡 REPORTES SERVICE] ✅ ${lista.length} reportes obtenidos');
      return lista;
    } catch (e) {
      print('[📡 REPORTES SERVICE] ❌ Error obteniendo reportes: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📤 PUSH: Subir un solo reporte (upsert)
  // ---------------------------------------------------------------------------
  Future<void> upsertReporteOnline(ReportesDb reporte) async {
    try {
      await _client.from('reportes').upsert({
        'uid': reporte.uid,
        'nombre': reporte.nombre,
        'fecha': reporte.fecha.toUtc().toIso8601String(),
        'ruta_remota': reporte.rutaRemota,
        'tipo': reporte.tipo,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
        'deleted': reporte.deleted,
      });
      print('[📡 REPORTES SERVICE] Reporte ${reporte.uid} upsert online');
    } catch (e) {
      print('[📡 REPORTES SERVICE] ❌ Error subiendo usuario: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 🗑️ Eliminar reporte remoto (soft delete)
  // ---------------------------------------------------------------------------
  Future<void> eliminarReporteOnline(String uid) async {
    await _client
        .from('reportes')
        .update({
          'deleted': true,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('uid', uid);
  }

  // ---------------------------------------------------------------------------
  // 📥 Descargar PDF desde Supabase Storage
  // ---------------------------------------------------------------------------
  Future<File?> descargarPDFOnline(String rutaRemota) async {
    try {
      print('[🔗REPORTE SERVICE] rutaRemota original: "$rutaRemota"');

      final cleanPath = rutaRemota.startsWith('/')
          ? rutaRemota.substring(1)
          : rutaRemota;
      print('[🔗REPORTE SERVICE] Intentando descargar: [$cleanPath]');

      final response = await _client.storage.from(_bucket).download(cleanPath);
      final dir = await getApplicationDocumentsDirectory();
      final safeName = rutaRemota.replaceAll('/', '_');
      final file = File('${dir.path}/$safeName');
      await file.writeAsBytes(response);

      return file;
    } catch (e) {
      print('[🔗REPORTE SERVICE] ❌ Error al descargar PDF: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 📤 Subir PDF a Supabase Storage
  // ---------------------------------------------------------------------------
  Future<String?> uploadPDFOnline(File archivo, String rutaRemota) async {
    try {
      await _client.storage.from(_bucket).upload(rutaRemota, archivo);
      return rutaRemota;
    } catch (e) {
      print('[🔗REPORTE SERVICE] ❌ Error al subir PDF: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 🗑️ Eliminar PDF de Supabase Storage
  // ---------------------------------------------------------------------------
  Future<void> eliminarPDFOnline(String rutaRemota) async {
    try {
      await _client.storage.from(_bucket).remove([rutaRemota]);
    } catch (e) {
      print('❌ Error al eliminar PDF: $e');
    }
  }
}

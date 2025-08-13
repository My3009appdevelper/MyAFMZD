// ignore_for_file: avoid_print

import 'dart:io';
import 'package:myafmzd/database/app_database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';

class ReportesService {
  final SupabaseClient supabase;

  ReportesService(AppDatabase db) : supabase = Supabase.instance.client;

  static const _bucket =
      'reportes-pdf'; // 🔑 Ajusta el nombre de tu bucket en Supabase

  // ---------------------------------------------------------------------------
  // 📌 COMPROBAR ACTUALIZACIONES ONLINE
  // ---------------------------------------------------------------------------

  Future<DateTime?> comprobarActualizacionesOnline() async {
    try {
      final response = await supabase
          .from('reportes')
          .select('updated_at')
          .order('updated_at', ascending: false)
          .limit(1);

      if (response.isEmpty || response.first['updated_at'] == null) {
        print('[🧾 MENSAJES REPORTES SERVICE] ❌ No hay updated_at en Supabase');
        return null;
      }

      final fecha = DateTime.parse(response.first['updated_at']).toUtc();
      print(
        '[🧾 MENSAJES REPORTES SERVICE] ⏱️ Última actualización online: $fecha',
      );
      return fecha;
    } catch (e) {
      print(
        '[🧾 MENSAJES REPORTES SERVICE] ❌ Error comprobando actualizaciones: $e',
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 OBTENER TODOS ONLINE
  // ---------------------------------------------------------------------------

  /// 🔄 Obtener todos los reportes desde Supabase.
  Future<List<Map<String, dynamic>>> obtenerTodosOnline() async {
    print(
      '[🧾 MENSAJES REPORTES SERVICE] 📥 Obteniendo TODOS los reportes online...',
    );
    try {
      final response = await supabase.from('reportes').select();
      print(
        '[🧾 MENSAJES REPORTES SERVICE] ✅ ${response.length} reportes obtenidos',
      );
      return response;
    } catch (e) {
      print('[🧾 MENSAJES REPORTES SERVICE] ❌ Error al obtener todos: $e');
      rethrow;
    }
  }

  /// 🔄 Obtener reportes actualizados estrictamente DESPUÉS de `ultimaSync` (UTC).
  /// Útil para un pull incremental si NO usas heads→diff.
  Future<List<Map<String, dynamic>>> obtenerFiltradosOnline(
    DateTime ultimaSync,
  ) async {
    print('[🧾 MENSAJES REPORTES SERVICE] 📥 Filtrando > $ultimaSync (UTC)');
    try {
      final response = await supabase
          .from('reportes')
          .select()
          .gt('updated_at', ultimaSync.toUtc().toIso8601String());
      print(
        '[🧾 MENSAJES REPORTES SERVICE] ✅ ${response.length} filtrados obtenidos',
      );
      return response;
    } catch (e) {
      print('[🧾 MENSAJES REPORTES SERVICE] ❌ Error al filtrar: $e');
      rethrow;
    }
  }

  /// 1) Heads: solo `uid` y `updated_at` (barato para diff).
  Future<List<Map<String, dynamic>>> obtenerCabecerasOnline() async {
    try {
      final res = await supabase.from('reportes').select('uid, updated_at');
      return res;
    } catch (e) {
      print('[🧾 MENSAJES REPORTES SERVICE] ❌ Error en cabezeras: $e');
      rethrow;
    }
  }

  /// 2) Fetch selectivo por lote: filas completas solo de los UIDs necesarios.
  Future<List<Map<String, dynamic>>> obtenerPorUidsOnline(
    List<String> uids,
  ) async {
    if (uids.isEmpty) return [];
    try {
      final res = await supabase
          .from('reportes')
          .select()
          .inFilter('uid', uids);
      return res;
    } catch (e) {
      print('[🧾 MENSAJES REPORTES SERVICE] ❌ Error fetch por UIDs: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📤 PUSH: Subir un solo reporte (upsert)
  // ---------------------------------------------------------------------------
  Future<void> upsertReporteOnline(Map<String, dynamic> data) async {
    final uid = data['uid'];
    print('[🧾 MENSAJES REPORTES SERVICE] ⬆️ Upsert online reporte: $uid');
    try {
      await supabase.from('reportes').upsert(data);
      print('[🧾 MENSAJES REPORTES SERVICE] ✅ Upsert $uid OK');
    } catch (e) {
      print('[🧾 MENSAJES REPORTES SERVICE] ❌ Error upsert $uid: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 🗑️ Eliminar reporte remoto (soft delete)
  // ---------------------------------------------------------------------------
  Future<void> eliminarReporteOnline(String uid) async {
    print('[🧾 MENSAJES REPORTES SERVICE] 🗑️ Soft delete reporte: $uid');
    try {
      await supabase
          .from('reportes')
          .update({
            'deleted': true,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('uid', uid);
      print('[🧾 MENSAJES REPORTES SERVICE] ✅ Marcado como eliminado: $uid');
    } catch (e) {
      print('[🧾 MENSAJES REPORTES SERVICE] ❌ Error al eliminar $uid: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📥 Descargar PDF desde Supabase Storage
  // ---------------------------------------------------------------------------
  Future<File?> descargarPDFOnline(String rutaRemota) async {
    try {
      print(
        '[🧾 MENSAJES REPORTES SERVICE] rutaRemota original: "$rutaRemota"',
      );

      final cleanPath = rutaRemota.startsWith('/')
          ? rutaRemota.substring(1)
          : rutaRemota;
      print(
        '[🧾 MENSAJES REPORTES SERVICE] Intentando descargar: [$cleanPath]',
      );

      final response = await supabase.storage.from(_bucket).download(cleanPath);
      final dir = await getApplicationDocumentsDirectory();
      final safeName = rutaRemota.replaceAll('/', '_');
      final file = File('${dir.path}/$safeName');
      await file.writeAsBytes(response);

      return file;
    } catch (e) {
      print('[🧾 MENSAJES REPORTES SERVICE] ❌ Error al descargar PDF: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 📤 Subir PDF a Supabase Storage
  // ---------------------------------------------------------------------------
  Future<String?> uploadPDFOnline(File archivo, String rutaRemota) async {
    try {
      await supabase.storage.from(_bucket).upload(rutaRemota, archivo);
      return rutaRemota;
    } catch (e) {
      print('[🧾 MENSAJES REPORTES SERVICE] ❌ Error al subir PDF: $e');
      return null;
    }
  }
}

// ignore_for_file: avoid_print

import 'dart:io';
import 'package:myafmzd/database/app_database.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path_provider/path_provider.dart';

class ReportesService {
  final SupabaseClient supabase;
  static const _bucket = 'reportes-pdf';

  ReportesService(AppDatabase db) : supabase = Supabase.instance.client;

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

      return DateTime.parse(response.first['updated_at']).toUtc();
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
      final response = await supabase
          .from('reportes')
          .select('uid, updated_at');
      return response;
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
      final response = await supabase
          .from('reportes')
          .select()
          .inFilter('uid', uids);
      return response;
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
  Future<File?> descargarPDFOnline(
    String rutaRemota, {
    bool temporal = false,
  }) async {
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

      final bytes = await supabase.storage.from(_bucket).download(cleanPath);

      // 👇 Decide destino según flag
      final baseDir = temporal
          ? await getTemporaryDirectory()
          : await getApplicationSupportDirectory();

      // Subcarpeta para mantener ordenado
      final subdir = temporal ? 'pdf_tmp' : 'reports';
      final targetDir = Directory(p.join(baseDir.path, subdir));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      // Nombre de archivo seguro (sin '/')
      final safeName = rutaRemota.replaceAll('/', '_');
      final file = File(p.join(targetDir.path, safeName));

      await file.writeAsBytes(bytes);

      print('[🧾 MENSAJES REPORTES SERVICE] PDF guardado en: ${file.path}');
      return file;
    } catch (e) {
      print('[🧾 MENSAJES REPORTES SERVICE] ❌ Error al descargar PDF: $e');
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 📤 Subir PDF a Supabase Storage
  // ---------------------------------------------------------------------------

  // Nos aseguramos de que no exista
  Future<bool> existsReporte(String remotePath) async {
    final dir = p.dirname(remotePath); // e.g. "reportes/2025-02"
    final fileName = p.basename(remotePath); // e.g. "archivo.pdf"
    final items = await supabase.storage
        .from(_bucket)
        .list(path: dir); // sin 'search' en Dart
    return items.any((it) => it.name == fileName);
  }

  // Subir PDF nuevo
  Future<void> uploadPDFOnline(
    File file,
    String remotePath, {
    bool overwrite = false,
  }) async {
    try {
      await supabase.storage
          .from(_bucket)
          .upload(
            remotePath,
            file,
            fileOptions: FileOptions(
              upsert: overwrite,
              contentType:
                  'application/pdf', // si quieres sobreescribir explícitamente
            ),
          );
    } on StorageException catch (e) {
      if ((e.statusCode ?? 0) == 409 && !overwrite) {
        // Ya existe y NO queremos sobreescribir → lo tratamos como OK.
        return;
      }
      rethrow;
    }
  }
}

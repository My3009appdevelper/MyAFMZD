// ignore_for_file: avoid_print

import 'dart:io';
import 'package:myafmzd/database/app_database.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ModelosService {
  final SupabaseClient supabase;
  static const _bucketFichas = 'fichas-tecnicas-pdf';

  ModelosService(AppDatabase db) : supabase = Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // 📌 COMPROBAR ACTUALIZACIONES ONLINE
  // ---------------------------------------------------------------------------
  Future<DateTime?> comprobarActualizacionesOnline() async {
    try {
      final response = await supabase
          .from('modelos')
          .select('updated_at')
          .order('updated_at', ascending: false)
          .limit(1);

      if (response.isEmpty || response.first['updated_at'] == null) {
        print('[🚗 MENSAJES MODELOS SERVICE] ❌ No hay updated_at en Supabase');
        return null;
      }

      final fecha = DateTime.parse(response.first['updated_at']).toUtc();
      return fecha;
    } catch (e) {
      print(
        '[🚗 MENSAJES MODELOS SERVICE] ❌ Error comprobando actualizaciones: $e',
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 OBTENER TODOS ONLINE
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> obtenerTodosOnline() async {
    print(
      '[🚗 MENSAJES MODELOS SERVICE] 📥 Obteniendo TODOS los modelos online…',
    );
    try {
      final response = await supabase.from('modelos').select();
      print(
        '[🚗 MENSAJES MODELOS SERVICE] ✅ ${response.length} filas obtenidas',
      );
      return response;
    } catch (e) {
      print('[🚗 MENSAJES MODELOS SERVICE] ❌ Error obtener todos: $e');
      rethrow;
    }
  }

  /// 🔄 Obtener estrictamente los modificados DESPUÉS de `ultimaSync` (UTC)
  Future<List<Map<String, dynamic>>> obtenerFiltradosOnline(
    DateTime ultimaSync,
  ) async {
    print('[🚗 MENSAJES MODELOS SERVICE] 📥 Filtrando > $ultimaSync (UTC)');
    try {
      final response = await supabase
          .from('modelos')
          .select()
          .gt('updated_at', ultimaSync.toUtc().toIso8601String());
      print('[🚗 MENSAJES MODELOS SERVICE] ✅ ${response.length} filtrados');
      return response;
    } catch (e) {
      print('[🚗 MENSAJES MODELOS SERVICE] ❌ Error filtrados: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 HEADS (uid, updated_at) → diff barato
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> obtenerCabecerasOnline() async {
    try {
      final response = await supabase.from('modelos').select('uid, updated_at');
      return response;
    } catch (e) {
      print('[🚗 MENSAJES MODELOS SERVICE] ❌ Error en cabeceras: $e');
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
      final response = await supabase
          .from('modelos')
          .select()
          .inFilter('uid', uids);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('[🚗 MENSAJES MODELOS SERVICE] ❌ Error fetch por UIDs: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 CREAR / ACTUALIZAR / ELIMINAR ONLINE
  // ---------------------------------------------------------------------------
  Future<void> upsertModeloOnline(Map<String, dynamic> data) async {
    final uid = data['uid'];
    print('[🚗 MENSAJES MODELOS SERVICE] ⬆️ Upsert online modelo: $uid');
    try {
      await supabase.from('modelos').upsert(data);
      print('[🚗 MENSAJES MODELOS SERVICE] ✅ Upsert $uid OK');
    } catch (e) {
      print('[🚗 MENSAJES MODELOS SERVICE] ❌ Error upsert $uid: $e');
      rethrow;
    }
  }

  Future<void> eliminarModeloOnline(String uid) async {
    try {
      await supabase
          .from('modelos')
          .update({
            'deleted': true,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('uid', uid);
      print(
        '[🚗 MENSAJES MODELOS SERVICE] Modelo $uid marcado como eliminado online',
      );
    } catch (e) {
      print('[🚗 MENSAJES MODELOS SERVICE] ❌ Error eliminando modelo: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📥 Descargar FICHA (PDF) desde Supabase Storage
  // ---------------------------------------------------------------------------
  Future<File?> descargarFichaOnline(
    String rutaRemota, {
    bool temporal = false,
  }) async {
    try {
      print('[🚗 MENSAJES MODELOS SERVICE] rutaRemota original: "$rutaRemota"');
      if (rutaRemota.trim().isEmpty) return null;

      final cleanPath = rutaRemota.startsWith('/')
          ? rutaRemota.substring(1)
          : rutaRemota;
      print(
        '[🚗 MENSAJES MODELOS SERVICE] Intentando descargar ficha: [$cleanPath]',
      );

      final bytes = await supabase.storage
          .from(_bucketFichas)
          .download(cleanPath);

      // 👇 Decide destino según flag
      final baseDir = temporal
          ? await getTemporaryDirectory()
          : await getApplicationSupportDirectory();

      // Subcarpeta para mantener ordenado
      final subdir = temporal ? 'fichas_tmp' : 'fichas';
      final targetDir = Directory(p.join(baseDir.path, subdir));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      // Nombre de archivo seguro (sin '/')
      final safeName = cleanPath.replaceAll('/', '_');
      final file = File(p.join(targetDir.path, safeName));

      await file.writeAsBytes(bytes);

      print('[🚗 MENSAJES MODELOS SERVICE] Ficha guardada en: ${file.path}');
      return file;
    } catch (e) {
      print('[🚗 MENSAJES MODELOS SERVICE] ❌ Error al descargar ficha: $e');
      return null;
    }
  }

  String _normalizePath(String p) {
    final s = p.trim();
    final noLeading = s.startsWith('/') ? s.substring(1) : s;
    return noLeading.replaceAll(RegExp(r'/+'), '/');
  }

  // ¿Existe ya el archivo en Storage?
  Future<bool> existsFicha(String remotePath) async {
    final clean = _normalizePath(remotePath);
    final dir = p.dirname(clean);
    final fileName = p.basename(clean);
    final items = await supabase.storage.from(_bucketFichas).list(path: dir);
    return items.any((it) => it.name == fileName);
  }

  // Subir/actualizar ficha PDF a Storage
  Future<void> uploadFichaOnline(
    File file,
    String remotePath, {
    bool overwrite = false,
  }) async {
    try {
      final clean = _normalizePath(remotePath);

      await supabase.storage
          .from(_bucketFichas)
          .upload(
            clean,
            file,
            fileOptions: FileOptions(
              contentType: 'application/pdf',
              upsert: overwrite, // si quieres sobreescribir explícitamente
            ),
          );
    } on StorageException catch (e) {
      if ((e.statusCode ?? 0) == 409 && !overwrite) {
        // Ya existe y NO queremos sobreescribir → OK
        return;
      }
      rethrow;
    }
  }
}

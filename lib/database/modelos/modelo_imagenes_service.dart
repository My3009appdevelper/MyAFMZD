// ignore_for_file: avoid_print

import 'dart:io';
import 'package:crypto/crypto.dart' show sha256;
import 'package:myafmzd/database/app_database.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ModeloImagenesService {
  final SupabaseClient supabase;
  static const _bucketImagenes = 'modelos-img';

  ModeloImagenesService(AppDatabase db) : supabase = Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // 📌 COMPROBAR ACTUALIZACIONES ONLINE
  // ---------------------------------------------------------------------------
  Future<DateTime?> comprobarActualizacionesOnline() async {
    try {
      final response = await supabase
          .from('modelo_imagenes')
          .select('updated_at')
          .order('updated_at', ascending: false)
          .limit(1);

      if (response.isEmpty || response.first['updated_at'] == null) {
        print(
          '[🚗👀 MENSAJES MODELO_IMAGENES SERVICE] ❌ No hay updated_at en Supabase',
        );
        return null;
      }
      return DateTime.parse(response.first['updated_at']).toUtc();
    } catch (e) {
      print(
        '[🚗👀 MENSAJES MODELO_IMAGENES SERVICE] ❌ Error comprobando actualizaciones: $e',
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 OBTENER TODOS / FILTRADOS ONLINE
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> obtenerTodosOnline() async {
    print(
      '[🚗👀 MENSAJES MODELO_IMAGENES SERVICE] 📥 Obteniendo TODAS las imágenes online…',
    );
    try {
      final response = await supabase.from('modelo_imagenes').select();
      print(
        '[🚗👀 MENSAJES MODELO_IMAGENES SERVICE] ✅ ${response.length} filas obtenidas',
      );
      return response;
    } catch (e) {
      print(
        '[🚗👀 MENSAJES MODELO_IMAGENES SERVICE] ❌ Error obtener todos: $e',
      );
      rethrow;
    }
  }

  /// 🔄 Obtener reportes actualizados estrictamente DESPUÉS de `ultimaSync` (UTC).
  /// Útil para un pull incremental si NO usas heads→diff.
  Future<List<Map<String, dynamic>>> obtenerFiltradosOnline(
    DateTime ultimaSync,
  ) async {
    print(
      '[🚗👀 MENSAJES MODELO_IMAGENES SERVICE] 📥 Filtrando > $ultimaSync (UTC)',
    );
    try {
      final response = await supabase
          .from('modelo_imagenes')
          .select()
          .gt('updated_at', ultimaSync.toUtc().toIso8601String());
      print(
        '[🚗👀 MENSAJES MODELO_IMAGENES SERVICE] ✅ ${response.length} filtrados obtenidos',
      );
      return response;
    } catch (e) {
      print('[🚗👀 MENSAJES MODELO_IMAGENES SERVICE] ❌ Error filtrados: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 HEADS y FETCH selectivo
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> obtenerCabecerasOnline() async {
    try {
      final response = await supabase
          .from('modelo_imagenes')
          .select('uid, updated_at');
      return response;
    } catch (e) {
      print('[🚗👀 MENSAJES MODELO_IMAGENES SERVICE] ❌ Error en cabeceras: $e');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> obtenerPorUidsOnline(
    List<String> uids,
  ) async {
    if (uids.isEmpty) return [];
    try {
      final response = await supabase
          .from('modelo_imagenes')
          .select()
          .inFilter('uid', uids);
      return response;
    } catch (e) {
      print(
        '[🚗👀 MENSAJES MODELO_IMAGENES SERVICE] ❌ Error fetch por UIDs: $e',
      );
      rethrow;
    }
  }

  // (Opcional) obtener por modeloUid, útil si quieres primer fetch por modelo
  Future<List<Map<String, dynamic>>> obtenerPorModeloUidOnline(
    String modeloUid,
  ) async {
    try {
      final res = await supabase
          .from('modelo_imagenes')
          .select()
          .eq('modelo_uid', modeloUid)
          .order('updated_at', ascending: true);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      print(
        '[🚗👀 MENSAJES MODELO_IMAGENES SERVICE] ❌ Error obtener por modeloUid: $e',
      );
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 CREAR / ACTUALIZAR / ELIMINAR ONLINE
  // ---------------------------------------------------------------------------
  Future<void> upsertImagenOnline(Map<String, dynamic> data) async {
    final uid = data['uid'];
    print(
      '[🚗👀 MENSAJES MODELO_IMAGENES SERVICE] ⬆️ Upsert online imagen: $uid',
    );
    try {
      await supabase.from('modelo_imagenes').upsert(data);
      print('[🚗👀 MENSAJES MODELO_IMAGENES SERVICE] ✅ Upsert $uid OK');
    } catch (e) {
      print('[🚗👀 MENSAJES MODELO_IMAGENES SERVICE] ❌ Error upsert $uid: $e');
      rethrow;
    }
  }

  Future<void> eliminarImagenOnline(String uid) async {
    try {
      await supabase
          .from('modelo_imagenes')
          .update({
            'deleted': true,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('uid', uid);
      print(
        '[🚗👀 MENSAJES MODELO_IMAGENES SERVICE] Imagen $uid marcada como eliminada online',
      );
    } catch (e) {
      print(
        '[🚗👀 MENSAJES MODELO_IMAGENES SERVICE] ❌ Error eliminando imagen: $e',
      );
      rethrow;
    }
  }

  Future<String> calcularSha256(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  // ---------------------------------------------------------------------------
  // 📥 Descargar IMAGEN desde Supabase Storage
  // ---------------------------------------------------------------------------
  Future<File?> descargarImagenOnline(
    String rutaRemota, {
    bool temporal = false,
  }) async {
    try {
      print(
        '[🚗👀 MENSAJES MODELO_IMAGENES SERVICE] rutaRemota original: "$rutaRemota"',
      );
      final path = rutaRemota.trim();
      if (path.isEmpty) {
        print('[🚗👀 MENSAJES MODELO_IMAGENES SERVICE] skip: rutaRemota vacía');
        return null;
      }
      final cleanPath = rutaRemota.startsWith('/')
          ? rutaRemota.substring(1)
          : rutaRemota;
      print(
        '[🚗👀 MENSAJES MODELO_IMAGENES SERVICE] Intentando descargar imagen: [$cleanPath]',
      );

      final bytes = await supabase.storage
          .from(_bucketImagenes)
          .download(cleanPath);

      // 👇 Decide destino según flag
      final baseDir = temporal
          ? await getTemporaryDirectory()
          : await getApplicationSupportDirectory();

      // Subcarpeta para mantener ordenado
      final subdir = temporal ? 'modelos_img_tmp' : 'modelos_img';
      final targetDir = Directory(p.join(baseDir.path, subdir));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      // Nombre de archivo seguro (sin '/')
      final safeName = cleanPath.replaceAll('/', '_');
      final file = File(p.join(targetDir.path, safeName));

      await file.writeAsBytes(bytes);

      print(
        '[🚗👀 MENSAJES MODELO_IMAGENES SERVICE] Imagen guardada en: ${file.path}',
      );
      return file;
    } catch (e) {
      print(
        '[🚗👀 MENSAJES MODELO_IMAGENES SERVICE] ❌ Error al descargar imagen: $e',
      );
      return null;
    }
  }

  // modelo_imagenes_service.dart
  String _normalizePath(String p) {
    final s = p.trim();
    final noLeading = s.startsWith('/') ? s.substring(1) : s;
    return noLeading.replaceAll(RegExp(r'/+'), '/');
  }

  // ¿Existe ya la imagen en Storage?
  Future<bool> existsImagen(String remotePath) async {
    final clean = _normalizePath(remotePath);
    final dir = p.dirname(clean);
    final fileName = p.basename(clean);
    final items = await supabase.storage.from(_bucketImagenes).list(path: dir);
    return items.any((it) => it.name == fileName);
  }

  // Subir/actualizar imagen a Storage
  Future<void> uploadImagenOnline(
    File file,
    String remotePath, {
    bool overwrite = false,
  }) async {
    final clean = _normalizePath(remotePath);
    final contentType = _guessImageContentTypeByExt(clean);
    try {
      await supabase.storage
          .from(_bucketImagenes)
          .upload(
            clean,
            file,
            fileOptions: FileOptions(
              upsert: overwrite,
              contentType: contentType,
            ),
          );
    } on StorageException catch (e) {
      if ((e.statusCode ?? 0) == 409 && !overwrite) return;
      rethrow;
    }
  }

  String _guessImageContentTypeByExt(String path) {
    final ext = p.extension(path).toLowerCase();
    switch (ext) {
      case '.png':
        return 'image/png';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.webp':
        return 'image/webp';
      default:
        return 'application/octet-stream';
    }
  }
}

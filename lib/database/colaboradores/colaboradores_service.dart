// ignore_for_file: avoid_print

import 'dart:io';
import 'package:crypto/crypto.dart' show sha256;
import 'package:myafmzd/database/app_database.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ColaboradoresService {
  final SupabaseClient supabase;
  static const _bucketImagenes = 'colaboradores-img';

  ColaboradoresService(AppDatabase db) : supabase = Supabase.instance.client;

  // ---------------------------------------------------------------------------
  // 📌 COMPROBAR ACTUALIZACIONES ONLINE
  // ---------------------------------------------------------------------------
  Future<DateTime?> comprobarActualizacionesOnline() async {
    try {
      final response = await supabase
          .from('colaboradores')
          .select('updated_at')
          .order('updated_at', ascending: false)
          .limit(1);

      if (response.isEmpty || response.first['updated_at'] == null) {
        print(
          '[👥 MENSAJES COLABORADORES SERVICE] ❌ No hay updated_at en Supabase',
        );
        return null;
      }

      return DateTime.parse(response.first['updated_at']).toUtc();
    } catch (e) {
      print(
        '[👥 MENSAJES COLABORADORES SERVICE] ❌ Error comprobando actualizaciones: $e',
      );
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 OBTENER TODOS / FILTRADOS ONLINE
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> obtenerTodosOnline() async {
    print(
      '[👥 MENSAJES COLABORADORES SERVICE] 📥 Obteniendo TODOS los colaboradores online…',
    );
    try {
      final res = await supabase.from('colaboradores').select();
      print('[👥 MENSAJES COLABORADORES SERVICE] ✅ ${res.length} filas');
      return res;
    } catch (e) {
      print('[👥 MENSAJES COLABORADORES SERVICE] ❌ Error obtener todos: $e');
      rethrow;
    }
  }

  /// 🔄 Obtener estrictamente los modificados DESPUÉS de `ultimaSync` (UTC)
  Future<List<Map<String, dynamic>>> obtenerFiltradosOnline(
    DateTime ultimaSync,
  ) async {
    print(
      '[👥 MENSAJES COLABORADORES SERVICE] 📥 Filtrando > $ultimaSync (UTC)',
    );
    try {
      final res = await supabase
          .from('colaboradores')
          .select()
          .gt('updated_at', ultimaSync.toUtc().toIso8601String());
      print('[👥 MENSAJES COLABORADORES SERVICE] ✅ ${res.length} filtrados');
      return res;
    } catch (e) {
      print('[👥 MENSAJES COLABORADORES SERVICE] ❌ Error filtrados: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 HEADS (uid, updated_at) → diff barato
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> obtenerCabecerasOnline() async {
    try {
      final res = await supabase
          .from('colaboradores')
          .select('uid, updated_at');
      return res;
    } catch (e) {
      print('[👥 MENSAJES COLABORADORES SERVICE] ❌ Error en cabeceras: $e');
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
          .from('colaboradores')
          .select()
          .inFilter('uid', uids);
      return res;
    } catch (e) {
      print('[👥 MENSAJES COLABORADORES SERVICE] ❌ Error fetch por UIDs: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 CREAR / ACTUALIZAR / ELIMINAR ONLINE
  // ---------------------------------------------------------------------------
  Future<void> upsertColaboradorOnline(Map<String, dynamic> data) async {
    final uid = data['uid'];
    print(
      '[👥 MENSAJES COLABORADORES SERVICE] ⬆️ Upsert online colaborador: $uid',
    );
    try {
      await supabase.from('colaboradores').upsert(data);
      print('[👥 MENSAJES COLABORADORES SERVICE] ✅ Upsert $uid OK');
    } catch (e) {
      print('[👥 MENSAJES COLABORADORES SERVICE] ❌ Error upsert $uid: $e');
      rethrow;
    }
  }

  Future<void> eliminarColaboradorOnline(String uid) async {
    try {
      await supabase
          .from('colaboradores')
          .update({
            'deleted': true,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('uid', uid);
      print(
        '[👥 MENSAJES COLABORADORES SERVICE] Colaborador $uid marcado como eliminado online',
      );
    } catch (e) {
      print(
        '[👥 MENSAJES COLABORADORES SERVICE] ❌ Error eliminando colaborador: $e',
      );
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 🖼️ IMÁGENES (Storage: colaboradores-img)
  // ---------------------------------------------------------------------------

  Future<String> calcularSha256(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  String _normalizePath(String pth) {
    final s = pth.trim();
    final noLeading = s.startsWith('/') ? s.substring(1) : s;
    return noLeading.replaceAll(RegExp(r'/+'), '/');
  }

  /// ¿Existe ya la imagen en Storage?
  Future<bool> existsImagen(String remotePath) async {
    final clean = _normalizePath(remotePath);
    final dir = p.dirname(clean);
    final fileName = p.basename(clean);
    final items = await supabase.storage.from(_bucketImagenes).list(path: dir);
    return items.any((it) => it.name == fileName);
  }

  /// Subir/actualizar imagen a Storage
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
      if ((e.statusCode ?? 0) == 409 && !overwrite) return; // Ya existe
      rethrow;
    }
  }

  /// Eliminar imagen de Storage de la mejor manera posible
  Future<void> deleteImagenOnlineSafe(String remotePath) async {
    final clean = _normalizePath(remotePath);
    try {
      await supabase.storage.from(_bucketImagenes).remove([clean]);
      print('[👥 MENSAJES COLABORADORES SERVICE] ✅ Imagen eliminada: $clean');
    } catch (e) {
      print(
        '[👥 MENSAJES COLABORADORES SERVICE] ❌ Error eliminando imagen: $e',
      );
    }
  }

  /// Descargar imagen de Storage y guardarla local
  Future<File?> descargarImagenOnline(
    String rutaRemota, {
    bool temporal = false,
  }) async {
    try {
      print(
        '[👥 MENSAJES COLABORADORES SERVICE] rutaRemota original: "$rutaRemota"',
      );
      final path = rutaRemota.trim();
      if (path.isEmpty) {
        print('[👥 MENSAJES COLABORADORES SERVICE] skip: rutaRemota vacía');
        return null;
      }

      final cleanPath = rutaRemota.startsWith('/')
          ? rutaRemota.substring(1)
          : rutaRemota;
      print(
        '[👥 MENSAJES COLABORADORES SERVICE] Intentando descargar imagen: [$cleanPath]',
      );

      final bytes = await supabase.storage
          .from(_bucketImagenes)
          .download(cleanPath);

      final baseDir = temporal
          ? await getTemporaryDirectory()
          : await getApplicationSupportDirectory();

      final subdir = temporal ? 'colaboradores_img_tmp' : 'colaboradores_img';
      final targetDir = Directory(p.join(baseDir.path, subdir));
      if (!await targetDir.exists()) {
        await targetDir.create(recursive: true);
      }

      final safeName = cleanPath.replaceAll('/', '_');
      final file = File(p.join(targetDir.path, safeName));
      await file.writeAsBytes(bytes);

      print(
        '[👥 MENSAJES COLABORADORES SERVICE] Imagen guardada en: ${file.path}',
      );
      return file;
    } catch (e) {
      print(
        '[👥 MENSAJES COLABORADORES SERVICE] ❌ Error al descargar imagen: $e',
      );
      return null;
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

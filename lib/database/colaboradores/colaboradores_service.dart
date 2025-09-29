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

  // ===== Añadido (alineado a VentasService) =====
  // Tamaños de bloque conservadores para móviles/redes lentas.
  static const int _pageSize = 1000; // range() es inclusivo
  static const int _uidsChunk = 200; // evita 414 al usar inFilter
  String _iso(DateTime d) => d.toUtc().toIso8601String();
  // ==============================================

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
      '[👥 MENSAJES COLABORADORES SERVICE] 📥 Obteniendo TODOS los colaboradores online (paginado)…',
    );
    // ===== Modificado: paginado con range() =====
    final out = <Map<String, dynamic>>[];
    try {
      int from = 0;
      while (true) {
        final to = from + _pageSize - 1; // range es inclusivo
        final page = await supabase
            .from('colaboradores')
            .select()
            .order('updated_at', ascending: true) // orden estable para paginar
            .range(from, to);

        final batch = List<Map<String, dynamic>>.from(page);
        out.addAll(batch);

        print(
          '[👥 MENSAJES COLABORADORES SERVICE]   Página $from..$to -> ${batch.length} filas',
        );
        if (batch.length < _pageSize) break; // última página
        from += _pageSize;
      }

      print(
        '[👥 MENSAJES COLABORADORES SERVICE] ✅ Total acumulado: ${out.length}',
      );
      return out;
    } catch (e) {
      print(
        '[👥 MENSAJES COLABORADORES SERVICE] ❌ Error obtener todos (paginado): $e',
      );
      rethrow;
    }
  }

  /// 🔄 Obtener estrictamente los modificados DESPUÉS de `ultimaSync` (UTC)
  Future<List<Map<String, dynamic>>> obtenerFiltradosOnline(
    DateTime ultimaSync,
  ) async {
    print(
      '[👥 MENSAJES COLABORADORES SERVICE] 📥 Filtrando > $ultimaSync (UTC, paginado)…',
    );
    // ===== Modificado: paginado con range() =====
    final out = <Map<String, dynamic>>[];
    try {
      final ts = _iso(ultimaSync);
      int from = 0;
      while (true) {
        final to = from + _pageSize - 1;
        final page = await supabase
            .from('colaboradores')
            .select()
            .gt('updated_at', ts)
            .order('updated_at', ascending: true)
            .range(from, to);

        final batch = List<Map<String, dynamic>>.from(page);
        out.addAll(batch);

        print(
          '[👥 MENSAJES COLABORADORES SERVICE]   Página $from..$to -> ${batch.length} filtrados',
        );
        if (batch.length < _pageSize) break;
        from += _pageSize;
      }

      print(
        '[👥 MENSAJES COLABORADORES SERVICE] ✅ Filtrados acumulados: ${out.length}',
      );
      return out;
    } catch (e) {
      print(
        '[👥 MENSAJES COLABORADORES SERVICE] ❌ Error filtrados (paginado): $e',
      );
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 HEADS (uid, updated_at) → diff barato
  // ---------------------------------------------------------------------------
  Future<List<Map<String, dynamic>>> obtenerCabecerasOnline() async {
    // ===== Modificado: paginado con range() =====
    print(
      '[👥 MENSAJES COLABORADORES SERVICE] 📥 Obteniendo cabeceras (paginado)…',
    );
    final out = <Map<String, dynamic>>[];
    try {
      int from = 0;
      while (true) {
        final to = from + _pageSize - 1;
        final page = await supabase
            .from('colaboradores')
            .select('uid, updated_at')
            .order('updated_at', ascending: true)
            .range(from, to);

        final batch = List<Map<String, dynamic>>.from(page);
        out.addAll(batch);

        print(
          '[👥 MENSAJES COLABORADORES SERVICE]   Heads $from..$to -> ${batch.length}',
        );
        if (batch.length < _pageSize) break;
        from += _pageSize;
      }
      print(
        '[👥 MENSAJES COLABORADORES SERVICE] ✅ Heads acumuladas: ${out.length}',
      );
      return out;
    } catch (e) {
      print(
        '[👥 MENSAJES COLABORADORES SERVICE] ❌ Error en cabeceras (paginado): $e',
      );
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
    // ===== Modificado: troceo en chunks para evitar 414 =====
    print(
      '[👥 MENSAJES COLABORADORES SERVICE] 📥 Fetch por UIDs (${uids.length}) en lotes…',
    );
    final out = <Map<String, dynamic>>[];
    try {
      for (int i = 0; i < uids.length; i += _uidsChunk) {
        final chunk = uids.sublist(
          i,
          (i + _uidsChunk > uids.length) ? uids.length : i + _uidsChunk,
        );

        final res = await supabase
            .from('colaboradores')
            .select()
            .inFilter('uid', chunk)
            .order('updated_at', ascending: true);

        final batch = List<Map<String, dynamic>>.from(res);
        out.addAll(batch);
        print(
          '[👥 MENSAJES COLABORADORES SERVICE]   Chunk $i..${i + chunk.length - 1} -> ${batch.length}',
        );
      }
      print(
        '[👥 MENSAJES COLABORADORES SERVICE] ✅ Total por UIDs: ${out.length}',
      );
      return out;
    } catch (e) {
      print(
        '[👥 MENSAJES COLABORADORES SERVICE] ❌ Error fetch por UIDs (lotes): $e',
      );
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

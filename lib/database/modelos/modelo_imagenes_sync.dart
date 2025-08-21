// ignore_for_file: avoid_print

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/modelos/modelo_imagenes_dao.dart';
import 'package:myafmzd/database/modelos/modelo_imagenes_service.dart';

class ModeloImagenesSync {
  final ModeloImagenesDao _dao;
  final ModeloImagenesService _service;

  ModeloImagenesSync(AppDatabase db)
    : _dao = ModeloImagenesDao(db),
      _service = ModeloImagenesService(db);

  // ---------------------------------------------------------------------------
  // 📤 PUSH: Subir imágenes locales pendientes (isSynced == false)
  //   - Sube imagen a Storage si existe rutaLocal
  //   - Upsert metadata a 'modelo_imagenes'
  //   - Marcar isSynced=true en local
  // ---------------------------------------------------------------------------
  Future<void> pushModeloImagenesOffline() async {
    print(
      '[🖼️ MENSAJES MODELO_IMAGENES SYNC] ⬆️ PUSH: buscando pendientes...',
    );
    final pendientes = await _dao.obtenerPendientesSyncDrift();

    if (pendientes.isEmpty) {
      print(
        '[🖼️ MENSAJES MODELO_IMAGENES SYNC] ✅ No hay pendientes de subida',
      );
      return;
    }

    for (final img in pendientes) {
      try {
        // 1) Subir imagen si está local y hay ruta remota
        final hasLocalImg =
            img.rutaLocal.isNotEmpty && File(img.rutaLocal).existsSync();

        if (hasLocalImg && img.rutaRemota.isNotEmpty) {
          final yaExiste = await _service.existsImagen(img.rutaRemota);
          if (!yaExiste) {
            await _service.uploadImagenOnline(
              File(img.rutaLocal),
              img.rutaRemota,
            );
            print(
              '[🖼️ MENSAJES MODELO_IMAGENES SYNC] ☁️ Imagen subida: ${img.rutaRemota}',
            );
          } else {
            print(
              '[🖼️ MENSAJES MODELO_IMAGENES SYNC] ⏭️ Remoto ya existe, no subo: ${img.rutaRemota}',
            );
          }
        } else {
          print(
            '[🖼️ MENSAJES MODELO_IMAGENES SYNC] ⚠️ Sin imagen local o rutaRemota vacía para ${img.uid}',
          );
        }

        // 2) Upsert metadata
        final data = _imagenToSupabase(img);
        await _service.upsertImagenOnline(data);

        // 3) Marcar local como sincronizada
        await _dao.marcarComoSincronizadoDrift(img.uid);
        print('[🖼️ MENSAJES MODELO_IMAGENES SYNC] ✅ Sincronizada: ${img.uid}');
      } catch (e) {
        print(
          '[🖼️ MENSAJES MODELO_IMAGENES SYNC] ❌ Error subiendo ${img.uid}: $e',
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 📥 PULL: estrategia heads → diff → bulk fetch
  //   - 1) Obtener cabezas remotas (uid, updated_at)
  //   - 2) Comparar con estado local (updatedAt, isSynced)
  //   - 3) Traer SOLO los UIDs necesarios
  //   - 4) Upsert en Drift como sincronizados
  //   - (No descarga imágenes aquí; solo metadata)
  // ---------------------------------------------------------------------------
  Future<void> pullModeloImagenesOnline() async {
    print('[🖼️ MENSAJES MODELO_IMAGENES SYNC] 📥 PULL: heads→diff→bulk');
    try {
      // 1) Heads remotos
      final heads = await _service.obtenerCabecerasOnline();
      if (heads.isEmpty) {
        print('[🖼️ MENSAJES MODELO_IMAGENES SYNC] ℹ️ Sin filas remotas');
        return;
      }

      // 2) Mapa remoto uid -> updatedAt(UTC)
      final remoteHead = <String, DateTime>{};
      for (final h in heads) {
        final uid = (h['uid'] ?? '').toString();
        final ru = h['updated_at'];
        if (uid.isEmpty || ru == null) continue;
        remoteHead[uid] = DateTime.parse(ru.toString()).toUtc();
      }

      // 3) Estado local mínimo (uid, updatedAt, isSynced)
      final locales = await _dao.obtenerTodosDrift();
      final localMap = {
        for (final i in locales)
          i.uid: {'u': i.updatedAt.toUtc(), 's': i.isSynced},
      };

      // 4) Diff → decidir qué bajar
      final toFetch = <String>[];
      remoteHead.forEach((uid, rU) {
        final l = localMap[uid];
        if (l == null) {
          toFetch.add(uid);
          return;
        }
        final lU = (l['u'] as DateTime);
        final lS = (l['s'] as bool);

        final remoteIsNewer = rU.isAfter(lU);
        final localDominates =
            (!lS) && (lU.isAfter(rU) || lU.isAtSameMomentAs(rU));
        if (localDominates) return;
        if (remoteIsNewer) toFetch.add(uid);
      });

      if (toFetch.isEmpty) {
        print(
          '[🖼️ MENSAJES MODELO_IMAGENES SYNC] ✅ Diff vacío: nada que bajar',
        );
        return;
      }
      print(
        '[🖼️ MENSAJES MODELO_IMAGENES SYNC] 🔽 Bajando ${toFetch.length} por diff',
      );

      // 5) Fetch selectivo por UIDs
      final remotos = await _service.obtenerPorUidsOnline(toFetch);
      if (remotos.isEmpty) {
        print(
          '[🖼️ MENSAJES MODELO_IMAGENES SYNC] ℹ️ Fetch selectivo devolvió 0',
        );
        return;
      }

      // 6) Map → Companions (remotos ⇒ isSynced=true)
      DateTime? _dt(dynamic v) => (v == null || (v is String && v.isEmpty))
          ? null
          : DateTime.parse(v.toString()).toUtc();

      final companions = remotos.map((m) {
        return ModeloImagenesCompanion(
          uid: Value(m['uid'] as String),
          modeloUid: Value((m['modelo_uid'] as String?) ?? ''),
          rutaRemota: Value((m['ruta_remota'] as String?) ?? ''),
          rutaLocal: m['ruta_local'] == null
              ? const Value.absent()
              : Value(m['ruta_local'] as String? ?? ''),
          updatedAt: Value(_dt(m['updated_at']) ?? DateTime.now().toUtc()),
          deleted: Value((m['deleted'] as bool?) ?? false),
          isSynced: const Value(true),
        );
      }).toList();

      await _dao.upsertImagenesDrift(companions);
      print(
        '[🖼️ MENSAJES MODELO_IMAGENES SYNC] ✅ Upsert remoto selectivo: ${companions.length}',
      );
    } catch (e) {
      print('[🖼️ MENSAJES MODELO_IMAGENES SYNC] ❌ Error en PULL: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 🔧 Helper: mapear ModeloImagenDb (Drift) → JSON snake_case para Supabase
  // ---------------------------------------------------------------------------
  Map<String, dynamic> _imagenToSupabase(ModeloImagenDb i) {
    String? _iso(DateTime? d) => d?.toUtc().toIso8601String();
    return {
      'uid': i.uid,
      'modelo_uid': i.modeloUid,
      'ruta_remota': i.rutaRemota,
      'updated_at': _iso(i.updatedAt),
      'deleted': i.deleted,
    };
  }
}

// ignore_for_file: avoid_print

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/modelos/modelos_dao.dart';
import 'package:myafmzd/database/modelos/modelos_service.dart';

class ModelosSync {
  final ModelosDao _dao;
  final ModelosService _service;

  ModelosSync(AppDatabase db)
    : _dao = ModelosDao(db),
      _service = ModelosService(db);

  // ---------------------------------------------------------------------------
  // 📤 PUSH: Subir cambios locales pendientes (isSynced == false)
  //   - Sube ficha PDF si existe rutaLocal
  //   - Upsert metadata en tabla `modelos`
  //   - Marcar isSynced=true en local (NO tocamos updatedAt aquí)
  // ---------------------------------------------------------------------------
  Future<void> pushModelosOffline() async {
    print('[🚗 MENSAJES MODELOS SYNC] ⬆️ PUSH: buscando pendientes...');
    final pendientes = await _dao.obtenerPendientesSyncDrift();

    if (pendientes.isEmpty) {
      print('[🚗 MENSAJES MODELOS SYNC] ✅ No hay pendientes de subida');
      return;
    }

    for (final m in pendientes) {
      try {
        // 1) Subir ficha técnica (PDF) si la tienes local y hay ruta remota
        final hasLocalPdf =
            m.fichaRutaLocal.isNotEmpty && File(m.fichaRutaLocal).existsSync();

        if (hasLocalPdf && m.fichaRutaRemota.isNotEmpty) {
          final yaExiste = await _service.existsFicha(m.fichaRutaRemota);
          if (!yaExiste) {
            await _service.uploadFichaOnline(
              File(m.fichaRutaLocal),
              m.fichaRutaRemota,
            );
            print(
              '[🚗 MENSAJES MODELOS SYNC] ☁️ Ficha subida: ${m.fichaRutaRemota}',
            );
          } else {
            print(
              '[🚗 MENSAJES MODELOS SYNC] ⏭️ Ficha ya existe, no subo: ${m.fichaRutaRemota}',
            );
          }
        } else {
          print(
            '[🚗 MENSAJES MODELOS SYNC] ⚠️ Sin ficha local o rutaRemota vacía para ${m.uid}',
          );
        }

        // 2) Upsert metadata de modelo
        final data = _modeloToSupabase(m);
        await _service.upsertModeloOnline(data);

        // 3) Marcar como sincronizado (no sobrescribimos updatedAt)
        await _dao.marcarComoSincronizadoDrift(m.uid);
        print('[🚗 MENSAJES MODELOS SYNC] ✅ Sincronizado: ${m.uid}');
      } catch (e) {
        print('[🚗 MENSAJES MODELOS SYNC] ❌ Error subiendo ${m.uid}: $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 📥 PULL: estrategia heads → diff → bulk fetch
  //   - 1) Obtener cabezas remotas (uid, updated_at)
  //   - 2) Comparar con estado local (updatedAt, isSynced)
  //   - 3) Traer SOLO los UIDs necesarios
  //   - 4) Upsert en Drift como sincronizados
  //   - (No descarga PDFs aquí; solo metadata)
  // ---------------------------------------------------------------------------
  Future<void> pullModelosOnline() async {
    print('[🚗 MENSAJES MODELOS SYNC] 📥 PULL: heads→diff→bulk');
    try {
      // 1) Heads remotos
      final heads = await _service.obtenerCabecerasOnline();
      if (heads.isEmpty) {
        print('[🚗 MENSAJES MODELOS SYNC] ℹ️ Sin filas remotas');
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
        for (final m in locales)
          m.uid: {'u': m.updatedAt.toUtc(), 's': m.isSynced},
      };

      // 4) Diff → decidir qué bajar
      final toFetch = <String>[];
      remoteHead.forEach((uid, rU) {
        final l = localMap[uid];
        if (l == null) {
          // No existe local → bajar
          toFetch.add(uid);
          return;
        }
        final lU = (l['u'] as DateTime);
        final lS = (l['s'] as bool);

        final remoteIsNewer = rU.isAfter(lU); // rU > lU
        final localDominates =
            (!lS) && (lU.isAfter(rU) || lU.isAtSameMomentAs(rU));
        if (localDominates) return; // hay cambio local pendiente → no pisar
        if (remoteIsNewer) toFetch.add(uid);
      });

      if (toFetch.isEmpty) {
        print('[🚗 MENSAJES MODELOS SYNC] ✅ Diff vacío: nada que bajar');
        return;
      }
      print('[🚗 MENSAJES MODELOS SYNC] 🔽 Bajando ${toFetch.length} por diff');

      // 5) Fetch selectivo por UIDs (trocea si esperas muchos)
      final remotos = await _service.obtenerPorUidsOnline(toFetch);
      if (remotos.isEmpty) {
        print('[🚗 MENSAJES MODELOS SYNC] ❌ Fetch selectivo devolvió 0');
        return;
      }

      // 6) Map → Companions (remotos ⇒ isSynced=true)
      DateTime? dt(dynamic v) => (v == null || (v is String && v.isEmpty))
          ? null
          : DateTime.parse(v.toString()).toUtc();
      double toDouble(dynamic v) =>
          (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;
      int toInt(dynamic v) => (v is int) ? v : int.tryParse('$v') ?? 0;

      final companions = remotos.map((m) {
        return ModelosCompanion(
          uid: Value(m['uid'] as String),
          claveCatalogo: Value((m['clave_catalogo'] as String?) ?? ''),
          marca: Value((m['marca'] as String?) ?? 'Mazda'),
          modelo: Value((m['modelo'] as String?) ?? ''),
          anio: Value(toInt(m['anio'])),
          tipo: Value((m['tipo'] as String?) ?? ''),
          transmision: Value((m['transmision'] as String?) ?? ''),
          descripcion: Value((m['descripcion'] as String?) ?? ''),
          activo: Value((m['activo'] as bool?) ?? true),
          precioBase: Value(toDouble(m['precio_base'])),
          fichaRutaRemota: Value((m['ficha_ruta_remota'] as String?) ?? ''),
          fichaRutaLocal: m['ficha_ruta_local'] == null
              ? const Value.absent()
              : Value(m['ficha_ruta_local'] as String? ?? ''),
          createdAt: Value(dt(m['created_at']) ?? DateTime.now().toUtc()),
          updatedAt: Value(dt(m['updated_at']) ?? DateTime.now().toUtc()),
          deleted: Value((m['deleted'] as bool?) ?? false),
          isSynced: const Value(true),
        );
      }).toList();

      await _dao.upsertModelosDrift(companions);
      print(
        '[🚗 MENSAJES MODELOS SYNC] ✅ Upsert remoto selectivo: ${companions.length}',
      );
    } catch (e) {
      print('[🚗 MENSAJES MODELOS SYNC] ❌ Error en PULL: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 🔧 Helper: mapear ModeloDb (Drift) → JSON snake_case para Supabase
  // ---------------------------------------------------------------------------
  Map<String, dynamic> _modeloToSupabase(ModeloDb m) {
    String? iso(DateTime? d) => d?.toUtc().toIso8601String();
    return {
      'uid': m.uid,
      'clave_catalogo': m.claveCatalogo,
      'marca': m.marca,
      'modelo': m.modelo,
      'anio': m.anio,
      'tipo': m.tipo,
      'transmision': m.transmision,
      'descripcion': m.descripcion,
      'activo': m.activo,
      'precio_base': m.precioBase,
      'ficha_ruta_remota': m.fichaRutaRemota,
      // Nota: NO enviamos ficha_ruta_local al servidor
      'created_at': iso(m.createdAt),
      'updated_at': iso(m.updatedAt),
      'deleted': m.deleted,
    };
  }
}

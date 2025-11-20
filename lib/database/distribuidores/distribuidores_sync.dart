// ignore_for_file: avoid_print

import 'package:drift/drift.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_dao.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_service.dart';

class DistribuidoresSync {
  final DistribuidoresDao _dao;
  final DistribuidoresService _service;

  DistribuidoresSync(AppDatabase db)
    : _dao = DistribuidoresDao(db),
      _service = DistribuidoresService(db);

  // ---------------------------------------------------------------------------
  // 📤 PUSH: Subir cambios locales pendientes (isSynced == false)
  //   - Upsert metadata en tabla `distribuidores`
  //   - Marcar isSynced=true en local (NO tocamos updatedAt aquí)
  // ---------------------------------------------------------------------------
  Future<void> pushDistribuidoresOffline() async {
    print('[🏢 MENSAJES DISTRIBUIDORES SYNC] ⬆️ PUSH: buscando pendientes…');
    final pendientes = await _dao.obtenerPendientesSyncDrift();

    if (pendientes.isEmpty) {
      print('[🏢 MENSAJES DISTRIBUIDORES SYNC] ✅ No hay pendientes de subida');
      return;
    }

    for (final d in pendientes) {
      try {
        final data = _distribuidorToSupabase(d);
        await _service.upsertDistribuidorOnline(data);

        // marcar como sincronizado (no sobrescribimos updatedAt)
        await _dao.marcarComoSincronizadoDrift(d.uid);
        print('[🏢 MENSAJES DISTRIBUIDORES SYNC] ✅ Sincronizado: ${d.uid}');
      } catch (e) {
        print(
          '[🏢 MENSAJES DISTRIBUIDORES SYNC] ❌ Error subiendo ${d.uid}: $e',
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
  // ---------------------------------------------------------------------------
  Future<void> pullDistribuidoresOnline() async {
    print('[🏢 MENSAJES DISTRIBUIDORES SYNC] 📥 PULL: heads→diff→bulk');
    try {
      // 1) Heads remotos
      final heads = await _service.obtenerCabecerasOnline();
      if (heads.isEmpty) {
        print('[🏢 MENSAJES DISTRIBUIDORES SYNC] ℹ️ Sin filas remotas');
        return;
      }

      // 2) Mapa remoto: uid -> updatedAt(UTC)
      final remoteHead = <String, DateTime>{};
      for (final h in heads) {
        final uid = (h['uid'] ?? '').toString();
        final ru = h['updated_at'];
        if (uid.isEmpty || ru == null) continue;
        remoteHead[uid] = DateTime.parse(ru.toString()).toUtc();
      }

      // 3) Estado local mínimo (uid, updatedAt, isSynced)
      final locales = await _dao.obtenerTodosDrift();
      final localMap = <String, Map<String, dynamic>>{
        for (final d in locales)
          d.uid: {'u': d.updatedAt.toUtc(), 's': d.isSynced},
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
        print('[🏢 MENSAJES DISTRIBUIDORES SYNC] ✅ Diff vacío: nada que bajar');
        return;
      }
      print(
        '[🏢 MENSAJES DISTRIBUIDORES SYNC] 🔽 Bajando ${toFetch.length} por diff',
      );

      // 5) Fetch selectivo por UIDs (puedes trocear si son muchos)
      final remotos = await _service.obtenerPorUidsOnline(toFetch);
      if (remotos.isEmpty) {
        print('[🏢 MENSAJES DISTRIBUIDORES SYNC] ❌ Fetch selectivo devolvió 0');
        return;
      }

      // 6) Map → Companions (remotos ⇒ isSynced=true)
      DateTime? dt(dynamic v) =>
          (v == null) ? null : DateTime.parse(v.toString()).toUtc();
      double toDouble(dynamic v) =>
          (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;

      final companions = remotos.map((m) {
        return DistribuidoresCompanion(
          uid: Value(m['uid'] as String),
          nombre: Value((m['nombre'] as String?) ?? ''),
          uuidGrupo: Value((m['uuid_grupo'] as String?) ?? ''),
          direccion: Value((m['direccion'] as String?) ?? ''),
          estado: Value((m['estado'] as String?) ?? ''),
          activo: Value((m['activo'] as bool?) ?? true),
          latitud: Value(toDouble(m['latitud'])),
          longitud: Value(toDouble(m['longitud'])),
          concentradoraUid: Value((m['concentradora_uid'] as String?) ?? ''),
          updatedAt: Value(dt(m['updated_at']) ?? DateTime.now().toUtc()),
          deleted: Value((m['deleted'] as bool?) ?? false),
          isSynced: const Value(true),
        );
      }).toList();

      await _dao.upsertDistribuidoresDrift(companions);
      print(
        '[🏢 MENSAJES DISTRIBUIDORES SYNC] ✅ Upsert remoto selectivo: ${companions.length}',
      );
    } catch (e) {
      print('[🏢 MENSAJES DISTRIBUIDORES SYNC] ❌ Error en PULL: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 🔧 Helper: mapear DistribuidorDb (Drift) → JSON snake_case para Supabase
  // ---------------------------------------------------------------------------
  Map<String, dynamic> _distribuidorToSupabase(DistribuidorDb d) {
    String? iso(DateTime? v) => v?.toUtc().toIso8601String();
    return {
      'uid': d.uid,
      'nombre': d.nombre,
      'uuid_grupo': d.uuidGrupo,
      'direccion': d.direccion,
      'estado': d.estado,
      'activo': d.activo,
      'latitud': d.latitud,
      'longitud': d.longitud,
      'concentradora_uid': d.concentradoraUid,
      'updated_at': iso(d.updatedAt),
      'deleted': d.deleted,
    };
  }
}

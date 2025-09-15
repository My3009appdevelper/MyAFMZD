// ignore_for_file: avoid_print

import 'package:drift/drift.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/grupo_distribuidores/grupos_distribuidores_dao.dart';
import 'package:myafmzd/database/grupo_distribuidores/grupos_distribuidores_service.dart';

class GruposDistribuidoresSync {
  final GruposDistribuidoresDao _dao;
  final GruposDistribuidoresService _service;

  GruposDistribuidoresSync(AppDatabase db)
    : _dao = GruposDistribuidoresDao(db),
      _service = GruposDistribuidoresService(db);

  // ---------------------------------------------------------------------------
  // 📤 PUSH: Subir cambios locales pendientes (isSynced == false)
  //   - Upsert metadata en tabla `grupos_distribuidores`
  //   - Marcar isSynced=true en local (NO tocamos updatedAt aquí)
  // ---------------------------------------------------------------------------
  Future<void> pushGruposDistribuidoresOffline() async {
    print('[🧑‍🤝‍🧑 MENSAJES GRUPOS SYNC] ⬆️ PUSH: buscando pendientes…');
    final pendientes = await _dao.obtenerPendientesSyncDrift();

    if (pendientes.isEmpty) {
      print('[🧑‍🤝‍🧑 MENSAJES GRUPOS SYNC] ✅ No hay pendientes de subida');
      return;
    }

    for (final g in pendientes) {
      try {
        final data = _grupoToSupabase(g);
        await _service.upsertGrupoOnline(data);

        await _dao.marcarComoSincronizadoDrift(g.uid);
        print('[🧑‍🤝‍🧑 MENSAJES GRUPOS SYNC] ✅ Sincronizado: ${g.uid}');
      } catch (e) {
        print('[🧑‍🤝‍🧑 MENSAJES GRUPOS SYNC] ❌ Error subiendo ${g.uid}: $e');
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
  Future<void> pullGruposDistribuidoresOnline() async {
    print('[🧑‍🤝‍🧑 MENSAJES GRUPOS SYNC] 📥 PULL: heads→diff→bulk');
    try {
      // 1) Heads remotos
      final heads = await _service.obtenerCabecerasOnline();
      if (heads.isEmpty) {
        print('[🧑‍🤝‍🧑 MENSAJES GRUPOS SYNC] ℹ️ Sin filas remotas');
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
        for (final g in locales)
          g.uid: {'u': g.updatedAt.toUtc(), 's': g.isSynced},
      };

      // 4) Diff → decidir qué bajar
      final toFetch = <String>[];
      remoteHead.forEach((uid, rU) {
        final l = localMap[uid];
        if (l == null) {
          toFetch.add(uid); // no existe local
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
        print('[🧑‍🤝‍🧑 MENSAJES GRUPOS SYNC] ✅ Diff vacío: nada que bajar');
        return;
      }
      print(
        '[🧑‍🤝‍🧑 MENSAJES GRUPOS SYNC] 🔽 Bajando ${toFetch.length} por diff',
      );

      // 5) Fetch selectivo por UIDs
      final remotos = await _service.obtenerPorUidsOnline(toFetch);
      if (remotos.isEmpty) {
        print('[🧑‍🤝‍🧑 MENSAJES GRUPOS SYNC] ❌ Fetch selectivo devolvió 0');
        return;
      }

      // 6) Map → Companions (remotos ⇒ isSynced=true)
      DateTime? dt(dynamic v) => (v == null || (v is String && v.isEmpty))
          ? null
          : DateTime.parse(v.toString()).toUtc();
      String str(dynamic v, {String def = ''}) =>
          (v is String && v.isNotEmpty) ? v : (v?.toString() ?? def);
      bool toBool(dynamic v) => (v is bool) ? v : (v?.toString() == 'true');

      final companions = remotos.map((m) {
        return GruposDistribuidoresCompanion(
          uid: Value(m['uid'] as String),
          nombre: Value(str(m['nombre'])),
          abreviatura: Value(str(m['abreviatura'])),
          notas: Value(str(m['notas'])),
          activo: Value(toBool(m['activo'])),
          createdAt: Value(dt(m['created_at']) ?? DateTime.now().toUtc()),
          updatedAt: Value(dt(m['updated_at']) ?? DateTime.now().toUtc()),
          deleted: Value(toBool(m['deleted'])),
          isSynced: const Value(true),
        );
      }).toList();

      await _dao.upsertGruposDrift(companions);
      print(
        '[🧑‍🤝‍🧑 MENSAJES GRUPOS SYNC] ✅ Upsert remoto selectivo: ${companions.length}',
      );
    } catch (e) {
      print('[🧑‍🤝‍🧑 MENSAJES GRUPOS SYNC] ❌ Error en PULL: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 🔧 Helper: mapear GrupoDistribuidorDb (Drift) → JSON snake_case (Supabase)
  // ---------------------------------------------------------------------------
  Map<String, dynamic> _grupoToSupabase(GrupoDistribuidorDb g) {
    String? iso(DateTime? d) => d?.toUtc().toIso8601String();
    return {
      'uid': g.uid,
      'nombre': g.nombre,
      'abreviatura': g.abreviatura,
      'notas': g.notas,
      'activo': g.activo,
      'created_at': iso(g.createdAt),
      'updated_at': iso(g.updatedAt),
      'deleted': g.deleted,
    };
  }
}

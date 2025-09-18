// lib/database/estatus/estatus_sync.dart
// ignore_for_file: avoid_print

import 'package:drift/drift.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/estatus/estatus_dao.dart';
import 'package:myafmzd/database/estatus/estatus_service.dart';

class EstatusSync {
  final EstatusDao _dao;
  final EstatusService _service;

  EstatusSync(AppDatabase db)
    : _dao = EstatusDao(db),
      _service = EstatusService(db);

  // ---------------------------------------------------------------------------
  // 📤 PUSH: Subir cambios locales pendientes (isSynced == false)
  //   - Upsert metadata en tabla `estatus`
  //   - Marcar isSynced=true en local (NO tocamos updatedAt aquí)
  // ---------------------------------------------------------------------------
  Future<void> pushEstatusOffline() async {
    print('[🏷️ MENSAJES ESTATUS SYNC] ⬆️ PUSH: buscando pendientes…');
    final pendientes = await _dao.obtenerPendientesSyncDrift();

    if (pendientes.isEmpty) {
      print('[🏷️ MENSAJES ESTATUS SYNC] ✅ No hay pendientes de subida');
      return;
    }

    for (final e in pendientes) {
      try {
        final data = _estatusToSupabase(e);
        await _service.upsertEstatusOnline(data);

        await _dao.marcarComoSincronizadoDrift(e.uid);
        print('[🏷️ MENSAJES ESTATUS SYNC] ✅ Sincronizado: ${e.uid}');
      } catch (err) {
        print('[🏷️ MENSAJES ESTATUS SYNC] ❌ Error subiendo ${e.uid}: $err');
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
  Future<void> pullEstatusOnline() async {
    print('[🏷️ MENSAJES ESTATUS SYNC] 📥 PULL: heads→diff→bulk');
    try {
      // 1) Heads remotos
      final heads = await _service.obtenerCabecerasOnline();
      if (heads.isEmpty) {
        print('[🏷️ MENSAJES ESTATUS SYNC] ℹ️ Sin filas remotas');
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
        for (final l in locales)
          l.uid: {'u': l.updatedAt.toUtc(), 's': l.isSynced},
      };

      // 4) Diff → decidir qué bajar
      final toFetch = <String>[];
      remoteHead.forEach((uid, rU) {
        final l = localMap[uid];
        if (l == null) {
          toFetch.add(uid); // no existe local → bajar
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
        print('[🏷️ MENSAJES ESTATUS SYNC] ✅ Diff vacío: nada que bajar');
        return;
      }
      print(
        '[🏷️ MENSAJES ESTATUS SYNC] 🔽 Bajando ${toFetch.length} por diff',
      );

      // 5) Fetch selectivo por UIDs (troceable si son muchos)
      final remotos = await _service.obtenerPorUidsOnline(toFetch);
      if (remotos.isEmpty) {
        print('[🏷️ MENSAJES ESTATUS SYNC] ❌ Fetch selectivo devolvió 0');
        return;
      }

      // 6) Map → Companions (remotos ⇒ isSynced=true)
      DateTime? dt(dynamic v) => (v == null || (v is String && v.isEmpty))
          ? null
          : DateTime.parse(v.toString()).toUtc();
      String str(dynamic v, {String def = ''}) =>
          (v is String && v.isNotEmpty) ? v : (v?.toString() ?? def);
      bool toBool(dynamic v) => (v is bool) ? v : (v?.toString() == 'true');
      int toInt(dynamic v) => (v is int) ? v : int.tryParse('${v ?? ''}') ?? 0;

      final companions = remotos.map((m) {
        return EstatusCompanion(
          uid: Value(m['uid'] as String),
          nombre: Value(str(m['nombre'])),
          categoria: Value(str(m['categoria'], def: 'ciclo')),
          orden: Value(toInt(m['orden'])),
          esFinal: Value(toBool(m['es_final'])),
          esCancelatorio: Value(toBool(m['es_cancelatorio'])),
          visible: Value(toBool(m['visible'])),
          colorHex: Value(str(m['color_hex'])),
          icono: Value(str(m['icono'])),
          notas: Value(str(m['notas'])),
          createdAt: Value(dt(m['created_at']) ?? DateTime.now().toUtc()),
          updatedAt: Value(dt(m['updated_at']) ?? DateTime.now().toUtc()),
          deleted: Value(toBool(m['deleted'])),
          isSynced: const Value(true),
        );
      }).toList();

      await _dao.upsertEstatusListaDrift(companions);
      print(
        '[🏷️ MENSAJES ESTATUS SYNC] ✅ Upsert remoto selectivo: ${companions.length}',
      );
    } catch (e) {
      print('[🏷️ MENSAJES ESTATUS SYNC] ❌ Error en PULL: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 🔧 Helper: mapear EstatusDb (Drift) → JSON snake_case para Supabase
  // ---------------------------------------------------------------------------
  Map<String, dynamic> _estatusToSupabase(EstatusDb e) {
    String? iso(DateTime? d) => d?.toUtc().toIso8601String();
    return {
      'uid': e.uid,
      'nombre': e.nombre,
      'categoria': e.categoria,
      'orden': e.orden,
      'es_final': e.esFinal,
      'es_cancelatorio': e.esCancelatorio,
      'visible': e.visible,
      'color_hex': e.colorHex,
      'icono': e.icono,
      'notas': e.notas,
      'created_at': iso(e.createdAt),
      'updated_at': iso(e.updatedAt),
      'deleted': e.deleted,
    };
  }
}

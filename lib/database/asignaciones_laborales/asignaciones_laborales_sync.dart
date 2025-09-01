// ignore_for_file: avoid_print

import 'package:drift/drift.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/asignaciones_laborales/asignaciones_laborales_dao.dart';
import 'package:myafmzd/database/asignaciones_laborales/asignaciones_laborales_service.dart';

class AsignacionesLaboralesSync {
  final AsignacionesLaboralesDao _dao;
  final AsignacionesLaboralesService _service;

  AsignacionesLaboralesSync(AppDatabase db)
    : _dao = AsignacionesLaboralesDao(db),
      _service = AsignacionesLaboralesService(db);

  // ---------------------------------------------------------------------------
  // 📤 PUSH: Subir cambios locales pendientes (isSynced == false)
  //   - Upsert metadata en tabla `asignaciones_laborales`
  //   - Marcar isSynced=true en local (NO tocamos updatedAt aquí)
  // ---------------------------------------------------------------------------
  Future<void> pushAsignacionesOffline() async {
    print('[👔 MENSAJES ASIGNACIONES SYNC] ⬆️ PUSH: buscando pendientes…');
    final pendientes = await _dao.obtenerPendientesSyncDrift();

    if (pendientes.isEmpty) {
      print('[👔 MENSAJES ASIGNACIONES SYNC] ✅ No hay pendientes de subida');
      return;
    }

    for (final a in pendientes) {
      try {
        final data = _asignacionToSupabase(a);
        await _service.upsertAsignacionLaboralOnline(data);

        await _dao.marcarComoSincronizadoDrift(a.uid);
        print('[👔 MENSAJES ASIGNACIONES SYNC] ✅ Sincronizada: ${a.uid}');
      } catch (e) {
        print('[👔 MENSAJES ASIGNACIONES SYNC] ❌ Error subiendo ${a.uid}: $e');
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
  Future<void> pullAsignacionesOnline() async {
    print('[👔 MENSAJES ASIGNACIONES SYNC] 📥 PULL: heads→diff→bulk');
    try {
      // 1) Heads remotos
      final heads = await _service.obtenerCabecerasOnline();
      if (heads.isEmpty) {
        print('[👔 MENSAJES ASIGNACIONES SYNC] ℹ️ Sin filas remotas');
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
        for (final a in locales)
          a.uid: {'u': a.updatedAt.toUtc(), 's': a.isSynced},
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
        print('[👔 MENSAJES ASIGNACIONES SYNC] ✅ Diff vacío: nada que bajar');
        return;
      }
      print(
        '[👔 MENSAJES ASIGNACIONES SYNC] 🔽 Bajando ${toFetch.length} por diff',
      );

      // 5) Fetch selectivo por UIDs
      final remotos = await _service.obtenerPorUidsOnline(toFetch);
      if (remotos.isEmpty) {
        print('[👔 MENSAJES ASIGNACIONES SYNC] ❌ Fetch selectivo devolvió 0');
        return;
      }

      // 6) Map → Companions (remotos ⇒ isSynced=true)
      DateTime? _dt(dynamic v) => (v == null || (v is String && v.isEmpty))
          ? null
          : DateTime.parse(v.toString()).toUtc();
      String _str(dynamic v, {String def = ''}) =>
          (v is String && v.isNotEmpty) ? v : (v?.toString() ?? def);
      bool _bool(dynamic v) => (v is bool) ? v : (v?.toString() == 'true');

      final companions = remotos.map((m) {
        return AsignacionesLaboralesCompanion(
          uid: Value(m['uid'] as String),
          colaboradorUid: Value(_str(m['colaborador_uid'])),
          distribuidorUid: Value(_str(m['distribuidor_uid'])),
          managerColaboradorUid: Value(_str(m['manager_colaborador_uid'])),
          rol: Value(_str(m['rol'], def: 'vendedor')),
          puesto: Value(_str(m['puesto'])),
          nivel: Value(_str(m['nivel'])),
          fechaInicio: Value(_dt(m['fecha_inicio']) ?? DateTime.now().toUtc()),
          fechaFin: m['fecha_fin'] == null
              ? const Value.absent()
              : Value(_dt(m['fecha_fin'])),
          createdByUsuarioUid: Value(_str(m['created_by_usuario_uid'])),
          closedByUsuarioUid: Value(_str(m['closed_by_usuario_uid'])),
          notas: Value(_str(m['notas'])),
          createdAt: Value(_dt(m['created_at']) ?? DateTime.now().toUtc()),
          updatedAt: Value(_dt(m['updated_at']) ?? DateTime.now().toUtc()),
          deleted: Value(_bool(m['deleted'])),
          isSynced: const Value(true),
        );
      }).toList();

      await _dao.upsertAsignacionesLaboralesDrift(companions);
      print(
        '[👔 MENSAJES ASIGNACIONES SYNC] ✅ Upsert remoto selectivo: ${companions.length}',
      );
    } catch (e) {
      print('[👔 MENSAJES ASIGNACIONES SYNC] ❌ Error en PULL: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 🔧 Helper: mapear AsignacionLaboralDb (Drift) → JSON snake_case (Supabase)
  // ---------------------------------------------------------------------------
  Map<String, dynamic> _asignacionToSupabase(AsignacionLaboralDb a) {
    String? _iso(DateTime? d) => d?.toUtc().toIso8601String();
    return {
      'uid': a.uid,
      'colaborador_uid': a.colaboradorUid,
      'distribuidor_uid': a.distribuidorUid,
      'manager_colaborador_uid': a.managerColaboradorUid,
      'rol': a.rol,
      'puesto': a.puesto,
      'nivel': a.nivel,
      'fecha_inicio': _iso(a.fechaInicio),
      'fecha_fin': _iso(a.fechaFin),
      'created_by_usuario_uid': a.createdByUsuarioUid,
      'closed_by_usuario_uid': a.closedByUsuarioUid,
      'notas': a.notas,
      'created_at': _iso(a.createdAt),
      'updated_at': _iso(a.updatedAt),
      'deleted': a.deleted,
    };
  }
}

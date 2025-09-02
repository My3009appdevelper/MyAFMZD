// ignore_for_file: avoid_print

import 'package:drift/drift.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/usuarios/usuarios_dao.dart';
import 'package:myafmzd/database/usuarios/usuarios_service.dart';

class UsuariosSync {
  final UsuariosDao _dao;
  final UsuarioService _service;

  UsuariosSync(AppDatabase db)
    : _dao = UsuariosDao(db),
      _service = UsuarioService(db);

  // ---------------------------------------------------------------------------
  // 📤 PUSH: Subir cambios locales pendientes (isSynced == false)
  //   - Upsert metadata en tabla `usuarios`
  //   - Marcar isSynced=true en local (NO tocamos updatedAt aquí)
  // ---------------------------------------------------------------------------
  Future<void> pushUsuariosOffline() async {
    print('[👤 MENSAJES USUARIOS SYNC] ⬆️ PUSH: buscando pendientes...');
    final pendientes = await _dao.obtenerPendientesSyncDrift();

    if (pendientes.isEmpty) {
      print(
        '[👤 MENSAJES USUARIOS SYNC] ✅ No hay usuarios pendientes de subida',
      );
      return;
    }

    for (final u in pendientes) {
      try {
        final data = _usuarioToSupabase(u);
        await _service.upsertUsuarioOnline(data);

        await _dao.marcarComoSincronizadoDrift(u.uid, DateTime.now().toUtc());
        print('[👤 MENSAJES USUARIOS SYNC] ✅ Sincronizado: ${u.uid}');
      } catch (e) {
        print('[👤 MENSAJES USUARIOS SYNC] ❌ Error subiendo ${u.uid}: $e');
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
  Future<void> pullUsuariosOnline() async {
    print('[👤 MENSAJES USUARIOS SYNC] 📥 PULL: heads→diff→bulk');

    try {
      // 1) Heads remotos
      final heads = await _service.obtenerCabecerasOnline();
      if (heads.isEmpty) {
        print('[👤 MENSAJES USUARIOS SYNC] ℹ️ Sin filas remotas');
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
        for (final u in locales)
          u.uid: {'u': u.updatedAt.toUtc(), 's': u.isSynced},
      };

      // 4) Diff para decidir qué bajar
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
        print('[👤 MENSAJES USUARIOS SYNC] ✅ Diff vacío: nada que bajar');
        return;
      }
      print(
        '[👤 MENSAJES USUARIOS SYNC] 🔽 Bajando ${toFetch.length} por diff',
      );

      // 5) Fetch selectivo por UIDs
      final remotos = await _service.obtenerPorUidsOnline(toFetch);
      if (remotos.isEmpty) {
        print('[👤 MENSAJES USUARIOS SYNC] ℹ️ Fetch selectivo devolvió 0');
        return;
      }

      // 6) Map → Companions (remotos ⇒ isSynced=true)
      DateTime? dt(dynamic v) =>
          (v == null) ? null : DateTime.parse(v.toString()).toUtc();

      final companions = remotos.map((m) {
        return UsuariosCompanion(
          uid: Value(m['uid'] as String),
          colaboradorUid: Value((m['colaborador_uid'] as String?)),
          userName: Value((m['user_name'] as String?) ?? ''),
          correo: Value((m['correo'] as String?) ?? ''),
          createdAt: Value(dt(m['created_at']) ?? DateTime.now().toUtc()),
          updatedAt: Value(dt(m['updated_at']) ?? DateTime.now().toUtc()),
          deleted: Value((m['deleted'] as bool?) ?? false),
          isSynced: const Value(true),
        );
      }).toList();

      await _dao.upsertUsuariosDrift(companions);
      print(
        '[👤 MENSAJES USUARIOS SYNC] ✅ Upsert remoto selectivo: ${companions.length}',
      );
    } catch (e) {
      print('[👤 MENSAJES USUARIOS SYNC] ❌ Error en PULL: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 🔧 Helper: mapear UsuarioDb (Drift) → JSON snake_case para Supabase
  // ---------------------------------------------------------------------------
  Map<String, dynamic> _usuarioToSupabase(UsuarioDb u) {
    String? iso(DateTime? d) => d?.toUtc().toIso8601String();
    return {
      'uid': u.uid,
      'colaborador_uid': u.colaboradorUid,
      'user_name': u.userName,
      'correo': u.correo,
      'created_at': iso(u.createdAt),
      'updated_at': iso(u.updatedAt),
      'deleted': u.deleted,
    };
  }
}

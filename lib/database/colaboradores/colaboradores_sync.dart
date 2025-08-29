// ignore_for_file: avoid_print

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_dao.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_service.dart';

class ColaboradoresSync {
  final ColaboradoresDao _dao;
  final ColaboradoresService _service;

  ColaboradoresSync(AppDatabase db)
    : _dao = ColaboradoresDao(db),
      _service = ColaboradoresService(db);

  // ---------------------------------------------------------------------------
  // 📤 PUSH: Subir cambios locales pendientes (isSynced == false)
  //   - Sube foto a Storage si existe fotoRutaLocal
  //   - Upsert metadata en tabla `colaboradores`
  //   - Marcar isSynced=true en local (NO tocamos updatedAt aquí)
  // ---------------------------------------------------------------------------
  Future<void> pushColaboradoresOffline() async {
    print('[👥 MENSAJES COLABORADORES SYNC] ⬆️ PUSH: buscando pendientes…');
    final pendientes = await _dao.obtenerPendientesSyncDrift();

    if (pendientes.isEmpty) {
      print('[👥 MENSAJES COLABORADORES SYNC] ✅ No hay pendientes de subida');
      return;
    }

    for (final c in pendientes) {
      try {
        // 1) Subir FOTO si está local y hay ruta remota
        final hasLocalImg =
            c.fotoRutaLocal.isNotEmpty && File(c.fotoRutaLocal).existsSync();

        if (hasLocalImg && c.fotoRutaRemota.isNotEmpty) {
          final yaExiste = await _service.existsImagen(c.fotoRutaRemota);
          if (!yaExiste) {
            await _service.uploadImagenOnline(
              File(c.fotoRutaLocal),
              c.fotoRutaRemota,
            );
            print(
              '[👥 MENSAJES COLABORADORES SYNC] ☁️ Foto subida: ${c.fotoRutaRemota}',
            );
          } else {
            print(
              '[👥 MENSAJES COLABORADORES SYNC] ⏭️ Remoto ya existe, no subo: ${c.fotoRutaRemota}',
            );
          }
        } else {
          print(
            '[👥 MENSAJES COLABORADORES SYNC] ⚠️ Sin foto local o rutaRemota vacía para ${c.uid}',
          );
        }

        // 2) Upsert metadata
        final data = _colaboradorToSupabase(c);
        await _service.upsertColaboradorOnline(data);

        // 3) Marcar local como sincronizado (no sobrescribimos updatedAt)
        await _dao.marcarComoSincronizadoDrift(c.uid);
        print('[👥 MENSAJES COLABORADORES SYNC] ✅ Sincronizado: ${c.uid}');
      } catch (e) {
        print('[👥 MENSAJES COLABORADORES SYNC] ❌ Error subiendo ${c.uid}: $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 📥 PULL: estrategia heads → diff → bulk fetch
  //   - 1) Obtener cabezas remotas (uid, updated_at)
  //   - 2) Comparar con estado local (updatedAt, isSynced)
  //   - 3) Traer SOLO los UIDs necesarios
  //   - 4) Upsert en Drift como sincronizados
  //   - (No descarga fotos aquí; solo metadata)
  // ---------------------------------------------------------------------------
  Future<void> pullColaboradoresOnline() async {
    print('[👥 MENSAJES COLABORADORES SYNC] 📥 PULL: heads→diff→bulk');
    try {
      // 1) Heads remotos
      final heads = await _service.obtenerCabecerasOnline();
      if (heads.isEmpty) {
        print('[👥 MENSAJES COLABORADORES SYNC] ℹ️ Sin filas remotas');
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
        for (final c in locales)
          c.uid: {'u': c.updatedAt.toUtc(), 's': c.isSynced},
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

        final remoteIsNewer = rU.isAfter(lU); // rU > lU
        final localDominates =
            (!lS) && (lU.isAfter(rU) || lU.isAtSameMomentAs(rU));
        if (localDominates) return; // hay cambio local pendiente → no pisar
        if (remoteIsNewer) toFetch.add(uid);
      });

      if (toFetch.isEmpty) {
        print('[👥 MENSAJES COLABORADORES SYNC] ✅ Diff vacío: nada que bajar');
        return;
      }
      print(
        '[👥 MENSAJES COLABORADORES SYNC] 🔽 Bajando ${toFetch.length} por diff',
      );

      // 5) Fetch selectivo por UIDs
      final remotos = await _service.obtenerPorUidsOnline(toFetch);
      if (remotos.isEmpty) {
        print('[👥 MENSAJES COLABORADORES SYNC] ❌ Fetch selectivo devolvió 0');
        return;
      }

      // 6) Map → Companions (remotos ⇒ isSynced=true)
      DateTime? _dt(dynamic v) => (v == null || (v is String && v.isEmpty))
          ? null
          : DateTime.parse(v.toString()).toUtc();

      String _str(dynamic v, {String def = ''}) =>
          (v is String && v.isNotEmpty) ? v : (v?.toString() ?? def);

      final companions = remotos.map((m) {
        return ColaboradoresCompanion(
          uid: Value(m['uid'] as String),
          nombres: Value(_str(m['nombres'])),
          apellidoPaterno: Value(_str(m['apellido_paterno'])),
          apellidoMaterno: Value(_str(m['apellido_materno'])),
          fechaNacimiento: m['fecha_nacimiento'] == null
              ? const Value.absent()
              : Value(_dt(m['fecha_nacimiento'])),
          curp: m['curp'] == null
              ? const Value.absent()
              : Value(_str(m['curp'])),
          rfc: m['rfc'] == null ? const Value.absent() : Value(_str(m['rfc'])),
          telefonoMovil: Value(_str(m['telefono_movil'])),
          emailPersonal: Value(_str(m['email_personal'])),
          // Foto: Remota desde servidor; Local NO se pisa si no viene
          fotoRutaRemota: Value(_str(m['foto_ruta_remota'])),
          fotoRutaLocal: m['foto_ruta_local'] == null
              ? const Value.absent()
              : Value(_str(m['foto_ruta_local'])),
          genero: m['genero'] == null
              ? const Value.absent()
              : Value(m['genero'] as String?),
          notas: Value(_str(m['notas'])),
          createdAt: Value(_dt(m['created_at']) ?? DateTime.now().toUtc()),
          updatedAt: Value(_dt(m['updated_at']) ?? DateTime.now().toUtc()),
          deleted: Value((m['deleted'] as bool?) ?? false),
          isSynced: const Value(true),
        );
      }).toList();

      await _dao.upsertColaboradoresDrift(companions);
      print(
        '[👥 MENSAJES COLABORADORES SYNC] ✅ Upsert remoto selectivo: ${companions.length}',
      );
    } catch (e) {
      print('[👥 MENSAJES COLABORADORES SYNC] ❌ Error en PULL: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 🔧 Helper: mapear ColaboradorDb (Drift) → JSON snake_case para Supabase
  // ---------------------------------------------------------------------------
  Map<String, dynamic> _colaboradorToSupabase(ColaboradorDb c) {
    String? _iso(DateTime? d) => d?.toUtc().toIso8601String();
    return {
      'uid': c.uid,
      'nombres': c.nombres,
      'apellido_paterno': c.apellidoPaterno,
      'apellido_materno': c.apellidoMaterno,
      'fecha_nacimiento': _iso(c.fechaNacimiento),
      'curp': c.curp,
      'rfc': c.rfc,
      'telefono_movil': c.telefonoMovil,
      'email_personal': c.emailPersonal,
      'foto_ruta_remota': c.fotoRutaRemota,
      // Nota: NO enviamos foto_ruta_local al servidor
      'genero': c.genero,
      'notas': c.notas,
      'created_at': _iso(c.createdAt),
      'updated_at': _iso(c.updatedAt),
      'deleted': c.deleted,
    };
  }
}

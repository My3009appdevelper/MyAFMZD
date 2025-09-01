// ignore_for_file: avoid_print

import 'dart:io';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/reportes/reportes_dao.dart';
import 'package:myafmzd/database/reportes/reportes_service.dart';
import 'package:drift/drift.dart';

class ReportesSync {
  final ReportesDao _dao;
  final ReportesService _service;

  ReportesSync(AppDatabase db)
    : _dao = ReportesDao(db),
      _service = ReportesService(db);

  // ---------------------------------------------------------------------------
  // 📤 PUSH: subir cambios locales pendientes (isSynced == false)
  //   - Sube PDF si existe rutaLocal
  //   - Upsert metadata a 'reportes'
  //   - Marca isSynced=true en local
  // ---------------------------------------------------------------------------
  Future<void> pushReportesOffline() async {
    print('[🧾 MENSAJES REPORTES SYNC] ⬆️ PUSH: buscando pendientes...');
    final pendientes = await _dao.obtenerPendientesSyncDrift();

    if (pendientes.isEmpty) {
      print('[🧾 MENSAJES REPORTES SYNC] ✅ No hay pendientes de subida');
      return;
    }

    for (final r in pendientes) {
      try {
        // 1) Subir PDF a Storage si está disponible localmente y si no se encuentra en Storage
        final hasLocalPdf =
            r.rutaLocal.isNotEmpty && File(r.rutaLocal).existsSync();

        if (hasLocalPdf && r.rutaRemota.isNotEmpty) {
          final yaExiste = await _service.existsReporte(r.rutaRemota);
          if (!yaExiste) {
            await _service.uploadPDFOnline(File(r.rutaLocal), r.rutaRemota);
            print('[🧾 MENSAJES REPORTES SYNC] ☁️ PDF subido: ${r.rutaRemota}');
          } else {
            print(
              '[🧾 MENSAJES REPORTES SYNC] ⏭️ Remoto ya existe, no subo: ${r.rutaRemota}',
            );
          }
        } else {
          print(
            '[🧾 MENSAJES REPORTES SYNC] ⚠️ Sin PDF local o rutaRemota vacía para ${r.uid}',
          );
        }

        // 2) Upsert metadata en tabla 'reportes'
        final data = _reporteToSupabase(r);
        await _service.upsertReporteOnline(data);

        // 3) Marcar local como sincronizado
        await _dao.marcarComoSincronizadoDrift(r.uid, DateTime.now().toUtc());
        print('[🧾 MENSAJES REPORTES SYNC] ✅ Sincronizado: ${r.uid}');
      } catch (e) {
        print('[🧾 MENSAJES REPORTES SYNC] ❌ Error subiendo ${r.uid}: $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 📥 PULL: estrategia heads → diff → bulk fetch
  //   - 1) Obtener cabezas remotas (uid, updated_at)
  //   - 2) Comparar con estado local (updatedAt, isSynced)
  //   - 3) Traer SOLO los UIDs necesarios
  //   - 4) Upsert en Drift como sincronizados
  //   - (Opcional) no descarga PDFs aquí; solo metadata
  // ---------------------------------------------------------------------------
  Future<void> pullReportesOnline() async {
    print('[🧾 MENSAJES REPORTES SYNC] 📥 PULL: heads→diff→bulk');
    try {
      // 1) Heads remotos
      final heads = await _service.obtenerCabecerasOnline();
      if (heads.isEmpty) {
        print('[🧾 MENSAJES REPORTES SYNC] ℹ️ Sin filas remotas');
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
      final locales = await _dao.obtenerTodosDrift(); // rápido y suficiente
      final localMap = {
        for (final r in locales)
          r.uid: {'u': r.updatedAt.toUtc(), 's': r.isSynced},
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
        print('[🧾 MENSAJES REPORTES SYNC] ✅ Diff vacío: nada que bajar');
        return;
      }
      print(
        '[🧾 MENSAJES REPORTES SYNC] 🔽 Bajando ${toFetch.length} por diff',
      );

      // 5) Fetch selectivo por UIDs (trocea si esperas muchos)
      final remotos = await _service.obtenerPorUidsOnline(toFetch);
      if (remotos.isEmpty) {
        print('[🧾 MENSAJES REPORTES SYNC] ℹ️ Fetch selectivo devolvió 0');
        return;
      }

      // 6) Map → Companions (vienen de remoto ⇒ isSynced=true)
      DateTime? dt(String? s) =>
          (s == null || s.isEmpty) ? null : DateTime.parse(s).toUtc();

      final companions = remotos.map((m) {
        return ReportesCompanion(
          uid: Value(m['uid'] as String),
          nombre: Value((m['nombre'] as String?) ?? ''),
          fecha: Value(dt(m['fecha']) ?? DateTime.now().toUtc()),
          rutaRemota: Value((m['ruta_remota'] as String?) ?? ''),
          // Nunca asumimos descarga automática del PDF:
          // si el servidor manda 'ruta_local', la respetamos; si no, dejamos lo que ya está localmente.
          rutaLocal: m['ruta_local'] == null
              ? const Value.absent()
              : Value(m['ruta_local'] as String? ?? ''),
          tipo: Value((m['tipo'] as String?) ?? ''),
          updatedAt: Value(dt(m['updated_at']) ?? DateTime.now().toUtc()),
          isSynced: const Value(true),
          deleted: Value((m['deleted'] as bool?) ?? false),
        );
      }).toList();

      await _dao.upsertReportesDrift(companions);
      print(
        '[🧾 MENSAJES REPORTES SYNC] ✅ Upsert remoto selectivo: ${companions.length}',
      );
    } catch (e) {
      print('[🧾 MENSAJES REPORTES SYNC] ❌ Error en PULL: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 🔧 Helper: mapear ReportesDb (Drift) → JSON snake_case para Supabase
  // ---------------------------------------------------------------------------
  Map<String, dynamic> _reporteToSupabase(ReportesDb r) {
    String? iso(DateTime? d) => d?.toUtc().toIso8601String();
    return {
      'uid': r.uid,
      'nombre': r.nombre,
      'fecha': iso(r.fecha),
      'ruta_remota': r.rutaRemota,
      'tipo': r.tipo,
      'updated_at': iso(r.updatedAt),
      'deleted': r.deleted,
    };
  }
}

// lib/database/ventas/ventas_sync.dart
// ignore_for_file: avoid_print

import 'package:drift/drift.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/ventas/ventas_dao.dart';
import 'package:myafmzd/database/ventas/ventas_service.dart';

class VentasSync {
  final VentasDao _dao;
  final VentasService _service;

  VentasSync(AppDatabase db)
    : _dao = VentasDao(db),
      _service = VentasService(db);

  // ---------------------------------------------------------------------------
  // 📤 PUSH: Subir cambios locales pendientes (isSynced == false)
  //   - Upsert metadata en tabla `ventas`
  //   - Marcar isSynced=true en local (NO tocamos updatedAt aquí)
  // ---------------------------------------------------------------------------
  Future<void> pushVentasOffline() async {
    print('[💸 MENSAJES VENTAS SYNC] ⬆️ PUSH: buscando pendientes…');
    final pendientes = await _dao.obtenerPendientesSyncDrift();

    if (pendientes.isEmpty) {
      print('[💸 MENSAJES VENTAS SYNC] ✅ No hay pendientes de subida');
      return;
    }

    for (final v in pendientes) {
      try {
        final data = _ventaToSupabase(v);
        await _service.upsertVentaOnline(data);

        // Marcar como sincronizada (no sobrescribimos updatedAt local)
        await _dao.marcarComoSincronizadoDrift(v.uid);
        print('[💸 MENSAJES VENTAS SYNC] ✅ Sincronizado: ${v.uid}');
      } catch (e) {
        print('[💸 MENSAJES VENTAS SYNC] ❌ Error subiendo ${v.uid}: $e');
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
  Future<void> pullVentasOnline() async {
    print('[💸 MENSAJES VENTAS SYNC] 📥 PULL: heads→diff→bulk');
    try {
      // 1) Heads remotos
      final heads = await _service.obtenerCabecerasOnline();
      if (heads.isEmpty) {
        print('[💸 MENSAJES VENTAS SYNC] ℹ️ Sin filas remotas');
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
      final locales = await _dao.obtenerTodasDrift();
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
        if (localDominates) return; // cambio local pendiente → no pisar
        if (remoteIsNewer) toFetch.add(uid);
      });

      if (toFetch.isEmpty) {
        print('[💸 MENSAJES VENTAS SYNC] ✅ Diff vacío: nada que bajar');
        return;
      }
      print('[💸 MENSAJES VENTAS SYNC] 🔽 Bajando ${toFetch.length} por diff');

      // 5) Fetch selectivo por UIDs (troceable si esperas muchos)
      final remotos = await _service.obtenerPorUidsOnline(toFetch);
      if (remotos.isEmpty) {
        print('[💸 MENSAJES VENTAS SYNC] ❌ Fetch selectivo devolvió 0');
        return;
      }

      // 6) Map → Companions (remotos ⇒ isSynced=true)
      DateTime? dt(dynamic v) => (v == null || (v is String && v.isEmpty))
          ? null
          : DateTime.parse(v.toString()).toUtc();
      int? toIntN(dynamic v) =>
          (v == null) ? null : (v is int ? v : int.tryParse('$v'));
      int toInt(dynamic v, {int def = 0}) =>
          (v is int) ? v : (int.tryParse('$v') ?? def);
      String str(dynamic v, {String def = ''}) =>
          (v is String && v.isNotEmpty) ? v : (v?.toString() ?? def);
      bool toBool(dynamic v, {bool def = false}) =>
          (v is bool) ? v : (v == null ? def : v.toString() == 'true');

      final companions = remotos.map((m) {
        return VentasCompanion(
          uid: Value(m['uid'] as String),

          distribuidoraOrigenUid: Value(str(m['distribuidora_origen_uid'])),
          distribuidoraUid: Value(str(m['distribuidora_uid'])),
          vendedorUid: Value(str(m['vendedor_uid'])),
          folioContrato: Value(str(m['folio_contrato'])),
          modeloUid: Value(str(m['modelo_uid'])),
          estatusUid: Value(str(m['estatus_uid'])),

          grupo: Value(toInt(m['grupo'] ?? 0)),
          integrante: Value(toInt(m['integrante'] ?? 0)),

          fechaContrato: dt(m['fecha_contrato']) == null
              ? const Value.absent()
              : Value(dt(m['fecha_contrato'])!),
          fechaVenta: dt(m['fecha_venta']) == null
              ? const Value.absent()
              : Value(dt(m['fecha_venta'])!),

          mesVenta: toIntN(m['mes_venta']) == null
              ? const Value.absent()
              : Value(toIntN(m['mes_venta'])!),
          anioVenta: toIntN(m['anio_venta']) == null
              ? const Value.absent()
              : Value(toIntN(m['anio_venta'])!),

          createdAt: Value(dt(m['created_at']) ?? DateTime.now().toUtc()),
          updatedAt: Value(dt(m['updated_at']) ?? DateTime.now().toUtc()),
          deleted: Value(toBool(m['deleted'], def: false)),
          isSynced: const Value(true),
        );
      }).toList();

      await _dao.upsertVentasDrift(companions);
      print(
        '[💸 MENSAJES VENTAS SYNC] ✅ Upsert remoto selectivo: ${companions.length}',
      );
    } catch (e) {
      print('[💸 MENSAJES VENTAS SYNC] ❌ Error en PULL: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 🔧 Helper: mapear VentaDb (Drift) → JSON snake_case para Supabase
  // ---------------------------------------------------------------------------
  Map<String, dynamic> _ventaToSupabase(VentaDb v) {
    String? iso(DateTime? d) => d?.toUtc().toIso8601String();
    return {
      'uid': v.uid,
      'distribuidora_origen_uid': v.distribuidoraOrigenUid,
      'distribuidora_uid': v.distribuidoraUid,
      'vendedor_uid': v.vendedorUid,
      'folio_contrato': v.folioContrato,
      'modelo_uid': v.modeloUid,
      'estatus_uid': v.estatusUid,

      'grupo': v.grupo,
      'integrante': v.integrante,

      'fecha_contrato': iso(v.fechaContrato),
      'fecha_venta': iso(v.fechaVenta),
      'mes_venta': v.mesVenta,
      'anio_venta': v.anioVenta,

      'created_at': iso(v.createdAt),
      'updated_at': iso(v.updatedAt),
      'deleted': v.deleted,
    };
  }
}

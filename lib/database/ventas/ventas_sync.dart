// lib/database/ventas/ventas_sync.dart
// ignore_for_file: avoid_print

import 'package:drift/drift.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/syncState/sync_state_dao.dart';
import 'package:myafmzd/database/syncState/sync_state_service.dart';
import 'package:myafmzd/database/ventas/ventas_dao.dart';
import 'package:myafmzd/database/ventas/ventas_service.dart';

class VentasSync {
  final VentasDao _dao;
  final VentasService _service;

  final SyncStateDao _syncDao;
  final SyncStateService _syncService;

  static const String _resource = 'ventas';

  VentasSync(AppDatabase db)
    : _dao = VentasDao(db),
      _service = VentasService(db),
      _syncDao = SyncStateDao(db),
      _syncService = SyncStateService(db);

  // ────────────────────────────────────────────────────────────────────────────
  // 📤 PUSH: sube ventas pendientes y (si aplica) la marca de sync_state
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> pushVentasOffline() async {
    print('[💸 MENSAJES VENTAS SYNC] ⬆️ PUSH: buscando pendientes…');

    // 1) Ventas pendientes
    final pendientes = await _dao.obtenerPendientesSyncDrift();
    for (final v in pendientes) {
      try {
        final data = _ventaToSupabase(v);
        await _service.upsertVentaOnline(data);
        await _dao.marcarComoSincronizadoDrift(v.uid);
        print('[💸 MENSAJES VENTAS SYNC] ✅ Venta sincronizada: ${v.uid}');
      } catch (e) {
        print('[💸 MENSAJES VENTAS SYNC] ❌ Error subiendo ${v.uid}: $e');
      }
    }

    // 2) Marca de sync_state pendiente → empujar
    try {
      final ss = await _syncDao.obtenerPorResourceDrift(_resource);
      if (ss != null && ss.isSynced == false) {
        final mark = ss.updatedAt.toUtc();
        await _syncService.upsertMarcaRemotaOnline(
          resource: _resource,
          updatedAt: mark,
        );
        await _syncDao.marcarComoSincronizadoDrift(_resource);
        print('[💸 MENSAJES VENTAS SYNC] 🔖 Marca remota sincronizada → $mark');
      }
    } catch (e) {
      print(
        '[💸 MENSAJES VENTAS SYNC] ⚠️ Error empujando marca sync_state: $e',
      );
    }

    // 3) Bootstrap / alineación (seguridad)
    try {
      await _syncDao.initIfMissingDrift(resource: _resource);
      final rem = await _syncService.obtenerMarcaRemotaOnline(
        resource: _resource,
      );
      if (rem != null) {
        await _syncDao.setMarcaDesdeRemotoDrift(
          resource: _resource,
          remoteUpdatedAt: rem,
        );
        print('[💸 MENSAJES VENTAS SYNC] 🔖 Marca local alineada ← $rem');
      } else {
        final now = DateTime.now().toUtc();
        await _syncService.upsertMarcaRemotaOnline(
          resource: _resource,
          updatedAt: now,
        );
        await _syncDao.setMarcaDesdeRemotoDrift(
          resource: _resource,
          remoteUpdatedAt: now,
        );
        print(
          '[💸 MENSAJES VENTAS SYNC] 🔖 Marca remota creada y alineada ← $now',
        );
      }
    } catch (e) {
      print(
        '[💸 MENSAJES VENTAS SYNC] ⚠️ No se pudo alinear marca remota/local: $e',
      );
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // 📥 PULL: heads → diff → fetch selectivo (compara marcas primero)
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> pullVentasOnline() async {
    print('[💸 MENSAJES VENTAS SYNC] 📥 PULL: heads→diff→fetch');

    try {
      // 0) Comparar marcas para cortar temprano
      final localMark = await _syncDao.obtenerMarcaLocalUtcDrift(_resource);
      final remoteMark = await _syncService.obtenerMarcaRemotaOnline(
        resource: _resource,
      );

      print(
        '[💸 MENSAJES VENTAS SYNC] 🔎 marcas -> remota:$remoteMark | local:$localMark',
      );

      if (remoteMark == null || !remoteMark.isAfter(localMark)) {
        print(
          '[💸 MENSAJES VENTAS SYNC] ✅ Sin cambios remotos según sync_state',
        );
        return;
      }

      // 1) Heads remotos
      final heads = await _service.obtenerCabecerasOnline();
      if (heads.isEmpty) {
        print('[💸 MENSAJES VENTAS SYNC] ℹ️ Sin filas remotas');
        await _syncDao.setMarcaDesdeRemotoDrift(
          resource: _resource,
          remoteUpdatedAt: remoteMark,
        );
        return;
      }

      // 2) Mapa remoto uid→updated_at
      final remoteHead = <String, DateTime>{};
      for (final h in heads) {
        final uid = (h['uid'] ?? '').toString();
        final ru = h['updated_at'];
        if (uid.isEmpty || ru == null) continue;
        remoteHead[uid] = DateTime.parse(ru.toString()).toUtc();
      }

      // 3) Estado local mínimo
      final locales = await _dao.obtenerTodasDrift();
      final localMap = <String, Map<String, dynamic>>{
        for (final l in locales)
          l.uid: {'u': l.updatedAt.toUtc(), 's': l.isSynced},
      };

      // 4) Diff
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

        if (localDominates) return; // no pisar cambios locales pendientes
        if (remoteIsNewer) toFetch.add(uid);
      });

      if (toFetch.isEmpty) {
        print('[💸 MENSAJES VENTAS SYNC] ✅ Diff vacío: nada que bajar');
        await _syncDao.setMarcaDesdeRemotoDrift(
          resource: _resource,
          remoteUpdatedAt: remoteMark,
        );
        return;
      }

      print('[💸 MENSAJES VENTAS SYNC] 🔽 Bajando ${toFetch.length} por diff');

      // 5) Fetch selectivo
      final remotos = await _service.obtenerPorUidsOnline(toFetch);
      if (remotos.isEmpty) {
        print('[💸 MENSAJES VENTAS SYNC] ❌ Fetch selectivo devolvió 0');
        return;
      }

      // 6) Map a Companions (isSynced=true)
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

      // 7) Reflejar marca remota confirmada
      await _syncDao.setMarcaDesdeRemotoDrift(
        resource: _resource,
        remoteUpdatedAt: remoteMark,
      );
    } catch (e) {
      print('[💸 MENSAJES VENTAS SYNC] ❌ Error en PULL: $e');
      rethrow;
    }
  }

  // ────────────────────────────────────────────────────────────────────────────
  // 🔧 Mapper VentaDb → JSON Supabase (snake_case)
  // ────────────────────────────────────────────────────────────────────────────
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

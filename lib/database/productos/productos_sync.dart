// ignore_for_file: avoid_print

import 'package:drift/drift.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/productos/productos_dao.dart';
import 'package:myafmzd/database/productos/productos_service.dart';

class ProductosSync {
  final ProductosDao _dao;
  final ProductosService _service;

  ProductosSync(AppDatabase db)
    : _dao = ProductosDao(db),
      _service = ProductosService(db);

  // ---------------------------------------------------------------------------
  // 📤 PUSH: Subir cambios locales pendientes (isSynced == false)
  //   - Upsert metadata en tabla `productos`
  //   - Marcar isSynced=true en local (NO tocamos updatedAt aquí)
  // ---------------------------------------------------------------------------
  Future<void> pushProductosOffline() async {
    print('[🧮 MENSAJES PRODUCTOS SYNC] ⬆️ PUSH: buscando pendientes…');
    final pendientes = await _dao.obtenerPendientesSyncDrift();

    if (pendientes.isEmpty) {
      print('[🧮 MENSAJES PRODUCTOS SYNC] ✅ No hay pendientes de subida');
      return;
    }

    for (final p in pendientes) {
      try {
        final data = _productoToSupabase(p);
        await _service.upsertProductoOnline(data);

        await _dao.marcarComoSincronizadoDrift(p.uid);
        print('[🧮 MENSAJES PRODUCTOS SYNC] ✅ Sincronizado: ${p.uid}');
      } catch (e) {
        print('[🧮 MENSAJES PRODUCTOS SYNC] ❌ Error subiendo ${p.uid}: $e');
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
  Future<void> pullProductosOnline() async {
    print('[🧮 MENSAJES PRODUCTOS SYNC] 📥 PULL: heads→diff→bulk');
    try {
      // 1) Heads remotos
      final heads = await _service.obtenerCabecerasOnline();
      if (heads.isEmpty) {
        print('[🧮 MENSAJES PRODUCTOS SYNC] ℹ️ Sin filas remotas');
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
        for (final p in locales)
          p.uid: {'u': p.updatedAt.toUtc(), 's': p.isSynced},
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
        print('[🧮 MENSAJES PRODUCTOS SYNC] ✅ Diff vacío: nada que bajar');
        return;
      }
      print(
        '[🧮 MENSAJES PRODUCTOS SYNC] 🔽 Bajando ${toFetch.length} por diff',
      );

      // 5) Fetch selectivo por UIDs
      final remotos = await _service.obtenerPorUidsOnline(toFetch);
      if (remotos.isEmpty) {
        print('[🧮 MENSAJES PRODUCTOS SYNC] ❌ Fetch selectivo devolvió 0');
        return;
      }

      // 6) Map → Companions (remotos ⇒ isSynced=true)
      DateTime? dt(dynamic v) => (v == null || (v is String && v.isEmpty))
          ? null
          : DateTime.parse(v.toString()).toUtc();
      double toDouble(dynamic v) =>
          (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;
      int toInt(dynamic v) => (v is int) ? v : int.tryParse('$v') ?? 0;
      bool toBool(dynamic v) => (v is bool) ? v : (v?.toString() == 'true');

      final companions = remotos.map((m) {
        return ProductosCompanion(
          uid: Value(m['uid'] as String),
          nombre: Value((m['nombre'] as String?) ?? 'Autofinanciamiento Puro'),
          activo: Value(toBool(m['activo'])),
          plazoMeses: Value(toInt(m['plazo_meses'])),
          factorIntegrante: Value(toDouble(m['factor_integrante'])),
          factorPropietario: Value(toDouble(m['factor_propietario'])),
          cuotaInscripcionPct: Value(toDouble(m['cuota_inscripcion_pct'])),
          cuotaAdministracionPct: Value(
            toDouble(m['cuota_administracion_pct']),
          ),
          ivaCuotaAdministracionPct: Value(
            toDouble(m['iva_cuota_administracion_pct']),
          ),
          cuotaSeguroVidaPct: Value(toDouble(m['cuota_seguro_vida_pct'])),
          adelantoMinMens: Value(toInt(m['adelanto_min_mens'])),
          adelantoMaxMens: Value(toInt(m['adelanto_max_mens'])),
          mesEntregaMin: Value(toInt(m['mes_entrega_min'])),
          mesEntregaMax: Value(toInt(m['mes_entrega_max'])),
          prioridad: Value(toInt(m['prioridad'])),
          notas: Value((m['notas'] as String?) ?? ''),
          vigenteDesde: m['vigente_desde'] == null
              ? const Value.absent()
              : Value(dt(m['vigente_desde'])),
          vigenteHasta: m['vigente_hasta'] == null
              ? const Value.absent()
              : Value(dt(m['vigente_hasta'])),
          createdAt: Value(dt(m['created_at']) ?? DateTime.now().toUtc()),
          updatedAt: Value(dt(m['updated_at']) ?? DateTime.now().toUtc()),
          deleted: Value(toBool(m['deleted'])),
          isSynced: const Value(true),
        );
      }).toList();

      await _dao.upsertProductosDrift(companions);
      print(
        '[🧮 MENSAJES PRODUCTOS SYNC] ✅ Upsert remoto selectivo: ${companions.length}',
      );
    } catch (e) {
      print('[🧮 MENSAJES PRODUCTOS SYNC] ❌ Error en PULL: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 🔧 Helper: mapear ProductoDb (Drift) → JSON snake_case para Supabase
  // ---------------------------------------------------------------------------
  Map<String, dynamic> _productoToSupabase(ProductoDb p) {
    String? iso(DateTime? d) => d?.toUtc().toIso8601String();
    return {
      'uid': p.uid,
      'nombre': p.nombre,
      'activo': p.activo,
      'plazo_meses': p.plazoMeses,
      'factor_integrante': p.factorIntegrante,
      'factor_propietario': p.factorPropietario,
      'cuota_inscripcion_pct': p.cuotaInscripcionPct,
      'cuota_administracion_pct': p.cuotaAdministracionPct,
      'iva_cuota_administracion_pct': p.ivaCuotaAdministracionPct,
      'cuota_seguro_vida_pct': p.cuotaSeguroVidaPct,
      'adelanto_min_mens': p.adelantoMinMens,
      'adelanto_max_mens': p.adelantoMaxMens,
      'mes_entrega_min': p.mesEntregaMin,
      'mes_entrega_max': p.mesEntregaMax,
      'prioridad': p.prioridad,
      'notas': p.notas,
      'vigente_desde': iso(p.vigenteDesde),
      'vigente_hasta': iso(p.vigenteHasta),
      'created_at': iso(p.createdAt),
      'updated_at': iso(p.updatedAt),
      'deleted': p.deleted,
    };
  }
}

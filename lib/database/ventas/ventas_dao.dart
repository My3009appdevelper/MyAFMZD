// lib/database/ventas/ventas_dao.dart

import 'package:drift/drift.dart';
import 'package:myafmzd/database/app_database.dart';
import 'ventas_table.dart';

part 'ventas_dao.g.dart';

@DriftAccessor(tables: [Ventas])
class VentasDao extends DatabaseAccessor<AppDatabase> with _$VentasDaoMixin {
  VentasDao(super.db);

  // ---------------------------------------------------------------------------
  // 📌 CRUD BÁSICO (solo local con Companions)
  // ---------------------------------------------------------------------------

  /// Upsert de una venta (parcial o completa).
  Future<void> upsertVentaDrift(VentasCompanion row) async {
    await into(ventas).insertOnConflictUpdate(row);
  }

  /// Upsert de múltiples ventas en batch.
  Future<void> upsertVentasDrift(List<VentasCompanion> lista) async {
    if (lista.isEmpty) return;
    await batch((b) => b.insertAllOnConflictUpdate(ventas, lista));
  }

  /// Actualización parcial por UID (solo columnas provistas en [cambios]).
  Future<int> actualizarParcialPorUid(String uid, VentasCompanion cambios) {
    return (update(ventas)..where((t) => t.uid.equals(uid))).write(cambios);
  }

  /// Soft delete: marca deleted=true, isSynced=false y toca updatedAt (UTC).
  Future<void> marcarComoEliminadasDrift(List<String> uids) async {
    if (uids.isEmpty) return;
    await (update(ventas)..where((t) => t.uid.isIn(uids))).write(
      VentasCompanion(
        deleted: const Value(true),
        isSynced: const Value(false),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 📌 CONSULTAS (solo local)
  // ---------------------------------------------------------------------------

  /// Obtener una venta por UID.
  Future<VentaDb?> obtenerPorUidDrift(String uid) {
    return (select(ventas)..where((t) => t.uid.equals(uid))).getSingleOrNull();
  }

  /// Obtener por folio exacto (útil para validación / búsqueda directa).
  Future<VentaDb?> obtenerPorFolioDrift(String folioContrato) {
    return (select(
      ventas,
    )..where((t) => t.folioContrato.equals(folioContrato))).getSingleOrNull();
  }

  /// ¿Existe un folio? (puedes excluir un UID para escenarios de edición).
  Future<bool> existeFolioDrift(
    String folioContrato, {
    String? excluirUid,
  }) async {
    final q = select(ventas)
      ..where((t) => t.folioContrato.equals(folioContrato))
      ..where((t) => t.deleted.equals(false));
    if (excluirUid != null && excluirUid.isNotEmpty) {
      q.where((t) => t.uid.isNotIn([excluirUid]));
    }
    final rows = await q.get();
    return rows.isNotEmpty;
  }

  /// Obtener todas (incluye eliminadas).
  Future<List<VentaDb>> obtenerTodasDrift() {
    return select(ventas).get();
  }

  /// Obtener NO eliminadas, ordenadas por fechaVenta DESC (y luego updatedAt).
  Future<List<VentaDb>> obtenerTodasNoDeletedDrift() {
    return (select(ventas)
          ..where((t) => t.deleted.equals(false))
          ..orderBy([
            // Primero por fechaVenta (nuevas arriba). Si es null, caerá en updatedAt.
            (t) =>
                OrderingTerm(expression: t.fechaVenta, mode: OrderingMode.desc),
            (t) =>
                OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// Búsqueda por texto en folioContrato (NO eliminadas).
  Future<List<VentaDb>> buscarPorFolioDrift(String query) {
    final like = '%${query.trim()}%';
    return (select(ventas)
          ..where((t) => t.deleted.equals(false) & t.folioContrato.like(like))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.fechaVenta, mode: OrderingMode.desc),
            (t) =>
                OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// Listar por vendedor (NO eliminadas), ordenado por fechaVenta DESC.
  Future<List<VentaDb>> listarPorVendedorDrift(String vendedorUid) {
    return (select(ventas)
          ..where(
            (t) => t.deleted.equals(false) & t.vendedorUid.equals(vendedorUid),
          )
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.fechaVenta, mode: OrderingMode.desc),
            (t) =>
                OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// Listar por distribuidora actual (NO eliminadas).
  Future<List<VentaDb>> listarPorDistribuidoraDrift(String distribuidoraUid) {
    return (select(ventas)
          ..where(
            (t) =>
                t.deleted.equals(false) &
                t.distribuidoraUid.equals(distribuidoraUid),
          )
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.fechaVenta, mode: OrderingMode.desc),
            (t) =>
                OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// Listar por año/mes (NO eliminadas). Si [mes] es null, trae todo el año.
  Future<List<VentaDb>> listarPorAnioMesDrift({required int anio, int? mes}) {
    final q = select(ventas)
      ..where((t) => t.deleted.equals(false) & t.anioVenta.equals(anio));
    if (mes != null) {
      q.where((t) => t.mesVenta.equals(mes));
    }
    q.orderBy([
      (t) => OrderingTerm(expression: t.fechaVenta, mode: OrderingMode.desc),
      (t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
    ]);
    return q.get();
  }

  /// Listar por rango de fechas de venta [inicio..fin] (NO eliminadas).
  /// Considera solo filas con `fechaVenta` no nula.
  Future<List<VentaDb>> listarPorRangoFechasDrift({
    required DateTime inicio,
    required DateTime fin,
  }) {
    final ini = inicio.toUtc();
    final fn = fin.toUtc();
    return (select(ventas)
          ..where(
            (t) =>
                t.deleted.equals(false) &
                t.fechaVenta.isBiggerOrEqualValue(ini) &
                t.fechaVenta.isSmallerOrEqualValue(fn),
          )
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.fechaVenta, mode: OrderingMode.desc),
            (t) =>
                OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  /// Listar por estatus (NO eliminadas).
  Future<List<VentaDb>> listarPorEstatusDrift(String estatusUid) {
    return (select(ventas)
          ..where(
            (t) => t.deleted.equals(false) & t.estatusUid.equals(estatusUid),
          )
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.fechaVenta, mode: OrderingMode.desc),
            (t) =>
                OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  // ---------------------------------------------------------------------------
  // 📌 SINCRONIZACIÓN (estado local)
  // ---------------------------------------------------------------------------

  /// Filas pendientes de sincronizar (isSynced == false).
  Future<List<VentaDb>> obtenerPendientesSyncDrift() {
    return (select(ventas)..where((t) => t.isSynced.equals(false))).get();
  }

  /// Marcar como sincronizado (no toca updatedAt).
  Future<void> marcarComoSincronizadoDrift(String uid) async {
    await (update(ventas)..where((t) => t.uid.equals(uid))).write(
      const VentasCompanion(isSynced: Value(true), updatedAt: Value.absent()),
    );
  }

  /// Última actualización local considerando SOLO sincronizados.
  Future<DateTime?> obtenerUltimaActualizacionDrift() async {
    final row =
        await (select(ventas)
              ..where((t) => t.isSynced.equals(true))
              ..orderBy([
                (t) => OrderingTerm(
                  expression: t.updatedAt,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();
    return row?.updatedAt;
  }
}

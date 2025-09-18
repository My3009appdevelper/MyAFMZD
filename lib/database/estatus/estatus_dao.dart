// lib/database/estatus/estatus_dao.dart
// ignore_for_file: avoid_print

import 'package:drift/drift.dart';
import 'package:myafmzd/database/app_database.dart';
import 'estatus_table.dart';

part 'estatus_dao.g.dart';

@DriftAccessor(tables: [Estatus])
class EstatusDao extends DatabaseAccessor<AppDatabase> with _$EstatusDaoMixin {
  EstatusDao(super.db);

  // ---------------------------------------------------------------------------
  // 📌 CRUD BÁSICO
  // ---------------------------------------------------------------------------

  /// Upsert de un estatus (parcial o completo).
  Future<void> upsertEstatusDrift(EstatusCompanion row) async {
    print('[EstatusDao] upsertEstatusDrift -> ${row.uid.value}');
    await into(estatus).insertOnConflictUpdate(row);
  }

  /// Upsert de múltiples estatus en batch.
  Future<void> upsertEstatusListaDrift(List<EstatusCompanion> lista) async {
    if (lista.isEmpty) return;
    print('[EstatusDao] upsertEstatusListaDrift -> ${lista.length} filas');
    await batch((b) => b.insertAllOnConflictUpdate(estatus, lista));
  }

  /// Actualización parcial por UID (solo columnas provistas en [cambios]).
  Future<int> actualizarParcialPorUid(String uid, EstatusCompanion cambios) {
    print('[EstatusDao] actualizarParcialPorUid -> $uid');
    return (update(estatus)..where((t) => t.uid.equals(uid))).write(cambios);
  }

  /// Soft delete: marca deleted=true, isSynced=false y toca updatedAt (UTC).
  Future<void> marcarComoEliminadosDrift(List<String> uids) async {
    if (uids.isEmpty) return;
    print('[EstatusDao] marcarComoEliminadosDrift -> ${uids.length} uids');
    await (update(estatus)..where((t) => t.uid.isIn(uids))).write(
      EstatusCompanion(
        deleted: const Value(true),
        isSynced: const Value(false),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 📌 CONSULTAS
  // ---------------------------------------------------------------------------

  /// Obtener un estatus por UID.
  Future<EstatusDb?> obtenerPorUidDrift(String uid) {
    print('[EstatusDao] obtenerPorUidDrift -> $uid');
    return (select(estatus)..where((t) => t.uid.equals(uid))).getSingleOrNull();
  }

  /// Obtener todos (incluye eliminados).
  Future<List<EstatusDb>> obtenerTodosDrift() {
    print('[EstatusDao] obtenerTodosDrift');
    return select(estatus).get();
  }

  /// Obtener NO eliminados, ordenados por categoria, orden y nombre.
  Future<List<EstatusDb>> obtenerTodosNoDeletedDrift() {
    print('[EstatusDao] obtenerTodosNoDeletedDrift');
    return (select(estatus)
          ..where((t) => t.deleted.equals(false))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.categoria, mode: OrderingMode.asc),
            (t) => OrderingTerm(expression: t.orden, mode: OrderingMode.asc),
            (t) => OrderingTerm(expression: t.nombre, mode: OrderingMode.asc),
          ]))
        .get();
  }

  /// Obtener por categoría (NO eliminados), ordenados por orden y nombre.
  Future<List<EstatusDb>> obtenerPorCategoriaDrift(String categoria) {
    print('[EstatusDao] obtenerPorCategoriaDrift -> $categoria');
    return (select(estatus)
          ..where(
            (t) => t.deleted.equals(false) & t.categoria.equals(categoria),
          )
          ..orderBy([
            (t) => OrderingTerm(expression: t.orden, mode: OrderingMode.asc),
            (t) => OrderingTerm(expression: t.nombre, mode: OrderingMode.asc),
          ]))
        .get();
  }

  /// Búsqueda por texto en nombre/categoría (NO eliminados).
  Future<List<EstatusDb>> buscarPorTextoDrift(String query) {
    final q = '%${query.trim()}%';
    print('[EstatusDao] buscarPorTextoDrift -> "$query"');
    return (select(estatus)
          ..where(
            (t) =>
                t.deleted.equals(false) &
                (t.nombre.like(q) | t.categoria.like(q)),
          )
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.categoria, mode: OrderingMode.asc),
            (t) => OrderingTerm(expression: t.orden, mode: OrderingMode.asc),
            (t) => OrderingTerm(expression: t.nombre, mode: OrderingMode.asc),
          ]))
        .get();
  }

  /// Cambia visibilidad sincrónica (NO toca isSynced para que suba en push).
  Future<int> setVisibleDrift(String uid, bool visible) {
    print('[EstatusDao] setVisibleDrift -> $uid : $visible');
    return (update(estatus)..where((t) => t.uid.equals(uid))).write(
      EstatusCompanion(
        visible: Value(visible),
        updatedAt: Value(DateTime.now().toUtc()),
        isSynced: const Value(false),
      ),
    );
  }

  /// Ajusta el orden (NO toca isSynced? Sí, para subir cambio).
  Future<int> setOrdenDrift(String uid, int orden) {
    print('[EstatusDao] setOrdenDrift -> $uid : $orden');
    return (update(estatus)..where((t) => t.uid.equals(uid))).write(
      EstatusCompanion(
        orden: Value(orden),
        updatedAt: Value(DateTime.now().toUtc()),
        isSynced: const Value(false),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 📌 SINCRONIZACIÓN
  // ---------------------------------------------------------------------------

  /// Filas pendientes de sincronizar (isSynced == false).
  Future<List<EstatusDb>> obtenerPendientesSyncDrift() {
    print('[EstatusDao] obtenerPendientesSyncDrift');
    return (select(estatus)..where((t) => t.isSynced.equals(false))).get();
  }

  /// Marcar como sincronizado (no toca updatedAt).
  Future<void> marcarComoSincronizadoDrift(String uid) async {
    print('[EstatusDao] marcarComoSincronizadoDrift -> $uid');
    await (update(estatus)..where((t) => t.uid.equals(uid))).write(
      const EstatusCompanion(isSynced: Value(true), updatedAt: Value.absent()),
    );
  }

  /// Última actualización local considerando SOLO sincronizados.
  Future<DateTime?> obtenerUltimaActualizacionDrift() async {
    print('[EstatusDao] obtenerUltimaActualizacionDrift');
    final row =
        await (select(estatus)
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

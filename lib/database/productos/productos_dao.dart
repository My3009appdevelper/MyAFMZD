import 'package:drift/drift.dart';
import 'package:myafmzd/database/app_database.dart';
import 'productos_table.dart';

part 'productos_dao.g.dart';

@DriftAccessor(tables: [Productos])
class ProductosDao extends DatabaseAccessor<AppDatabase>
    with _$ProductosDaoMixin {
  ProductosDao(super.db);

  // ---------------------------------------------------------------------------
  // 📌 CRUD BÁSICO
  // ---------------------------------------------------------------------------

  /// Insertar o actualizar un producto (parcial o completo).
  Future<void> upsertProductoDrift(ProductosCompanion producto) =>
      into(productos).insertOnConflictUpdate(producto);

  /// Insertar/actualizar múltiples productos.
  Future<void> upsertProductosDrift(List<ProductosCompanion> lista) async {
    if (lista.isEmpty) return;
    await batch((b) => b.insertAllOnConflictUpdate(productos, lista));
  }

  /// Actualización parcial por UID (solo escribe las columnas provistas).
  Future<int> actualizarParcialPorUid(String uid, ProductosCompanion cambios) {
    return (update(productos)..where((t) => t.uid.equals(uid))).write(cambios);
  }

  /// Soft delete: marcar productos como eliminados.
  Future<void> marcarComoEliminadosDrift(List<String> uids) async {
    if (uids.isEmpty) return;
    await (update(productos)..where((t) => t.uid.isIn(uids))).write(
      ProductosCompanion(
        deleted: const Value(true),
        isSynced: const Value(false),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 📌 CONSULTAS
  // ---------------------------------------------------------------------------

  /// Obtener un producto por UID.
  Future<ProductoDb?> obtenerPorUidDrift(String uid) =>
      (select(productos)..where((t) => t.uid.equals(uid))).getSingleOrNull();

  /// Obtener todos (incluye eliminados).
  Future<List<ProductoDb>> obtenerTodosDrift() => select(productos).get();

  /// Obtener NO eliminados, ordenados por prioridad y nombre.
  Future<List<ProductoDb>> obtenerTodosNoDeletedDrift() {
    return (select(productos)
          ..where((t) => t.deleted.equals(false))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.prioridad, mode: OrderingMode.asc),
            (t) => OrderingTerm(expression: t.nombre, mode: OrderingMode.asc),
          ]))
        .get();
  }

  /// Obtener productos ACTIVOS y VIGENTES en una fecha dada (por defecto: ahora).
  Future<List<ProductoDb>> obtenerActivosVigentesDrift({DateTime? enFecha}) {
    final f = (enFecha ?? DateTime.now()).toUtc();
    return (select(productos)
          ..where(
            (t) =>
                t.deleted.equals(false) &
                t.activo.equals(true) &
                // vigenteDesde <= f o nulo
                (t.vigenteDesde.isNull() |
                    t.vigenteDesde.isSmallerOrEqualValue(f)) &
                // vigenteHasta >= f o nulo
                (t.vigenteHasta.isNull() |
                    t.vigenteHasta.isBiggerOrEqualValue(f)),
          )
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.prioridad, mode: OrderingMode.asc),
            (t) => OrderingTerm(expression: t.nombre, mode: OrderingMode.asc),
          ]))
        .get();
  }

  /// Obtener el PRIMER producto activo/vigente (por prioridad). Útil para default.
  Future<ProductoDb?> obtenerActivoVigenteTopDrift({DateTime? enFecha}) async {
    final list = await obtenerActivosVigentesDrift(enFecha: enFecha);
    if (list.isEmpty) return null;
    return list.first;
  }

  // ---------------------------------------------------------------------------
  // 📌 SINCRONIZACIÓN
  // ---------------------------------------------------------------------------

  /// Productos pendientes de subida (isSynced == false).
  Future<List<ProductoDb>> obtenerPendientesSyncDrift() {
    return (select(productos)..where((t) => t.isSynced.equals(false))).get();
  }

  /// Marcar como sincronizado (no tocamos updatedAt).
  Future<void> marcarComoSincronizadoDrift(String uid) async {
    await (update(productos)..where((t) => t.uid.equals(uid))).write(
      const ProductosCompanion(
        isSynced: Value(true),
        updatedAt: Value.absent(),
      ),
    );
  }

  /// Última actualización local considerando SOLO sincronizados.
  Future<DateTime?> obtenerUltimaActualizacionDrift() async {
    final row =
        await (select(productos)
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

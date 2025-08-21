import 'package:drift/drift.dart';
import 'package:myafmzd/database/app_database.dart';
import 'modelo_imagenes_table.dart';

part 'modelo_imagenes_dao.g.dart';

@DriftAccessor(tables: [ModeloImagenes])
class ModeloImagenesDao extends DatabaseAccessor<AppDatabase>
    with _$ModeloImagenesDaoMixin {
  ModeloImagenesDao(super.db);

  // ---------------------------------------------------------------------------
  // 📌 CRUD BÁSICO
  // ---------------------------------------------------------------------------

  Future<void> upsertImagenDrift(ModeloImagenesCompanion modeloImagen) =>
      into(modeloImagenes).insertOnConflictUpdate(modeloImagen);

  Future<void> upsertImagenesDrift(List<ModeloImagenesCompanion> lista) async {
    if (lista.isEmpty) return;
    await batch((b) => b.insertAllOnConflictUpdate(modeloImagenes, lista));
  }

  Future<void> eliminarImagenesDeModeloDrift(String modeloUid) async {
    await (delete(
      modeloImagenes,
    )..where((t) => t.modeloUid.equals(modeloUid))).go();
  }

  // ---------------------------------------------------------------------------
  // 📌 CONSULTAS
  // ---------------------------------------------------------------------------

  Future<List<ModeloImagenDb>> obtenerTodosDrift() =>
      select(modeloImagenes).get();

  Future<List<ModeloImagenDb>> obtenerPorModeloDrift(String modeloUid) =>
      (select(modeloImagenes)
            ..where((t) => t.modeloUid.equals(modeloUid))
            ..orderBy([
              (t) =>
                  OrderingTerm(expression: t.modeloUid, mode: OrderingMode.asc),
            ]))
          .get();

  // ---------------------------------------------------------------------------
  // 📌 SINCRONIZACIÓN
  // ---------------------------------------------------------------------------
  Future<List<ModeloImagenDb>> obtenerPendientesSyncDrift() =>
      (select(modeloImagenes)..where((t) => t.isSynced.equals(false))).get();

  Future<void> marcarComoSincronizadoDrift(String uid) async {
    await (update(modeloImagenes)..where((t) => t.uid.equals(uid))).write(
      const ModeloImagenesCompanion(
        isSynced: Value(true),
        updatedAt: Value.absent(),
      ),
    );
  }

  Future<DateTime?> obtenerUltimaActualizacionDrift() async {
    final row =
        await (select(modeloImagenes)
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

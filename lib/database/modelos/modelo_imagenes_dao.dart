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

  // Upsert preservando columnas locales (rutaLocal)
  Future<void> upsertImagenRemotaPreservandoLocal(
    ModeloImagenesCompanion remote,
  ) async {
    // Nos aseguramos de no tocar rutaLocal en el UPDATE.
    final sanitized = remote.copyWith(rutaLocal: const Value.absent());

    await into(modeloImagenes).insert(
      sanitized,
      onConflict: DoUpdate(
        (old) => sanitized, // usa los mismos valores del insert
        target: [modeloImagenes.uid], // conflicto por PK (uid)
      ),
    );
  }

  // Upsert de MUCHAS filas remotas preservando columnas locales (batch)
  // Nota: usamos batch con insert() por cada fila para poder pasar su Companion.
  Future<void> upsertImagenesRemotasPreservandoLocal(
    List<ModeloImagenesCompanion> rows,
  ) async {
    if (rows.isEmpty) return;

    await batch((b) {
      for (final r in rows) {
        final sanitized = r.copyWith(rutaLocal: const Value.absent());
        b.insert(
          modeloImagenes,
          sanitized,
          onConflict: DoUpdate(
            (old) => sanitized,
            target: [modeloImagenes.uid],
          ),
        );
      }
    });
  }

  // actualizarParcialPorUid
  Future<int> actualizarParcialPorUid(
    String uid,
    ModeloImagenesCompanion cambios,
  ) {
    return (update(
      modeloImagenes,
    )..where((t) => t.uid.equals(uid))).write(cambios);
  }

  /// Soft delete de TODAS las imágenes de un modelo (para sync correcto)
  Future<int> marcarComoEliminadasDeModeloDrift(String modeloUid) {
    return (update(
      modeloImagenes,
    )..where((t) => t.modeloUid.equals(modeloUid))).write(
      ModeloImagenesCompanion(
        deleted: const Value(true),
        isSynced: const Value(false),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
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
                  OrderingTerm(expression: t.updatedAt, mode: OrderingMode.asc),
            ]))
          .get();

  Future<ModeloImagenDb?> obtenerPorShaEnModeloDrift(
    String modeloUid,
    String sha,
  ) =>
      (select(modeloImagenes)
            ..where(
              (t) =>
                  t.modeloUid.equals(modeloUid) &
                  t.sha256.equals(sha) &
                  t.deleted.equals(false),
            )
            ..limit(1))
          .getSingleOrNull();

  // portada actual (activa) de un modelo
  Future<ModeloImagenDb?> obtenerCoverDeModeloDrift(String modeloUid) =>
      (select(modeloImagenes)
            ..where(
              (t) =>
                  t.modeloUid.equals(modeloUid) &
                  t.deleted.equals(false) &
                  t.isCover.equals(true),
            )
            ..limit(1))
          .getSingleOrNull();

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

  // ---------------------------------------------------------------------------
  // DUPLICACIONES
  // ---------------------------------------------------------------------------
  // ¿Existe una imagen (activa) con este sha en el modelo?
  Future<bool> existeShaEnModeloDrift(String modeloUid, String sha) async {
    final q =
        await (select(modeloImagenes)..where(
              (t) =>
                  t.modeloUid.equals(modeloUid) &
                  t.sha256.equals(sha) &
                  t.deleted.equals(false),
            ))
            .get();
    return q.isNotEmpty;
  }
}

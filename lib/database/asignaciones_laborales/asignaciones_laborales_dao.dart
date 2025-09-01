import 'package:drift/drift.dart';
import 'package:myafmzd/database/app_database.dart';
import 'asignaciones_laborales_table.dart';

part 'asignaciones_laborales_dao.g.dart';

@DriftAccessor(tables: [AsignacionesLaborales])
class AsignacionesLaboralesDao extends DatabaseAccessor<AppDatabase>
    with _$AsignacionesLaboralesDaoMixin {
  AsignacionesLaboralesDao(super.db);

  // ---------------------------------------------------------------------------
  // 📌 CRUD BÁSICO (solo local con Companions)
  // ---------------------------------------------------------------------------

  /// Insertar o actualizar una asignación (parcial o completa).
  Future<void> upsertAsignacionLaboralDrift(
    AsignacionesLaboralesCompanion asignacion,
  ) => into(asignacionesLaborales).insertOnConflictUpdate(asignacion);

  /// Insertar/actualizar múltiples asignaciones.
  Future<void> upsertAsignacionesLaboralesDrift(
    List<AsignacionesLaboralesCompanion> lista,
  ) async {
    if (lista.isEmpty) return;
    await batch(
      (b) => b.insertAllOnConflictUpdate(asignacionesLaborales, lista),
    );
  }

  /// Update parcial por UID.
  Future<int> actualizarParcialPorUid(
    String uid,
    AsignacionesLaboralesCompanion cambios,
  ) {
    return (update(
      asignacionesLaborales,
    )..where((t) => t.uid.equals(uid))).write(cambios);
  }

  /// Soft delete masivo por UIDs.
  Future<void> marcarComoEliminadasDrift(List<String> uids) async {
    if (uids.isEmpty) return;
    await (update(asignacionesLaborales)..where((t) => t.uid.isIn(uids))).write(
      AsignacionesLaboralesCompanion(
        deleted: const Value(true),
        isSynced: const Value(false),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🔧 Helpers de negocio (garantizar 1 activa por colaborador)
  // ---------------------------------------------------------------------------

  /// Cierra TODAS las asignaciones activas (fechaFin IS NULL) de un colaborador.
  Future<int> cerrarAsignacionesActivasDeColaboradorDrift(
    String colaboradorUid, {
    DateTime? fechaFin,
    String? closedByUsuarioUid,
  }) {
    final fin = fechaFin ?? DateTime.now().toUtc();
    return (update(asignacionesLaborales)..where(
          (t) =>
              t.colaboradorUid.equals(colaboradorUid) &
              t.fechaFin.isNull() &
              t.deleted.equals(false),
        ))
        .write(
          AsignacionesLaboralesCompanion(
            fechaFin: Value(fin),
            closedByUsuarioUid: closedByUsuarioUid != null
                ? Value(closedByUsuarioUid)
                : const Value.absent(),
            isSynced: const Value(false),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
  }

  /// Cierra por UID una asignación activa.
  Future<int> cerrarAsignacionPorUidDrift(
    String uid, {
    DateTime? fechaFin,
    String? closedByUsuarioUid,
  }) {
    final fin = fechaFin ?? DateTime.now().toUtc();
    return (update(
      asignacionesLaborales,
    )..where((t) => t.uid.equals(uid))).write(
      AsignacionesLaboralesCompanion(
        fechaFin: Value(fin),
        closedByUsuarioUid: closedByUsuarioUid != null
            ? Value(closedByUsuarioUid)
            : const Value.absent(),
        isSynced: const Value(false),
        updatedAt: Value(DateTime.now().toUtc()),
      ),
    );
  }

  /// Abre una NUEVA asignación cerrando antes las activas del colaborador.
  /// Útil para movimientos (cambios de distribuidor/rol/puesto).
  Future<void> abrirNuevaCerrandoActivasDrift(
    AsignacionesLaboralesCompanion nueva,
  ) async {
    await transaction(() async {
      // 1) Cierra activas del colaborador
      await (update(asignacionesLaborales)..where(
            (t) =>
                t.colaboradorUid.equals(nueva.colaboradorUid.value) &
                t.fechaFin.isNull() &
                t.deleted.equals(false),
          ))
          .write(
            AsignacionesLaboralesCompanion(
              fechaFin: Value(nueva.fechaInicio.value),
              isSynced: const Value(false),
              updatedAt: Value(DateTime.now().toUtc()),
            ),
          );

      // 2) Inserta la nueva
      await into(asignacionesLaborales).insertOnConflictUpdate(nueva);
    });
  }

  // ---------------------------------------------------------------------------
  // 📌 CONSULTAS (solo local)
  // ---------------------------------------------------------------------------

  /// Obtener por UID.
  Future<AsignacionLaboralDb?> obtenerPorUidDrift(String uid) => (select(
    asignacionesLaborales,
  )..where((t) => t.uid.equals(uid))).getSingleOrNull();

  /// Asignación ACTIVA de un colaborador (si existe).
  Future<AsignacionLaboralDb?> obtenerActivaPorColaboradorDrift(
    String colaboradorUid,
  ) {
    return (select(asignacionesLaborales)
          ..where(
            (t) =>
                t.colaboradorUid.equals(colaboradorUid) &
                t.fechaFin.isNull() &
                t.deleted.equals(false),
          )
          ..orderBy([
            (t) => OrderingTerm(
              expression: t.fechaInicio,
              mode: OrderingMode.desc,
            ),
          ])
          ..limit(1))
        .getSingleOrNull();
  }

  /// Histórico (todas) por colaborador.
  Future<List<AsignacionLaboralDb>> obtenerHistoricoPorColaboradorDrift(
    String colaboradorUid, {
    bool incluirEliminadas = false,
  }) {
    final q = select(asignacionesLaborales)
      ..where(
        (t) =>
            t.colaboradorUid.equals(colaboradorUid) &
            (incluirEliminadas
                ? const Constant(true)
                : t.deleted.equals(false)),
      )
      ..orderBy([
        (t) => OrderingTerm(expression: t.fechaInicio, mode: OrderingMode.desc),
      ]);
    return q.get();
  }

  /// Activas por distribuidor y rol (rol opcional).
  Future<List<AsignacionLaboralDb>> obtenerActivasPorDistribuidorYRolDrift({
    required String distribuidorUid,
    String? rol,
  }) {
    final q = select(asignacionesLaborales)
      ..where((t) {
        var expr =
            t.distribuidorUid.equals(distribuidorUid) &
            t.fechaFin.isNull() &
            t.deleted.equals(false);
        if (rol != null && rol.isNotEmpty) {
          expr = expr & t.rol.equals(rol);
        }
        return expr;
      })
      ..orderBy([
        (t) => OrderingTerm(expression: t.fechaInicio, mode: OrderingMode.asc),
      ]);
    return q.get();
  }

  /// Activas por manager (jefe directo).
  Future<List<AsignacionLaboralDb>> obtenerActivasPorManagerDrift(
    String managerColaboradorUid,
  ) {
    return (select(asignacionesLaborales)
          ..where(
            (t) =>
                t.managerColaboradorUid.equals(managerColaboradorUid) &
                t.fechaFin.isNull() &
                t.deleted.equals(false),
          )
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.fechaInicio, mode: OrderingMode.asc),
          ]))
        .get();
  }

  /// Vigentes en una fecha dada (útil para auditorías).
  Future<List<AsignacionLaboralDb>> obtenerVigentesEnFechaDrift(
    DateTime fecha,
  ) {
    return (select(asignacionesLaborales)..where(
          (t) =>
              t.deleted.equals(false) &
              t.fechaInicio.isSmallerOrEqualValue(fecha) &
              (t.fechaFin.isNull() | t.fechaFin.isBiggerOrEqualValue(fecha)),
        ))
        .get();
  }

  /// Todos (incluye eliminados).
  Future<List<AsignacionLaboralDb>> obtenerTodosDrift() =>
      select(asignacionesLaborales).get();

  /// Todos NO eliminados.
  Future<List<AsignacionLaboralDb>> obtenerTodosNoDeletedDrift() {
    return (select(asignacionesLaborales)
          ..where((t) => t.deleted.equals(false))
          ..orderBy([
            (t) =>
                OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc),
          ]))
        .get();
  }

  // ---------------------------------------------------------------------------
  // 📌 SINCRONIZACIÓN (estado local)
  // ---------------------------------------------------------------------------

  /// Pendientes de subida (isSynced == false).
  Future<List<AsignacionLaboralDb>> obtenerPendientesSyncDrift() {
    return (select(
      asignacionesLaborales,
    )..where((t) => t.isSynced.equals(false))).get();
  }

  /// Marcar como sincronizada (no se actualiza updatedAt).
  Future<void> marcarComoSincronizadoDrift(String uid) async {
    await (update(
      asignacionesLaborales,
    )..where((t) => t.uid.equals(uid))).write(
      const AsignacionesLaboralesCompanion(
        isSynced: Value(true),
        updatedAt: Value.absent(),
      ),
    );
  }

  /// Última actualización local considerando SOLO sincronizados.
  Future<DateTime?> obtenerUltimaActualizacionDrift() async {
    final row =
        await (select(asignacionesLaborales)
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

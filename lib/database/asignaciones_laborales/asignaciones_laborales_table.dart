import 'package:drift/drift.dart';

@DataClassName('AsignacionLaboralDb') // ✅ Clase generada por Drift
class AsignacionesLaborales extends Table {
  // ── Identificador ────────────────────────────────────────────────────────────
  TextColumn get uid => text()(); // 🔑 PK
  TextColumn get colaboradorUid => text()();
  TextColumn get distribuidorUid => text().withDefault(const Constant(''))();
  TextColumn get managerColaboradorUid =>
      text().withDefault(const Constant(''))();
  TextColumn get rol => text().withDefault(const Constant('vendedor'))();
  TextColumn get puesto => text().withDefault(const Constant(''))();
  TextColumn get nivel => text().withDefault(const Constant(''))();
  DateTimeColumn get fechaInicio => dateTime()();
  DateTimeColumn get fechaFin => dateTime().nullable()();

  // ── Auditoría / trazabilidad ────────────────────────────────────────────────
  TextColumn get createdByUsuarioUid =>
      text().withDefault(const Constant(''))();
  TextColumn get closedByUsuarioUid => text().withDefault(const Constant(''))();
  TextColumn get notas => text().withDefault(const Constant(''))();

  // ── Sync / soft-delete ──────────────────────────────────────────────────────
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {uid};
}

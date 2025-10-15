import 'package:drift/drift.dart';

/// Tabla local para controlar la sincronización global por recurso.
@DataClassName('SyncStateDb')
class SyncState extends Table {
  // ── Identificador del recurso (nombre lógico de la tabla o entidad) ──────────
  TextColumn get resource => text()(); // PK, ej. 'ventas', 'usuarios', etc.

  // ── Auditoría / trazabilidad ────────────────────────────────────────────────
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {resource};
}

// estatus_table.dart
import 'package:drift/drift.dart';

@DataClassName('EstatusDb')
class Estatus extends Table {
  TextColumn get uid => text()(); // PK (uuid)
  TextColumn get nombre => text()(); // p.ej. "Prospecto"
  TextColumn get categoria => text().withDefault(const Constant('ciclo'))();
  IntColumn get orden => integer().withDefault(const Constant(0))();
  BoolColumn get esFinal => boolean().withDefault(const Constant(false))();
  BoolColumn get esCancelatorio =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get visible => boolean().withDefault(const Constant(true))();
  TextColumn get colorHex =>
      text().withDefault(const Constant(''))(); // UI opcional
  TextColumn get icono =>
      text().withDefault(const Constant(''))(); // UI opcional
  TextColumn get notas => text().withDefault(const Constant(''))();

  // Sync / soft-delete
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {uid};
}

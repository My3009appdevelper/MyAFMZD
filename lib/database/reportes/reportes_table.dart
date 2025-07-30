import 'package:drift/drift.dart';

@DataClassName('ReportesDb') // ✅ Nombre de la clase generada por Drift
class Reportes extends Table {
  TextColumn get uid => text()(); // UUID
  TextColumn get nombre => text().withDefault(const Constant(''))();
  DateTimeColumn get fecha => dateTime().withDefault(currentDateAndTime)();
  TextColumn get rutaRemota => text().withDefault(const Constant(''))();
  TextColumn get rutaLocal => text().withDefault(const Constant(''))();
  TextColumn get tipo => text().withDefault(const Constant(''))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get isSynced => boolean().withDefault(const Constant(true))();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {uid};
}

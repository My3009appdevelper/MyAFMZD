import 'package:drift/drift.dart';

@DataClassName('GrupoDistribuidorDb') // ✅ Clase generada por Drift
class GruposDistribuidores extends Table {
  TextColumn get uid => text()(); // 🔑 PK
  TextColumn get nombre => text().withDefault(const Constant(''))();
  TextColumn get abreviatura => text().withDefault(const Constant(''))();
  TextColumn get notas => text().withDefault(const Constant(''))();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {uid};
}

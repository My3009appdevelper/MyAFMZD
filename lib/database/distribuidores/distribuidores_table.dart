import 'package:drift/drift.dart';

@DataClassName('DistribuidorDb') // ✅ Nombre de la clase generada por Drift
class Distribuidores extends Table {
  TextColumn get uid => text()(); // 🔑 ID (PK)
  TextColumn get nombre => text().withDefault(const Constant(''))();
  TextColumn get uuidGrupo => text().withDefault(const Constant(''))();
  TextColumn get direccion => text().withDefault(const Constant(''))();
  TextColumn get estado => text().withDefault(const Constant(''))();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
  RealColumn get latitud => real().withDefault(const Constant(0.0))();
  RealColumn get longitud => real().withDefault(const Constant(0.0))();
  TextColumn get concentradoraUid => text().withDefault(const Constant(''))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {uid};
}

import 'package:drift/drift.dart';

@DataClassName('ModeloDb')
class Modelos extends Table {
  // Identidad y catálogo
  TextColumn get uid => text()();
  TextColumn get claveCatalogo => text().withDefault(const Constant(''))();
  TextColumn get marca => text().withDefault(const Constant('Mazda'))();
  TextColumn get modelo => text().withDefault(const Constant(''))();
  IntColumn get anio => integer()();
  TextColumn get tipo => text().withDefault(const Constant(''))();
  TextColumn get transmision => text().withDefault(const Constant(''))();
  TextColumn get descripcion => text().withDefault(const Constant(''))();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();
  RealColumn get precioBase => real().withDefault(const Constant(0.0))();

  // Ficha técnica (PDF)
  TextColumn get fichaRutaRemota => text().withDefault(const Constant(''))();
  TextColumn get fichaRutaLocal => text().withDefault(const Constant(''))();

  // Tiempos y Sync
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {uid};
}

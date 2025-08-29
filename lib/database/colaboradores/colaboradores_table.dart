import 'package:drift/drift.dart';

@DataClassName('ColaboradorDb')
class Colaboradores extends Table {
  // Identidad básica
  TextColumn get uid => text()(); // PK
  TextColumn get nombres => text()();
  TextColumn get apellidoPaterno => text().withDefault(const Constant(''))();
  TextColumn get apellidoMaterno => text().withDefault(const Constant(''))();
  DateTimeColumn get fechaNacimiento => dateTime().nullable()();
  TextColumn get curp => text().nullable()();
  TextColumn get rfc => text().nullable()();
  TextColumn get telefonoMovil => text().withDefault(const Constant(''))();
  TextColumn get emailPersonal => text().withDefault(const Constant(''))();
  TextColumn get fotoRutaLocal => text().withDefault(const Constant(''))();
  TextColumn get fotoRutaRemota => text().withDefault(const Constant(''))();
  TextColumn get genero => text().withDefault(const Constant('')).nullable()();
  TextColumn get notas => text().withDefault(const Constant(''))();

  // Sync
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {uid};
}

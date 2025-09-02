import 'package:drift/drift.dart';

@DataClassName('UsuarioDb')
class Usuarios extends Table {
  TextColumn get uid => text()(); // Primary key
  TextColumn get colaboradorUid => text().nullable()();
  TextColumn get userName => text().withDefault(const Constant(''))();
  TextColumn get correo => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {uid};
}

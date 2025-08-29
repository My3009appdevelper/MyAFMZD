import 'package:drift/drift.dart';

@DataClassName('ModeloImagenDb')
class ModeloImagenes extends Table {
  TextColumn get uid => text()();
  TextColumn get modeloUid => text()();
  TextColumn get rutaRemota => text().withDefault(const Constant(''))();
  TextColumn get rutaLocal => text().withDefault(const Constant(''))();

  TextColumn get sha256 => text().withDefault(const Constant(''))();
  BoolColumn get isCover => boolean().withDefault(const Constant(false))();

  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {uid};
}

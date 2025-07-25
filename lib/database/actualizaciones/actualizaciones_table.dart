import 'package:drift/drift.dart';

@DataClassName('Actualizacion')
class Actualizaciones extends Table {
  TextColumn get coleccion => text()(); // "usuarios", "distribuidores"
  DateTimeColumn get ultimaSync => dateTime()();
  @override
  Set<Column> get primaryKey => {coleccion};
}

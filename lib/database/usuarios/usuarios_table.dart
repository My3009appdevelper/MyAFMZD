import 'dart:convert';
import 'package:drift/drift.dart';

@DataClassName('UsuarioDb')
class Usuarios extends Table {
  TextColumn get uid => text()(); // Primary key
  TextColumn get nombre => text().withDefault(const Constant(''))();
  TextColumn get correo => text().withDefault(const Constant(''))();
  TextColumn get rol => text().withDefault(const Constant('usuario'))();
  TextColumn get uuidDistribuidora => text().withDefault(const Constant(''))();
  TextColumn get permisos =>
      text().map(const PermisosConverter()).withDefault(const Constant('{}'))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {uid};
}

class PermisosConverter extends TypeConverter<Map<String, bool>, String> {
  const PermisosConverter();

  @override
  Map<String, bool> fromSql(String fromDb) {
    if (fromDb.isEmpty) return {};
    final decoded = jsonDecode(fromDb);
    return Map<String, bool>.from(decoded);
  }

  @override
  String toSql(Map<String, bool> value) => jsonEncode(value);
}

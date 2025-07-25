import 'dart:convert';
import 'package:drift/drift.dart';

@DataClassName('Usuario')
class Usuarios extends Table {
  TextColumn get uid => text()(); // Primary key
  TextColumn get nombre => text().withDefault(const Constant(''))();
  TextColumn get correo => text().withDefault(const Constant(''))();
  TextColumn get rol => text().withDefault(const Constant('usuario'))();
  TextColumn get uuidDistribuidora => text().withDefault(const Constant(''))();

  /// Guardamos el Map<String,bool> como JSON
  TextColumn get permisos =>
      text().map(const PermisosConverter()).withDefault(const Constant('{}'))();

  /// 🆕 Nuevo campo para sincronización incremental
  DateTimeColumn get updatedAt => dateTime().nullable()();

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

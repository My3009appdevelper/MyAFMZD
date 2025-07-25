import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:myafmzd/database/actualizaciones/actualizaciones_dao.dart';
import 'package:myafmzd/database/usuarios/usuarios_dao.dart';
import 'package:myafmzd/database/actualizaciones/actualizaciones_table.dart';
import 'package:myafmzd/database/usuarios/usuarios_table.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Usuarios, Actualizaciones], // ✅ Ahora incluye ambas tablas
  daos: [UsuariosDao, ActualizacionesDao], // ✅ Registramos ambos DAOs
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  /// 🔄 Migraciones futuras
  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (Migrator m) async {
      await m.createAll(); // Crea todas las tablas definidas
    },
    onUpgrade: (Migrator m, int from, int to) async {
      // Aquí se definen migraciones cuando cambie el schemaVersion
    },
  );
}

/// 📂 Conexión a la base de datos local
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    await dir.create(recursive: true); // ✅ FIX Android
    final dbFile = File(p.join(dir.path, 'myafmzd.sqlite'));
    return NativeDatabase(dbFile);
  });
}

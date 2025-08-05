import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_dao.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_table.dart';
import 'package:myafmzd/database/reportes/reportes_dao.dart';
import 'package:myafmzd/database/reportes/reportes_table.dart';
import 'package:myafmzd/database/usuarios/usuarios_dao.dart';
import 'package:myafmzd/database/usuarios/usuarios_table.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [Usuarios, Distribuidores, Reportes], // ✅ Ahora incluye ambas tablas
  daos: [
    UsuariosDao,
    DistribuidoresDao,
    ReportesDao,
  ], // ✅ Registramos ambos DAOs
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
    await dir.create(recursive: true);
    final dbFile = File(p.join(dir.path, 'myafmzd.sqlite'));

    // 🧹 OPCIÓN: Borrar base de datos para pruebas/migraciones
    // ⚠️ Comenta esta sección en producción cuando no quieras borrar datos
    const bool borrarDB =
        true; // ⬅️ Cambia a true cuando quieras forzar recrear
    if (borrarDB && await dbFile.exists()) {
      print(
        '[🗑️ MENSAJE APP DATABASE] Eliminando base de datos local para recrear...',
      );
      await dbFile.delete();
    }

    if (borrarDB) {
      final tempDir = await getTemporaryDirectory();
      final appDir = await getApplicationDocumentsDirectory();

      for (final file in tempDir.listSync()) {
        if (file is File && file.path.endsWith('.pdf')) {
          await file.delete();
        }
        if (file is File && file.path.contains('miniatura_')) {
          await file.delete();
        }
      }

      for (final file in appDir.listSync()) {
        if (file is File && file.path.contains('miniatura_')) {
          await file.delete();
        }
      }

      print(
        '[🗑️ MENSAJE APP DATABASE] 🧹 También se borraron PDFs temporales y miniaturas',
      );
    }

    return NativeDatabase(dbFile);
  });
}

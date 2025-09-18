import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:myafmzd/database/asignaciones_laborales/asignaciones_laborales_dao.dart';
import 'package:myafmzd/database/asignaciones_laborales/asignaciones_laborales_table.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_dao.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_table.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_dao.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_table.dart';
import 'package:myafmzd/database/estatus/estatus_dao.dart';
import 'package:myafmzd/database/estatus/estatus_table.dart';
import 'package:myafmzd/database/grupo_distribuidores/grupos_distribuidores_dao.dart';
import 'package:myafmzd/database/grupo_distribuidores/grupos_distribuidores_table.dart';
import 'package:myafmzd/database/modelos/modelo_imagenes_dao.dart';
import 'package:myafmzd/database/modelos/modelo_imagenes_table.dart';
import 'package:myafmzd/database/modelos/modelos_dao.dart';
import 'package:myafmzd/database/modelos/modelos_table.dart';
import 'package:myafmzd/database/productos/productos_dao.dart';
import 'package:myafmzd/database/productos/productos_table.dart';
import 'package:myafmzd/database/reportes/reportes_dao.dart';
import 'package:myafmzd/database/reportes/reportes_table.dart';
import 'package:myafmzd/database/usuarios/usuarios_dao.dart';
import 'package:myafmzd/database/usuarios/usuarios_table.dart';
import 'package:myafmzd/database/ventas/ventas_dao.dart';
import 'package:myafmzd/database/ventas/ventas_table.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Usuarios,
    Distribuidores,
    GruposDistribuidores,
    Reportes,
    Modelos,
    ModeloImagenes,
    Productos,
    Colaboradores,
    AsignacionesLaborales,
    Estatus,
    Ventas,
  ],
  daos: [
    UsuariosDao,
    DistribuidoresDao,
    GruposDistribuidoresDao,
    ReportesDao,
    ModelosDao,
    ModeloImagenesDao,
    ProductosDao,
    ColaboradoresDao,
    AsignacionesLaboralesDao,
    EstatusDao,
    VentasDao,
  ],
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
    // ───────────────────────────── paths ─────────────────────────────
    final docsDir =
        await getApplicationDocumentsDirectory(); // p.ej. /data/user/0/pack/files
    final supportDir =
        await getApplicationSupportDirectory(); // p.ej. /data/user/0/pack/files/.app_support
    final tempDir =
        await getTemporaryDirectory(); // p.ej. /data/user/0/pack/cache

    await docsDir.create(recursive: true);
    await supportDir.create(recursive: true);

    final dbFile = File(p.join(docsDir.path, 'myafmzd.sqlite'));
    final modelosImgDir = Directory(p.join(supportDir.path, 'modelos_img'));

    // ───────────────────────── toggle de limpieza ────────────────────
    const bool wipeOnColdStart = true; // ⬅️ ponlo en false para producción

    // ─────────────────────── helpers de borrado ──────────────────────
    Future<int> deleteWhere(Directory dir, bool Function(File f) test) async {
      var count = 0;
      if (!(await dir.exists())) return 0;
      try {
        await for (final entity in dir.list(
          recursive: false,
          followLinks: false,
        )) {
          if (entity is File && test(entity)) {
            try {
              await entity.delete();
              count++;
            } catch (_) {
              /* ignora errores puntuales */
            }
          }
        }
      } catch (_) {
        /* ignora errores de permisos */
      }
      return count;
    }

    Future<int> deleteAllInDir(Directory dir) async {
      var count = 0;
      if (!(await dir.exists())) return 0;
      try {
        await for (final entity in dir.list(
          recursive: false,
          followLinks: false,
        )) {
          try {
            if (entity is File) {
              await entity.delete();
              count++;
            } else if (entity is Directory) {
              // Borrado recursivo seguro
              await entity.delete(recursive: true);
            }
          } catch (_) {
            /* ignora */
          }
        }
      } catch (_) {
        /* ignora */
      }
      return count;
    }

    String name(File f) => p.basename(f.path).toLowerCase();

    // ─────────────────────────── limpieza ────────────────────────────
    if (wipeOnColdStart) {
      print(
        '[🗑️ MENSAJE APP DATABASE] Eliminando base de datos local para recrear...',
      );
      if (await dbFile.exists()) {
        try {
          await dbFile.delete();
        } catch (_) {}
      }

      // PDFs y miniaturas en temp y documents
      final deletedTempPdfs = await deleteWhere(
        tempDir,
        (f) => name(f).endsWith('.pdf'),
      );
      final deletedDocsPdfs = await deleteWhere(
        docsDir,
        (f) => name(f).endsWith('.pdf'),
      );
      final deletedTempTh = await deleteWhere(
        tempDir,
        (f) => name(f).contains('miniatura_'),
      );
      final deletedDocsTh = await deleteWhere(
        docsDir,
        (f) => name(f).contains('miniatura_'),
      );

      // Todas las imágenes gestionadas por la app (nuestro repositorio canónico)
      await modelosImgDir.create(recursive: true);
      final deletedImgs = await deleteAllInDir(modelosImgDir);

      print('[🗑️ MENSAJE APP DATABASE] 🧹 Limpieza completada:');
      print(
        '  PDFs      → temp:$deletedTempPdfs  | documents:$deletedDocsPdfs',
      );
      print('  miniaturas→ temp:$deletedTempTh    | documents:$deletedDocsTh');
      print('  imágenes  → modelos_img:$deletedImgs');
    } else {
      print(
        '[🧷 MENSAJE APP DATABASE] Limpieza desactivada (no se borra nada).',
      );
    }

    // ─────────────────── abrir DB sin bloquear UI ────────────────────
    // Usa isolate de fondo para operaciones iniciales de SQLite
    return NativeDatabase.createInBackground(dbFile);
  });
}

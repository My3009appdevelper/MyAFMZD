import 'package:drift/drift.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/actualizaciones/actualizaciones_table.dart';

part 'actualizaciones_dao.g.dart';

@DriftAccessor(tables: [Actualizaciones])
class ActualizacionesDao extends DatabaseAccessor<AppDatabase>
    with _$ActualizacionesDaoMixin {
  ActualizacionesDao(AppDatabase db) : super(db);

  Future<DateTime?> obtenerUltimaSync(String coleccion) async {
    final row = await (select(
      actualizaciones,
    )..where((a) => a.coleccion.equals(coleccion))).getSingleOrNull();
    print(
      '📥 [DAO ACTUALIZACIONES] Leyendo timestamp $row?.ultimaSync para $coleccion',
    );

    return row?.ultimaSync;
  }

  Future<void> guardarUltimaSync(String coleccion, DateTime fecha) async {
    print(
      '💾 [DAO ACTUALIZACIONES] Guardando timestamp $fecha para $coleccion',
    );

    await into(actualizaciones).insertOnConflictUpdate(
      Actualizacion(coleccion: coleccion, ultimaSync: fecha),
    );
  }
}

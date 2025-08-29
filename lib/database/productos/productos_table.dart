import 'package:drift/drift.dart';

@DataClassName('ProductoDb')
class Productos extends Table {
  // Identidad y estado
  TextColumn get uid => text()(); // PK
  TextColumn get nombre =>
      text().withDefault(const Constant('Autofinanciamiento Puro'))();
  BoolColumn get activo => boolean().withDefault(const Constant(true))();

  // Parámetros de cálculo (alineados a tu Python)
  IntColumn get plazoMeses => integer().withDefault(const Constant(60))();
  RealColumn get factorIntegrante =>
      real().withDefault(const Constant(0.01667))();
  RealColumn get factorPropietario =>
      real().withDefault(const Constant(0.0206))();
  RealColumn get cuotaInscripcionPct =>
      real().withDefault(const Constant(0.005))();
  RealColumn get cuotaAdministracionPct =>
      real().withDefault(const Constant(0.002))();
  RealColumn get ivaCuotaAdministracionPct =>
      real().withDefault(const Constant(0.16))();
  RealColumn get cuotaSeguroVidaPct =>
      real().withDefault(const Constant(0.00065))();

  // Límites/reglas operativas (para UI/validación)
  IntColumn get adelantoMinMens => integer().withDefault(const Constant(0))();
  IntColumn get adelantoMaxMens => integer().withDefault(const Constant(59))();
  IntColumn get mesEntregaMin => integer().withDefault(const Constant(1))();
  IntColumn get mesEntregaMax => integer().withDefault(const Constant(60))();

  // Presentación/selección
  IntColumn get prioridad =>
      integer().withDefault(const Constant(0))(); // orden en UI
  TextColumn get notas => text().withDefault(const Constant(''))();

  // Vigencia (activar/desactivar por fechas)
  DateTimeColumn get vigenteDesde => dateTime().nullable()();
  DateTimeColumn get vigenteHasta => dateTime().nullable()();

  // Sync metadata
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {uid};
}

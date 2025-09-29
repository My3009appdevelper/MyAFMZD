import 'package:drift/drift.dart';

/// DataClass generada: `VentaDb`
/// Tabla local para ventas (offline-first).
@DataClassName('VentaDb')
class Ventas extends Table {
  TextColumn get uid => text()(); // PK (uuid v4 en texto)
  TextColumn get distribuidoraOrigenUid =>
      text().withDefault(const Constant(''))(); // Distribuidora origen
  TextColumn get distribuidoraUid =>
      text().withDefault(const Constant(''))(); // Distribuidora actual
  TextColumn get vendedorUid =>
      text().withDefault(const Constant(''))(); // Colaborador (vendedor)
  TextColumn get folioContrato =>
      text().withDefault(const Constant(''))(); // Folio de contrato
  TextColumn get modeloUid =>
      text().withDefault(const Constant(''))(); // Modelo (catálogo)
  TextColumn get estatusUid => text().withDefault(
    const Constant(''),
  )(); // Estatus (FK lógica a `estatus.uid`)
  IntColumn get grupo => integer().withDefault(const Constant(0))();
  IntColumn get integrante => integer().withDefault(const Constant(0))();
  DateTimeColumn get fechaContrato => dateTime().nullable()(); // Puede ser nula
  DateTimeColumn get fechaVenta => dateTime().nullable()(); // Puede ser nula
  IntColumn get mesVenta =>
      integer().nullable().check(mesVenta.isBetweenValues(1, 12))();
  IntColumn get anioVenta =>
      integer().nullable().check(anioVenta.isBetweenValues(1990, 2100))();

  // ---------------------------------------------------------------------------
  // 🔄 Sync / Soft-delete
  // ---------------------------------------------------------------------------
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {uid};
}

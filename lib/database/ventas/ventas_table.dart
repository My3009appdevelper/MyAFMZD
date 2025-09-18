import 'package:drift/drift.dart';

/// DataClass generada: `VentaDb`
/// Tabla local para ventas (offline-first).
@DataClassName('VentaDb')
class Ventas extends Table {
  // ---------------------------------------------------------------------------
  // 🔑 Identidad y relaciones (por UID en texto, consistente con tu esquema)
  // ---------------------------------------------------------------------------
  TextColumn get uid => text()(); // PK (uuid v4 en texto)
  TextColumn get distribuidoraOrigenUid =>
      text().withDefault(const Constant(''))(); // Distribuidora origen
  TextColumn get distribuidoraUid =>
      text().withDefault(const Constant(''))(); // Distribuidora actual
  TextColumn get gerenteGrupoUid =>
      text().withDefault(const Constant(''))(); // Colaborador (manager)
  TextColumn get vendedorUid =>
      text().withDefault(const Constant(''))(); // Colaborador (vendedor)
  TextColumn get folioContrato =>
      text().withDefault(const Constant(''))(); // Folio de contrato
  TextColumn get modeloUid =>
      text().withDefault(const Constant(''))(); // Modelo (catálogo)
  TextColumn get estatusUid => text().withDefault(
    const Constant(''),
  )(); // Estatus (FK lógica a `estatus.uid`)

  // ---------------------------------------------------------------------------
  // 👥 Grupo / Integrante
  // ---------------------------------------------------------------------------
  IntColumn get grupo => integer().withDefault(const Constant(0))();
  IntColumn get integrante => integer().withDefault(const Constant(0))();

  // ---------------------------------------------------------------------------
  // 🗓️ Fechas y derivados de venta
  // ---------------------------------------------------------------------------
  DateTimeColumn get fechaContrato => dateTime().nullable()(); // Puede ser nula
  DateTimeColumn get fechaVenta => dateTime().nullable()(); // Puede ser nula

  /// Mes de venta [1..12] — opcional (útil para filtros/reportes)
  IntColumn get mesVenta =>
      integer().nullable().check(mesVenta.isBetweenValues(1, 12))();

  /// Año de venta [1990..2100] — opcional (útil para filtros/reportes)
  IntColumn get anioVenta =>
      integer().nullable().check(anioVenta.isBetweenValues(1990, 2100))();

  // ---------------------------------------------------------------------------
  // 🔄 Sync / Soft-delete
  // ---------------------------------------------------------------------------
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
  BoolColumn get deleted => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();

  // ---------------------------------------------------------------------------
  // 🔐 Clave primaria
  // ---------------------------------------------------------------------------
  @override
  Set<Column> get primaryKey => {uid};
}

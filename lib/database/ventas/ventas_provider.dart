// lib/database/ventas/ventas_provider.dart
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/screens/z%20Utils/csv_utils.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/database_provider.dart';

import 'package:myafmzd/database/ventas/ventas_dao.dart';
import 'package:myafmzd/database/ventas/ventas_service.dart';
import 'package:myafmzd/database/ventas/ventas_sync.dart';

/// ---------------------------------------------------------------------------
/// Provider global: lista completa de ventas (incluye eliminadas si las cargas)
/// ---------------------------------------------------------------------------
final ventasProvider = StateNotifierProvider<VentasNotifier, List<VentaDb>>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  return VentasNotifier(ref, db);
});

class VentasNotifier extends StateNotifier<List<VentaDb>> {
  VentasNotifier(this._ref, AppDatabase db)
    : _dao = VentasDao(db),
      _servicio = VentasService(db),
      _sync = VentasSync(db),
      super([]);

  final Ref _ref;
  final VentasDao _dao;
  final VentasService _servicio;
  final VentasSync _sync;

  bool _hayInternet = true;
  bool get hayInternet => _hayInternet;

  // ---------------------------------------------------------------------------
  // ✅ Cargar ventas (offline-first)
  // ---------------------------------------------------------------------------
  Future<void> cargarOfflineFirst() async {
    try {
      _hayInternet = _ref.read(connectivityProvider);

      // 1) Pintar local primero
      final local = await _dao.obtenerTodasDrift();
      state = _ordenado(local);
      print(
        '[💸 MENSAJES VENTAS PROVIDER] Local cargado -> ${local.length} ventas',
      );

      // 2) Sin internet → detener
      if (!_hayInternet) {
        print('[💸 MENSAJES VENTAS PROVIDER] Sin internet → usando solo local');
        return;
      }

      // 3) (Opcional) comparar timestamps para log/telemetría
      final localTs = await _dao.obtenerUltimaActualizacionDrift();
      final remotoTs = await _servicio.comprobarActualizacionesOnline();
      print('[💸 MENSAJES VENTAS PROVIDER] Remoto:$remotoTs | Local:$localTs');

      // 4) Pull (heads → diff → fetch)
      await _sync.pullVentasOnline();

      // 5) Push de cambios offline
      await _sync.pushVentasOffline();

      // 6) Recargar desde Drift
      final actualizados = await _dao.obtenerTodasDrift();
      state = _ordenado(actualizados);
    } catch (e) {
      print('[💸 MENSAJES VENTAS PROVIDER] ❌ Error al cargar ventas: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // ➕ Crear venta (LOCAL → isSynced=false; el push la sube)
  //    - Calcula mes/año desde fechaVenta si vienen nulos
  // ---------------------------------------------------------------------------
  Future<VentaDb> crearVenta({
    // Identidad/relaciones
    required String distribuidoraOrigenUid,
    required String distribuidoraUid,
    String gerenteGrupoUid = '',
    required String vendedorUid,
    String folioContrato = '',
    required String modeloUid,
    String estatusUid = '',

    // Grupo/Integrante
    int grupo = 0,
    int integrante = 0,

    // Fechas derivadas
    DateTime? fechaContrato,
    DateTime? fechaVenta,
    int? mesVenta,
    int? anioVenta,
  }) async {
    final uid = const Uuid().v4();
    final now = DateTime.now().toUtc();

    // Derivados
    final mes = mesVenta ?? (fechaVenta?.month);
    final anio = anioVenta ?? (fechaVenta?.year);

    // Guard local
    await _dao.upsertVentaDrift(
      VentasCompanion(
        uid: Value(uid),
        distribuidoraOrigenUid: Value(distribuidoraOrigenUid),
        distribuidoraUid: Value(distribuidoraUid),
        gerenteGrupoUid: Value(gerenteGrupoUid),
        vendedorUid: Value(vendedorUid),
        folioContrato: Value(folioContrato),
        modeloUid: Value(modeloUid),
        estatusUid: Value(estatusUid),

        grupo: Value(grupo),
        integrante: Value(integrante),

        fechaContrato: fechaContrato == null
            ? const Value.absent()
            : Value(fechaContrato.toUtc()),
        fechaVenta: fechaVenta == null
            ? const Value.absent()
            : Value(fechaVenta.toUtc()),
        mesVenta: mes == null ? const Value.absent() : Value(mes),
        anioVenta: anio == null ? const Value.absent() : Value(anio),

        createdAt: Value(now),
        updatedAt: Value(now),
        deleted: const Value(false),
        isSynced: const Value(false),
      ),
    );

    final actual = await _dao.obtenerTodasDrift();
    state = _ordenado(actual);
    return state.firstWhere((v) => v.uid == uid);
  }

  // ---------------------------------------------------------------------------
  // ✏️ Editar venta (LOCAL → isSynced=false; el push lo sube)
  //     Si se envía `fechaVenta`, por defecto recalcula mes/año salvo que
  //     explícitamente pases mesVenta/anioVenta.
  // ---------------------------------------------------------------------------
  Future<void> editarVenta({
    required String uid,

    String? distribuidoraOrigenUid,
    String? distribuidoraUid,
    String? gerenteGrupoUid,
    String? vendedorUid,
    String? folioContrato,
    String? modeloUid,
    String? estatusUid,

    int? grupo,
    int? integrante,

    DateTime? fechaContrato, // Value(null) ⇒ limpia
    DateTime? fechaVenta, // recalcula mes/año si no los mandas
    int? mesVenta, // si lo mandas, respeta el valor
    int? anioVenta, // si lo mandas, respeta el valor

    bool? deleted,
  }) async {
    try {
      final dtNow = DateTime.now().toUtc();

      final mes = mesVenta ?? (fechaVenta != null ? fechaVenta.month : null);
      final anio = anioVenta ?? (fechaVenta != null ? fechaVenta.year : null);

      final comp = VentasCompanion(
        uid: Value(uid),
        distribuidoraOrigenUid: distribuidoraOrigenUid == null
            ? const Value.absent()
            : Value(distribuidoraOrigenUid),
        distribuidoraUid: distribuidoraUid == null
            ? const Value.absent()
            : Value(distribuidoraUid),
        gerenteGrupoUid: gerenteGrupoUid == null
            ? const Value.absent()
            : Value(gerenteGrupoUid),
        vendedorUid: vendedorUid == null
            ? const Value.absent()
            : Value(vendedorUid),
        folioContrato: folioContrato == null
            ? const Value.absent()
            : Value(folioContrato),
        modeloUid: modeloUid == null ? const Value.absent() : Value(modeloUid),
        estatusUid: estatusUid == null
            ? const Value.absent()
            : Value(estatusUid),

        grupo: grupo == null ? const Value.absent() : Value(grupo),
        integrante: integrante == null
            ? const Value.absent()
            : Value(integrante),

        // Nullable: si quieres limpiar, pasa fechaContrato == null intencional con Value(null)
        fechaContrato: fechaContrato == null
            ? const Value.absent()
            : Value(fechaContrato.toUtc()),
        fechaVenta: fechaVenta == null
            ? const Value.absent()
            : Value(fechaVenta.toUtc()),
        mesVenta: mes == null ? const Value.absent() : Value(mes),
        anioVenta: anio == null ? const Value.absent() : Value(anio),

        updatedAt: Value(dtNow),
        deleted: deleted == null ? const Value.absent() : Value(deleted),
        isSynced: const Value(false),
      );

      await _dao.actualizarParcialPorUid(uid, comp);

      state = _ordenado(await _dao.obtenerTodasDrift());
      print('[💸 MENSAJES VENTAS PROVIDER] Venta $uid editada localmente');
    } catch (e) {
      print('[💸 MENSAJES VENTAS PROVIDER] ❌ Error al editar venta: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 🔁 Cambiar estatus (helper dedicado)
  // ---------------------------------------------------------------------------
  Future<void> cambiarEstatus({
    required String uid,
    required String estatusUid,
  }) async {
    await editarVenta(uid: uid, estatusUid: estatusUid);
  }

  // ---------------------------------------------------------------------------
  // 🗑️ Soft delete local → push lo sube
  // ---------------------------------------------------------------------------
  Future<void> eliminarVentaLocal(String uid) async {
    try {
      await _dao.actualizarParcialPorUid(
        uid,
        VentasCompanion(
          deleted: const Value(true),
          updatedAt: Value(DateTime.now().toUtc()),
          isSynced: const Value(false),
        ),
      );
      state = _ordenado(await _dao.obtenerTodasDrift());
      print(
        '[💸 MENSAJES VENTAS PROVIDER] Venta $uid marcada como eliminada (local)',
      );
    } catch (e) {
      print('[💸 MENSAJES VENTAS PROVIDER] ❌ Error al eliminar: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 🧪 Validaciones
  // ---------------------------------------------------------------------------
  /// Duplicado por folio (ignora mayúsculas/espacios). Si `folio` está vacío, no valida.
  bool existeDuplicadoFolio({
    required String uidActual,
    required String folio,
    bool incluirEliminados = false,
  }) {
    final f = folio.trim().toLowerCase();
    if (f.isEmpty) return false;
    return state.any((v) {
      if (v.uid == uidActual) return false;
      if (!incluirEliminados && v.deleted) return false;
      return v.folioContrato.trim().toLowerCase() == f;
    });
  }

  /// Duplicado por “slot” operativo (grupo+integrante+mes+año). Útil en lotes.
  bool existeDuplicadoSlot({
    required String uidActual,
    required int grupo,
    required int integrante,
    int? mesVenta,
    int? anioVenta,
    bool incluirEliminados = false,
  }) {
    if (grupo <= 0 ||
        integrante <= 0 ||
        mesVenta == null ||
        anioVenta == null) {
      return false;
    }
    return state.any((v) {
      if (v.uid == uidActual) return false;
      if (!incluirEliminados && v.deleted) return false;
      final sameGI = v.grupo == grupo && v.integrante == integrante;
      final samePeriodo =
          (v.mesVenta ?? -1) == mesVenta && (v.anioVenta ?? -1) == anioVenta;
      return sameGI && samePeriodo;
    });
  }

  // ---------------------------------------------------------------------------
  // 🔎 Consultas / utilidades en memoria
  // ---------------------------------------------------------------------------
  VentaDb? obtenerPorUid(String uid) {
    try {
      return state.firstWhere((e) => e.uid == uid);
    } catch (_) {
      return null;
    }
  }

  /// Búsqueda por texto (folio contrato, modeloUid, vendedorUid)
  List<VentaDb> buscar(String query, {bool incluirEliminados = false}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty)
      return _ordenado(
        incluirEliminados ? state : state.where((e) => !e.deleted).toList(),
      );
    final res = state.where((v) {
      if (!incluirEliminados && v.deleted) return false;
      return v.folioContrato.toLowerCase().contains(q) ||
          v.modeloUid.toLowerCase().contains(q) ||
          v.vendedorUid.toLowerCase().contains(q);
    }).toList();
    return _ordenado(res);
  }

  /// Filtrado flexible para listados y reportes
  List<VentaDb> filtrar({
    String? distribuidoraUid,
    String? vendedorUid,
    String? estatusUid,
    int? mes,
    int? anio,
    DateTime?
    desde, // compara contra fechaVenta si existe; si no, contra updatedAt
    DateTime? hasta,
    bool incluirEliminados = false,
  }) {
    bool inRange(VentaDb v) {
      final refDate = v.fechaVenta ?? v.updatedAt;
      final fromOk = desde == null || !refDate.isBefore(desde);
      final toOk = hasta == null || !refDate.isAfter(hasta);
      return fromOk && toOk;
    }

    return _ordenado(
      state.where((v) {
        if (!incluirEliminados && v.deleted) return false;
        final distOk =
            distribuidoraUid == null ||
            distribuidoraUid.isEmpty ||
            v.distribuidoraUid == distribuidoraUid;
        final vendOk =
            vendedorUid == null ||
            vendedorUid.isEmpty ||
            v.vendedorUid == vendedorUid;
        final estOk =
            estatusUid == null ||
            estatusUid.isEmpty ||
            v.estatusUid == estatusUid;
        final mesOk = mes == null || (v.mesVenta ?? -1) == mes;
        final anioOk = anio == null || (v.anioVenta ?? -1) == anio;
        final rangoOk = inRange(v);
        return distOk && vendOk && estOk && mesOk && anioOk && rangoOk;
      }).toList(),
    );
  }

  // ---- Helpers de ordenamiento / catálogos en memoria -----------------------
  List<VentaDb> _ordenado(List<VentaDb> lst) {
    lst.sort((a, b) {
      // 1) no eliminadas primero
      if (a.deleted != b.deleted) return a.deleted ? 1 : -1;
      // 2) por fechaVenta desc (si no hay, updatedAt desc)
      final ad = (a.fechaVenta ?? a.updatedAt);
      final bd = (b.fechaVenta ?? b.updatedAt);
      final cmp = bd.compareTo(ad);
      if (cmp != 0) return cmp;
      // 3) por folio asc de desempate
      return a.folioContrato.compareTo(b.folioContrato);
    });
    return lst;
  }

  List<int> get aniosDisponibles {
    final set = <int>{};
    for (final v in state) {
      if (v.anioVenta != null) set.add(v.anioVenta!);
    }
    final out = set.toList()..sort();
    return out;
  }

  List<int> get mesesDisponibles {
    final set = <int>{};
    for (final v in state) {
      if (v.mesVenta != null) set.add(v.mesVenta!);
    }
    final out = set.toList()..sort();
    return out;
  }

  // ===== CSV =====

  // Header estable (sin uid, igual que colaboradores)
  static const List<String> _csvHeaderVentas = [
    'distribuidoraOrigenUid',
    'distribuidoraUid', // concentradora
    'gerenteGrupoUid',
    'vendedorUid',
    'folioContrato',
    'modeloUid',
    'estatusUid',
    'grupo',
    'integrante',
    'fechaContrato', // ISO o dd/MM/yyyy
    'fechaVenta', // ISO o dd/MM/yyyy
    'mesVenta', // opcional, si vacío se calcula
    'anioVenta', // opcional, si vacío se calcula
    'createdAt',
    'updatedAt',
    'deleted',
    'isSynced',
  ];

  String _fmtIso(DateTime? d) => d == null ? '' : d.toUtc().toIso8601String();

  /// EXPORTAR → String CSV (por defecto solo no eliminadas)
  Future<String> exportarCsvVentas({bool incluirEliminadas = false}) async {
    final lista = incluirEliminadas
        ? await _dao.obtenerTodasDrift()
        : (await _dao.obtenerTodasDrift()).where((v) => !v.deleted).toList();

    // orden: por fechaVenta desc, luego folio
    lista.sort((a, b) {
      final av = a.fechaVenta ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bv = b.fechaVenta ?? DateTime.fromMillisecondsSinceEpoch(0);
      final cmp = bv.compareTo(av);
      if (cmp != 0) return cmp;
      return a.folioContrato.compareTo(b.folioContrato);
    });

    final rows = <List<dynamic>>[
      ['uid', ..._csvHeaderVentas],
    ];
    for (final v in lista) {
      rows.add([
        v.uid,
        v.distribuidoraOrigenUid,
        v.distribuidoraUid,
        v.gerenteGrupoUid,
        v.vendedorUid,
        v.folioContrato,
        v.modeloUid,
        v.estatusUid,
        v.grupo,
        v.integrante,
        _fmtIso(v.fechaContrato),
        _fmtIso(v.fechaVenta),
        v.mesVenta ?? '',
        v.anioVenta ?? '',
        _fmtIso(v.createdAt),
        _fmtIso(v.updatedAt),
        v.deleted.toString(),
        v.isSynced.toString(),
      ]);
    }
    return toCsvStringWithBom(rows);
  }

  /// EXPORTAR → escribe archivo .csv y devuelve la ruta
  Future<String> exportarCsvAArchivo({String? nombreArchivo}) async {
    final csv = await exportarCsvVentas();

    final now = DateTime.now().toUtc();
    final ts = now.toIso8601String().replaceAll(':', '-');
    final fileName = (nombreArchivo?.trim().isNotEmpty == true)
        ? nombreArchivo!.trim()
        : 'ventas_$ts.csv';

    Directory dir;
    try {
      final downloads = await getDownloadsDirectory();
      dir = downloads ?? await getApplicationSupportDirectory();
    } catch (_) {
      dir = await getApplicationSupportDirectory();
    }

    final file = File(p.join(dir.path, fileName));
    await file.create(recursive: true);
    await file.writeAsString(csv, flush: true);
    return file.path;
  }

  /// IMPORTAR → SOLO INSERTA. Nunca edita existentes.
  /// Duplicado si:
  /// 1) `folioContrato` coincide (case-insensitive) con una venta no eliminada, o
  /// 2) (vendedorUid + fechaVenta + modeloUid) coinciden (regla opcional útil para evitar repetidos).
  /// También evita duplicados dentro del mismo CSV.
  Future<(int insertados, int saltados)> importarCsvVentas({
    String? csvText,
    List<int>? csvBytes,
  }) async {
    assert(
      csvText != null || csvBytes != null,
      'Proporciona csvText o csvBytes',
    );

    final text = csvText ?? decodeCsvBytes(csvBytes!);
    final rows = const CsvToListConverter(
      shouldParseNumbers: false,
      eol: '\n',
    ).convert(text);
    if (rows.isEmpty) return (0, 0);

    // Header exacto
    final header = rows.first.map((e) => (e ?? '').toString().trim()).toList();
    final validHeader =
        header.length == _csvHeaderVentas.length &&
        _csvHeaderVentas.asMap().entries.every((e) => e.value == header[e.key]);
    if (!validHeader) {
      throw const FormatException(
        'Encabezado CSV inválido. Esperado: '
        'distribuidoraOrigenUid,distribuidoraUid,gerenteGrupoUid,vendedorUid,folioContrato,'
        'modeloUid,estatusUid,grupo,integrante,fechaContrato,fechaVenta,mesVenta,anioVenta,'
        'createdAt,updatedAt,deleted,isSynced',
      );
    }

    final dataRows = rows.skip(1);
    final nowUtc = DateTime.now().toUtc();

    // === Índices DB (lookup rápido) ===
    final existentes = await _dao.obtenerTodasDrift();
    final byFolio = <String, bool>{};
    final byCombo = <String, bool>{}; // key: vendedor|yyyy-mm-dd|modelo

    String kFolio(String s) => s.trim().toLowerCase();
    String kDate(DateTime? d) => (d == null)
        ? ''
        : '${d.toUtc().year}-${d.toUtc().month.toString().padLeft(2, '0')}-${d.toUtc().day.toString().padLeft(2, '0')}';
    String kCombo(String vendedor, DateTime? fecha, String modelo) =>
        '${vendedor.trim()}|${kDate(fecha)}|${modelo.trim()}';

    for (final v in existentes) {
      if (v.deleted) continue;
      if (v.folioContrato.trim().isNotEmpty) {
        byFolio[kFolio(v.folioContrato)] = true;
      }
      byCombo[kCombo(v.vendedorUid, v.fechaVenta, v.modeloUid)] = true;
    }

    // === Seen para evitar duplicados dentro del CSV ===
    final seenFolio = <String, bool>{};
    final seenCombo = <String, bool>{};

    int ins = 0, skip = 0;

    await _dao.db.transaction(() async {
      for (final r in dataRows) {
        if (r.isEmpty) continue;

        final row = List<String>.generate(
          _csvHeaderVentas.length,
          (i) => (i < r.length ? (r[i] ?? '').toString() : '').trim(),
        );

        final distribuidoraOrigenUid = row[0];
        final distribuidoraUid = row[1];
        final gerenteGrupoUid = row[2];
        final vendedorUid = row[3];
        final folioContrato = row[4];
        final modeloUid = row[5];
        final estatusUid = row[6];
        final grupo = int.tryParse(row[7]) ?? 0;
        final integrante = int.tryParse(row[8]) ?? 0;
        final fechaContrato = parseDateFlexible(row[9]);
        final fechaVenta = parseDateFlexible(row[10]);
        final mesVentaCsv = int.tryParse(row[11]);
        final anioVentaCsv = int.tryParse(row[12]);
        final createdAt = parseDateFlexible(row[13]) ?? nowUtc;
        final updatedAt = parseDateFlexible(row[14]) ?? nowUtc;
        final deleted = parseBoolFlexible(row[15], defaultValue: false);
        final isSynced = parseBoolFlexible(row[16], defaultValue: false);

        // Completa mes/año si vienen vacíos y hay fechaVenta
        final mesVenta = mesVentaCsv ?? (fechaVenta?.toUtc().month);
        final anioVenta = anioVentaCsv ?? (fechaVenta?.toUtc().year);

        // Reglas duplicado
        final folioK = kFolio(folioContrato);
        final comboK = kCombo(vendedorUid, fechaVenta, modeloUid);

        final dupDb =
            (folioK.isNotEmpty && byFolio[folioK] == true) ||
            byCombo[comboK] == true;

        final dupCsv =
            (folioK.isNotEmpty && seenFolio[folioK] == true) ||
            seenCombo[comboK] == true;

        if (dupDb || dupCsv) {
          skip++;
          if (folioK.isNotEmpty) seenFolio[folioK] = true;
          seenCombo[comboK] = true;
          continue; // NO insertar
        }

        // Inserción SIEMPRE con uid nuevo
        final uid = const Uuid().v4();
        final comp = VentasCompanion(
          uid: Value(uid),
          distribuidoraOrigenUid: Value(distribuidoraOrigenUid),
          distribuidoraUid: Value(distribuidoraUid),
          gerenteGrupoUid: Value(gerenteGrupoUid),
          vendedorUid: Value(vendedorUid),
          folioContrato: Value(folioContrato),
          modeloUid: Value(modeloUid),
          estatusUid: Value(estatusUid),
          grupo: Value(grupo),
          integrante: Value(integrante),
          fechaContrato: fechaContrato == null
              ? const Value.absent()
              : Value(fechaContrato.toUtc()),
          fechaVenta: fechaVenta == null
              ? const Value.absent()
              : Value(fechaVenta.toUtc()),
          mesVenta: mesVenta == null ? const Value.absent() : Value(mesVenta),
          anioVenta: anioVenta == null
              ? const Value.absent()
              : Value(anioVenta),
          createdAt: Value(createdAt),
          updatedAt: Value(updatedAt),
          deleted: Value(deleted),
          isSynced: Value(isSynced),
        );

        await _dao.upsertVentaDrift(comp);
        ins++;

        // actualiza índices DB & CSV
        if (folioK.isNotEmpty) {
          byFolio[folioK] = true;
          seenFolio[folioK] = true;
        }
        byCombo[comboK] = true;
        seenCombo[comboK] = true;
      }
    });

    state = await _dao.obtenerTodasDrift();
    return (ins, skip);
  }
}

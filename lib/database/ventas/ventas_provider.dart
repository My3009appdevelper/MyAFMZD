// lib/database/ventas/ventas_provider.dart
// ignore_for_file: avoid_print

import 'dart:io';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/database/syncState/sync_state_dao.dart';
import 'package:myafmzd/widgets/CSV/csv_utils.dart';
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
      _syncDao = SyncStateDao(db),

      super([]);

  final Ref _ref;
  final VentasDao _dao;
  final VentasService _servicio;
  final VentasSync _sync;
  final SyncStateDao _syncDao;

  static const _resourceVentas = 'ventas';

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
      print(
        '[💸 MENSAJES VENTAS PROVIDER] Recargado desde DB -> ${state.length} ventas',
      );
    } catch (e) {
      print('[💸 MENSAJES VENTAS PROVIDER] ❌ Error al cargar ventas: $e');
    }
  }

  // ➕ Crear venta → toca sync_state (pending)
  Future<VentaDb> crearVenta({
    required String distribuidoraOrigenUid,
    required String distribuidoraUid,
    required String vendedorUid,
    String folioContrato = '',
    required String modeloUid,
    String estatusUid = '',
    int grupo = 0,
    int integrante = 0,
    DateTime? fechaContrato,
    DateTime? fechaVenta,
    int? mesVenta,
    int? anioVenta,
  }) async {
    final uid = const Uuid().v4();
    final now = DateTime.now().toUtc();

    final mes = mesVenta ?? (fechaVenta?.month);
    final anio = anioVenta ?? (fechaVenta?.year);

    await _dao.upsertVentaDrift(
      VentasCompanion(
        uid: Value(uid),
        distribuidoraOrigenUid: Value(distribuidoraOrigenUid),
        distribuidoraUid: Value(distribuidoraUid),
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

    // 👇 TOCAR sync_state (pendiente)
    await _syncDao.touchLocalPending(resource: _resourceVentas);

    final actual = await _dao.obtenerTodasDrift();
    state = _ordenado(actual);
    return state.firstWhere((v) => v.uid == uid);
  }

  // ✏️ Editar → toca sync_state (pending)
  Future<void> editarVenta({
    required String uid,
    String? distribuidoraOrigenUid,
    String? distribuidoraUid,
    String? vendedorUid,
    String? folioContrato,
    String? modeloUid,
    String? estatusUid,
    int? grupo,
    int? integrante,
    DateTime? fechaContrato,
    DateTime? fechaVenta,
    int? mesVenta,
    int? anioVenta,
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

      // 👇 TOCAR sync_state (pendiente)
      await _syncDao.touchLocalPending(resource: _resourceVentas);

      state = _ordenado(await _dao.obtenerTodasDrift());
      print('[💸 VENTAS PROVIDER] Venta $uid editada (local)');
    } catch (e) {
      print('[💸 VENTAS PROVIDER] ❌ Error al editar venta: $e');
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

  // 🗑️ Soft delete → toca sync_state (pending)
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

      // 👇 TOCAR sync_state (pendiente)
      await _syncDao.touchLocalPending(resource: _resourceVentas);

      state = _ordenado(await _dao.obtenerTodasDrift());
      print('[💸 VENTAS PROVIDER] Venta $uid marcada como eliminada (local)');
    } catch (e) {
      print('[💸 VENTAS PROVIDER] ❌ Error al eliminar: $e');
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

  // ⬇️ EXPORT mantiene TODO (incluye distribuidoraUid)
  static const List<String> _csvHeaderVentasExport = [
    'distribuidoraOrigenUid',
    'distribuidoraUid', // concentradora (solo export)
    'vendedorUid',
    'folioContrato',
    'modeloUid',
    'estatusUid',
    'grupo',
    'integrante',
    'fechaContrato',
    'fechaVenta',
    'mesVenta',
    'anioVenta',
    'createdAt',
    'updatedAt',
    'deleted',
    'isSynced',
  ];

  // ⬇️ IMPORT ya NO espera distribuidoraUid
  static const List<String> _csvHeaderVentasImport = [
    'distribuidoraOrigenUid',
    'vendedorUid',
    'folioContrato',
    'modeloUid',
    'estatusUid',
    'grupo',
    'integrante',
    'fechaContrato',
    'fechaVenta',
    'mesVenta',
    'anioVenta',
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

    lista.sort((a, b) {
      final av = a.fechaVenta ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bv = b.fechaVenta ?? DateTime.fromMillisecondsSinceEpoch(0);
      final cmp = bv.compareTo(av);
      if (cmp != 0) return cmp;
      return a.folioContrato.compareTo(b.folioContrato);
    });

    final rows = <List<dynamic>>[
      ['uid', ..._csvHeaderVentasExport], // 👈 usa header de EXPORT
    ];
    for (final v in lista) {
      rows.add([
        v.uid,
        v.distribuidoraOrigenUid,
        v.distribuidoraUid, // 👈 se exporta
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

    // ✅ Header de IMPORT (sin distribuidoraUid)
    final header = rows.first.map((e) => (e ?? '').toString().trim()).toList();
    final validHeader =
        header.length == _csvHeaderVentasImport.length &&
        _csvHeaderVentasImport.asMap().entries.every(
          (e) => e.value == header[e.key],
        );
    if (!validHeader) {
      throw const FormatException(
        'Encabezado CSV inválido. Esperado: '
        'distribuidoraOrigenUid,vendedorUid,folioContrato,'
        'modeloUid,estatusUid,grupo,integrante,fechaContrato,fechaVenta,mesVenta,anioVenta,'
        'createdAt,updatedAt,deleted,isSynced',
      );
    }

    final dataRows = rows.skip(1);
    final nowUtc = DateTime.now().toUtc();

    // ⚡️ Mapa origen -> concentradora (derivación en memoria)
    final distos = _ref.read(distribuidoresProvider);
    final concMap = <String, String>{
      for (final d in distos)
        d.uid: (d.concentradoraUid.isNotEmpty ? d.concentradoraUid : d.uid),
    };
    String _concentradoraDe(String origenUid) =>
        concMap[origenUid] ?? origenUid;

    // 🔧 Helpers de fecha
    bool _looksDateOnly(String s) {
      final t = s.trim();
      if (t.isEmpty) return false;
      // Sin 'T' y sin ':' es buen indicador de “solo fecha” (e.g., 01/08/2025 o 2025-08-01)
      if (!t.contains('T') && !t.contains(':')) return true;
      // Defensivo: “01-08-2025 00:00” sin TZ también lo tratamos como solo fecha
      final lower = t.toLowerCase();
      final noTz =
          !lower.contains('z') &&
          !t.contains('+') &&
          !RegExp(r'.+\-\d{2}:\d{2}$').hasMatch(lower);
      return noTz && RegExp(r'\b00:00(:00)?\b').hasMatch(t);
    }

    DateTime? _toUtcSafe(String raw) {
      final s = raw.trim();
      if (s.isEmpty) return null;

      final parsed = parseDateFlexible(s); // tu parser existente
      if (parsed == null) return null;

      if (_looksDateOnly(s)) {
        // ⛑️ “Solo fecha”: guardar a las 12:00 UTC para evitar desbordes de día
        return DateTime.utc(parsed.year, parsed.month, parsed.day, 12, 0, 0);
      }
      // Con hora/offset real
      return parsed.toUtc();
    }

    int ins = 0, skip = 0;

    await _dao.db.transaction(() async {
      for (final r in dataRows) {
        if (r.isEmpty) continue;

        // 👇 Genera fila con el largo exacto del HEADER DE IMPORT
        final row = List<String>.generate(
          _csvHeaderVentasImport.length,
          (i) => (i < r.length ? (r[i] ?? '').toString() : '').trim(),
        );

        // Campos CSV (sin distribuidoraUid)
        final distribuidoraOrigenUid = row[0];
        final vendedorUid = row[1];
        final folioContrato = row[2];
        final modeloUid = row[3];
        final estatusUid = row[4];
        final grupo = int.tryParse(row[5]) ?? 0;
        final integrante = int.tryParse(row[6]) ?? 0;

        final fechaContratoUtc = _toUtcSafe(row[7]);
        final fechaVentaUtc = _toUtcSafe(row[8]);

        final mesVentaCsv = int.tryParse(row[9]);
        final anioVentaCsv = int.tryParse(row[10]);

        final createdAt = _toUtcSafe(row[11]) ?? nowUtc;
        final updatedAt = _toUtcSafe(row[12]) ?? nowUtc;

        final deleted = parseBoolFlexible(row[13], defaultValue: false);
        final isSynced = parseBoolFlexible(row[14], defaultValue: false);

        // Completa mes/año desde la fecha YA normalizada
        final mesVenta = mesVentaCsv ?? fechaVentaUtc?.month;
        final anioVenta = anioVentaCsv ?? fechaVentaUtc?.year;

        final concUid = _concentradoraDe(distribuidoraOrigenUid);

        final uid = const Uuid().v4();
        final comp = VentasCompanion(
          uid: Value(uid),
          distribuidoraOrigenUid: Value(distribuidoraOrigenUid),
          distribuidoraUid: Value(concUid),
          vendedorUid: Value(vendedorUid),
          folioContrato: Value(folioContrato),
          modeloUid: Value(modeloUid),
          estatusUid: Value(estatusUid),
          grupo: Value(grupo),
          integrante: Value(integrante),
          fechaContrato: fechaContratoUtc == null
              ? const Value.absent()
              : Value(fechaContratoUtc),
          fechaVenta: fechaVentaUtc == null
              ? const Value.absent()
              : Value(fechaVentaUtc),
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
      }
    });

    state = await _dao.obtenerTodasDrift();
    print(
      '[🧾 MENSAJES VENTAS PROVIDER] CSV import → insertadas:$ins | '
      'saltadas:$skip (concentradora derivada; fechas “solo día” guardadas a 12:00 UTC)',
    );
    if (ins > 0) {
      await _syncDao.touchLocalPending(resource: _resourceVentas);
    }
    return (ins, skip);
  }

  // ===========================================================================
  // AGRUPACIÓN / CONTEOS POR ASIGNACIÓN LABORAL
  // ===========================================================================

  /// Determina si una venta pertenece a la asignación dada:
  /// - Coincide el colaborador (vendedorUid == colaboradorUid de la asignación)
  /// - La fecha de referencia (fechaVenta || updatedAt) cae dentro del rango de la asignación
  /// - Opcionalmente, coincide la distribuidora (venta.distribuidoraUid == asignacion.distribuidorUid)
  bool _ventaPerteneceAAsignacion(
    VentaDb v,
    AsignacionLaboralDb asignacion, {
    bool exigirDistribuidor = false,
    bool incluirEliminadas = false,
  }) {
    if (!incluirEliminadas && v.deleted) return false;

    // ✅ Relación venta ↔ asignación (vendedorUid es el UID de la asignación)
    if (v.vendedorUid != asignacion.uid) return false;

    // ✅ Distribuidora (opcional)
    if (exigirDistribuidor) {
      final distAsignacion = asignacion.distribuidorUid.trim();
      if (distAsignacion.isNotEmpty && v.distribuidoraUid != distAsignacion) {
        return false;
      }
    }

    // ❌ Ya no se valida ningún rango de fechas de la asignación
    return true;
  }

  /// Cuenta ventas del [mes] (1–12) y [anio] que pertenecen a la [asignacion].
  /// - Si la venta trae mesVenta/anioVenta los usamos; si están nulos, derivamos de su fecha de referencia.
  int contarVentasMesAsignacion({
    required AsignacionLaboralDb asignacion,
    required int anio,
    required int mes,
    bool exigirDistribuidor = false,
    bool incluirEliminadas = false,
  }) {
    assert(mes >= 1 && mes <= 12, 'mes debe ser 1..12');

    print(
      '[📊 DEBUG contarMes] anio=$anio mes=$mes '
      'asigUid=${asignacion.uid.substring(0, 8)} '
      'distAsig="${asignacion.distribuidorUid}" '
      'ventasEnMemoria=${state.length} exigirDist=$exigirDistribuidor inclElim=$incluirEliminadas '
      '(solo fechaVenta, sin rango de asignación)',
    );

    int count = 0;
    int revisadas = 0, consideradas = 0, descartadas = 0;

    for (final v in state) {
      revisadas++;

      // Pertenencia por asignación/distribuidora, sin fechas
      if (!_ventaPerteneceAAsignacion(
        v,
        asignacion,
        exigirDistribuidor: exigirDistribuidor,
        incluirEliminadas: incluirEliminadas,
      )) {
        descartadas++;
        continue;
      }

      // ✅ Solo cuenta si hay fechaVenta
      final f = v.fechaVenta;
      if (f == null) {
        descartadas++;
        continue;
      }

      final vMes = v.mesVenta ?? f.toUtc().month;
      final vAnio = v.anioVenta ?? f.toUtc().year;

      if (vMes == mes && vAnio == anio) {
        count++;
        consideradas++;
      } else {
        descartadas++;
      }
    }

    print(
      '[📊 DEBUG contarMes] revisadas=$revisadas consideradas=$consideradas descartadas=$descartadas total=$count',
    );
    return count;
  }

  /// Serie de 12 meses (enero..diciembre) para un [anio] y una [asignacion].
  /// Útil para graficar con fl_chart en el Perfil.
  List<int> serieMensualAnioAsignacion({
    required AsignacionLaboralDb asignacion,
    required int anio,
    bool exigirDistribuidor = false,
    bool incluirEliminadas = false,
  }) {
    final salida = List<int>.filled(12, 0, growable: false);

    print('────────────────────────────────────────────────');
    print(
      '[📈 DEBUG serie] anio=$anio asigUid=${asignacion.uid.substring(0, 8)} '
      'distAsig="${asignacion.distribuidorUid}" ventasEnMemoria=${state.length} '
      'exigirDist=$exigirDistribuidor inclElim=$incluirEliminadas '
      '(solo fechaVenta, sin rango de asignación)',
    );

    int revisadas = 0,
        consideradas = 0,
        descartadasPorAsignacion = 0,
        descartadasPorAnio = 0,
        descartadasSinFechaVenta = 0,
        sumadas = 0;

    for (final v in state) {
      revisadas++;

      // Pertenencia por asignación/distribuidora, sin fechas
      final pertenece = _ventaPerteneceAAsignacion(
        v,
        asignacion,
        exigirDistribuidor: exigirDistribuidor,
        incluirEliminadas: incluirEliminadas,
      );
      if (!pertenece) {
        descartadasPorAsignacion++;
        continue;
      }

      // ✅ Solo contar si hay fechaVenta
      final f = v.fechaVenta;
      if (f == null) {
        descartadasSinFechaVenta++;
        continue;
      }

      consideradas++;

      final vAnio = v.anioVenta ?? f.toUtc().year;
      if (vAnio != anio) {
        descartadasPorAnio++;
        continue;
      }

      final vMes = v.mesVenta ?? f.toUtc().month;
      if (vMes >= 1 && vMes <= 12) {
        salida[vMes - 1] += 1;
        sumadas++;
      }
    }

    print(
      '[📈 DEBUG serie] revisadas=$revisadas consideradas=$consideradas '
      'descartadasPorAsignacion=$descartadasPorAsignacion '
      'descartadasPorAnio=$descartadasPorAnio '
      'sinFechaVenta=$descartadasSinFechaVenta sumadas=$sumadas',
    );
    print('[📈 DEBUG serie] resultado=${salida.join(', ')}');
    print('────────────────────────────────────────────────');

    return salida;
  }
}

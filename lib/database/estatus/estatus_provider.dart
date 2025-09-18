// lib/database/estatus/estatus_provider.dart
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

import 'package:myafmzd/database/estatus/estatus_dao.dart';
import 'package:myafmzd/database/estatus/estatus_service.dart';
import 'package:myafmzd/database/estatus/estatus_sync.dart';

/// ----------------------------------------------------------------------------
/// Provider global de catálogo de Estatus
/// ----------------------------------------------------------------------------
final estatusProvider = StateNotifierProvider<EstatusNotifier, List<EstatusDb>>(
  (ref) {
    final db = ref.watch(appDatabaseProvider);
    return EstatusNotifier(ref, db);
  },
);

class EstatusNotifier extends StateNotifier<List<EstatusDb>> {
  EstatusNotifier(this._ref, AppDatabase db)
    : _dao = EstatusDao(db),
      _servicio = EstatusService(db),
      _sync = EstatusSync(db),
      super([]);

  final Ref _ref;
  final EstatusDao _dao;
  final EstatusService _servicio;
  final EstatusSync _sync;

  bool _hayInternet = true;
  bool get hayInternet => _hayInternet;

  // ---------------------------------------------------------------------------
  // ✅ Cargar estatus (offline-first)
  // ---------------------------------------------------------------------------
  Future<void> cargarOfflineFirst() async {
    try {
      _hayInternet = _ref.read(connectivityProvider);

      // 1) Pintar siempre local primero
      final local = await _dao.obtenerTodosDrift();
      state = _ordenado(local);
      print(
        '[🏷️ MENSAJES ESTATUS PROVIDER] Local cargado -> ${local.length} estatus',
      );

      // 2) Sin internet → detener
      if (!_hayInternet) {
        print(
          '[🏷️ MENSAJES ESTATUS PROVIDER] Sin internet → usando solo local',
        );
        return;
      }

      // 3) (Opcional) comparar timestamps para log/telemetría
      final localTimestamp = await _dao.obtenerUltimaActualizacionDrift();
      final remotoTimestamp = await _servicio.comprobarActualizacionesOnline();
      print(
        '[🏷️ MENSAJES ESTATUS PROVIDER] Remoto:$remotoTimestamp | Local:$localTimestamp',
      );

      // 4) Pull (heads → diff → fetch)
      await _sync.pullEstatusOnline();

      // 5) Push de cambios offline
      await _sync.pushEstatusOffline();

      // 6) Recargar desde Drift
      final actualizados = await _dao.obtenerTodosDrift();
      state = _ordenado(actualizados);
    } catch (e) {
      print('[🏷️ MENSAJES ESTATUS PROVIDER] ❌ Error al cargar estatus: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // ➕ Crear estatus (LOCAL). Deja isSynced=true como en Grupos (simetría).
  //    Si prefieres subir por push, cambia isSynced=false.
  // ---------------------------------------------------------------------------
  Future<EstatusDb?> crearEstatus({
    required String nombre,
    String categoria = 'ciclo',
    int orden = 0,
    bool esFinal = false,
    bool esCancelatorio = false,
    bool visible = true,
    String colorHex = '',
    String icono = '',
    String notas = '',
  }) async {
    final uid = const Uuid().v4();
    try {
      final now = DateTime.now().toUtc();

      final comp = EstatusCompanion(
        uid: Value(uid),
        nombre: Value(nombre),
        categoria: Value(categoria),
        orden: Value(orden),
        esFinal: Value(esFinal),
        esCancelatorio: Value(esCancelatorio),
        visible: Value(visible),
        colorHex: Value(colorHex),
        icono: Value(icono),
        notas: Value(notas),
        createdAt: Value(now),
        updatedAt: Value(now),
        deleted: const Value(false),
        isSynced: const Value(false),
      );

      await _dao.upsertEstatusDrift(comp);

      final actualizados = await _dao.obtenerTodosDrift();
      state = _ordenado(actualizados);

      return state.firstWhere((e) => e.uid == uid, orElse: () => state.last);
    } catch (e) {
      print('[🏷️ MENSAJES ESTATUS PROVIDER] ❌ Error al crear estatus: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // ✏️ Editar estatus (LOCAL → isSynced=false; el push lo sube)
  // ---------------------------------------------------------------------------
  Future<void> editarEstatus({
    required String uid,
    required String nombre,
    String? categoria,
    int? orden,
    bool? esFinal,
    bool? esCancelatorio,
    bool? visible,
    String? colorHex,
    String? icono,
    String? notas,
  }) async {
    try {
      final comp = EstatusCompanion(
        uid: Value(uid),
        nombre: Value(nombre),
        categoria: categoria == null ? const Value.absent() : Value(categoria),
        orden: orden == null ? const Value.absent() : Value(orden),
        esFinal: esFinal == null ? const Value.absent() : Value(esFinal),
        esCancelatorio: esCancelatorio == null
            ? const Value.absent()
            : Value(esCancelatorio),
        visible: visible == null ? const Value.absent() : Value(visible),
        colorHex: colorHex == null ? const Value.absent() : Value(colorHex),
        icono: icono == null ? const Value.absent() : Value(icono),
        notas: notas == null ? const Value.absent() : Value(notas),
        updatedAt: Value(DateTime.now().toUtc()),
        deleted: const Value.absent(),
        isSynced: const Value(false),
      );

      await _dao.actualizarParcialPorUid(uid, comp);

      final actualizados = await _dao.obtenerTodosDrift();
      state = _ordenado(actualizados);
      print('[🏷️ MENSAJES ESTATUS PROVIDER] Estatus $uid editado localmente');
    } catch (e) {
      print('[🏷️ MENSAJES ESTATUS PROVIDER] ❌ Error al editar estatus: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 👁️ Visibilidad / Orden (helpers dedicados)
  // ---------------------------------------------------------------------------
  Future<void> setVisible({required String uid, required bool visible}) async {
    try {
      await _dao.setVisibleDrift(uid, visible);
      state = _ordenado(await _dao.obtenerTodosDrift());
    } catch (e) {
      print('[🏷️ MENSAJES ESTATUS PROVIDER] ❌ Error setVisible: $e');
      rethrow;
    }
  }

  Future<void> setOrden({required String uid, required int orden}) async {
    try {
      await _dao.setOrdenDrift(uid, orden);
      state = _ordenado(await _dao.obtenerTodosDrift());
    } catch (e) {
      print('[🏷️ MENSAJES ESTATUS PROVIDER] ❌ Error setOrden: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 🗑️ Soft delete local → push lo sube
  // ---------------------------------------------------------------------------
  Future<void> eliminarEstatusLocal(String uid) async {
    try {
      await _dao.actualizarParcialPorUid(
        uid,
        EstatusCompanion(
          deleted: const Value(true),
          updatedAt: Value(DateTime.now().toUtc()),
          isSynced: const Value(false),
        ),
      );
      state = _ordenado(await _dao.obtenerTodosDrift());
      print(
        '[🏷️ MENSAJES ESTATUS PROVIDER] Estatus $uid marcado como eliminado (local)',
      );
    } catch (e) {
      print('[🏷️ MENSAJES ESTATUS PROVIDER] ❌ Error al eliminar: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 🔍 Consultas / utilidades en memoria
  // ---------------------------------------------------------------------------
  EstatusDb? obtenerPorUid(String uid) {
    try {
      return state.firstWhere((e) => e.uid == uid);
    } catch (_) {
      return null;
    }
  }

  /// Buscar por texto en nombre o categoría (case-insensitive)
  List<EstatusDb> buscar(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _ordenado(state);
    final res = state.where((e) {
      return e.nombre.trim().toLowerCase().contains(q) ||
          e.categoria.trim().toLowerCase().contains(q);
    }).toList();
    return _ordenado(res);
  }

  /// Filtrar por categoría y visibilidad.
  /// - [categoria]: si es null o 'Todos', no filtra por categoría
  /// - [soloVisibles]: si true, excluye visibles=false
  /// - [incluirEliminados]: si false, excluye deleted=true
  List<EstatusDb> filtrar({
    String? categoria,
    bool soloVisibles = true,
    bool incluirEliminados = false,
  }) {
    final res = state.where((e) {
      final catOk =
          categoria == null || categoria == 'Todos' || e.categoria == categoria;
      final visOk = !soloVisibles || e.visible;
      final delOk = incluirEliminados || !e.deleted;
      return catOk && visOk && delOk;
    }).toList();
    return _ordenado(res);
  }

  /// Detección de duplicado (por nombre+categoría, ignorando mayúsculas/espacios)
  bool existeDuplicado({
    required String uidActual,
    required String nombre,
    required String categoria,
  }) {
    final nom = nombre.trim().toLowerCase();
    final cat = categoria.trim().toLowerCase();
    return state.any((e) {
      if (e.uid == uidActual) return false;
      return e.nombre.trim().toLowerCase() == nom &&
          e.categoria.trim().toLowerCase() == cat &&
          !e.deleted;
    });
  }

  // ----- Helpers -----
  List<EstatusDb> _ordenado(List<EstatusDb> lst) {
    lst.sort((a, b) {
      // 1) visibles primero
      if (a.visible != b.visible) return a.visible ? -1 : 1;
      // 2) categoría
      final c = a.categoria.compareTo(b.categoria);
      if (c != 0) return c;
      // 3) orden numérico
      if (a.orden != b.orden) return a.orden.compareTo(b.orden);
      // 4) nombre asc
      return a.nombre.compareTo(b.nombre);
    });
    return lst;
  }

  // ====================== CSV: helpers locales ======================

  // Encabezado estable (SIN uid). Mismo patrón que el resto: en export se agrega
  // 'uid' como primera columna, el import valida el header SIN 'uid'.
  static const List<String> _csvHeaderEstatus = [
    'nombre',
    'categoria',
    'orden',
    'esFinal',
    'esCancelatorio',
    'visible',
    'colorHex',
    'icono',
    'notas',
    'createdAt',
    'updatedAt',
    'deleted',
    'isSynced',
  ];

  String _fmtIso(DateTime? d) => d == null ? '' : d.toUtc().toIso8601String();

  // ====================== CSV: EXPORTAR ======================

  /// Exporta todos los estatus (o solo NO eliminados) a CSV (String).
  /// Orden consistente: visibles primero, luego categoría, orden y nombre.
  Future<String> exportarCsvEstatus({bool incluirEliminados = false}) async {
    final lista = incluirEliminados
        ? await _dao.obtenerTodosDrift()
        : (await _dao.obtenerTodosDrift()).where((e) => !e.deleted).toList();

    lista.sort((a, b) {
      if (a.visible != b.visible) return a.visible ? -1 : 1;
      final c = a.categoria.compareTo(b.categoria);
      if (c != 0) return c;
      final o = a.orden.compareTo(b.orden);
      if (o != 0) return o;
      return a.nombre.compareTo(b.nombre);
    });

    final rows = <List<dynamic>>[
      ['uid', ..._csvHeaderEstatus],
    ];

    for (final e in lista) {
      rows.add([
        e.uid,
        e.nombre,
        e.categoria,
        e.orden,
        e.esFinal.toString(),
        e.esCancelatorio.toString(),
        e.visible.toString(),
        e.colorHex,
        e.icono,
        e.notas,
        _fmtIso(e.createdAt),
        _fmtIso(e.updatedAt),
        e.deleted.toString(),
        e.isSynced.toString(),
      ]);
    }

    return toCsvStringWithBom(rows);
  }

  /// Genera el archivo .csv en Descargas (si existe) o AppSupport y devuelve la ruta.
  Future<String> exportarCsvAArchivo({String? nombreArchivo}) async {
    final csv = await exportarCsvEstatus();

    final now = DateTime.now().toUtc();
    final ts = now.toIso8601String().replaceAll(':', '-');
    final fileName = (nombreArchivo?.trim().isNotEmpty == true)
        ? nombreArchivo!.trim()
        : 'estatus_$ts.csv';

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

  // ====================== CSV: IMPORTAR ======================

  /// Importa estatus desde CSV. SOLO INSERTA (nunca edita).
  /// Regla de duplicado (DB y dentro del mismo CSV):
  ///   - (nombre + categoria) case-insensitive y trim, ignorando eliminados en DB.
  /// Si una fila es inválida (p.ej. nombre vacío), se salta.
  Future<(int insertados, int saltados)> importarCsvEstatus({
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

    // Header EXACTO (SIN uid)
    final header = rows.first.map((e) => (e ?? '').toString().trim()).toList();
    final validHeader =
        header.length == _csvHeaderEstatus.length &&
        _csvHeaderEstatus.asMap().entries.every(
          (e) => e.value == header[e.key],
        );
    if (!validHeader) {
      throw const FormatException(
        'Encabezado CSV inválido. Esperado: '
        'nombre,categoria,orden,esFinal,esCancelatorio,visible,colorHex,icono,notas,'
        'createdAt,updatedAt,deleted,isSynced',
      );
    }

    final dataRows = rows.skip(1);
    final nowUtc = DateTime.now().toUtc();

    // ===== Índices DB para lookup rápido (nombre+categoria) =====
    final existentes = await _dao.obtenerTodosDrift();
    final byNomCat = <String, bool>{};
    String k(String s) => s.trim().toLowerCase();
    String keyNc(String nombre, String categoria) =>
        '${k(nombre)}|${k(categoria)}';

    for (final e in existentes) {
      if (e.deleted) continue;
      byNomCat[keyNc(e.nombre, e.categoria)] = true;
    }

    // ===== Seen para evitar duplicado dentro del propio CSV =====
    final seenNomCat = <String, bool>{};

    int insertados = 0, saltados = 0;

    await _dao.db.transaction(() async {
      for (final r in dataRows) {
        if (r.isEmpty) continue;

        final row = List<String>.generate(
          _csvHeaderEstatus.length,
          (i) => (i < r.length ? (r[i] ?? '').toString() : '').trim(),
        );

        final nombre = row[0];
        final categoria = row[1].isEmpty ? 'ciclo' : row[1];
        final orden = int.tryParse(row[2]) ?? 0;
        final esFinal = parseBoolFlexible(row[3], defaultValue: false);
        final esCancelatorio = parseBoolFlexible(row[4], defaultValue: false);
        final visible = parseBoolFlexible(row[5], defaultValue: true);
        final colorHex = row[6];
        final icono = row[7];
        final notas = row[8];
        final createdAt = parseDateFlexible(row[9]) ?? nowUtc;
        final updatedAt = parseDateFlexible(row[10]) ?? nowUtc;
        final deleted = parseBoolFlexible(row[11], defaultValue: false);
        final isSynced = parseBoolFlexible(row[12], defaultValue: false);

        // Validación básica
        if (nombre.trim().isEmpty) {
          saltados++;
          continue;
        }

        final nc = keyNc(nombre, categoria);
        final dupDb = byNomCat[nc] == true;
        final dupCsv = seenNomCat[nc] == true;

        if (dupDb || dupCsv) {
          saltados++;
          seenNomCat[nc] = true;
          continue;
        }

        // Inserción SIEMPRE con uid nuevo
        final uid = const Uuid().v4();
        final comp = EstatusCompanion(
          uid: Value(uid),
          nombre: Value(nombre),
          categoria: Value(categoria),
          orden: Value(orden),
          esFinal: Value(esFinal),
          esCancelatorio: Value(esCancelatorio),
          visible: Value(visible),
          colorHex: Value(colorHex),
          icono: Value(icono),
          notas: Value(notas),
          createdAt: Value(createdAt),
          updatedAt: Value(updatedAt),
          deleted: Value(deleted),
          isSynced: Value(isSynced),
        );

        await _dao.upsertEstatusDrift(comp);
        insertados++;

        byNomCat[nc] = true;
        seenNomCat[nc] = true;
      }
    });

    state = _ordenado(await _dao.obtenerTodosDrift());
    print(
      '[🏷️ MENSAJES ESTATUS PROVIDER] CSV import → insertados:$insertados | saltados:$saltados',
    );
    return (insertados, saltados);
  }
}

import 'dart:io';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/database_provider.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_dao.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_service.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_sync.dart';
import 'package:myafmzd/widgets/CSV/csv_utils.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// Estado = lista completa (incluye eliminados si los cargas explícitamente)
final distribuidoresProvider =
    StateNotifierProvider<DistribuidoresNotifier, List<DistribuidorDb>>((ref) {
      final db = ref.watch(appDatabaseProvider);
      return DistribuidoresNotifier(ref, db);
    });

class DistribuidoresNotifier extends StateNotifier<List<DistribuidorDb>> {
  DistribuidoresNotifier(this._ref, AppDatabase db)
    : _dao = DistribuidoresDao(db),
      _servicio = DistribuidoresService(db),
      _sync = DistribuidoresSync(db),
      super([]);

  final Ref _ref;
  final DistribuidoresDao _dao;
  final DistribuidoresService _servicio;
  final DistribuidoresSync _sync;

  bool _hayInternet = true;
  bool get hayInternet => _hayInternet;

  // ---------------------------------------------------------------------------
  // ✅ Cargar distribuidores (offline-first)
  // ---------------------------------------------------------------------------
  Future<void> cargarOfflineFirst() async {
    try {
      _hayInternet = _ref.read(connectivityProvider);

      // 1) Pintar siempre local primero
      final local = await _dao.obtenerTodosDrift();
      state = local;
      print(
        '[🏢 MENSAJES DISTRIBUIDORES PROVIDER] Local cargado -> ${local.length} distribuidores',
      );

      // 2) Sin internet → detener
      if (!_hayInternet) {
        print(
          '[🏢 MENSAJES DISTRIBUIDORES PROVIDER] Sin internet → usando solo local',
        );
        return;
      }

      // 3) (Opcional) comparar timestamps para logging/telemetría
      final localTimestamp = await _dao.obtenerUltimaActualizacionDrift();
      final remotoTimestamp = await _servicio.comprobarActualizacionesOnline();
      print(
        '[🏢 MENSAJES DISTRIBUIDORES PROVIDER] Remoto:$remotoTimestamp | Local:$localTimestamp',
      );

      // 4) Pull (heads → diff → bulk)
      await _sync.pullDistribuidoresOnline();

      // 5) Push de cambios offline
      await _sync.pushDistribuidoresOffline();

      // 6) Recargar desde Drift
      final actualizados = await _dao.obtenerTodosDrift();
      state = actualizados;
    } catch (e) {
      print(
        '[🏢 MENSAJES DISTRIBUIDORES PROVIDER] ❌ Error al cargar distribuidores: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // ➕ Crear distribuidor (ONLINE upsert → local isSynced=true)
  //    Simétrico a crearUsuario pero sin Auth.
  // ---------------------------------------------------------------------------
  Future<DistribuidorDb?> crearDistribuidor({
    required String nombre,
    String uuidGrupo = '',
    String direccion = '',
    bool activo = true,
    double latitud = 0.0,
    double longitud = 0.0,
    String? concentradoraUid,
  }) async {
    final uid = const Uuid().v4();

    try {
      final now = DateTime.now().toUtc();
      // Regla: si no pasas concentradoraUid, se auto-apunta (es concentradora)
      final conc = (concentradoraUid == null || concentradoraUid.trim().isEmpty)
          ? uid
          : concentradoraUid.trim();

      // 2) Upsert LOCAL (remoto ⇒ isSynced=true)
      final comp = DistribuidoresCompanion(
        uid: Value(uid),
        nombre: Value(nombre),
        uuidGrupo: Value(uuidGrupo),
        direccion: Value(direccion),
        activo: Value(activo),
        latitud: Value(latitud),
        longitud: Value(longitud),
        concentradoraUid: Value(conc),
        deleted: const Value(false),
        updatedAt: Value(now),
        isSynced: const Value(false),
      );
      await _dao.upsertDistribuidoresDrift([comp]);

      // 3) Refrescar estado
      final actualizados = await _dao.obtenerTodosDrift();
      state = actualizados;

      // 4) Devolver el insertado
      return actualizados.firstWhere(
        (d) => d.uid == uid,
        orElse: () => actualizados.last,
      );
    } catch (e) {
      print(
        '[🏢 MENSAJES DISTRIBUIDORES PROVIDER] ❌ Error al crear distribuidor: $e',
      );
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // ✏️ Editar distribuidor (LOCAL → isSynced=false; el push lo sube)
  // ---------------------------------------------------------------------------
  Future<void> editarDistribuidor({
    required String uid,
    required String nombre,
    String? uuidGrupo,
    String? direccion,
    bool? activo,
    double? latitud,
    double? longitud,
    String? concentradoraUid,
  }) async {
    try {
      final comp = DistribuidoresCompanion(
        uid: Value(uid),
        nombre: Value(nombre),
        uuidGrupo: uuidGrupo == null ? const Value.absent() : Value(uuidGrupo),
        direccion: direccion == null ? const Value.absent() : Value(direccion),
        activo: activo == null ? const Value.absent() : Value(activo),
        latitud: latitud == null ? const Value.absent() : Value(latitud),
        longitud: longitud == null ? const Value.absent() : Value(longitud),
        concentradoraUid: (concentradoraUid == null)
            ? const Value.absent()
            : Value(concentradoraUid),
        updatedAt: Value(DateTime.now().toUtc()),
        deleted: const Value.absent(),
        isSynced: const Value(false),
      );

      await _dao.upsertDistribuidorDrift(comp);

      final actualizados = await _dao.obtenerTodosDrift();
      state = actualizados;
      print(
        '[🏢 MENSAJES DISTRIBUIDORES PROVIDER] Distribuidor $uid editado localmente',
      );
    } catch (e) {
      print(
        '[🏢 MENSAJES DISTRIBUIDORES PROVIDER] ❌ Error al editar distribuidor: $e',
      );
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 🧪 Validación de duplicados
  //    (Simétrico a usuarios: usamos nombre y/o dirección como llave "humana")
  // ---------------------------------------------------------------------------
  bool existeDuplicado({
    required String uidActual,
    required String nombre,
    String? direccion,
  }) {
    final nom = nombre.trim().toLowerCase();
    final dir = (direccion ?? '').trim().toLowerCase();
    return state.any((d) {
      if (d.uid == uidActual) return false;
      final sameName = d.nombre.trim().toLowerCase() == nom;
      final sameDir = dir.isNotEmpty && d.direccion.trim().toLowerCase() == dir;
      return sameName || sameDir;
    });
  }

  DistribuidorDb? obtenerPorId(String id) {
    try {
      return state.firstWhere((d) => d.uid == id);
    } catch (_) {
      return null;
    }
  }

  /// ✅ Obtener lista de grupos únicos
  List<String> get gruposUnicos {
    final grupos = state.map((d) => d.uuidGrupo).toSet().toList(); // 👈 cambio
    grupos.sort();
    // Nota: ya no insertamos 'AFMZD' porque ahora es FK; si quieres un “default”
    // visual, hazlo en la UI leyendo la tabla de grupos.
    return grupos;
  }

  /// ✅ Filtrar distribuidores por grupo y estado
  List<DistribuidorDb> filtrar({
    required bool mostrarInactivos,
    String? uuidGrupo, // 👈 si lo usas desde UI, ahora debe pasar uuidGrupo
  }) {
    return state.where((d) {
      final activoOk = mostrarInactivos || d.activo;
      final grupoOk =
          uuidGrupo == null ||
          uuidGrupo == 'Todos' ||
          d.uuidGrupo == uuidGrupo; // 👈
      return activoOk && grupoOk;
    }).toList()..sort((a, b) {
      if (a.activo != b.activo) return a.activo ? -1 : 1;
      return a.nombre.compareTo(b.nombre);
    });
  }

  String concentradoraDe(String origenUid) {
    final d = obtenerPorId(origenUid);
    if (d == null) return '';
    return (d.concentradoraUid.isNotEmpty) ? d.concentradoraUid : d.uid;
  }

  // ====================== CSV: helpers locales ======================

  // Encabezado estable (sin uid). Solo campos propios de la tabla.
  static const List<String> _csvHeaderDistribuidores = [
    'nombre',
    'uuidGrupo',
    'direccion',
    'activo',
    'latitud',
    'longitud',
    'concentradoraUid',
    'updatedAt', // ISO-UTC o vacío
    'deleted', // true/false/1/0/yes/no/si
    'isSynced', // true/false/1/0/yes/no/si
  ];

  String _fmtIso(DateTime? d) => d == null ? '' : d.toUtc().toIso8601String();

  // ====================== CSV: EXPORTAR ======================

  /// Exporta todas (o solo NO eliminadas) a CSV en String.
  /// Orden: activas primero, luego por nombre asc. Header EXACTO (sin uid).
  Future<String> exportarCsvDistribuidores({
    bool incluirEliminados = false,
  }) async {
    final lista = incluirEliminados
        ? await _dao.obtenerTodosDrift()
        : (await _dao.obtenerTodosDrift()).where((d) => !d.deleted).toList();

    // Orden consistente: activas primero, luego nombre
    lista.sort((a, b) {
      if (a.activo != b.activo) return a.activo ? -1 : 1;
      return a.nombre.compareTo(b.nombre);
    });

    final rows = <List<dynamic>>[
      ['uid', ..._csvHeaderDistribuidores],
    ];

    for (final d in lista) {
      rows.add([
        d.uid,
        d.nombre,
        d.uuidGrupo,
        d.direccion,
        d.activo.toString(),
        d.latitud,
        d.longitud,
        d.concentradoraUid,
        _fmtIso(d.updatedAt),
        d.deleted.toString(),
        d.isSynced.toString(),
      ]);
    }

    return toCsvStringWithBom(rows);
  }

  /// Genera el archivo .csv y devuelve la ruta exacta donde quedó.
  Future<String> exportarCsvAArchivo({String? nombreArchivo}) async {
    final csv = await exportarCsvDistribuidores();

    final now = DateTime.now().toUtc();
    final ts = now.toIso8601String().replaceAll(':', '-');
    final fileName = (nombreArchivo?.trim().isNotEmpty == true)
        ? nombreArchivo!.trim()
        : 'distribuidores_$ts.csv';

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

  /// Importa distribuidores desde CSV. SOLO INSERTA. Nunca edita existentes.
  /// Reglas de duplicado:
  ///  - (nombre) case-insensitive
  ///  - o (direccion) si viene no vacía, case-insensitive
  /// Además evita duplicados dentro del mismo CSV.
  ///
  /// Nota: si `concentradoraUid` viene vacío, se auto-apunta al propio uid
  /// generado (la propia distribuidora es su concentradora).
  Future<(int insertados, int saltados)> importarCsvDistribuidores({
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

    // Header EXACTO
    final header = rows.first.map((e) => (e ?? '').toString().trim()).toList();
    final validHeader =
        header.length == _csvHeaderDistribuidores.length &&
        _csvHeaderDistribuidores.asMap().entries.every(
          (e) => e.value == header[e.key],
        );
    if (!validHeader) {
      throw const FormatException(
        'Encabezado CSV inválido. Esperado: '
        'nombre,uuidGrupo,direccion,activo,latitud,longitud,concentradoraUid,updatedAt,deleted,isSynced',
      );
    }

    final dataRows = rows.skip(1);
    final nowUtc = DateTime.now().toUtc();

    // ===== Índices de existentes (DB) para lookup rápido =====
    final existentes = await _dao.obtenerTodosDrift();
    final byName = <String, bool>{};
    final byDir = <String, bool>{};

    String k(String s) => s.trim().toLowerCase();

    for (final d in existentes) {
      if (d.deleted) continue;
      byName[k(d.nombre)] = true;
      if (d.direccion.trim().isNotEmpty) {
        byDir[k(d.direccion)] = true;
      }
    }

    // ===== Seen para evitar duplicado dentro del CSV =====
    final seenName = <String, bool>{};
    final seenDir = <String, bool>{};

    int insertados = 0, saltados = 0;

    await _dao.db.transaction(() async {
      for (final r in dataRows) {
        if (r.isEmpty) continue;

        final row = List<String>.generate(
          _csvHeaderDistribuidores.length,
          (i) => (i < r.length ? (r[i] ?? '').toString() : '').trim(),
        );

        final nombre = row[0];
        final uuidGrupo = row[1];
        final direccion = row[2];
        final activoStr = row[3];
        final latStr = row[4];
        final lngStr = row[5];
        final concentradoraUidCsv = row[6];
        final updatedStr = row[7];
        final deletedStr = row[8];
        final syncedStr = row[9];

        final activo = parseBoolFlexible(activoStr, defaultValue: true);
        final lat = double.tryParse(latStr) ?? 0.0;
        final lng = double.tryParse(lngStr) ?? 0.0;
        final updatedAt = parseDateFlexible(updatedStr) ?? nowUtc;
        final deleted = parseBoolFlexible(deletedStr, defaultValue: false);
        final isSynced = parseBoolFlexible(syncedStr, defaultValue: false);

        final nameK = k(nombre);
        final dirK = k(direccion);

        final dupDb =
            (nameK.isNotEmpty && byName[nameK] == true) ||
            (dirK.isNotEmpty && byDir[dirK] == true);

        final dupCsv =
            (nameK.isNotEmpty && seenName[nameK] == true) ||
            (dirK.isNotEmpty && seenDir[dirK] == true);

        if (dupDb || dupCsv) {
          saltados++;
          if (nameK.isNotEmpty) seenName[nameK] = true;
          if (dirK.isNotEmpty) seenDir[dirK] = true;
          continue; // NO insertes
        }

        // Inserción SIEMPRE con uid nuevo
        final uid = const Uuid().v4();
        final concUid = (concentradoraUidCsv.isEmpty)
            ? uid
            : concentradoraUidCsv;

        final comp = DistribuidoresCompanion(
          uid: Value(uid),
          nombre: Value(nombre),
          uuidGrupo: Value(uuidGrupo),
          direccion: Value(direccion),
          activo: Value(activo),
          latitud: Value(lat),
          longitud: Value(lng),
          concentradoraUid: Value(concUid),
          updatedAt: Value(updatedAt),
          deleted: Value(deleted),
          isSynced: Value(isSynced),
        );

        await _dao.upsertDistribuidorDrift(comp);
        insertados++;

        // Actualiza índices para siguientes filas
        if (nameK.isNotEmpty) {
          byName[nameK] = true;
          seenName[nameK] = true;
        }
        if (dirK.isNotEmpty) {
          byDir[dirK] = true;
          seenDir[dirK] = true;
        }
      }
    });

    state = await _dao.obtenerTodosDrift();
    print(
      '[🏢 MENSAJES DISTRIBUIDORES PROVIDER] CSV import → insertados:$insertados | saltados:$saltados',
    );
    return (insertados, saltados);
  }

  String concentradoraDeOrSelf(String origenUid) {
    final distos = _ref.read(distribuidoresProvider);
    for (final d in distos) {
      if (d.uid == origenUid) {
        return (d.concentradoraUid.isNotEmpty) ? d.concentradoraUid : d.uid;
      }
    }
    return origenUid;
  }
}

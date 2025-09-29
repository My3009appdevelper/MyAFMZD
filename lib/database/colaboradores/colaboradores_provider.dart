// ignore_for_file: avoid_print
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/database_provider.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_dao.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_service.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_sync.dart';
import 'package:myafmzd/screens/z%20Utils/csv_utils.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

/// ----------------------------------------------------------------------------
/// Provider global
/// ----------------------------------------------------------------------------
final colaboradoresProvider =
    StateNotifierProvider<ColaboradoresNotifier, List<ColaboradorDb>>((ref) {
      final db = ref.watch(appDatabaseProvider);
      return ColaboradoresNotifier(ref, db);
    });

class ColaboradoresNotifier extends StateNotifier<List<ColaboradorDb>> {
  ColaboradoresNotifier(this._ref, AppDatabase db)
    : _dao = ColaboradoresDao(db),
      _servicio = ColaboradoresService(db),
      _sync = ColaboradoresSync(db),
      super([]);

  final Ref _ref;
  final ColaboradoresDao _dao;
  final ColaboradoresService _servicio;
  final ColaboradoresSync _sync;

  bool _hayInternet = true;
  bool get hayInternet => _hayInternet;

  String? _nvl(String? s) => (s == null || s.trim().isEmpty) ? null : s.trim();

  // ---------------------------------------------------------------------------
  // ✅ Cargar colaboradores (offline-first)
  // ---------------------------------------------------------------------------
  Future<void> cargarOfflineFirst() async {
    try {
      _hayInternet = _ref.read(connectivityProvider);

      final local = await _dao.obtenerTodosDrift();
      state = local;
      print('[👥 COLABS PROVIDER] Local -> ${local.length}');

      if (!_hayInternet) {
        print('[👥 COLABS PROVIDER] Sin internet → solo local');
        return;
      }

      final localTimestamp = await _dao.obtenerUltimaActualizacionDrift();
      final remotoTimestamp = await _servicio.comprobarActualizacionesOnline();
      print(
        '[👥 COLABS PROVIDER] Remoto:$remotoTimestamp | Local:$localTimestamp',
      );

      await _sync.pullColaboradoresOnline();
      await _sync.pushColaboradoresOffline();

      final actualizados = await _dao.obtenerTodosDrift();
      state = actualizados;

      final cambios = await syncFotosLocales();
      if (cambios > 0) {
        state = await _dao.obtenerTodosDrift();
        print('[👥 COLABS PROVIDER] Fotos sync → $cambios cambios');
      }
    } catch (e) {
      print('[👥 COLABS PROVIDER] ❌ Error al cargar: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // ➕ Crear colaborador
  // ---------------------------------------------------------------------------
  Future<ColaboradorDb?> crearColaborador({
    required String nombres,
    String apellidoPaterno = '',
    String apellidoMaterno = '',
    DateTime? fechaNacimiento,
    String curp = '',
    String rfc = '',
    String telefonoMovil = '',
    String emailPersonal = '',
    String genero = '',
    String notas = '',
    String fotoRutaRemota = '',
    String fotoRutaLocal = '',
  }) async {
    final uid = const Uuid().v4();

    try {
      final now = DateTime.now().toUtc();

      final comp = ColaboradoresCompanion(
        uid: Value(uid),
        nombres: Value(nombres), // no-nullable
        // 👇 normaliza '' → NULL
        apellidoPaterno: Value(_nvl(apellidoPaterno)),
        apellidoMaterno: Value(_nvl(apellidoMaterno)),
        fechaNacimiento: fechaNacimiento == null
            ? const Value(null)
            : Value(fechaNacimiento.toUtc()),
        curp: Value(_nvl(curp)),
        rfc: Value(_nvl(rfc)),
        telefonoMovil: Value(_nvl(telefonoMovil)),
        emailPersonal: Value(_nvl(emailPersonal)),
        genero: Value(_nvl(genero)),
        notas: Value(_nvl(notas)),
        fotoRutaRemota: Value(_nvl(fotoRutaRemota)),
        fotoRutaLocal: Value(_nvl(fotoRutaLocal)),
        createdAt: Value(now),
        updatedAt: Value(now),
        deleted: const Value(false),
        isSynced: const Value(false),
      );
      await _dao.upsertColaboradorDrift(comp);

      final actualizados = await _dao.obtenerTodosDrift();
      state = actualizados;
      return actualizados.firstWhere(
        (c) => c.uid == uid,
        orElse: () => actualizados.last,
      );
    } catch (e) {
      print('[👥 COLABS PROVIDER] ❌ Error al crear: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // ✏️ Editar colaborador
  //   - null  -> no tocar (absent)
  //   - ''    -> escribir NULL
  //   - texto -> escribir texto
  // ---------------------------------------------------------------------------
  Future<void> editarColaborador({
    required String uid,
    required String nombres,
    String? apellidoPaterno,
    String? apellidoMaterno,
    DateTime? fechaNacimiento,
    String? curp,
    String? rfc,
    String? telefonoMovil,
    String? emailPersonal,
    String? genero,
    String? notas,
    String? fotoRutaRemota,
    String? fotoRutaLocal,
  }) async {
    try {
      final comp = ColaboradoresCompanion(
        uid: Value(uid),
        nombres: Value(nombres),
        apellidoPaterno: Value(apellidoPaterno),
        apellidoMaterno: Value(apellidoMaterno),
        fechaNacimiento: fechaNacimiento == null
            ? const Value.absent()
            : Value(fechaNacimiento.toUtc()),
        curp: Value(curp),
        rfc: Value(rfc),
        telefonoMovil: Value(telefonoMovil),
        emailPersonal: Value(emailPersonal),
        genero: Value(genero),
        notas: Value(notas),
        fotoRutaRemota: Value(fotoRutaRemota),
        fotoRutaLocal: Value(fotoRutaLocal),
        updatedAt: Value(DateTime.now().toUtc()),
        deleted: const Value.absent(),
        isSynced: const Value(false),
      );

      await _dao.upsertColaboradorDrift(comp);

      state = await _dao.obtenerTodosDrift();
      print('[👥 COLABS PROVIDER] Editado local: $uid');
    } catch (e) {
      print('[👥 COLABS PROVIDER] ❌ Error al editar: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📷 Fotos
  // ---------------------------------------------------------------------------
  Future<ColaboradorDb?> descargarFoto(ColaboradorDb c) async {
    final reused = _localFileForRuta(c.fotoRutaRemota);
    if (reused != null) {
      await _dao.actualizarParcialPorUid(
        c.uid,
        ColaboradoresCompanion(fotoRutaLocal: Value(reused.path)),
      );
      state = await _dao.obtenerTodosDrift();
      return state.firstWhere((x) => x.uid == c.uid, orElse: () => c);
    }

    final remote = c.fotoRutaRemota?.trim() ?? '';
    if (remote.isEmpty) {
      print('[👥 COLABS PROVIDER] ⚠️ rutaRemota vacía');
      return null;
    }

    final file = await _servicio.descargarImagenOnline(remote);
    if (file == null) {
      print('[👥 COLABS PROVIDER] ❌ No se pudo descargar foto');
      return null;
    }

    await _dao.actualizarParcialPorUid(
      c.uid,
      ColaboradoresCompanion(fotoRutaLocal: Value(file.path)),
    );

    state = await _dao.obtenerTodosDrift();
    return state.firstWhere((x) => x.uid == c.uid, orElse: () => c);
  }

  Future<void> eliminarFotoLocal(ColaboradorDb c) async {
    print('[👥 COLABS PROVIDER] Borrando foto local: ${c.fotoRutaLocal}');
    final path = c.fotoRutaLocal;
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      try {
        if (await file.exists()) await file.delete();
      } catch (e) {
        print('[👥 COLABS PROVIDER] ⚠️ Error borrando foto local: $e');
      }
    }

    await _dao.actualizarParcialPorUid(
      c.uid,
      const ColaboradoresCompanion(fotoRutaLocal: Value(null)), // NULL
    );

    state = await _dao.obtenerTodosDrift();
  }

  Future<void> subirNuevaFoto({
    required ColaboradorDb colaborador,
    required File archivo,
  }) async {
    try {
      final hash = await _servicio.calcularSha256(archivo);
      final ext = p.extension(archivo.path).toLowerCase();
      final cleanExt = (ext.isEmpty ? '.jpg' : ext);

      final remotePath = 'colaboradores/${colaborador.uid}/$hash$cleanExt';

      final dir = await getApplicationSupportDirectory();
      final fotosDir = Directory(p.join(dir.path, 'colaboradores_img'));
      if (!await fotosDir.exists()) await fotosDir.create(recursive: true);

      final safeName = remotePath.replaceAll('/', '_');
      final destino = File(p.join(fotosDir.path, safeName));
      await archivo.copy(destino.path);

      final oldRemote = colaborador.fotoRutaRemota ?? '';
      final oldLocal = colaborador.fotoRutaLocal ?? '';

      await _dao.actualizarParcialPorUid(
        colaborador.uid,
        ColaboradoresCompanion(
          fotoRutaRemota: Value(remotePath),
          fotoRutaLocal: Value(destino.path),
          updatedAt: Value(DateTime.now().toUtc()),
          isSynced: const Value(false),
        ),
      );

      if (oldLocal.isNotEmpty &&
          oldLocal != destino.path &&
          await File(oldLocal).exists()) {
        try {
          await File(oldLocal).delete();
          print('[👥 COLABS PROVIDER] 🧹 Local anterior eliminado: $oldLocal');
        } catch (e) {
          print('[👥 COLABS PROVIDER] ⚠️ No se pudo borrar local anterior: $e');
        }
      }

      state = await _dao.obtenerTodosDrift();

      if (_hayInternet) {
        await _sync.pushColaboradoresOffline();
        if (oldRemote.isNotEmpty && oldRemote != remotePath) {
          await _servicio.deleteImagenOnlineSafe(oldRemote);
        }
        await _sync.pullColaboradoresOnline();
        state = await _dao.obtenerTodosDrift();
      }

      print('[Colaboradores] Foto lista para sync: $remotePath');
    } catch (e) {
      print('[Colaboradores] ❌ Error preparando foto: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📥 Descarga diferida en lote
  // ---------------------------------------------------------------------------
  Future<int> syncFotosLocales({
    int max = 500,
    bool borrarObsoletas = true,
  }) async {
    if (!_hayInternet) return 0;

    final candidatos = state.where((c) {
      if (c.deleted) return false;
      return (c.fotoRutaRemota?.trim().isNotEmpty == true);
    }).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (candidatos.isEmpty) return 0;

    int cambios = 0;
    int procesados = 0;

    String _cleanRemote(String r) => r.startsWith('/') ? r.substring(1) : r;
    String _safeName(String r) => _cleanRemote(r).replaceAll('/', '_');

    for (final c in candidatos) {
      if (procesados >= max) break;
      final remote = (c.fotoRutaRemota ?? '').trim();
      if (remote.isEmpty) {
        procesados++;
        continue;
      }
      final expectedSafeName = _safeName(remote);

      final tieneLocal =
          (c.fotoRutaLocal?.isNotEmpty == true) &&
          File(c.fotoRutaLocal!).existsSync();
      final apuntaALoEsperado =
          tieneLocal && p.basename(c.fotoRutaLocal!) == expectedSafeName;

      if (apuntaALoEsperado) {
        procesados++;
        continue;
      }

      if (tieneLocal &&
          p.basename(c.fotoRutaLocal!) != expectedSafeName &&
          borrarObsoletas) {
        try {
          await File(c.fotoRutaLocal!).delete();
        } catch (_) {}
      }

      File? targetFile;
      try {
        final baseDir = await getApplicationSupportDirectory();
        final targetDir = Directory(p.join(baseDir.path, 'colaboradores_img'));
        final canonical = File(p.join(targetDir.path, expectedSafeName));
        if (await canonical.exists()) {
          targetFile = canonical;
        }
      } catch (_) {}

      targetFile ??= await _servicio.descargarImagenOnline(remote);
      if (targetFile == null) {
        procesados++;
        continue;
      }

      await _dao.actualizarParcialPorUid(
        c.uid,
        ColaboradoresCompanion(fotoRutaLocal: Value(targetFile.path)),
      );

      cambios++;
      procesados++;
    }

    if (cambios > 0) {
      state = await _dao.obtenerTodosDrift();
    }
    return cambios;
  }

  // ---------------------------------------------------------------------------
  // 🔍 Consultas / utilidades
  // ---------------------------------------------------------------------------
  ColaboradorDb? obtenerPorUid(String uid) {
    try {
      return state.firstWhere((c) => c.uid == uid);
    } catch (_) {
      return null;
    }
  }

  List<ColaboradorDb> buscarPorNombre(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return state;
    return state.where((c) {
      final nombreCompleto =
          '${c.nombres} ${c.apellidoPaterno ?? ''} ${c.apellidoMaterno ?? ''}'
              .trim()
              .toLowerCase();
      return nombreCompleto.contains(q) ||
          (c.emailPersonal?.toLowerCase().contains(q) ?? false) ||
          (c.telefonoMovil?.toLowerCase().contains(q) ?? false);
    }).toList()..sort((a, b) => a.nombres.compareTo(b.nombres));
  }

  // Soft delete local → push lo sube
  Future<void> eliminarColaboradorLocal(String uid) async {
    await _dao.upsertColaboradorDrift(
      ColaboradoresCompanion(
        uid: Value(uid),
        deleted: const Value(true),
        updatedAt: Value(DateTime.now().toUtc()),
        isSynced: const Value(false),
      ),
    );
    state = await _dao.obtenerTodosDrift();
  }

  // Helpers de reuso local
  File? _localFileForRuta(String? ruta) {
    final r = ruta?.trim() ?? '';
    if (r.isEmpty) return null;
    try {
      final other = state.firstWhere(
        (c) =>
            c.fotoRutaRemota == r &&
            (c.fotoRutaLocal?.isNotEmpty == true) &&
            File(c.fotoRutaLocal!).existsSync(),
      );
      return File(other.fotoRutaLocal!);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 🔎 Duplicados
  // ---------------------------------------------------------------------------
  bool existeDuplicado({
    String curp = '',
    String rfc = '',
    String telefonoMovil = '',
    String emailPersonal = '',
    String nombres = '',
    String apellidoPaterno = '',
    String apellidoMaterno = '',
    DateTime? fechaNacimiento,
    String? excluirUid,
  }) {
    final curpIn = curp.trim().toLowerCase();
    final rfcIn = rfc.trim().toLowerCase();
    final emailIn = emailPersonal.trim().toLowerCase();
    final phoneIn = _digits(telefonoMovil);
    final fullNameIn = _norm('$nombres $apellidoPaterno $apellidoMaterno');

    for (final c in state) {
      if (c.deleted) continue;
      if (excluirUid != null && excluirUid.isNotEmpty && c.uid == excluirUid) {
        continue;
      }

      final curpDb = (c.curp ?? '').trim().toLowerCase();
      if (curpIn.isNotEmpty && curpDb.isNotEmpty && curpDb == curpIn)
        return true;

      final rfcDb = (c.rfc ?? '').trim().toLowerCase();
      if (rfcIn.isNotEmpty && rfcDb.isNotEmpty && rfcDb == rfcIn) return true;

      final emailDb = (c.emailPersonal ?? '').trim().toLowerCase();
      if (emailIn.isNotEmpty && emailDb.isNotEmpty && emailDb == emailIn)
        return true;

      final telDb = _digits(c.telefonoMovil ?? '');
      if (phoneIn.isNotEmpty && telDb.isNotEmpty && telDb == phoneIn)
        return true;

      if (fullNameIn.isNotEmpty && fechaNacimiento != null) {
        final fullNameDb = _norm(
          '${c.nombres} ${c.apellidoPaterno ?? ''} ${c.apellidoMaterno ?? ''}',
        );
        final fDb = c.fechaNacimiento?.toUtc();
        if (fullNameDb == fullNameIn &&
            fDb != null &&
            fDb == fechaNacimiento.toUtc()) {
          return true;
        }
      }
    }
    return false;
  }

  // ----- Helpers de normalización -----
  String _norm(String s) {
    final lower = s.trim().toLowerCase();
    return lower
        .replaceAll(RegExp(r'[áàä]'), 'a')
        .replaceAll(RegExp(r'[éèë]'), 'e')
        .replaceAll(RegExp(r'[íìï]'), 'i')
        .replaceAll(RegExp(r'[óòö]'), 'o')
        .replaceAll(RegExp(r'[úùü]'), 'u')
        .replaceAll(RegExp(r'ñ'), 'n')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _digits(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  // ====================== CSV ======================
  static const List<String> _csvHeaderColabs = [
    'nombres',
    'apellidoPaterno',
    'apellidoMaterno',
    'fechaNacimiento',
    'curp',
    'rfc',
    'telefonoMovil',
    'emailPersonal',
    'fotoRutaLocal',
    'fotoRutaRemota',
    'genero',
    'notas',
    'createdAt',
    'updatedAt',
    'deleted',
    'isSynced',
  ];

  String _fmtIso(DateTime? d) => d == null ? '' : d.toUtc().toIso8601String();

  Future<String> exportarCsvColaboradores({
    bool incluirEliminados = false,
  }) async {
    final lista = incluirEliminados
        ? await _dao.obtenerTodosDrift()
        : (await _dao.obtenerTodosDrift()).where((c) => !c.deleted).toList();

    lista.sort((a, b) => a.nombres.compareTo(b.nombres));

    final rows = <List<dynamic>>[
      ['uid', ..._csvHeaderColabs],
    ];

    for (final c in lista) {
      rows.add([
        c.uid,
        c.nombres,
        c.apellidoPaterno ?? '',
        c.apellidoMaterno ?? '',
        _fmtIso(c.fechaNacimiento),
        c.curp ?? '',
        c.rfc ?? '',
        c.telefonoMovil ?? '',
        c.emailPersonal ?? '',
        c.fotoRutaLocal ?? '',
        c.fotoRutaRemota ?? '',
        c.genero ?? '',
        c.notas ?? '',
        _fmtIso(c.createdAt),
        _fmtIso(c.updatedAt),
        c.deleted.toString(),
        c.isSynced.toString(),
      ]);
    }

    return toCsvStringWithBom(rows);
  }

  Future<String> exportarCsvAArchivo({String? nombreArchivo}) async {
    final csv = await exportarCsvColaboradores();

    final now = DateTime.now().toUtc();
    final ts = now.toIso8601String().replaceAll(':', '-');
    final fileName = (nombreArchivo?.trim().isNotEmpty == true)
        ? nombreArchivo!.trim()
        : 'colaboradores_$ts.csv';

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

  Future<(int insertados, int saltados)> importarCsvColaboradores({
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

    final header = rows.first.map((e) => (e ?? '').toString().trim()).toList();
    final validHeader =
        header.length == _csvHeaderColabs.length &&
        _csvHeaderColabs.asMap().entries.every((e) => e.value == header[e.key]);
    if (!validHeader) {
      throw const FormatException(
        'Encabezado CSV inválido. Esperado: '
        'nombres,apellidoPaterno,apellidoMaterno,fechaNacimiento,curp,rfc,'
        'telefonoMovil,emailPersonal,fotoRutaLocal,fotoRutaRemota,genero,notas,'
        'createdAt,updatedAt,deleted,isSynced',
      );
    }

    final dataRows = rows.skip(1);
    final nowUtc = DateTime.now().toUtc();

    final existentes = await _dao.obtenerTodosDrift();
    final byCurp = <String, bool>{};
    final byRfc = <String, bool>{};
    final byEmail = <String, bool>{};
    final byPhone = <String, bool>{};
    final byNameDob = <String, bool>{};

    String kCurp(String s) => s.trim().toLowerCase();
    String kRfc(String s) => s.trim().toLowerCase();
    String kEmail(String s) => s.trim().toLowerCase();
    String kPhone(String s) => _digits(s);
    String kNameDob(String n, String ap, String am, DateTime? f) {
      final name = _norm('$n $ap $am');
      final d = f == null
          ? ''
          : '${f.toUtc().year}-${f.toUtc().month.toString().padLeft(2, '0')}-${f.toUtc().day.toString().padLeft(2, '0')}';
      return '$name|$d';
    }

    for (final c in existentes) {
      if (c.deleted) continue;
      if ((c.curp ?? '').trim().isNotEmpty) byCurp[kCurp(c.curp!)] = true;
      if ((c.rfc ?? '').trim().isNotEmpty) byRfc[kRfc(c.rfc!)] = true;
      if ((c.emailPersonal ?? '').trim().isNotEmpty)
        byEmail[kEmail(c.emailPersonal!)] = true;
      if ((c.telefonoMovil ?? '').trim().isNotEmpty)
        byPhone[kPhone(c.telefonoMovil!)] = true;
      byNameDob[kNameDob(
            c.nombres,
            c.apellidoPaterno ?? '',
            c.apellidoMaterno ?? '',
            c.fechaNacimiento,
          )] =
          true;
    }

    final seenCurp = <String, bool>{};
    final seenRfc = <String, bool>{};
    final seenEmail = <String, bool>{};
    final seenPhone = <String, bool>{};
    final seenNameDob = <String, bool>{};

    int insertados = 0, saltados = 0;

    await _dao.db.transaction(() async {
      for (final r in dataRows) {
        if (r.isEmpty) continue;

        final row = List<String>.generate(
          _csvHeaderColabs.length,
          (i) => (i < r.length ? (r[i] ?? '').toString() : '').trim(),
        );

        final nombres = row[0];
        final apP = row[1];
        final apM = row[2];
        final fNacStr = row[3];
        final curp = row[4];
        final rfc = row[5];
        final tel = row[6];
        final email = row[7];
        final fotoLocal = row[8];
        final fotoRem = row[9];
        final genero = row[10];
        final notas = row[11];
        final createdStr = row[12];
        final updatedStr = row[13];
        final deletedStr = row[14];
        final syncedStr = row[15];

        final fNac = parseDateFlexible(fNacStr);
        final createdAt = parseDateFlexible(createdStr) ?? nowUtc;
        final updatedAt = parseDateFlexible(updatedStr) ?? nowUtc;
        final deleted = parseBoolFlexible(deletedStr, defaultValue: false);
        final isSynced = parseBoolFlexible(syncedStr, defaultValue: false);

        final curpK = kCurp(curp);
        final rfcK = kRfc(rfc);
        final emailK = kEmail(email);
        final phoneK = kPhone(tel);
        final nameDobK = kNameDob(nombres, apP, apM, fNac);

        final dupDb =
            (curpK.isNotEmpty && byCurp[curpK] == true) ||
            (rfcK.isNotEmpty && byRfc[rfcK] == true) ||
            (emailK.isNotEmpty && byEmail[emailK] == true) ||
            (phoneK.isNotEmpty && byPhone[phoneK] == true) ||
            (nameDobK.isNotEmpty && byNameDob[nameDobK] == true);

        final dupCsv =
            (curpK.isNotEmpty && seenCurp[curpK] == true) ||
            (rfcK.isNotEmpty && seenRfc[rfcK] == true) ||
            (emailK.isNotEmpty && seenEmail[emailK] == true) ||
            (phoneK.isNotEmpty && seenPhone[phoneK] == true) ||
            (nameDobK.isNotEmpty && seenNameDob[nameDobK] == true);

        if (dupDb || dupCsv) {
          saltados++;
          if (curpK.isNotEmpty) seenCurp[curpK] = true;
          if (rfcK.isNotEmpty) seenRfc[rfcK] = true;
          if (emailK.isNotEmpty) seenEmail[emailK] = true;
          if (phoneK.isNotEmpty) seenPhone[phoneK] = true;
          if (nameDobK.isNotEmpty) seenNameDob[nameDobK] = true;
          continue;
        }

        final uid = const Uuid().v4();
        final comp = ColaboradoresCompanion(
          uid: Value(uid),
          nombres: Value(nombres),
          apellidoPaterno: Value(_nvl(apP)),
          apellidoMaterno: Value(_nvl(apM)),
          fechaNacimiento: fNac == null
              ? const Value(null)
              : Value(fNac.toUtc()),
          curp: Value(_nvl(curp)),
          rfc: Value(_nvl(rfc)),
          telefonoMovil: Value(_nvl(tel)),
          emailPersonal: Value(_nvl(email)),
          fotoRutaLocal: Value(_nvl(fotoLocal)),
          fotoRutaRemota: Value(_nvl(fotoRem)),
          genero: Value(_nvl(genero)),
          notas: Value(_nvl(notas)),
          createdAt: Value(createdAt),
          updatedAt: Value(updatedAt),
          deleted: Value(deleted),
          isSynced: Value(isSynced),
        );

        await _dao.upsertColaboradorDrift(comp);
        insertados++;

        if (curpK.isNotEmpty) {
          byCurp[curpK] = true;
          seenCurp[curpK] = true;
        }
        if (rfcK.isNotEmpty) {
          byRfc[rfcK] = true;
          seenRfc[rfcK] = true;
        }
        if (emailK.isNotEmpty) {
          byEmail[emailK] = true;
          seenEmail[emailK] = true;
        }
        if (phoneK.isNotEmpty) {
          byPhone[phoneK] = true;
          seenPhone[phoneK] = true;
        }
        if (nameDobK.isNotEmpty) {
          byNameDob[nameDobK] = true;
          seenNameDob[nameDobK] = true;
        }
      }
    });

    state = await _dao.obtenerTodosDrift();
    return (insertados, saltados);
  }
}

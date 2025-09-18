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

  // ---------------------------------------------------------------------------
  // ✅ Cargar colaboradores (offline-first)
  // ---------------------------------------------------------------------------
  Future<void> cargarOfflineFirst() async {
    try {
      _hayInternet = _ref.read(connectivityProvider);

      // 1) Local primero
      final local = await _dao.obtenerTodosDrift();
      state = local;
      print(
        '[👥 MENSAJES COLABORADORES PROVIDER] Local cargado -> ${local.length} colaboradores',
      );

      // 2) Sin internet → detener
      if (!_hayInternet) {
        print(
          '[👥 MENSAJES COLABORADORES PROVIDER] Sin internet → usando solo local',
        );
        return;
      }

      // 3) (Opcional) timestamps para logs/telemetría
      final localTimestamp = await _dao.obtenerUltimaActualizacionDrift();
      final remotoTimestamp = await _servicio.comprobarActualizacionesOnline();
      print(
        '[👥 MENSAJES COLABORADORES PROVIDER] Remoto:$remotoTimestamp | Local:$localTimestamp',
      );

      // 4) Pull (heads → diff → bulk)
      await _sync.pullColaboradoresOnline();

      // 5) Push de cambios offline
      await _sync.pushColaboradoresOffline();

      // 6) Recargar desde Drift
      final actualizados = await _dao.obtenerTodosDrift();
      state = actualizados;

      // 7) Sincroniza fotos locales con lo remoto (descarga nuevas y limpia obsoletas)
      final cambios = await syncFotosLocales();
      if (cambios > 0) {
        state = await _dao.obtenerTodosDrift();
        print(
          '[👥 MENSAJES COLABORADORES PROVIDER] Fotos sincronizadas → $cambios cambios aplicados',
        );
      }
    } catch (e) {
      print(
        '[👥 MENSAJES COLABORADORES PROVIDER] ❌ Error al cargar colaboradores: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // ➕ Crear colaborador (ONLINE upsert → local isSynced=true)
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

      // 2) Upsert LOCAL (remoto ⇒ isSynced=true)
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
        genero: genero.isEmpty ? const Value.absent() : Value(genero),
        notas: Value(notas),
        fotoRutaRemota: Value(fotoRutaRemota),
        fotoRutaLocal: Value(fotoRutaLocal),
        createdAt: Value(now),
        updatedAt: Value(now),
        deleted: const Value(false),
        isSynced: const Value(false),
      );
      await _dao.upsertColaboradorDrift(comp);

      // 3) Refrescar estado y devolver
      final actualizados = await _dao.obtenerTodosDrift();
      state = actualizados;
      return actualizados.firstWhere(
        (c) => c.uid == uid,
        orElse: () => actualizados.last,
      );
    } catch (e) {
      print(
        '[👥 MENSAJES COLABORADORES PROVIDER] ❌ Error al crear colaborador: $e',
      );
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // ✏️ Editar colaborador (LOCAL → isSynced=false; el push lo sube)
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
        apellidoPaterno: apellidoPaterno == null
            ? const Value.absent()
            : Value(apellidoPaterno),
        apellidoMaterno: apellidoMaterno == null
            ? const Value.absent()
            : Value(apellidoMaterno),
        fechaNacimiento: fechaNacimiento == null
            ? const Value.absent()
            : Value(fechaNacimiento.toUtc()),
        curp: curp == null ? const Value.absent() : Value(curp),
        rfc: rfc == null ? const Value.absent() : Value(rfc),
        telefonoMovil: telefonoMovil == null
            ? const Value.absent()
            : Value(telefonoMovil),
        emailPersonal: emailPersonal == null
            ? const Value.absent()
            : Value(emailPersonal),
        genero: genero == null ? const Value.absent() : Value(genero),
        notas: notas == null ? const Value.absent() : Value(notas),
        fotoRutaRemota: fotoRutaRemota == null
            ? const Value.absent()
            : Value(fotoRutaRemota),
        fotoRutaLocal: fotoRutaLocal == null
            ? const Value.absent()
            : Value(fotoRutaLocal),
        updatedAt: Value(DateTime.now().toUtc()),
        deleted: const Value.absent(),
        isSynced: const Value(false),
      );

      await _dao.upsertColaboradorDrift(comp);

      state = await _dao.obtenerTodosDrift();
      print(
        '[👥 MENSAJES COLABORADORES PROVIDER] Colaborador $uid editado localmente',
      );
    } catch (e) {
      print(
        '[👥 MENSAJES COLABORADORES PROVIDER] ❌ Error al editar colaborador: $e',
      );
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📷 Fotos: descargar / eliminar local / subir desde archivo
  // ---------------------------------------------------------------------------
  Future<ColaboradorDb?> descargarFoto(ColaboradorDb c) async {
    // Reuso: si otro colaborador ya tiene misma rutaRemota descargada
    final reused = _localFileForRuta(c.fotoRutaRemota);
    if (reused != null) {
      await _dao.actualizarParcialPorUid(
        c.uid,
        ColaboradoresCompanion(fotoRutaLocal: Value(reused.path)),
      );
      state = await _dao.obtenerTodosDrift();
      return state.firstWhere((x) => x.uid == c.uid, orElse: () => c);
    }

    // Descarga real
    final file = await _servicio.descargarImagenOnline(c.fotoRutaRemota);
    if (file == null) {
      print('[👥 MENSAJES COLABORADORES PROVIDER] ❌ No se pudo descargar foto');
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
    print(
      '[👥 MENSAJES COLABORADORES PROVIDER] Borrando foto local: ${c.fotoRutaLocal}',
    );
    if (c.fotoRutaLocal.isNotEmpty) {
      final file = File(c.fotoRutaLocal);
      try {
        if (await file.exists()) await file.delete();
      } catch (e) {
        print(
          '[👥 MENSAJES COLABORADORES PROVIDER] ⚠️ Error borrando foto local: $e',
        );
      }
    }

    await _dao.actualizarParcialPorUid(
      c.uid,
      const ColaboradoresCompanion(fotoRutaLocal: Value('')),
    );

    state = await _dao.obtenerTodosDrift();
  }

  /// Copia la foto al almacenamiento de la app, setea rutaRemota y marca para sync.
  Future<void> subirNuevaFoto({
    required ColaboradorDb colaborador,
    required File archivo,
  }) async {
    try {
      // 0) Hash + ext
      final hash = await _servicio.calcularSha256(archivo);
      final ext = p.extension(archivo.path).toLowerCase();
      final cleanExt = (ext.isEmpty ? '.jpg' : ext); // default si hace falta

      // 1) Ruta remota con hash (ej: colaboradores/<uid>/<sha>.png)
      final remotePath = 'colaboradores/${colaborador.uid}/$hash$cleanExt';

      // 2) Copia local canónica (nombre deriva de remotePath => cambia con el hash)
      final dir = await getApplicationSupportDirectory();
      final fotosDir = Directory(p.join(dir.path, 'colaboradores_img'));
      if (!await fotosDir.exists()) await fotosDir.create(recursive: true);

      final safeName = remotePath.replaceAll('/', '_');
      final destino = File(p.join(fotosDir.path, safeName));
      await archivo.copy(destino.path);

      // 3) Guardar metadata local (nueva ruta remota + local) y marcar para sync
      final oldRemote =
          colaborador.fotoRutaRemota; // para limpieza remota luego
      final oldLocal = colaborador.fotoRutaLocal;

      await _dao.actualizarParcialPorUid(
        colaborador.uid,
        ColaboradoresCompanion(
          fotoRutaRemota: Value(remotePath),
          fotoRutaLocal: Value(destino.path),
          updatedAt: Value(DateTime.now().toUtc()),
          isSynced: const Value(false),
        ),
      );

      //Eliminarmos el archivo local viejo
      if (oldLocal.isNotEmpty &&
          oldLocal != destino.path &&
          await File(oldLocal).exists()) {
        try {
          await File(oldLocal).delete();
          print(
            '[👥 MENSAJES COLABORADORES PROVIDER] 🧹 Local anterior eliminado: $oldLocal',
          );
        } catch (e) {
          print(
            '[👥 MENSAJES COLABORADORES PROVIDER] ⚠️ No se pudo borrar local anterior: $e',
          );
        }
      }
      // 4) Refrescar estado y sincronizar si hay red
      state = await _dao.obtenerTodosDrift();

      if (_hayInternet) {
        // Sube nueva imagen + metadata
        await _sync.pushColaboradoresOffline();
        // Limpia la imagen remota anterior si existe y es distinta
        if (oldRemote.isNotEmpty && oldRemote != remotePath) {
          await _servicio.deleteImagenOnlineSafe(oldRemote);
        }
        // Trae metadata fresca si otro cliente tocó algo más
        await _sync.pullColaboradoresOnline();
        state = await _dao.obtenerTodosDrift();
      }

      print('[Colaboradores] Foto preparada y lista para sync: $remotePath');
    } catch (e) {
      print('[Colaboradores] ❌ Error preparando foto: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📥 Descarga diferida en lote (faltantes)
  // ---------------------------------------------------------------------------
  Future<int> syncFotosLocales({
    int max = 500,
    bool borrarObsoletas = true,
  }) async {
    if (!_hayInternet) return 0;

    // Construye la lista de “candidatos” a revisar (tienen una ruta remota válida)
    final candidatos =
        state.where((c) {
          if (c.deleted) return false;
          return c.fotoRutaRemota.trim().isNotEmpty;
        }).toList()..sort(
          (a, b) => b.updatedAt.compareTo(a.updatedAt),
        ); // recientes primero

    if (candidatos.isEmpty) return 0;

    int cambios = 0;
    int procesados = 0;

    String _cleanRemote(String r) => r.startsWith('/') ? r.substring(1) : r;
    String _safeName(String r) => _cleanRemote(r).replaceAll('/', '_');

    for (final c in candidatos) {
      if (procesados >= max) break;
      final remote = c.fotoRutaRemota.trim();
      final expectedSafeName = _safeName(remote);

      // Si ya hay ruta local, verifica si apunta al archivo esperado (mismo “safeName”)
      final tieneLocal =
          c.fotoRutaLocal.isNotEmpty && File(c.fotoRutaLocal).existsSync();
      final apuntaALoEsperado =
          tieneLocal && p.basename(c.fotoRutaLocal) == expectedSafeName;

      // Ya está correcto → nada que hacer
      if (apuntaALoEsperado) {
        procesados++;
        continue;
      }

      // Si hay local pero NO corresponde al archivo esperado (hash cambió o moviste path)
      if (tieneLocal &&
          p.basename(c.fotoRutaLocal) != expectedSafeName &&
          borrarObsoletas) {
        try {
          await File(c.fotoRutaLocal).delete();
        } catch (_) {
          // no nos detenemos por errores de borrado
        }
      }

      // ¿Ya existe en el destino canónico por casualidad?
      // Nota: descargarImagenOnline guarda como "<safeName>" en appSupport/colaboradores_img
      // así que podemos intentar usarlo directamente.
      File? targetFile;
      try {
        // Intenta componer el path canónico y ver si ya existe
        final baseDir = await getApplicationSupportDirectory();
        final targetDir = Directory(p.join(baseDir.path, 'colaboradores_img'));
        final canonical = File(p.join(targetDir.path, expectedSafeName));
        if (await canonical.exists()) {
          targetFile = canonical;
        }
      } catch (_) {
        // Ignora y fuerza descarga
      }

      // Si no existe localmente el esperado, descárgalo del Storage
      targetFile ??= await _servicio.descargarImagenOnline(remote);
      if (targetFile == null) {
        // No se pudo descargar; pasa al siguiente sin romper
        procesados++;
        continue;
      }

      // Actualiza la ruta local en DB para que apunte al canónico recién creado/encontrado
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
          '${c.nombres} ${c.apellidoPaterno} ${c.apellidoMaterno}'
              .trim()
              .toLowerCase();
      return nombreCompleto.contains(q) ||
          c.emailPersonal.toLowerCase().contains(q) ||
          c.telefonoMovil.toLowerCase().contains(q);
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
  File? _localFileForRuta(String ruta) {
    if (ruta.trim().isEmpty) return null;
    try {
      final other = state.firstWhere(
        (c) =>
            c.fotoRutaRemota == ruta &&
            c.fotoRutaLocal.isNotEmpty &&
            File(c.fotoRutaLocal).existsSync(),
      );
      return File(other.fotoRutaLocal);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // 🔎 Duplicados
  //   - Reglas (en orden de mayor a menor fuerza):
  //     1) CURP (si no viene vacío) coincide exactamente (case-insensitive)
  //     2) RFC  (si no viene vacío) coincide exactamente (case-insensitive)
  //     3) Email o Teléfono móvil coinciden (normalizados)
  //     4) Nombre completo + Fecha de nacimiento (si ambos presentes)
  // ---------------------------------------------------------------------------
  // 🔎 Duplicados (DB) — ahora con opción de nombre+fecha y excluir al propio uid.
  bool existeDuplicado({
    String curp = '',
    String rfc = '',
    String telefonoMovil = '',
    String emailPersonal = '',
    String nombres = '',
    String apellidoPaterno = '',
    String apellidoMaterno = '',
    DateTime? fechaNacimiento,
    String? excluirUid, // 👈 nuevo
  }) {
    final curpIn = curp.trim().toLowerCase();
    final rfcIn = rfc.trim().toLowerCase();
    final emailIn = emailPersonal.trim().toLowerCase();
    final phoneIn = _digits(telefonoMovil);
    final fullNameIn = _norm('$nombres $apellidoPaterno $apellidoMaterno');

    for (final c in state) {
      if (c.deleted) continue;

      // 👇 evita compararte contra ti mismo cuando editas
      if (excluirUid != null && excluirUid.isNotEmpty && c.uid == excluirUid) {
        continue;
      }

      // 1) CURP
      final curpDb = (c.curp ?? '').trim().toLowerCase();
      if (curpIn.isNotEmpty && curpDb.isNotEmpty && curpDb == curpIn)
        return true;

      // 2) RFC
      final rfcDb = (c.rfc ?? '').trim().toLowerCase();
      if (rfcIn.isNotEmpty && rfcDb.isNotEmpty && rfcDb == rfcIn) return true;

      // 3) Email
      final emailDb = c.emailPersonal.trim().toLowerCase();
      if (emailIn.isNotEmpty && emailDb.isNotEmpty && emailDb == emailIn) {
        return true;
      }

      // 4) Teléfono
      final telDb = _digits(c.telefonoMovil);
      if (phoneIn.isNotEmpty && telDb.isNotEmpty && telDb == phoneIn) {
        return true;
      }

      // 5) Nombre completo + fecha (si ambos presentes)
      if (fullNameIn.isNotEmpty && fechaNacimiento != null) {
        final fullNameDb = _norm(
          '${c.nombres} ${c.apellidoPaterno} ${c.apellidoMaterno}',
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
    // quita acentos más comunes
    return lower
        .replaceAll(RegExp(r'[áàä]'), 'a')
        .replaceAll(RegExp(r'[éèë]'), 'e')
        .replaceAll(RegExp(r'[íìï]'), 'i')
        .replaceAll(RegExp(r'[óòö]'), 'o')
        .replaceAll(RegExp(r'[úùü]'), 'u')
        .replaceAll(RegExp(r'ñ'), 'n')
        .replaceAll(RegExp(r'\s+'), ' ') // colapsa espacios
        .trim();
  }

  String _digits(String s) => s.replaceAll(RegExp(r'[^0-9]'), '');

  // ====================== CSV: helpers locales ======================

  // Encabezado estable (mismo orden en import/export).
  static const List<String> _csvHeaderColabs = [
    'nombres',
    'apellidoPaterno',
    'apellidoMaterno',
    'fechaNacimiento', // ISO o dd/MM/yyyy, se guarda en UTC
    'curp',
    'rfc',
    'telefonoMovil',
    'emailPersonal',
    'fotoRutaLocal',
    'fotoRutaRemota',
    'genero',
    'notas',
    'createdAt', // opcional; si vacío: nowUtc
    'updatedAt', // opcional; si vacío: nowUtc
    'deleted', // true/false/1/0/yes/no/si
    'isSynced', // true/false/1/0/yes/no/si
  ];

  // Formatea DateTime a ISO-UTC o cadena vacía
  String _fmtIso(DateTime? d) => d == null ? '' : d.toUtc().toIso8601String();

  // ====================== CSV: EXPORTAR ======================

  /// Exporta todos los colaboradores (o solo NO eliminados) a CSV (String).
  Future<String> exportarCsvColaboradores({
    bool incluirEliminados = false,
  }) async {
    final lista = incluirEliminados
        ? await _dao.obtenerTodosDrift()
        : (await _dao.obtenerTodosDrift()).where((c) => !c.deleted).toList();

    // Orden consistente
    lista.sort((a, b) => a.nombres.compareTo(b.nombres));

    // 1) Header EXACTO (sin uid)
    final rows = <List<dynamic>>[
      ['uid', ..._csvHeaderColabs],
    ];

    // 2) Filas (sin uid)
    for (final c in lista) {
      rows.add([
        c.uid,
        c.nombres,
        c.apellidoPaterno,
        c.apellidoMaterno,
        _fmtIso(c.fechaNacimiento),
        c.curp ?? '',
        c.rfc ?? '',
        c.telefonoMovil,
        c.emailPersonal,
        c.fotoRutaLocal,
        c.fotoRutaRemota,
        c.genero ?? '',
        c.notas,
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

    // Preferir Descargas en desktop si está disponible; soporte app en mobile
    Directory dir;
    try {
      // Sólo desktop expone Downloads de forma estándar
      final downloads = await getDownloadsDirectory();
      dir = downloads ?? await getApplicationSupportDirectory();
    } catch (_) {
      dir = await getApplicationSupportDirectory();
    }

    final file = File(p.join(dir.path, fileName));
    await file.create(recursive: true);
    await file.writeAsString(csv, flush: true);

    return file.path; // 👈 Devuelve la ruta exacta donde quedó el export
  }

  /// Importa colaboradores desde CSV. SOLO INSERTA. Nunca edita existentes.
  /// Reglas duplicado (en este orden): CURP, RFC, Email, Tel, Nombre+Fecha.
  /// Además evita repetir filas duplicadas dentro del mismo CSV.
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

    // Header EXACTO (sin uid)
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

    // === Índices de existentes (DB) para lookup rápido ===
    final existentes = await _dao.obtenerTodosDrift();
    final byCurp = <String, bool>{};
    final byRfc = <String, bool>{};
    final byEmail = <String, bool>{};
    final byPhone = <String, bool>{};
    final byNameDob = <String, bool>{}; // key: "<fullName>|<yyyy-mm-dd>"

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
      if (c.emailPersonal.trim().isNotEmpty)
        byEmail[kEmail(c.emailPersonal)] = true;
      if (c.telefonoMovil.trim().isNotEmpty)
        byPhone[kPhone(c.telefonoMovil)] = true;
      byNameDob[kNameDob(
            c.nombres,
            c.apellidoPaterno,
            c.apellidoMaterno,
            c.fechaNacimiento,
          )] =
          true;
    }

    // === Seen maps para evitar duplicado DENTRO del CSV ===
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

        final fNac = parseDateFlexible(fNacStr); // UTC o null
        final createdAt = parseDateFlexible(createdStr) ?? nowUtc;
        final updatedAt = parseDateFlexible(updatedStr) ?? nowUtc;
        final deleted = parseBoolFlexible(deletedStr, defaultValue: false);
        final isSynced = parseBoolFlexible(syncedStr, defaultValue: false);

        // --- Normaliza llaves
        final curpK = kCurp(curp);
        final rfcK = kRfc(rfc);
        final emailK = kEmail(email);
        final phoneK = kPhone(tel);
        final nameDobK = kNameDob(nombres, apP, apM, fNac);

        // --- ¿Duplicado en DB?
        final dupDb =
            (curpK.isNotEmpty && byCurp[curpK] == true) ||
            (rfcK.isNotEmpty && byRfc[rfcK] == true) ||
            (emailK.isNotEmpty && byEmail[emailK] == true) ||
            (phoneK.isNotEmpty && byPhone[phoneK] == true) ||
            (nameDobK.isNotEmpty && byNameDob[nameDobK] == true);

        // --- ¿Duplicado en el propio CSV (ya procesado)?
        final dupCsv =
            (curpK.isNotEmpty && seenCurp[curpK] == true) ||
            (rfcK.isNotEmpty && seenRfc[rfcK] == true) ||
            (emailK.isNotEmpty && seenEmail[emailK] == true) ||
            (phoneK.isNotEmpty && seenPhone[phoneK] == true) ||
            (nameDobK.isNotEmpty && seenNameDob[nameDobK] == true);

        if (dupDb || dupCsv) {
          saltados++;
          // Marca como vistos (para cascada de duplicados dentro del CSV)
          if (curpK.isNotEmpty) seenCurp[curpK] = true;
          if (rfcK.isNotEmpty) seenRfc[rfcK] = true;
          if (emailK.isNotEmpty) seenEmail[emailK] = true;
          if (phoneK.isNotEmpty) seenPhone[phoneK] = true;
          if (nameDobK.isNotEmpty) seenNameDob[nameDobK] = true;
          continue; // 👈 NO insertes, NO actualices
        }

        // --- Insertar SIEMPRE (uid nuevo)
        final uid = const Uuid().v4();
        final comp = ColaboradoresCompanion(
          uid: Value(uid),
          nombres: Value(nombres),
          apellidoPaterno: Value(apP),
          apellidoMaterno: Value(apM),
          fechaNacimiento: fNac == null
              ? const Value.absent()
              : Value(fNac.toUtc()),
          curp: curp.isEmpty ? const Value.absent() : Value(curp),
          rfc: rfc.isEmpty ? const Value.absent() : Value(rfc),
          telefonoMovil: Value(tel),
          emailPersonal: Value(email),
          fotoRutaLocal: Value(fotoLocal),
          fotoRutaRemota: Value(fotoRem),
          genero: genero.isEmpty ? const Value.absent() : Value(genero),
          notas: Value(notas),
          createdAt: Value(createdAt),
          updatedAt: Value(updatedAt),
          deleted: Value(deleted),
          isSynced: Value(isSynced),
        );

        await _dao.upsertColaboradorDrift(comp); // uid nuevo → inserta
        insertados++;

        // Actualiza índices para siguientes filas (DB y CSV)
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

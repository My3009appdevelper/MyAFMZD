// ignore_for_file: avoid_print

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/database_provider.dart';
import 'package:myafmzd/database/modelos/modelo_imagenes_dao.dart';
import 'package:myafmzd/database/modelos/modelo_imagenes_service.dart';
import 'package:myafmzd/database/modelos/modelo_imagenes_sync.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

// -----------------------------------------------------------------------------
// Provider global
// -----------------------------------------------------------------------------
final modeloImagenesProvider =
    StateNotifierProvider<ModeloImagenesNotifier, List<ModeloImagenDb>>((ref) {
      final db = ref.watch(appDatabaseProvider);
      return ModeloImagenesNotifier(ref, db);
    });

class ModeloImagenesNotifier extends StateNotifier<List<ModeloImagenDb>> {
  ModeloImagenesNotifier(this._ref, AppDatabase db)
    : _dao = ModeloImagenesDao(db),
      _service = ModeloImagenesService(db),
      _sync = ModeloImagenesSync(db),
      super([]);

  final Ref _ref;
  final ModeloImagenesDao _dao;
  final ModeloImagenesService _service;
  final ModeloImagenesSync _sync;

  bool _hayInternet = true;
  bool get hayInternet => _hayInternet;

  // -----------------------------------------------------------------------------
  // CARGA OFFLINE-FIRST (local → pull → push → refresh)
  // -----------------------------------------------------------------------------
  Future<void> cargarOfflineFirst() async {
    try {
      _hayInternet = _ref.read(connectivityProvider);

      // 1) Local primero
      final local = await _dao.obtenerTodosDrift();
      state = local;
      print(
        '[🚗👀 MENSAJES MODELO_IMAGENES PROVIDER] Local cargado → ${local.length} imágenes',
      );

      // 2) Sin internet → listo
      if (!_hayInternet) {
        print(
          '[🚗👀 MENSAJES MODELO_IMAGENES PROVIDER] Sin internet: solo local',
        );
        return;
      }

      // 3) (Opcional) timestamps para logs
      final localTimestamp = await _dao.obtenerUltimaActualizacionDrift();
      final remotoTimestamp = await _service.comprobarActualizacionesOnline();
      print(
        '[🚗👀 MENSAJES MODELO_IMAGENES PROVIDER] Remoto:$remotoTimestamp | Local:$localTimestamp',
      );

      // 4) Pull (heads → diff → bulk)
      await _sync.pullModeloImagenesOnline();

      // 5) Push de cambios offline

      await _sync.pushModeloImagenesOffline();

      // 6) Recargar desde Drift
      final actualizados = await _dao.obtenerTodosDrift();
      state = actualizados;

      // 7) (Nuevo) Prefetch de imágenes para tenerlas SIEMPRE locales
      final descargadas = await descargarFaltantes(
        incluirEliminadas: true,
      ); // opcional: pasa modeloUid
      if (descargadas > 0) {
        // Opcional: refrescar estado por si cambió rutaLocal/sha en varias
        state = await _dao.obtenerTodosDrift();
        print(
          '[🚗👀 MENSAJES MODELO_IMAGENES PROVIDER] Prefetch completado → $descargadas descargadas',
        );
      }
    } catch (e) {
      print(
        '[🚗👀 MENSAJES MODELO_IMAGENES PROVIDER] ❌ Error cargarOfflineFirst: $e',
      );
    }
  }

  Future<int> descargarFaltantes({
    String? modeloUid,
    int max = 200,
    bool incluirEliminadas = true,
    bool debug = true, // para controlar verbosity de logs
  }) async {
    // ───────────────────────────── helpers ─────────────────────────────
    void log(String m) {
      if (debug) print('[🚗👀 MENSAJES MODELO_IMAGENES PROVIDER] $m');
    }

    String norm(String p) {
      final s = p.trim();
      final noLeading = s.startsWith('/') ? s.substring(1) : s;
      return noLeading.replaceAll(RegExp(r'/+'), '/');
    }

    String basename(String ruta) {
      final rn = norm(ruta);
      final idx = rn.lastIndexOf('/');
      return idx >= 0 ? rn.substring(idx + 1) : rn;
    }

    String extFromRuta(String ruta) {
      final base = basename(ruta);
      final i = base.lastIndexOf('.');
      return (i >= 0 && i < base.length - 1)
          ? base.substring(i + 1).toLowerCase()
          : 'jpg';
    }

    String? yearFromRuta(String ruta) {
      final rn = norm(ruta);
      final first = rn.split('/').first;
      final m = RegExp(r'^\d{4}$').firstMatch(first);
      return m != null ? first : null;
    }

    // Si sha256 viene vacío, intenta extraerlo del nombre del archivo remoto (sin extensión)
    String? deriveShaFromRutaRemota(String ruta) {
      final base = basename(ruta);
      final nameNoExt = base.replaceFirst(RegExp(r'\.[^.]+$'), '');
      return RegExp(r'^[0-9a-fA-F]{64}$').hasMatch(nameNoExt)
          ? nameNoExt.toLowerCase()
          : null;
    }

    // Nombre canónico por SHA: AAAA_<sha>.ext  (sin el id de modelo)
    Future<File> canonicalFileFor(
      String sha,
      String ext, {
      String? year,
    }) async {
      final dir = await getApplicationSupportDirectory();
      final imgsDir = Directory(p.join(dir.path, 'modelos_img'));
      if (!await imgsDir.exists()) await imgsDir.create(recursive: true);
      final y = (year != null && RegExp(r'^\d{4}$').hasMatch(year))
          ? year
          : '0000';
      return File(p.join(imgsDir.path, '${y}_$sha.$ext'));
    }

    // Ruta local existente para un SHA usando el estado (rápido)
    File? localFromStateBySha(String sha) {
      try {
        final row = state.firstWhere(
          (i) =>
              i.sha256.toLowerCase() == sha.toLowerCase() &&
              i.rutaLocal.isNotEmpty &&
              File(i.rutaLocal).existsSync(),
        );
        return File(row.rutaLocal);
      } catch (_) {
        return null;
      }
    }

    // Ruta local existente para un SHA escaneando la carpeta (por si hay archivos previos)
    Future<File?> scanDiskBySha(String sha) async {
      try {
        final dir = await getApplicationSupportDirectory();
        final imgsDir = Directory(p.join(dir.path, 'modelos_img'));
        if (!await imgsDir.exists()) return null;
        final rex = RegExp(sha, caseSensitive: false);
        await for (final fse in imgsDir.list()) {
          if (fse is File && rex.hasMatch(p.basename(fse.path))) {
            if (await fse.exists()) return fse;
          }
        }
        return null;
      } catch (_) {
        return null;
      }
    }

    // Mueve/renombra de forma segura (si ya está con ese nombre, no hace nada)
    Future<File> ensureCanonicalName(
      File file,
      String sha,
      String ext, {
      String? year,
    }) async {
      final dst = await canonicalFileFor(sha, ext, year: year);
      if (p.equals(file.path, dst.path)) return file;
      try {
        if (await dst.exists()) {
          try {
            if (await file.exists()) await file.delete();
          } catch (_) {}
          return dst;
        }
        final renamed = await file.rename(dst.path);
        return renamed;
      } catch (_) {
        try {
          await file.copy(dst.path);
          await file.delete();
          return dst;
        } catch (_) {
          return file;
        }
      }
    }
    // ───────────────────────── fin helpers ────────────────────────────

    log(
      '⇢ descargarFaltantes(modeloUid=$modeloUid, max=$max, incluirEliminadas=$incluirEliminadas)',
    );
    log('Estado actual: ${state.length} filas en memoria');

    // 1) Candidatas que necesitan archivo local
    final candidatas = state.where((i) {
      if (!incluirEliminadas && i.deleted) return false;
      if (modeloUid != null && i.modeloUid != modeloUid) return false;
      if (i.rutaRemota.trim().isEmpty) return false;
      if (i.rutaLocal.isNotEmpty && File(i.rutaLocal).existsSync()) {
        return false;
      }
      return true;
    }).toList();

    log('Candidatas que requieren archivo local: ${candidatas.length}');
    if (candidatas.isEmpty) return 0;

    // 2) Calcula el SHA efectivo por fila (sha256 o basename)
    final effective = <String, List<ModeloImagenDb>>{};
    final sinShaList = <ModeloImagenDb>[];
    for (final row in candidatas) {
      final ownSha = row.sha256.trim().toLowerCase();
      final derived = deriveShaFromRutaRemota(row.rutaRemota) ?? '';
      final effSha = (ownSha.isNotEmpty ? ownSha : derived);
      if (effSha.isEmpty) {
        sinShaList.add(row);
        final key = 'ruta:${norm(row.rutaRemota)}';
        (effective[key] ??= []).add(row);
      } else {
        (effective['sha:$effSha'] ??= []).add(row);
      }
    }

    // 3) Ordena grupos: covers primero, luego más recientes
    final entries = effective.entries.toList();
    bool hasCover(List<ModeloImagenDb> g) => g.any((e) => e.isCover);
    DateTime maxU(List<ModeloImagenDb> g) =>
        g.map((e) => e.updatedAt).reduce((a, b) => a.isAfter(b) ? a : b);

    entries.sort((a, b) {
      final ac = hasCover(a.value), bc = hasCover(b.value);
      if (ac != bc) return ac ? -1 : 1;
      return maxU(b.value).compareTo(maxU(a.value));
    });

    final totalGrupos = entries.length;
    final gruposSha = entries.where((e) => e.key.startsWith('sha:')).length;
    final gruposRuta = totalGrupos - gruposSha;
    final unicosSha = entries
        .where((e) => e.key.startsWith('sha:'))
        .map((e) => e.key.substring(4))
        .toSet()
        .length;

    log(
      'Grupos formados: total=$totalGrupos | por_SHA=$gruposSha (únicos=$unicosSha) | por_RUTA=$gruposRuta',
    );
    if (sinShaList.isNotEmpty) {
      log('⚠️ Filas sin SHA deducible (grupos por ruta): ${sinShaList.length}');
    }

    // Para diagnóstico
    var descargasReales = 0;
    final descargadas = <String, String>{}; // sha -> path local
    final reusadasEstado = <String, String>{}; // sha -> path local
    final reusadasDisco = <String, String>{}; // sha -> path local
    final ejemploRutaPorKey =
        <String, String>{}; // key -> una rutaRemota ejemplo
    final tamGrupo = <String, int>{}; // key -> tamaño grupo
    final coverGrupo = <String, bool>{}; // key -> tiene cover

    // 4) Recorre cada grupo (SHA o ruta) y baja una sola vez por grupo
    var idxGrupo = 0;
    for (final entry in entries) {
      if (descargasReales >= max) break;

      idxGrupo++;
      final key = entry.key;
      final grupo = entry.value;
      if (grupo.isEmpty) continue;

      final isShaGroup = key.startsWith('sha:');
      final sha0 = isShaGroup
          ? key.substring(4)
          : (deriveShaFromRutaRemota(grupo.first.rutaRemota) ?? '')
                .toLowerCase();
      final year = yearFromRuta(grupo.first.rutaRemota);
      final ext = extFromRuta(grupo.first.rutaRemota);

      ejemploRutaPorKey[key] = norm(grupo.first.rutaRemota);
      tamGrupo[key] = grupo.length;
      coverGrupo[key] = hasCover(grupo);

      log(
        '• Grupo $idxGrupo/$totalGrupos  key=$key  size=${grupo.length}  cover=${coverGrupo[key]}  ext=$ext  year=${year ?? "0000"}',
      );

      // 4.a INTENTO DE REUSO LOCAL
      File? local;
      if (isShaGroup && sha0.isNotEmpty) {
        local = localFromStateBySha(sha0);
        if (local != null) {
          reusadasEstado[sha0] = local.path;
          log('  ↳ Reuso por estado (SHA): $sha0 → ${p.basename(local.path)}');
        } else {
          local = await scanDiskBySha(sha0);
          if (local != null) {
            reusadasDisco[sha0] = local.path;
            log('  ↳ Reuso por disco (SHA): $sha0 → ${p.basename(local.path)}');
          }
        }
      } else {
        // Fallback raro: sin SHA -> reuso por ruta normalizada
        final rn = norm(grupo.first.rutaRemota);
        try {
          final other = state.firstWhere(
            (i) =>
                norm(i.rutaRemota) == rn &&
                i.rutaLocal.isNotEmpty &&
                File(i.rutaLocal).existsSync(),
          );
          local = File(other.rutaLocal);
          log('  ↳ Reuso por ruta: ${p.basename(local.path)}');
        } catch (_) {}
      }

      String effectiveSha = sha0;

      // 4.b DESCARGA ÚNICA (si no hubo reuso)
      if (local == null) {
        final remotePath = norm(grupo.first.rutaRemota);
        log('  ↓ Descargando: $remotePath');
        final tmp = await _service.descargarImagenOnline(remotePath);
        if (tmp == null) {
          log('  ⚠️ No se pudo descargar $remotePath (skip)');
          continue;
        }

        if (effectiveSha.isEmpty) {
          effectiveSha = (await _service.calcularSha256(tmp)).toLowerCase();
          log('  ↳ SHA calculado: $effectiveSha');
        }

        local = await ensureCanonicalName(tmp, effectiveSha, ext, year: year);
        descargasReales++;
        descargadas[effectiveSha] = local.path;
        log('  ✅ Descargada y normalizada → ${p.basename(local.path)}');
      } else {
        // Asegura nombre canónico si ya teníamos el archivo en un nombre viejo
        final shaForName = (isShaGroup && sha0.isNotEmpty)
            ? sha0
            : (effectiveSha.isNotEmpty ? effectiveSha : '');
        if (shaForName.isNotEmpty) {
          final before = local.path;
          local = await ensureCanonicalName(local, shaForName, ext, year: year);
          if (!p.equals(before, local.path)) {
            log('  ↳ Renombrada a canónico: ${p.basename(local.path)}');
          }
        }
      }

      // 4.c PROPAGA rutaLocal y SHA a TODO el grupo (sin tocar updatedAt/isSynced)
      final localPath = local.path;
      for (final img in grupo) {
        final needsSha = (img.sha256.trim().isEmpty && effectiveSha.isNotEmpty);
        await _dao.actualizarParcialPorUid(
          img.uid,
          ModeloImagenesCompanion(
            rutaLocal: Value(localPath),
            sha256: needsSha ? Value(effectiveSha) : const Value.absent(),
          ),
        );
      }
    }

    // 5) Refresca el estado una sola vez
    if (descargasReales > 0) {
      state = await _dao.obtenerTodosDrift();
    }

    // 6) RESUMEN
    log('—'.padRight(60, '—'));
    log('RESUMEN');
    log('  candidatos=${candidatas.length}');
    log(
      '  grupos_total=$totalGrupos  | por_SHA=$gruposSha (únicos=$unicosSha) | por_RUTA=$gruposRuta',
    );
    log(
      '  descargas_reales=$descargasReales  | reuso_estado=${reusadasEstado.length} | reuso_disco=${reusadasDisco.length}',
    );
    if (descargadas.isNotEmpty) {
      log('  Descargadas (${descargadas.length}):');
      descargadas.forEach((sha, path) {
        final key = 'sha:$sha';
        final eg = ejemploRutaPorKey[key] ?? '';
        log('    • $sha  ← $eg  → ${p.basename(path)}');
      });
    }
    if (gruposRuta > 0) {
      log('  Grupos por RUTA (sin SHA deducible): $gruposRuta');
    }

    return descargasReales;
  }

  // -----------------------------------------------------------------------------
  // CONSULTAS
  // -----------------------------------------------------------------------------
  List<ModeloImagenDb> imagenesDeModelo(
    String modeloUid, {
    bool incluirEliminadas = false,
    bool soloDescargadas = false,
  }) {
    return state.where((i) {
        if (i.modeloUid != modeloUid) return false;
        if (!incluirEliminadas && i.deleted) return false;
        if (soloDescargadas &&
            (i.rutaLocal.isEmpty || !File(i.rutaLocal).existsSync())) {
          return false;
        }
        return true;
      }).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt)); // recientes primero
  }

  ModeloImagenDb? obtenerPorUid(String uid) {
    try {
      return state.firstWhere((i) => i.uid == uid);
    } catch (_) {
      return null;
    }
  }

  bool todasDescargadas(String modeloUid) {
    final imgs = imagenesDeModelo(modeloUid);
    return imgs.isNotEmpty &&
        imgs.every(
          (i) => i.rutaLocal.isNotEmpty && File(i.rutaLocal).existsSync(),
        );
  }

  // -----------------------------------------------------------------------------
  // CREAR / EDITAR (LOCAL)
  // -----------------------------------------------------------------------------
  Future<ModeloImagenDb> crearImagenLocal({
    required String modeloUid,
    String rutaRemota = '',
    String rutaLocal = '',
    bool isCover = false,
  }) async {
    final uid = const Uuid().v4();
    final now = DateTime.now().toUtc();

    String sha = '';
    if (rutaLocal.isNotEmpty && await File(rutaLocal).exists()) {
      sha = await _service.calcularSha256(File(rutaLocal));
    }

    await _dao.upsertImagenDrift(
      ModeloImagenesCompanion.insert(
        uid: uid,
        modeloUid: modeloUid,
        rutaRemota: Value(rutaRemota),
        rutaLocal: Value(rutaLocal),
        sha256: Value(sha),
        isCover: Value(isCover),
        deleted: const Value(false),
        isSynced: const Value(false),
        updatedAt: Value(now),
      ),
    );

    state = await _dao.obtenerTodosDrift();
    return state.firstWhere((i) => i.uid == uid);
  }

  Future<ModeloImagenDb> editarImagen({
    required ModeloImagenDb actualizada,
  }) async {
    final now = DateTime.now().toUtc();
    await _dao.upsertImagenDrift(
      ModeloImagenesCompanion(
        uid: Value(actualizada.uid),
        modeloUid: Value(actualizada.modeloUid),
        rutaRemota: Value(actualizada.rutaRemota),
        rutaLocal: Value(actualizada.rutaLocal),
        sha256: Value(actualizada.sha256),
        isCover: Value(actualizada.isCover),
        deleted: Value(actualizada.deleted),
        isSynced: const Value(false),
        updatedAt: Value(now),
      ),
    );
    state = await _dao.obtenerTodosDrift();
    return state.firstWhere((i) => i.uid == actualizada.uid);
  }

  // Marca una imagen como portada (y limpia las demás del mismo modelo)
  Future<void> setCover({
    required String modeloUid,
    required String imagenUid,
  }) async {
    final now = DateTime.now().toUtc();

    // desmarcar todas las portadas de ese modelo
    final imgsModelo = state.where((i) => i.modeloUid == modeloUid).toList();
    for (final i in imgsModelo) {
      final debeSerCover = i.uid == imagenUid;
      if (i.isCover != debeSerCover) {
        await _dao.actualizarParcialPorUid(
          i.uid,
          ModeloImagenesCompanion(
            isCover: Value(debeSerCover),
            isSynced: const Value(false),
            updatedAt: Value(now),
          ),
        );
      }
    }
    state = await _dao.obtenerTodosDrift();

    if (_hayInternet) {
      // esto empuja el cambio de portada
      await _sync.pushModeloImagenesOffline();
    }
  }

  // Obtén la imagen de portada o, si no hay, la más reciente activa (descargada si pides)
  ModeloImagenDb? coverOrFallback(
    String modeloUid, {
    bool soloDescargadas = true,
  }) {
    final activas = imagenesDeModelo(modeloUid, incluirEliminadas: false);
    if (activas.isEmpty) return null;

    final cover = activas.firstWhere(
      (i) => i.isCover,
      orElse: () => activas.first,
    );

    if (!soloDescargadas) return cover;
    return (cover.rutaLocal.isNotEmpty && File(cover.rutaLocal).existsSync())
        ? cover
        : activas.firstWhere(
            (i) => i.rutaLocal.isNotEmpty && File(i.rutaLocal).existsSync(),
            orElse: () => cover,
          );
  }

  // -----------------------------------------------------------------------------
  // Garantizar que siempre exista un cover
  // -----------------------------------------------------------------------------
  Future<void> ensureCover(String modeloUid) async {
    final activas = imagenesDeModelo(modeloUid, incluirEliminadas: false);
    if (activas.isEmpty) return; // nada que hacer

    // ¿ya hay portada válida?
    final yaHayCover = activas.any((i) => i.isCover);
    if (yaHayCover) return;

    // si no hay, tomamos la más reciente y la marcamos como portada
    final fallback = activas.first;
    await setCover(modeloUid: modeloUid, imagenUid: fallback.uid);
  }

  // -----------------------------------------------------------------------------
  // SUBIR NUEVA IMAGEN (copiar a almacenamiento app → marcar para sync)
  // -----------------------------------------------------------------------------
  Future<void> subirNuevaImagen({
    required ModeloImagenDb imagen,
    required File archivo,
    required String nuevoPath,
    String? sha256Override, // 👈 opcional
  }) async {
    try {
      final sha = sha256Override ?? await _service.calcularSha256(archivo);

      // dedup por sha en el MISMO modelo
      final dup = await _dao.obtenerPorShaEnModeloDrift(imagen.modeloUid, sha);
      if (dup != null && dup.uid != imagen.uid) {
        await _dao.actualizarParcialPorUid(
          imagen.uid,
          ModeloImagenesCompanion(
            deleted: const Value(true),
            isSynced: const Value(false),
            updatedAt: Value(DateTime.now().toUtc()),
          ),
        );
        state = await _dao.obtenerTodosDrift();
        print(
          '[🚗👀 MENSAJES MODELO_IMAGENES PROVIDER] Duplicada por sha256. Reutiliza uid=${dup.uid}',
        );
        return;
      }

      // copia local + persistir sha
      final dir = await getApplicationSupportDirectory();
      final imgsDir = Directory(p.join(dir.path, 'modelos_img'));
      if (!await imgsDir.exists()) await imgsDir.create(recursive: true);

      final safeName = nuevoPath.replaceAll('/', '_');
      final destino = File(p.join(imgsDir.path, safeName));
      await archivo.copy(destino.path);

      await _dao.actualizarParcialPorUid(
        imagen.uid,
        ModeloImagenesCompanion(
          rutaRemota: Value(nuevoPath),
          rutaLocal: Value(destino.path),
          sha256: Value(sha),
          updatedAt: Value(DateTime.now().toUtc()),
          isSynced: const Value(false),
        ),
      );

      // 👇 LOGS útiles
      final countPend = (await _dao.obtenerPendientesSyncDrift()).length;
      print(
        '[🚗👀 MENSAJES MODELO_IMAGENES PROVIDER] upsert parcial OK → pendientes=$countPend',
      );

      state = await _dao.obtenerTodosDrift();
      print(
        '[🚗👀 MENSAJES MODELO_IMAGENES PROVIDER] estado local tras upsert: ${state.length} imgs',
      );

      if (_hayInternet) {
        await cargarOfflineFirst();
      }
      print(
        '[🚗👀 MENSAJES MODELO_IMAGENES PROVIDER] subirNuevaImagen() terminó',
      );

      print(
        '[🚗👀 MENSAJES MODELO_IMAGENES PROVIDER] Imagen guardada localmente: ${destino.path}',
      );
    } catch (e) {
      print(
        '[🚗👀 MENSAJES MODELO_IMAGENES PROVIDER] ❌ Error preparando imagen: $e',
      );
      rethrow;
    }
  }

  // -----------------------------------------------------------------------------
  // DESCARGAR / ELIMINAR LOCAL
  // -----------------------------------------------------------------------------

  Future<ModeloImagenDb?> buscarPorShaEnModelo(String modeloUid, String sha) {
    return _dao.obtenerPorShaEnModeloDrift(modeloUid, sha);
  }

  // Devuelve un File local para un sha ya descargado en cualquier registro
  File? _localFileForSha(String sha) {
    if (sha.trim().isEmpty) return null;
    try {
      final other = state.firstWhere(
        (i) =>
            i.sha256 == sha &&
            i.rutaLocal.isNotEmpty &&
            File(i.rutaLocal).existsSync(),
      );
      return File(other.rutaLocal);
    } catch (_) {
      return null;
    }
  }

  // Devuelve un File local para una rutaRemota ya descargada (por si aún no hay sha)
  File? _localFileForRuta(String ruta) {
    if (ruta.trim().isEmpty) return null;
    try {
      final other = state.firstWhere(
        (i) =>
            i.rutaRemota == ruta &&
            i.rutaLocal.isNotEmpty &&
            File(i.rutaLocal).existsSync(),
      );
      return File(other.rutaLocal);
    } catch (_) {
      return null;
    }
  }

  Future<ModeloImagenDb?> descargarImagen(ModeloImagenDb img) async {
    // 0) Intento de REUSO por sha o por rutaRemota
    File? reused;
    if (img.sha256.trim().isNotEmpty) {
      reused = _localFileForSha(img.sha256);
    }
    reused ??= _localFileForRuta(img.rutaRemota);

    if (reused != null) {
      // Actualizamos sólo rutaLocal; no tocamos updatedAt/isSynced
      await _dao.actualizarParcialPorUid(
        img.uid,
        ModeloImagenesCompanion(rutaLocal: Value(reused.path)),
      );
      state = await _dao.obtenerTodosDrift();
      return state.firstWhere((i) => i.uid == img.uid, orElse: () => img);
    }

    // 1) Si no hubo reuso, descargar realmente
    final file = await _service.descargarImagenOnline(img.rutaRemota);
    if (file == null) {
      print('[🚗👀] ❌ No se pudo descargar ${img.rutaRemota}');
      return null;
    }

    // 2) Completar sha si viniera vacío (sin tocar updatedAt)
    final sha = await _service.calcularSha256(file);

    await _dao.actualizarParcialPorUid(
      img.uid,
      ModeloImagenesCompanion(
        rutaLocal: Value(file.path),
        sha256: img.sha256.isEmpty ? Value(sha) : const Value.absent(),
      ),
    );

    state = await _dao.obtenerTodosDrift();
    return state.firstWhere((i) => i.uid == img.uid, orElse: () => img);
  }

  Future<void> eliminarImagenLocal(ModeloImagenDb img) async {
    print(
      '[🚗👀 MENSAJES MODELO_IMAGENES PROVIDER] Borrando imagen local: ${img.rutaLocal}',
    );
    if (img.rutaLocal.isNotEmpty) {
      final file = File(img.rutaLocal);
      try {
        if (await file.exists()) await file.delete();
      } catch (e) {
        print(
          '[🚗👀 MENSAJES MODELO_IMAGENES PROVIDER] ⚠️ Error borrando archivo local: $e',
        );
      }
    }

    // ✅ Update parcial
    await _dao.actualizarParcialPorUid(
      img.uid,
      ModeloImagenesCompanion(rutaLocal: const Value('')),
    );

    state = await _dao.obtenerTodosDrift();
  }

  // Soft delete “total” (se sincroniza el borrado al servidor)
  Future<void> eliminarImagen(
    ModeloImagenDb img, {
    bool borrarArchivoLocal =
        false, // 👈 por si algún día quieres liberar espacio
  }) async {
    if (borrarArchivoLocal) {
      await eliminarImagenLocal(img); // esto sí vacía rutaLocal
    }

    await _dao.actualizarParcialPorUid(
      img.uid,
      ModeloImagenesCompanion(
        deleted: const Value(true),
        isSynced: const Value(false),
        isCover: const Value(false),
        updatedAt: Value(DateTime.now().toUtc()),
        rutaLocal: borrarArchivoLocal ? const Value('') : const Value.absent(),
      ),
    );

    state = await _dao.obtenerTodosDrift();
    if (_hayInternet) {
      await cargarOfflineFirst();
    }
  }

  // -----------------------------------------------------------------------------
  // Acciones MASIVAS por modelo
  // -----------------------------------------------------------------------------
  Future<int> descargarTodasDeModelo(String modeloUid) async {
    final imgs = imagenesDeModelo(modeloUid, incluirEliminadas: true);
    int count = 0;
    for (final i in imgs) {
      final yaLocal = i.rutaLocal.isNotEmpty && File(i.rutaLocal).existsSync();
      if (yaLocal) continue;
      final ok = await descargarImagen(i);
      if (ok != null) count++;
    }
    return count;
  }

  Future<int> eliminarLocalesDeModelo(String modeloUid) async {
    final imgs = imagenesDeModelo(
      modeloUid,
      incluirEliminadas: false,
      soloDescargadas: true,
    );
    int count = 0;
    for (final i in imgs) {
      await eliminarImagenLocal(i);
      count++;
    }
    return count;
  }
}

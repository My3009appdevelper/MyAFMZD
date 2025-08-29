// ignore_for_file: avoid_print

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/database_provider.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_dao.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_service.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_sync.dart';
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

      // 7) Prefetch de fotos (descargar faltantes si hay red)
      final descargadas = await descargarFaltantes();
      if (descargadas > 0) {
        state = await _dao.obtenerTodosDrift();
        print(
          '[👥 MENSAJES COLABORADORES PROVIDER] Prefetch completado → $descargadas fotos descargadas',
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
    required String nuevoPath, // e.g. "empleados/uid123/avatar.jpg"
  }) async {
    try {
      // Si ya existe en remoto, no copiamos local; solo metadata
      final yaExisteRemoto = await _servicio.existsImagen(nuevoPath);
      if (yaExisteRemoto) {
        print(
          '[👥 MENSAJES COLABORADORES PROVIDER] ⏭️ Remoto ya existe: $nuevoPath',
        );
        await _dao.actualizarParcialPorUid(
          colaborador.uid,
          ColaboradoresCompanion(
            fotoRutaRemota: Value(nuevoPath),
            fotoRutaLocal: const Value(''),
            updatedAt: Value(DateTime.now().toUtc()),
            isSynced: const Value(false),
          ),
        );
        state = await _dao.obtenerTodosDrift();
        if (_hayInternet) await cargarOfflineFirst();
        return;
      }

      final dir = await getApplicationSupportDirectory();
      final fotosDir = Directory(p.join(dir.path, 'colaboradores_img'));
      if (!await fotosDir.exists()) await fotosDir.create(recursive: true);

      final safeName = nuevoPath.replaceAll('/', '_');
      final destino = File(p.join(fotosDir.path, safeName));
      await archivo.copy(destino.path);

      await _dao.actualizarParcialPorUid(
        colaborador.uid,
        ColaboradoresCompanion(
          fotoRutaRemota: Value(nuevoPath),
          fotoRutaLocal: Value(destino.path),
          updatedAt: Value(DateTime.now().toUtc()),
          isSynced: const Value(false),
        ),
      );

      state = await _dao.obtenerTodosDrift();

      if (_hayInternet) {
        await cargarOfflineFirst();
      }

      print(
        '[👥 MENSAJES COLABORADORES PROVIDER] Foto guardada localmente: ${destino.path}',
      );
    } catch (e) {
      print('[👥 MENSAJES COLABORADORES PROVIDER] ❌ Error preparando foto: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 📥 Descarga diferida en lote (faltantes)
  // ---------------------------------------------------------------------------
  Future<int> descargarFaltantes({int max = 200}) async {
    if (!_hayInternet) return 0;

    // Candidatos: tienen rutaRemota válida pero no rutaLocal o archivo no existe
    final candidatos =
        state.where((c) {
          if (c.deleted) return false;
          if (c.fotoRutaRemota.trim().isEmpty) return false;
          if (c.fotoRutaLocal.isNotEmpty &&
              File(c.fotoRutaLocal).existsSync()) {
            return false;
          }
          return true;
        }).toList()..sort(
          (a, b) => b.updatedAt.compareTo(a.updatedAt),
        ); // recientes primero

    if (candidatos.isEmpty) return 0;

    // Reusar por rutaRemota cuando sea posible
    int descargados = 0;
    int procesados = 0;

    // Agrupar por rutaRemota para descargar una sola vez por ruta
    final Map<String, List<ColaboradorDb>> grupos = {};
    for (final c in candidatos) {
      final key = c.fotoRutaRemota.trim();
      (grupos[key] ??= []).add(c);
    }

    for (final entry in grupos.entries) {
      if (procesados >= max) break;
      final ruta = entry.key;
      final grupo = entry.value;

      // ¿Se puede reusar ya?
      File? reused = _localFileForRuta(ruta);

      if (reused == null) {
        final file = await _servicio.descargarImagenOnline(ruta);
        if (file == null) continue;
        reused = file;
        descargados++;
      }

      // Propagar rutaLocal al grupo
      for (final c in grupo) {
        await _dao.actualizarParcialPorUid(
          c.uid,
          ColaboradoresCompanion(fotoRutaLocal: Value(reused.path)),
        );
        procesados++;
        if (procesados >= max) break;
      }
    }

    if (descargados > 0 || procesados > 0) {
      state = await _dao.obtenerTodosDrift();
    }
    return descargados;
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
  bool existeDuplicado({
    required String uidActual,
    required String nombres,
    String apellidoPaterno = '',
    String apellidoMaterno = '',
    DateTime? fechaNacimiento,
    String curp = '',
    String rfc = '',
    String telefonoMovil = '',
    String emailPersonal = '',
  }) {
    final fullNameInput = _norm('$nombres $apellidoPaterno $apellidoMaterno');
    final dobInput = fechaNacimiento == null
        ? null
        : _dateOnlyUtc(fechaNacimiento);
    final emailIn = emailPersonal.trim().toLowerCase();
    final phoneIn = _digits(telefonoMovil);

    for (final c in state) {
      if (c.deleted) continue;
      if (c.uid == uidActual) continue;

      // 1) CURP exacta (si aplica)
      final cCurp = (c.curp ?? '').trim().toLowerCase();
      if (curp.trim().isNotEmpty && cCurp.isNotEmpty) {
        if (cCurp == curp.trim().toLowerCase()) return true;
      }

      // 2) RFC exacto (si aplica)
      final cRfc = (c.rfc ?? '').trim().toLowerCase();
      if (rfc.trim().isNotEmpty && cRfc.isNotEmpty) {
        if (cRfc == rfc.trim().toLowerCase()) return true;
      }

      // 3) Email / Tel (normalizados)
      if (emailIn.isNotEmpty && c.emailPersonal.trim().isNotEmpty) {
        if (c.emailPersonal.trim().toLowerCase() == emailIn) return true;
      }
      if (phoneIn.isNotEmpty && c.telefonoMovil.trim().isNotEmpty) {
        if (_digits(c.telefonoMovil) == phoneIn) return true;
      }

      // 4) Nombre completo + fecha de nacimiento
      if (dobInput != null && c.fechaNacimiento != null) {
        final cFull = _norm(
          '${c.nombres} ${c.apellidoPaterno} ${c.apellidoMaterno}',
        );
        final cDob = _dateOnlyUtc(c.fechaNacimiento!);
        if (cFull == fullNameInput && cDob == dobInput) return true;
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

  DateTime _dateOnlyUtc(DateTime d) =>
      DateTime.utc(d.toUtc().year, d.toUtc().month, d.toUtc().day);
}

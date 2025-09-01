// ignore_for_file: avoid_print

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/database_provider.dart';
import 'package:myafmzd/database/asignaciones_laborales/asignaciones_laborales_dao.dart';
import 'package:myafmzd/database/asignaciones_laborales/asignaciones_laborales_service.dart';
import 'package:myafmzd/database/asignaciones_laborales/asignaciones_laborales_sync.dart';
import 'package:uuid/uuid.dart';

/// ---------------------------------------------------------------------------
/// Provider global
/// ---------------------------------------------------------------------------
/// Mantiene en memoria TODAS las asignaciones (activas + históricas si las cargas).
final asignacionesLaboralesProvider =
    StateNotifierProvider<
      AsignacionesLaboralesNotifier,
      List<AsignacionLaboralDb>
    >((ref) {
      final db = ref.watch(appDatabaseProvider);
      return AsignacionesLaboralesNotifier(ref, db);
    });

class AsignacionesLaboralesNotifier
    extends StateNotifier<List<AsignacionLaboralDb>> {
  AsignacionesLaboralesNotifier(this._ref, AppDatabase db)
    : _dao = AsignacionesLaboralesDao(db),
      _service = AsignacionesLaboralesService(db),
      _sync = AsignacionesLaboralesSync(db),
      super([]);

  final Ref _ref;
  final AsignacionesLaboralesDao _dao;
  final AsignacionesLaboralesService _service;
  final AsignacionesLaboralesSync _sync;

  bool _hayInternet = true;
  bool get hayInternet => _hayInternet;

  // Opciones por defecto para el Form (puedes moverlas a config si quieres)
  static const List<String> rolesDisponibles = <String>[
    'vendedor',
    'coordinador',
    'gerente',
    'administrativo',
  ];

  static const List<String> nivelesDisponibles = <String>[
    '', // sin nivel
    'jr',
    'sr',
    'lead',
  ];

  // ---------------------------------------------------------------------------
  // ✅ Cargar asignaciones (offline-first)
  //   1) Local primero
  //   2) Si hay internet: pull (heads→diff→bulk) y luego push
  //   3) Refrescar estado
  // ---------------------------------------------------------------------------
  Future<void> cargarOfflineFirst() async {
    try {
      _hayInternet = _ref.read(connectivityProvider);

      // 1) Pintar local
      final local = await _dao.obtenerTodosDrift();
      state = local;
      print(
        '[👔 MENSAJES ASIGNACIONES PROVIDER] Local cargado -> ${local.length} asignaciones',
      );

      // 2) Sin internet → solo local
      if (!_hayInternet) {
        print(
          '[👔 MENSAJES ASIGNACIONES PROVIDER] Sin internet → usando solo local',
        );
        return;
      }

      // 3) (Opcional) timestamps para logs/telemetría
      final localTimestamp = await _dao.obtenerUltimaActualizacionDrift();
      final remotoTimestamp = await _service.comprobarActualizacionesOnline();
      print(
        '[👔 MENSAJES ASIGNACIONES PROVIDER] Remoto:$remotoTimestamp | Local:$localTimestamp',
      );

      // 4) Pull (heads → diff → bulk)
      await _sync.pullAsignacionesOnline();

      // 5) Push de cambios offline
      await _sync.pushAsignacionesOffline();

      // 6) Recargar desde Drift
      final actualizados = await _dao.obtenerTodosDrift();
      state = actualizados;
    } catch (e) {
      print(
        '[👔 MENSAJES ASIGNACIONES PROVIDER] ❌ Error al cargar asignaciones: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // ➕ Crear asignación (LOCAL → isSynced=false; el push la sube)
  //    Úsalo desde tu FormPage cuando das de alta o reasignas.
  // ---------------------------------------------------------------------------
  Future<AsignacionLaboralDb> crearAsignacion({
    required String colaboradorUid,
    required DateTime fechaInicio,
    String distribuidorUid = '',
    String managerColaboradorUid = '',
    String rol = 'vendedor',
    String puesto = '',
    String nivel = '',
    String createdByUsuarioUid = '',
    String notas = '',
    DateTime? fechaFin, // opcional (normalmente null al crear)
  }) async {
    final uid = const Uuid().v4();
    try {
      final now = DateTime.now().toUtc();

      // Validación básica: no traslapar con otra activa del mismo colaborador.
      if (tieneTraslapeEnRango(
        colaboradorUid: colaboradorUid,
        inicio: fechaInicio,
        fin: fechaFin,
        excluirUid: null,
      )) {
        throw StateError(
          'El colaborador ya tiene una asignación activa o traslapada en ese rango.',
        );
      }

      final comp = AsignacionesLaboralesCompanion.insert(
        uid: uid,
        colaboradorUid: colaboradorUid,
        distribuidorUid: Value(distribuidorUid),
        managerColaboradorUid: Value(managerColaboradorUid),
        rol: Value(rol),
        puesto: Value(puesto),
        nivel: Value(nivel),
        fechaInicio: fechaInicio.toUtc(),
        fechaFin: fechaFin == null
            ? const Value.absent()
            : Value(fechaFin.toUtc()),
        createdByUsuarioUid: Value(createdByUsuarioUid),
        closedByUsuarioUid: const Value(''),
        notas: Value(notas),
        createdAt: Value(now),
        updatedAt: Value(now),
        deleted: const Value(false),
        isSynced: const Value(false),
      );

      await _dao.upsertAsignacionLaboralDrift(comp);
      final actualizados = await _dao.obtenerTodosDrift();
      state = actualizados;
      return actualizados.firstWhere((a) => a.uid == uid);
    } catch (e) {
      print(
        '[👔 MENSAJES ASIGNACIONES PROVIDER] ❌ Error al crear asignación: $e',
      );
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // ✏️ Editar asignación (LOCAL → isSynced=false; el push la sube)
  // ---------------------------------------------------------------------------
  Future<void> editarAsignacion({
    required String uid,
    String? distribuidorUid,
    String? managerColaboradorUid,
    String? rol,
    String? puesto,
    String? nivel,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? notas,
  }) async {
    // Si tocas fechas, valida traslapes
    final current = obtenerPorUid(uid);
    if (current == null) {
      throw StateError('Asignación no encontrada: $uid');
    }

    final nuevoInicio = fechaInicio ?? current.fechaInicio;
    final nuevoFin = fechaFin ?? current.fechaFin;

    if (tieneTraslapeEnRango(
      colaboradorUid: current.colaboradorUid,
      inicio: nuevoInicio,
      fin: nuevoFin,
      excluirUid: uid,
    )) {
      throw StateError(
        'Este cambio generaría un traslape de asignaciones para el colaborador.',
      );
    }

    final comp = AsignacionesLaboralesCompanion(
      uid: Value(uid),
      distribuidorUid: distribuidorUid == null
          ? const Value.absent()
          : Value(distribuidorUid),
      managerColaboradorUid: managerColaboradorUid == null
          ? const Value.absent()
          : Value(managerColaboradorUid),
      rol: rol == null ? const Value.absent() : Value(rol),
      puesto: puesto == null ? const Value.absent() : Value(puesto),
      nivel: nivel == null ? const Value.absent() : Value(nivel),
      fechaInicio: fechaInicio == null
          ? const Value.absent()
          : Value(nuevoInicio.toUtc()),
      fechaFin: fechaFin == null
          ? const Value.absent()
          : Value(nuevoFin?.toUtc()),
      notas: notas == null ? const Value.absent() : Value(notas),
      updatedAt: Value(DateTime.now().toUtc()),
      isSynced: const Value(false),
    );

    await _dao.actualizarParcialPorUid(uid, comp);
    state = await _dao.obtenerTodosDrift();
    print(
      '[👔 MENSAJES ASIGNACIONES PROVIDER] Asignación $uid editada localmente',
    );
  }

  // ---------------------------------------------------------------------------
  // ✅ Cerrar / Reabrir
  // ---------------------------------------------------------------------------
  Future<void> cerrarAsignacion({
    required String uid,
    required String closedByUsuarioUid,
    DateTime? fechaFin,
    String? notasAppend,
  }) async {
    try {
      final now = DateTime.now().toUtc();
      final fin = (fechaFin ?? now).toUtc();

      final comp = AsignacionesLaboralesCompanion(
        // uid NO se toca en el SET; el WHERE lo maneja el DAO
        fechaFin: Value(fin),
        closedByUsuarioUid: Value(closedByUsuarioUid),
        notas: (notasAppend == null || notasAppend.trim().isEmpty)
            ? const Value.absent()
            : Value(notasAppend.trim()),
        updatedAt: Value(now),
        isSynced: const Value(false),
      );

      await _dao.actualizarParcialPorUid(uid, comp);
      state = await _dao.obtenerTodosDrift();
      print(
        '[👔 MENSAJES ASIGNACIONES PROVIDER] Asignación $uid cerrada localmente',
      );
    } catch (e) {
      print(
        '[👔 MENSAJES ASIGNACIONES PROVIDER] ❌ Error al cerrar asignación: $e',
      );
      rethrow;
    }
  }

  Future<void> reabrirAsignacion({required String uid}) async {
    try {
      final now = DateTime.now().toUtc();

      final comp = AsignacionesLaboralesCompanion(
        // uid NO se toca en el SET; el WHERE lo maneja el DAO
        fechaFin: const Value(null),
        closedByUsuarioUid: const Value(''),
        updatedAt: Value(now),
        isSynced: const Value(false),
      );

      await _dao.actualizarParcialPorUid(uid, comp);
      state = await _dao.obtenerTodosDrift();
      print(
        '[👔 MENSAJES ASIGNACIONES PROVIDER] Asignación $uid reabierta localmente',
      );
    } catch (e) {
      print(
        '[👔 MENSAJES ASIGNACIONES PROVIDER] ❌ Error al reabrir asignación: $e',
      );
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 🗑️ Soft delete local (marca isSynced=false) → push lo sube
  // ---------------------------------------------------------------------------
  Future<void> eliminarAsignacionLocal(String uid) async {
    try {
      final comp = AsignacionesLaboralesCompanion(
        // uid NO se toca en el SET; el WHERE lo maneja el DAO
        deleted: const Value(true),
        updatedAt: Value(DateTime.now().toUtc()),
        isSynced: const Value(false),
      );

      await _dao.actualizarParcialPorUid(uid, comp);
      state = await _dao.obtenerTodosDrift();
      print(
        '[👔 MENSAJES ASIGNACIONES PROVIDER] Asignación $uid marcada como eliminada (soft delete)',
      );
    } catch (e) {
      print(
        '[👔 MENSAJES ASIGNACIONES PROVIDER] ❌ Error al eliminar asignación: $e',
      );
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 🔍 Consultas / utilidades pensadas para FormPage, Screen y Tile
  //   - Listas filtradas y ordenadas
  //   - Texto compacto para tiles
  //   - Búsquedas típicas
  // ---------------------------------------------------------------------------
  AsignacionLaboralDb? obtenerPorUid(String uid) {
    try {
      return state.firstWhere((a) => a.uid == uid);
    } catch (_) {
      return null;
    }
  }

  /// Asignación ACTIVA (fechaFin == null) de un colaborador (si hubiera).
  AsignacionLaboralDb? activaPorColaborador(String colaboradorUid) {
    final activas = state.where((a) {
      return !a.deleted &&
          a.colaboradorUid == colaboradorUid &&
          a.fechaFin == null;
    }).toList()..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return activas.isNotEmpty ? activas.first : null;
  }

  /// Historial completo (más reciente primero) de un colaborador.
  List<AsignacionLaboralDb> historicoPorColaborador(String colaboradorUid) {
    return state.where((a) => a.colaboradorUid == colaboradorUid).toList()
      ..sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));
  }

  /// Listar activas con filtros opcionales para Screen/List.
  List<AsignacionLaboralDb> listarActivas({
    String? distribuidorUid,
    String? rol,
  }) {
    return state.where((a) {
      if (a.deleted) return false;
      if (a.fechaFin != null) return false;
      final dOk =
          distribuidorUid == null ||
          distribuidorUid.isEmpty ||
          a.distribuidorUid == distribuidorUid;
      final rOk = rol == null || rol.isEmpty || a.rol == rol;
      return dOk && rOk;
    }).toList()..sort((a, b) {
      // Orden útil para tiles: por rol, luego fechaInicio desc
      final r = a.rol.compareTo(b.rol);
      return r != 0 ? r : b.fechaInicio.compareTo(a.fechaInicio);
    });
  }

  /// Listar históricas (cerradas) por filtros, más recientes primero.
  List<AsignacionLaboralDb> listarHistoricas({
    String? distribuidorUid,
    String? rol,
  }) {
    return state.where((a) {
      if (a.deleted) return false;
      if (a.fechaFin == null) return false;
      final dOk =
          distribuidorUid == null ||
          distribuidorUid.isEmpty ||
          a.distribuidorUid == distribuidorUid;
      final rOk = rol == null || rol.isEmpty || a.rol == rol;
      return dOk && rOk;
    }).toList()..sort((a, b) => b.fechaFin!.compareTo(a.fechaFin!));
  }

  /// Texto compacto para usar directamente en un ListTile.
  String tileTitle(AsignacionLaboralDb a) {
    // Ej.: "Vendedor (jr) — Mazda Norte"
    final n = (a.nivel.trim().isEmpty) ? '' : ' (${a.nivel})';
    final d = (a.distribuidorUid.isEmpty) ? '' : ' — ${a.distribuidorUid}';
    return '${a.rol}$n$d';
  }

  String tileSubtitle(AsignacionLaboralDb a) {
    // Ej.: "Inicio: 01/2024 • Fin: —" (o fecha)
    final i =
        '${a.fechaInicio.toLocal().day.toString().padLeft(2, '0')}/${a.fechaInicio.toLocal().month.toString().padLeft(2, '0')}/${a.fechaInicio.toLocal().year}';
    final f = (a.fechaFin == null)
        ? '—'
        : '${a.fechaFin!.toLocal().day.toString().padLeft(2, '0')}/${a.fechaFin!.toLocal().month.toString().padLeft(2, '0')}/${a.fechaFin!.toLocal().year}';
    return 'Inicio: $i • Fin: $f';
  }

  // ---------------------------------------------------------------------------
  // 🛡️ Validaciones
  //   - Traslapes: no permitimos dos asignaciones activas que se crucen
  //     (misma persona). Útil para el FormPage en onSave.
  // ---------------------------------------------------------------------------
  bool tieneTraslapeEnRango({
    required String colaboradorUid,
    required DateTime inicio,
    DateTime? fin, // null => abierta
    String? excluirUid,
  }) {
    final start = inicio.toUtc();
    final end = fin?.toUtc(); // null = abierto/activo

    for (final a in state) {
      if (a.deleted) continue;
      if (a.colaboradorUid != colaboradorUid) continue;
      if (excluirUid != null && a.uid == excluirUid) continue;

      final aStart = a.fechaInicio.toUtc();
      final aEnd = a.fechaFin?.toUtc(); // null = abierta

      // Caso intervalos:
      // [aStart, aEnd?] vs [start, end?] — hay traslape si:
      // - si ambos cerrados: aStart <= end && start <= aEnd
      // - si uno abierto: solapan si el inicio está dentro del otro
      final overlaps = () {
        if (aEnd != null && end != null) {
          return aStart.isBefore(end) && start.isBefore(aEnd) ||
              aStart.isAtSameMomentAs(end) ||
              start.isAtSameMomentAs(aEnd);
        }
        if (aEnd == null && end == null) {
          // ambos abiertos => traslape seguro
          return true;
        }
        if (aEnd == null && end != null) {
          // a abierto: solapa si aStart <= end
          return !aStart.isAfter(end);
        }
        if (aEnd != null && end == null) {
          // nuevo abierto: solapa si start <= aEnd
          return !start.isAfter(aEnd);
        }
        return false;
      }();

      if (overlaps) return true;
    }
    return false;
  }

  // ---------------------------------------------------------------------------
  // 🧭 Listas para el FormPage (combos)
  // ---------------------------------------------------------------------------
  List<String> get opcionesRol => rolesDisponibles;
  List<String> get opcionesNivel => nivelesDisponibles;
}

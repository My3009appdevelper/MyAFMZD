// ignore_for_file: avoid_print

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/database_provider.dart';
import 'package:myafmzd/database/grupo_distribuidores/grupos_distribuidores_dao.dart';
import 'package:myafmzd/database/grupo_distribuidores/grupos_distribuidores_service.dart';
import 'package:myafmzd/database/grupo_distribuidores/grupos_distribuidores_sync.dart';
import 'package:uuid/uuid.dart';

/// Estado = lista completa (incluye eliminados si los cargas explícitamente)
final gruposDistribuidoresProvider =
    StateNotifierProvider<
      GruposDistribuidoresNotifier,
      List<GrupoDistribuidorDb>
    >((ref) {
      final db = ref.watch(appDatabaseProvider);
      return GruposDistribuidoresNotifier(ref, db);
    });

class GruposDistribuidoresNotifier
    extends StateNotifier<List<GrupoDistribuidorDb>> {
  GruposDistribuidoresNotifier(this._ref, AppDatabase db)
    : _dao = GruposDistribuidoresDao(db),
      _servicio = GruposDistribuidoresService(db),
      _sync = GruposDistribuidoresSync(db),
      super([]);

  final Ref _ref;
  final GruposDistribuidoresDao _dao;
  final GruposDistribuidoresService _servicio;
  final GruposDistribuidoresSync _sync;

  bool _hayInternet = true;
  bool get hayInternet => _hayInternet;

  // ---------------------------------------------------------------------------
  // ✅ Cargar grupos (offline-first)
  // ---------------------------------------------------------------------------
  Future<void> cargarOfflineFirst() async {
    try {
      _hayInternet = _ref.read(connectivityProvider);

      // 1) Local primero
      final local = await _dao.obtenerTodosDrift();
      state = local;
      print(
        '[🧑‍🤝‍🧑 MENSAJES GRUPOS PROVIDER] Local cargado -> ${local.length} grupos',
      );

      // 2) Sin internet → detener
      if (!_hayInternet) {
        print(
          '[🧑‍🤝‍🧑 MENSAJES GRUPOS PROVIDER] Sin internet → usando solo local',
        );
        return;
      }

      // 3) (Opcional) timestamps para log/telemetría
      final localTimestamp = await _dao.obtenerUltimaActualizacionDrift();
      final remotoTimestamp = await _servicio.comprobarActualizacionesOnline();
      print(
        '[🧑‍🤝‍🧑 MENSAJES GRUPOS PROVIDER] Remoto:$remotoTimestamp | Local:$localTimestamp',
      );

      // 4) Pull (heads → diff → fetch)
      await _sync.pullGruposDistribuidoresOnline();

      // 5) Push de cambios offline
      await _sync.pushGruposDistribuidoresOffline();

      // 6) Recargar desde Drift
      final actualizados = await _dao.obtenerTodosDrift();
      state = actualizados;
    } catch (e) {
      print('[🧑‍🤝‍🧑 MENSAJES GRUPOS PROVIDER] ❌ Error al cargar grupos: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // ➕ Crear grupo (ONLINE upsert → local isSynced=true)
  // ---------------------------------------------------------------------------
  Future<GrupoDistribuidorDb?> crearGrupo({
    required String nombre,
    String abreviatura = '',
    String notas = '',
    bool activo = true,
  }) async {
    final uid = const Uuid().v4();
    try {
      final now = DateTime.now().toUtc();

      // 2) Upsert LOCAL (remoto ⇒ isSynced=true)
      final comp = GruposDistribuidoresCompanion(
        uid: Value(uid),
        nombre: Value(nombre),
        abreviatura: Value(abreviatura),
        notas: Value(notas),
        activo: Value(activo),
        createdAt: Value(now),
        updatedAt: Value(now),
        deleted: const Value(false),
        isSynced: const Value(false),
      );
      await _dao.upsertGruposDrift([comp]);

      // 3) Refrescar estado y devolver
      final actualizados = await _dao.obtenerTodosDrift();
      state = actualizados;
      return actualizados.firstWhere(
        (g) => g.uid == uid,
        orElse: () => actualizados.last,
      );
    } catch (e) {
      print('[🧑‍🤝‍🧑 MENSAJES GRUPOS PROVIDER] ❌ Error al crear grupo: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // ✏️ Editar grupo (LOCAL → isSynced=false; el push lo sube)
  // ---------------------------------------------------------------------------
  Future<void> editarGrupo({
    required String uid,
    required String nombre,
    String? abreviatura,
    String? notas,
    bool? activo,
  }) async {
    try {
      final comp = GruposDistribuidoresCompanion(
        uid: Value(uid),
        nombre: Value(nombre),
        abreviatura: abreviatura == null
            ? const Value.absent()
            : Value(abreviatura),
        notas: notas == null ? const Value.absent() : Value(notas),
        activo: activo == null ? const Value.absent() : Value(activo),
        updatedAt: Value(DateTime.now().toUtc()),
        deleted: const Value.absent(),
        isSynced: const Value(false),
      );

      await _dao.upsertGrupoDrift(comp);

      state = await _dao.obtenerTodosDrift();
      print(
        '[🧑‍🤝‍🧑 MENSAJES GRUPOS PROVIDER] Grupo $uid editado localmente',
      );
    } catch (e) {
      print('[🧑‍🤝‍🧑 MENSAJES GRUPOS PROVIDER] ❌ Error al editar grupo: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 🗑️ Soft delete local → push lo sube
  // ---------------------------------------------------------------------------
  Future<void> eliminarGrupoLocal(String uid) async {
    try {
      await _dao.actualizarParcialPorUid(
        uid,
        GruposDistribuidoresCompanion(
          deleted: const Value(true),
          updatedAt: Value(DateTime.now().toUtc()),
          isSynced: const Value(false),
        ),
      );
      state = await _dao.obtenerTodosDrift();
      print(
        '[🧑‍🤝‍🧑 MENSAJES GRUPOS PROVIDER] Grupo $uid marcado como eliminado (local)',
      );
    } catch (e) {
      print(
        '[🧑‍🤝‍🧑 MENSAJES GRUPOS PROVIDER] ❌ Error al marcar eliminado: $e',
      );
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 🔍 Consultas / utilidades
  // ---------------------------------------------------------------------------
  GrupoDistribuidorDb? obtenerPorUid(String uid) {
    try {
      return state.firstWhere((g) => g.uid == uid);
    } catch (_) {
      return null;
    }
  }

  /// Buscar por nombre o abreviatura (case-insensitive)
  List<GrupoDistribuidorDb> buscar(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return _ordenado(state);
    return _ordenado(
      state.where((g) {
        return g.nombre.trim().toLowerCase().contains(q) ||
            g.abreviatura.trim().toLowerCase().contains(q);
      }).toList(),
    );
  }

  /// Filtrar por activo/inactivo
  List<GrupoDistribuidorDb> filtrar({required bool mostrarInactivos}) {
    final res = state.where((g) => mostrarInactivos || g.activo).toList();
    return _ordenado(res);
  }

  /// Detección de duplicados por nombre o abreviatura (llaves “humanas”)
  bool existeDuplicado({
    required String uidActual,
    required String nombre,
    String abreviatura = '',
  }) {
    final nom = nombre.trim().toLowerCase();
    final abv = abreviatura.trim().toLowerCase();
    return state.any((g) {
      if (g.uid == uidActual) return false;
      final sameName = g.nombre.trim().toLowerCase() == nom;
      final sameAbv =
          abv.isNotEmpty && g.abreviatura.trim().toLowerCase() == abv;
      return sameName || sameAbv;
    });
  }

  // ----- Helpers -----
  List<GrupoDistribuidorDb> _ordenado(List<GrupoDistribuidorDb> lst) {
    lst.sort((a, b) {
      if (a.activo != b.activo) return a.activo ? -1 : 1;
      return a.nombre.compareTo(b.nombre);
    });
    return lst;
  }

  /// Devuelve el nombre del grupo por UID.
  /// Reglas:
  /// - uid vacío o null => "AFMZD" (tu default histórico)
  /// - uid no encontrado => "—"
  String nombrePorUid(String? uid) {
    final id = (uid ?? '').trim();
    if (id.isEmpty) return 'AFMZD';

    try {
      final g = state.firstWhere((e) => e.uid == id && !e.deleted);
      final n = g.nombre.trim();
      return n.isEmpty ? '—' : n;
    } catch (_) {
      return '—';
    }
  }

  /// True si el UID corresponde (por nombre) al grupo "AFMZD".
  bool esAfmzd(String? uid) => nombrePorUid(uid) == 'AFMZD';
}

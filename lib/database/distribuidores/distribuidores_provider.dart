import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/database_provider.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_dao.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_service.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_sync.dart';
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
    String grupo = 'AFMZD',
    String direccion = '',
    bool activo = true,
    double latitud = 0.0,
    double longitud = 0.0,
  }) async {
    final uid = const Uuid().v4();

    try {
      final now = DateTime.now().toUtc();

      // 2) Upsert LOCAL (remoto ⇒ isSynced=true)
      final comp = DistribuidoresCompanion(
        uid: Value(uid),
        nombre: Value(nombre),
        grupo: Value(grupo),
        direccion: Value(direccion),
        activo: Value(activo),
        latitud: Value(latitud),
        longitud: Value(longitud),
        deleted: const Value(false),
        updatedAt: Value(now),
        isSynced: const Value(true),
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
    String? grupo,
    String? direccion,
    bool? activo,
    double? latitud,
    double? longitud,
  }) async {
    try {
      final comp = DistribuidoresCompanion(
        uid: Value(uid),
        nombre: Value(nombre),
        grupo: grupo == null ? const Value.absent() : Value(grupo),
        direccion: direccion == null ? const Value.absent() : Value(direccion),
        activo: activo == null ? const Value.absent() : Value(activo),
        latitud: latitud == null ? const Value.absent() : Value(latitud),
        longitud: longitud == null ? const Value.absent() : Value(longitud),
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
    final grupos = state.map((d) => d.grupo).toSet().toList();
    grupos.sort();
    grupos.insert(0, 'AFMZD');
    return grupos;
  }

  /// ✅ Filtrar distribuidores por grupo y estado
  List<DistribuidorDb> filtrar({
    required bool mostrarInactivos,
    String? grupo,
  }) {
    return state.where((d) {
      final activoOk = mostrarInactivos || d.activo;
      final grupoOk = grupo == null || grupo == 'Todos' || d.grupo == grupo;
      return activoOk && grupoOk;
    }).toList()..sort((a, b) {
      if (a.activo != b.activo) return a.activo ? -1 : 1;
      return a.nombre.compareTo(b.nombre);
    });
  }
}

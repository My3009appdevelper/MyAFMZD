import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_dao.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_service.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_sync.dart';
import 'package:myafmzd/main.dart';

final distribuidoresProvider =
    StateNotifierProvider<DistribuidoresNotifier, List<DistribuidorDb>>((ref) {
      final db = ref.watch(appDatabaseProvider);
      return DistribuidoresNotifier(db);
    });

class DistribuidoresNotifier extends StateNotifier<List<DistribuidorDb>> {
  DistribuidoresNotifier(AppDatabase db)
    : _dao = DistribuidoresDao(db),
      _service = DistribuidoresService(db),
      _sync = DistribuidoresSync(db),
      super([]);

  final DistribuidoresDao _dao;
  final DistribuidoresService _service;
  final DistribuidoresSync _sync;

  // ---------------------------------------------------------------------------
  // 📌 Cargar distribuidores (offline-first)
  // ---------------------------------------------------------------------------

  Future<void> cargar({required bool hayInternet}) async {
    try {
      // 1️⃣ Pintar siempre la base local primero
      final local = await _dao.obtenerTodosDrift();
      state = local;
      print(
        '[📴 DISTRIBUIDORES PROVIDER] Local cargado -> ${local.length} distribuidores',
      );

      // 2️⃣ Si no hay internet → detenerse aquí
      if (!hayInternet) {
        print('[📴 DISTRIBUIDORES PROVIDER] Sin internet → usando solo local');
        return;
      }

      // 3️⃣ Subir cambios pendientes primero (push)
      await _sync.pushDistribuidoresOffline();

      // 4️⃣ Comparar timestamps
      final localTimestamp = await _dao
          .obtenerUltimaActualizacionDistribuidoresDrift();
      final remoto = await _service.comprobarActualizacionesOnline();

      print(
        '[⏱️ DISTRIBUIDORES PROVIDER] Remoto:$remoto | Local:$localTimestamp',
      );

      // 5️⃣ Si Supabase está vacío → usar solo local
      if (remoto == null) {
        print(
          '[📴 DISTRIBUIDORES PROVIDER] ⚠️ Supabase vacío → usar solo local',
        );
        return;
      }

      // 6️⃣ Si no hay cambios → mantener local
      if (localTimestamp != null) {
        final diff = remoto.difference(localTimestamp).inSeconds.abs();
        if (diff <= 1) {
          print('[📴 DISTRIBUIDORES PROVIDER] ✅ Sin cambios → mantener local');
          return;
        }
      }

      // 7️⃣ Hacer sync completo (push + pull)
      await _sync.pullDistribuidoresOnline(ultimaSync: localTimestamp);

      // 8️⃣ Cargar datos actualizados desde Drift
      final actualizados = await _dao.obtenerTodosDrift();
      state = actualizados;
    } catch (e) {
      print('[❌ DISTRIBUIDORES PROVIDER] Error al cargar distribuidores: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 Utilidades
  // ---------------------------------------------------------------------------

  /// ✅ Obtener distribuidor por UID (importante para pantallas de perfil)
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
    grupos.insert(0, 'Todos');
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

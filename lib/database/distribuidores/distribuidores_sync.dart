// ignore_for_file: avoid_print
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_dao.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_service.dart';

class DistribuidoresSync {
  final DistribuidoresDao _dao;
  final DistribuidoresService _service;

  DistribuidoresSync(AppDatabase db)
    : _dao = DistribuidoresDao(db),
      _service = DistribuidoresService(db);

  // ---------------------------------------------------------------------------
  // 📌 PUSH: Subir cambios locales pendientes
  // ---------------------------------------------------------------------------

  Future<void> pushDistribuidoresOffline() async {
    final pendientes = await _dao.obtenerPendientesSyncDrift();
    if (pendientes.isEmpty) {
      print(
        '[DISTRIBUIDORES SYNC] ✅ No hay distribuidores pendientes de subida',
      );
      return;
    }

    print(
      '[DISTRIBUIDORES SYNC] ⬆️ Subiendo ${pendientes.length} distribuidores offline...',
    );

    for (final dist in pendientes) {
      try {
        await _service.upsertDistribuidorOnline(dist);
        await _dao.marcarComoSincronizadoDrift([dist.uid]);
        print('[DISTRIBUIDORES SYNC] ✅ Distribuidor ${dist.uid} sincronizado');
      } catch (e) {
        print('[DISTRIBUIDORES SYNC] ❌ Error subiendo ${dist.uid}: $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 PULL: Descargar cambios online y aplicarlos localmente
  // ---------------------------------------------------------------------------

  Future<void> pullDistribuidoresOnline({DateTime? ultimaSync}) async {
    print('[DISTRIBUIDORES SYNC] ⬇️ Descargando cambios desde Supabase...');
    try {
      final lista = await _service.obtenerFiltradosOnline(
        ultimaSync: ultimaSync,
      );
      await _dao.upsertDistribuidoresDrift(lista);
      print(
        '[DISTRIBUIDORES SYNC] ✅ Descargados ${lista.length} distribuidores',
      );
    } catch (e) {
      print('[DISTRIBUIDORES SYNC] ❌ Error al descargar distribuidores: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 SYNC COMPLETO: Push + Pull
  // ---------------------------------------------------------------------------

  Future<void> syncDistribuidores({DateTime? ultimaSync}) async {
    print(
      '[DISTRIBUIDORES SYNC] 🔄 Iniciando sincronización de distribuidores...',
    );
    await pushDistribuidoresOffline();
    await pullDistribuidoresOnline(ultimaSync: ultimaSync);
    print(
      '[DISTRIBUIDORES SYNC] ✅ Sincronización de distribuidores finalizada',
    );
  }
}

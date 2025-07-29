// ignore_for_file: avoid_print
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/usuarios/usuarios_dao.dart';
import 'package:myafmzd/database/usuarios/usuarios_service.dart';

class UsuarioSync {
  final UsuariosDao _dao;
  final UsuarioService _service;

  UsuarioSync(AppDatabase db)
    : _dao = UsuariosDao(db),
      _service = UsuarioService(db);

  // ---------------------------------------------------------------------------
  // 📌 Push: Subir cambios locales pendientes
  // ---------------------------------------------------------------------------

  Future<void> pushUsuariosOffline() async {
    final pendientes = await _dao.obtenerPendientesSyncDrift();
    if (pendientes.isEmpty) {
      print('[⬆️ USUARIOS SYNC] ✅ No hay usuarios pendientes de subida');
      return;
    }

    print(
      '[⬆️ USUARIOS SYNC] ⬆️ Subiendo ${pendientes.length} usuarios offline...',
    );

    for (final usuario in pendientes) {
      try {
        await _service.upsertUsuarioOnline(usuario);
        await _dao.marcarComoSincronizadoDrift([usuario.uid]);
        print('[⬆️ USUARIOS SYNC] ✅ Usuario ${usuario.uid} sincronizado');
      } catch (e) {
        print('[⬆️ USUARIOS SYNC] ❌ Error subiendo ${usuario.uid}: $e');
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 Pull: Descargar cambios online y aplicarlos localmente
  // ---------------------------------------------------------------------------

  Future<void> pullUsuariosOnline({DateTime? ultimaSync}) async {
    print('[⬇️ USUARIOS SYNC] ⬇️ Descargando cambios desde Supabase...');
    try {
      final lista = await _service.obtenerFiltradosOnline(
        ultimaSync: ultimaSync,
      );
      await _dao.upsertUsuariosDrift(lista);
      print('[⬇️ USUARIOS SYNC] ✅ Descargados ${lista.length} usuarios');
    } catch (e) {
      print('[⬇️ USUARIOS SYNC] ❌ Error al descargar usuarios: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 Sync completo: Push + Pull
  // ---------------------------------------------------------------------------

  Future<void> syncUsuarios({DateTime? ultimaSync}) async {
    print('[⬆️⬇️ USUARIOS SYNC] 🔄 Iniciando sincronización de usuarios...');
    await pushUsuariosOffline();
    await pullUsuariosOnline(ultimaSync: ultimaSync);
    print('[⬆️⬇️ USUARIOS SYNC] ✅ Sincronización de usuarios finalizada');
  }
}

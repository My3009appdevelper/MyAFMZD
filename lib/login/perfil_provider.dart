// ignore_for_file: avoid_print

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_dao.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_service.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_sync.dart';
import 'package:myafmzd/database/usuarios/usuarios_dao.dart';
import 'package:myafmzd/database/usuarios/usuarios_sync.dart';
import 'package:myafmzd/database/usuarios/usuarios_service.dart';
import 'package:myafmzd/main.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final perfilProvider = StateNotifierProvider<PerfilNotifier, UsuarioDb?>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PerfilNotifier(db);
});

class PerfilNotifier extends StateNotifier<UsuarioDb?> {
  PerfilNotifier(AppDatabase db)
    : _daoUsuarios = UsuariosDao(db),
      _syncUsuarios = UsuarioSync(db),
      _serviceUsuarios = UsuarioService(db),
      _daoDistribuidores = DistribuidoresDao(db),
      _syncDistribuidores = DistribuidoresSync(db),
      _serviceDistribuidores = DistribuidoresService(db),
      super(null);

  final UsuariosDao _daoUsuarios;
  final UsuarioSync _syncUsuarios;
  final UsuarioService _serviceUsuarios;

  final DistribuidoresDao _daoDistribuidores;
  final DistribuidoresSync _syncDistribuidores;
  final DistribuidoresService _serviceDistribuidores;

  /// ✅ Cargar perfil (offline-first)
  Future<void> cargarUsuario({required bool hayInternet}) async {
    print(
      '[🔃 PERFIL PROVIDER] 👀 Entrando a cargarUsuario (offline-first con timestamps)...',
    );

    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) {
      state = null;
      return;
    }
    final uid = authUser.id;
    print('[🔃 PERFIL PROVIDER] ✅ Usuario autenticado: $uid');

    try {
      // 1️⃣ Pintar siempre local primero
      final local = await _daoUsuarios.obtenerPorUidDrift(uid);
      if (local != null) {
        state = local;
        print('[🔃 PERFIL PROVIDER] 📦 Perfil cargado desde DB local');
      } else {
        print('[🔃 PERFIL PROVIDER] ⚠️ No hay perfil local');
      }

      // 2️⃣ Si no hay internet → detenerse aquí
      if (!hayInternet) {
        print('[🔃 PERFIL PROVIDER] 📴 Sin internet → mantener local');
        return;
      }

      if (local != null) {
        state = local;
      }
    } catch (e) {
      print('[🔃 PERFIL PROVIDER] ❌ Error cargando perfil: $e');
      state = null;
    }
  }

  void limpiarUsuario() {
    state = null;
  }
}

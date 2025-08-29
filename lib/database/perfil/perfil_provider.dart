// ignore_for_file: avoid_print

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/database_provider.dart';
import 'package:myafmzd/database/usuarios/usuarios_dao.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final perfilProvider = StateNotifierProvider<PerfilNotifier, UsuarioDb?>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return PerfilNotifier(ref, db);
});

class PerfilNotifier extends StateNotifier<UsuarioDb?> {
  PerfilNotifier(this._ref, AppDatabase db)
    : _daoUsuarios = UsuariosDao(db),
      super(null);

  final Ref _ref;
  final UsuariosDao _daoUsuarios;

  bool _hayInternet = true;
  bool get hayInternet => _hayInternet;

  /// ✅ Cargar perfil (offline-first)
  Future<void> cargarUsuario() async {
    if (!mounted) return;
    print(
      '[🫵🏼 MENSAJES PERFIL PROVIDER] 👀 Entrando a cargarUsuario (offline-first con timestamps)...',
    );

    final authUser = Supabase.instance.client.auth.currentUser;
    if (authUser == null) {
      state = null;
      return;
    }
    final uid = authUser.id;
    print('[🫵🏼 MENSAJES PERFIL PROVIDER] ✅ Usuario autenticado: $uid');

    try {
      _hayInternet = _ref.read(connectivityProvider);

      // 1️⃣ Pintar siempre local primero
      final local = await _daoUsuarios.obtenerPorUidDrift(uid);
      if (local != null) {
        state = local;
        print(
          '[🫵🏼 MENSAJES PERFIL PROVIDER] 📦 Perfil cargado desde DB local',
        );
      } else {
        print('[🫵🏼 MENSAJES PERFIL PROVIDER] ⚠️ No hay perfil local');
      }

      // 2️⃣ Si no hay internet → detenerse aquí
      if (!hayInternet) {
        print(
          '[🫵🏼 MENSAJES PERFIL PROVIDER] 📴 Sin internet → mantener local',
        );
        return;
      }

      if (local != null) {
        state = local;
      }
    } catch (e) {
      print('[🫵🏼 MENSAJES PERFIL PROVIDER] ❌ Error cargando perfil: $e');
      state = null;
    }
  }

  void limpiarUsuario() {
    state = null;
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/usuario_model.dart';

final perfilProvider = StateNotifierProvider<PerfilProvider, UsuarioModel?>((
  ref,
) {
  return PerfilProvider();
});

class PerfilProvider extends StateNotifier<UsuarioModel?> {
  PerfilProvider() : super(null);

  bool _yaCargado = false;

  Future<void> cargarUsuario({
    required bool hayInternet,
    bool forzar = false,
  }) async {
    print('👀 Entrando a cargarUsuario...');

    if (_yaCargado && !forzar) {
      print(
        '🛑 ARCHIVOS[Provider] Ya estaba cargado y no se fuerza. Cancelando lectura.',
      );
      return;
    }

    final authUser = FirebaseAuth.instance.currentUser;
    print('Cargando usuario desde Firebase: ${authUser?.uid}');
    if (authUser == null) {
      state = null;
      return;
    }
    print('✅ Cargando usuario desde Firebase: ${authUser.uid}');
    final uid = authUser.uid;

    final source = hayInternet ? Source.server : Source.cache;

    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(uid)
        .get(GetOptions(source: source));

    if (!doc.exists) {
      state = null;
      return;
    }

    final data = doc.data();
    if (data == null) {
      state = null;
      return;
    }

    state = UsuarioModel.fromMap(uid, data);
    _yaCargado = true;
  }

  void limpiarUsuario() {
    state = null;
    _yaCargado = false;
  }
}

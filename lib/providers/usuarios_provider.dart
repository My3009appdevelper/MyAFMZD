import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/models/usuario_model.dart';
import 'package:myafmzd/services/usuario_service.dart';

final usuariosProvider =
    StateNotifierProvider<UsuariosNotifier, List<UsuarioModel>>((ref) {
      return UsuariosNotifier();
    });

class UsuariosNotifier extends StateNotifier<List<UsuarioModel>> {
  UsuariosNotifier() : super([]);

  final _servicio = UsuarioService();
  bool _yaCargado = false;
  bool get yaCargado => _yaCargado;

  Future<void> cargar({required bool hayInternet, bool forzar = false}) async {
    if (_yaCargado && !forzar) {
      print(
        '🛑 ARCHIVOSUSUARIOS[Provider] Ya estaba cargado y no se fuerza. Cancelando...',
      );
      return;
    }

    final desdeCache = await _servicio.leerDesdeCache();

    if (hayInternet) {
      final desdeFirebase = await _servicio.leerDesdeServidor();
      final iguales = _listasIguales(desdeCache, desdeFirebase);

      if (!iguales) {
        print(
          '🆕 ARCHIVOSUSUARIOS Cambios detectados en Firebase, sincronizando...',
        );
        state = desdeFirebase;
        _yaCargado = true;
        return;
      }

      print('✅ ARCHIVOSUSUARIOS Firebase y caché están sincronizados');
    }

    if (desdeCache.isNotEmpty) {
      print('📦 ARCHIVOSUSUARIOS Usando caché local');
    } else {
      print('⚠️ ARCHIVOSUSUARIOS Sin conexión y sin caché previa');
    }

    state = desdeCache;
    _yaCargado = true;
  }

  UsuarioModel? obtenerPorUid(String uid) {
    return state.firstWhere((u) => u.uid == uid);
  }

  void limpiar() {
    _yaCargado = false;
    state = [];
  }

  bool _listasIguales(List<UsuarioModel> a, List<UsuarioModel> b) {
    if (a.length != b.length) return false;
    a.sort((x, y) => x.uid.compareTo(y.uid));
    b.sort((x, y) => x.uid.compareTo(y.uid));
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  Future<void> crearUsuarioConAuth({
    required String nombre,
    required String correo,
    required String contrasena,
    required String rol,
    required String uuidDistribuidora,
    required Map<String, bool> permisos,
    required String correoAdmin,

    required String contrasenaAdmin,
  }) async {
    final nuevo = await _servicio.crearUsuarioEnAuthYFirestore(
      nombre: nombre,
      correo: correo,
      contrasena: contrasena,
      rol: rol,
      uuidDistribuidora: uuidDistribuidora,
      permisos: permisos,
      correoAdmin: correoAdmin,
      contrasenaAdmin: contrasenaAdmin,
    );

    state = [...state, nuevo];
  }

  Future<void> editarUsuario(UsuarioModel usuario) async {
    await _servicio.actualizarUsuario(usuario);
    final index = state.indexWhere((u) => u.uid == usuario.uid);
    if (index != -1) {
      final nuevaLista = [...state];
      nuevaLista[index] = usuario;
      state = nuevaLista;
    }
  }

  Future<void> eliminarUsuario(String uid) async {
    await _servicio.eliminarUsuario(uid);
    state = state.where((u) => u.uid != uid).toList();
  }
}

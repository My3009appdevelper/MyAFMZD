import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/actualizaciones/actualizaciones_dao.dart';
import 'package:myafmzd/main.dart';
import 'package:myafmzd/database/usuarios/usuario_service.dart';

final usuariosProvider = StateNotifierProvider<UsuariosNotifier, List<Usuario>>(
  (ref) {
    final db = ref.watch(appDatabaseProvider); // ✅ usa la DB global
    return UsuariosNotifier(db);
  },
);

class UsuariosNotifier extends StateNotifier<List<Usuario>> {
  UsuariosNotifier(AppDatabase db)
    : _servicio = UsuarioService(db),
      _daoActualizaciones = ActualizacionesDao(db),
      super([]);

  final UsuarioService _servicio;
  final ActualizacionesDao _daoActualizaciones; // ✅ usa la misma DB

  bool _yaCargado = false;
  bool get yaCargado => _yaCargado;

  Future<void> cargar({required bool hayInternet, bool forzar = false}) async {
    if (_yaCargado && !forzar) {
      print('🛑 [PROVIDER USUARIOS] Ya cargado y no se fuerza. Cancelando...');
      return;
    }

    try {
      // ✅ 1. Leer siempre Drift local primero (offline inmediato)
      final local = await _servicio.leerLocal();
      state = local;
      print('📴 [PROVIDER USUARIOS] 1 Leyendo local siempre');

      if (!hayInternet) {
        print('📴 [PROVIDER USUARIOS] 2 Sin internet, usando solo local');
        _yaCargado = true;
        return;
      }

      // ✅ 2. Comprobar timestamp remoto
      final remoto = await _servicio.comprobarActualizaciones();
      final localTimestamp = await _daoActualizaciones.obtenerUltimaSync(
        'usuarios',
      );

      if (!forzar && remoto != null && localTimestamp != null) {
        if (!remoto.isAfter(localTimestamp) ||
            remoto.isAtSameMomentAs(localTimestamp)) {
          print('✅ [PROVIDER USUARIOS] Sin cambios en Firebase, usando local');
          _yaCargado = true;
          return;
        }
      }

      // ✅ 3. Si hay cambios o es forzado → descargar servidor
      final desdeServidor = await _servicio.leerDesdeServidor(
        ultimaSync: localTimestamp,
      );
      state = desdeServidor;

      // ✅ 4. Guardar timestamp de sync
      if (remoto != null) {
        await _daoActualizaciones.guardarUltimaSync('usuarios', remoto);
        print('💾 [PROVIDER USUARIOS] Timestamp actualizado: $remoto');
      }

      _yaCargado = true;
    } catch (e) {
      print('❌ [PROVIDER USUARIOS] Error al cargar usuarios: $e');
      // fallback a local, ya que state se cargó al inicio
      _yaCargado = true;
    }
  }

  Usuario? obtenerPorUid(String uid) {
    return state.firstWhere((u) => u.uid == uid);
  }

  void limpiar() {
    _yaCargado = false;
    state = [];
  }

  /// ✅ Crear usuario
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

  /// ✅ Editar usuario
  Future<void> editarUsuario(Usuario usuario) async {
    await _servicio.actualizarUsuario(usuario);
    final index = state.indexWhere((u) => u.uid == usuario.uid);
    if (index != -1) {
      final nuevaLista = [...state];
      nuevaLista[index] = usuario;
      state = nuevaLista;
    }
  }

  /// ✅ Eliminar usuario
  Future<void> eliminarUsuario(String uid) async {
    await _servicio.eliminarUsuario(uid);
    state = state.where((u) => u.uid != uid).toList();
  }
}

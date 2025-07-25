import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drift/drift.dart' hide Query;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myafmzd/database/usuarios/usuarios_dao.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/models/usuario_model.dart';

class UsuarioService {
  final _coleccion = FirebaseFirestore.instance.collection('usuarios');
  final _actualizaciones = FirebaseFirestore.instance.collection(
    'actualizaciones',
  );
  final UsuariosDao _dao;
  UsuarioService(AppDatabase db) : _dao = UsuariosDao(db);

  /// ✅ 1. Comprobar si hay actualizaciones en Firebase
  Future<DateTime?> comprobarActualizaciones() async {
    try {
      print(
        '[MENSAJE: USER SERVICE] 🔄 Consultando timestamp de actualizaciones...',
      );
      final doc = await _actualizaciones.doc('usuarios').get();
      final data = doc.data();
      if (data == null || !data.containsKey('ultimaActualizacion')) {
        print('[MENSAJE: USER SERVICE] ⚠️ No hay timestamp en Firebase.');
        return null;
      }
      final timestamp = (data['ultimaActualizacion'] as Timestamp).toDate();
      print(
        '[MENSAJE: USER SERVICE] 🔄 Última actualización en Firebase desde usuarios: $timestamp',
      );
      return timestamp;
    } on FirebaseException catch (e) {
      print(
        '[MENSAJE: USER SERVICE] ❌ Error Firebase al comprobar actualizaciones desde usuarios: ${e.code} - ${e.message}',
      );
      return null; // no rethrow, no es crítico
    } catch (e) {
      print(
        '[MENSAJE: USER SERVICE] ❌ Error inesperado al comprobar actualizaciones desde usuarios: $e',
      );
      return null;
    }
  }

  /// ✅ 2. Leer local (Drift)
  Future<List<Usuario>> leerLocal() async {
    try {
      print('[MENSAJE: USER SERVICE] 📦 Leyendo usuarios desde DB local...');
      final usuarios = await _dao.obtenerTodos();
      print('[MENSAJE: USER SERVICE] 📦 Local -> ${usuarios.length} usuarios');
      return usuarios;
    } catch (e) {
      print(
        '[MENSAJE: USER SERVICE] ❌ Error leyendo DB local desde usuarios: $e',
      );
      rethrow;
    }
  }

  /// ✅ 3. Leer desde Firebase (server) y sincronizar Drift
  Future<List<Usuario>> leerDesdeServidor({DateTime? ultimaSync}) async {
    try {
      print(
        '[MENSAJE: USER SERVICE] 📡 Leyendo usuarios desde Firebase SERVER...',
      );

      Query query = _coleccion;
      if (ultimaSync != null) {
        query = query.where('updatedAt', isGreaterThan: ultimaSync);
        print(
          '[MENSAJE: USER SERVICE] 🔄 Delta Sync desde usuarios desde : $ultimaSync',
        );
      }

      final snapshot = await query.get(const GetOptions(source: Source.server));

      final lista = snapshot.docs
          .map(
            (doc) => UsuarioModel.fromMap(
              doc.id,
              doc.data() as Map<String, dynamic>, // 👈 casteo explícito
            ),
          )
          .map(_mapToDrift)
          .toList();

      if (ultimaSync == null) {
        // Si es la primera carga, borramos todo para que la DB local sea un espejo
        await _dao.eliminarTodos();
      }

      await _dao.upsertUsuarios(lista);

      print(
        '[MENSAJE: USER SERVICE] 📡 Server -> ${lista.length} cambios sincronizados desde usuarios',
      );
      return lista;
    } on FirebaseException catch (e) {
      print(
        '[MENSAJE: USER SERVICE] ❌ Error Firebase al leer SERVER desde usuarios: ${e.code} - ${e.message}',
      );
      rethrow;
    } catch (e) {
      print(
        '[MENSAJE: USER SERVICE] ❌ Error inesperado leyendo SERVER desde usuarios: $e',
      );
      rethrow;
    }
  }

  /// ✅ 4. Obtener por UID (offline-first)
  Future<Usuario?> obtenerPorUid(String uid) async {
    try {
      print('[MENSAJE: USER SERVICE] 🔍 Buscando usuario $uid local...');
      final local = await _dao.obtenerPorUid(uid);
      if (local != null) return local;

      print(
        '[MENSAJE: USER SERVICE] ⚠️ No encontrado local desde usuarios, buscando en Firebase...',
      );
      final doc = await _coleccion.doc(uid).get();
      final data = doc.data();
      if (!doc.exists || data == null) {
        print('[MENSAJE: USER SERVICE] ❌ Usuario $uid no existe en Firebase');
        return null;
      }

      final usuario = UsuarioModel.fromMap(doc.id, data);
      final driftUser = _mapToDrift(usuario);
      await _dao.upsertUsuario(driftUser);
      return driftUser;
    } on FirebaseException catch (e) {
      print(
        '[MENSAJE: USER SERVICE] ❌ Error Firebase obtenerPorUid desde usuarios: ${e.code} - ${e.message}',
      );
      rethrow;
    } catch (e) {
      print(
        '[MENSAJE: USER SERVICE] ❌ Error inesperado obtenerPorUid desde usuarios: $e',
      );
      rethrow;
    }
  }

  /// ✅ 5. Crear usuario online y sincronizar Drift (con rollback)
  Future<Usuario> crearUsuarioEnAuthYFirestore({
    required String nombre,
    required String correo,
    required String contrasena,
    required String rol,
    required String uuidDistribuidora,
    required Map<String, bool> permisos,
    required String correoAdmin,
    required String contrasenaAdmin,
  }) async {
    print('[MENSAJE: USER SERVICE] 🆕 Creando usuario en Firebase...');
    final primaryAuth = FirebaseAuth.instance;
    UserCredential? newUserCred;

    try {
      final tempAuth = FirebaseAuth.instanceFor(app: primaryAuth.app);
      await tempAuth.signInWithEmailAndPassword(
        email: correoAdmin,
        password: contrasenaAdmin,
      );

      newUserCred = await primaryAuth.createUserWithEmailAndPassword(
        email: correo,
        password: contrasena,
      );
      final uidNuevo = newUserCred.user!.uid;

      // ✅ Para Drift local puedes usar DateTime.now()
      final usuario = Usuario(
        uid: uidNuevo,
        nombre: nombre,
        correo: correo,
        rol: rol,
        uuidDistribuidora: uuidDistribuidora,
        permisos: permisos,
        updatedAt: DateTime.now(), // Solo local
      );

      // ✅ En Firestore usamos serverTimestamp()
      await _coleccion.doc(uidNuevo).set({
        ..._mapFromDrift(usuario),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _actualizaciones.doc('usuarios').set({
        'ultimaActualizacion': FieldValue.serverTimestamp(),
      });

      try {
        await _dao.upsertUsuario(usuario);
      } catch (e) {
        // 🔄 Si falla Drift, revertimos para que todo quede consistente
        await _coleccion.doc(uidNuevo).delete();
        await newUserCred.user!.delete();
        rethrow;
      }

      await primaryAuth.signOut();
      await primaryAuth.signInWithEmailAndPassword(
        email: correoAdmin,
        password: contrasenaAdmin,
      );

      print(
        '[MENSAJE: USER SERVICE] ✅ Usuario $uidNuevo creado y sincronizado local',
      );
      return usuario;
    } on FirebaseAuthException catch (e) {
      print(
        '[MENSAJE: USER SERVICE] ❌ Error FirebaseAuth crearUsuario: ${e.code} - ${e.message}',
      );
      rethrow;
    } catch (e) {
      print('[MENSAJE: USER SERVICE] ❌ Error inesperado crearUsuario: $e');
      if (newUserCred?.user != null) {
        try {
          await newUserCred!.user!.delete();
          print('[MENSAJE: USER SERVICE] 🔄 Rollback: Usuario Auth eliminado');
        } catch (rb) {
          print('[MENSAJE: USER SERVICE] ⚠️ Error rollback usuario Auth: $rb');
        }
      }
      rethrow;
    }
  }

  /// ✅ 6. Actualizar usuario
  Future<void> actualizarUsuario(Usuario usuario) async {
    try {
      await _coleccion.doc(usuario.uid).update({
        ..._mapFromDrift(usuario),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _actualizaciones.doc('usuarios').set({
        'ultimaActualizacion': FieldValue.serverTimestamp(),
      });
      await _dao.upsertUsuario(
        usuario.copyWith(updatedAt: Value(DateTime.now())),
      );
      print('[MENSAJE: USER SERVICE] ♻️ Usuario ${usuario.uid} actualizado');
    } catch (e) {
      print('[MENSAJE: USER SERVICE] ❌ Error actualizarUsuario: $e');
      rethrow;
    }
  }

  /// ✅ 7. Eliminar usuario
  Future<void> eliminarUsuario(String uid) async {
    try {
      await _coleccion.doc(uid).delete();
      await _dao.eliminarPorUid(uid);

      await _actualizaciones.doc('usuarios').set({
        'ultimaActualizacion': FieldValue.serverTimestamp(),
      });
      print('[MENSAJE: USER SERVICE] 🗑️ Usuario $uid eliminado');
    } on FirebaseException catch (e) {
      print(
        '[MENSAJE: USER SERVICE] ❌ Error Firebase eliminarUsuario: ${e.code} - ${e.message}',
      );
      rethrow;
    } catch (e) {
      print('[MENSAJE: USER SERVICE] ❌ Error inesperado eliminarUsuario: $e');
      rethrow;
    }
  }

  /// 🔄 Mapper: UsuarioModel → Usuario (Drift)
  Usuario _mapToDrift(UsuarioModel model) {
    return Usuario(
      uid: model.uid,
      nombre: model.nombre,
      correo: model.correo,
      rol: model.rol,
      uuidDistribuidora: model.uuidDistribuidora,
      permisos: model.permisos,
      updatedAt: model.updatedAt,
    );
  }

  /// 🔄 Mapper: Usuario (Drift) → Map para Firebase
  Map<String, dynamic> _mapFromDrift(Usuario usuario) {
    return {
      'nombre': usuario.nombre,
      'correo': usuario.correo,
      'rol': usuario.rol,
      'uuidDistribuidora': usuario.uuidDistribuidora,
      'permisos': usuario.permisos,
    };
  }
}

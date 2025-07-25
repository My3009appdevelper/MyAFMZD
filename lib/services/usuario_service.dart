import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:myafmzd/models/usuario_model.dart';

class UsuarioService {
  final _coleccion = FirebaseFirestore.instance.collection('usuarios');

  Future<List<UsuarioModel>> leerDesdeCache() async {
    print('📦 ARCHIVOS[CACHE] Leyendo usuarios desde caché local...');
    final snapshot = await _coleccion.get(
      const GetOptions(source: Source.cache),
    );
    print('📦 [CACHE] Leídos ${snapshot.docs.length} usuarios desde caché.');
    return snapshot.docs
        .map((doc) => UsuarioModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<List<UsuarioModel>> leerDesdeServidor() async {
    print('📡 ARCHIVOS[FIREBASE] Leyendo usuarios desde Firebase...');
    final snapshot = await _coleccion.get(
      const GetOptions(source: Source.serverAndCache),
    );
    print(
      '📡 ARCHIVOS[FIREBASE] Leídos ${snapshot.docs.length} usuarios desde servidor.',
    );
    return snapshot.docs
        .map((doc) => UsuarioModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<UsuarioModel?> obtenerPorUid(String uid) async {
    print('📡 ARCHIVOS[FIREBASE] Buscando usuario con UID $uid');
    final doc = await _coleccion.doc(uid).get();
    if (!doc.exists) {
      print('⚠️ ARCHIVOS[FIREBASE] No se encontró el usuario $uid');
      return null;
    }
    print('📡 ARCHIVOS[FIREBASE] Usuario $uid encontrado.');
    return UsuarioModel.fromMap(doc.id, doc.data()!);
  }

  Future<UsuarioModel> crearUsuarioEnAuthYFirestore({
    required String nombre,
    required String correo,
    required String contrasena,
    required String rol,
    required String uuidDistribuidora,
    required Map<String, bool> permisos,
    required String correoAdmin,
    required String contrasenaAdmin,
  }) async {
    final primaryAuth = FirebaseAuth.instance;

    try {
      // 1. Crear nueva instancia de FirebaseAuth para verificar admin
      final tempAuth = FirebaseAuth.instanceFor(app: primaryAuth.app);

      // 2. Verificar credenciales del admin (sin afectar sesión actual)
      final adminCred = await tempAuth.signInWithEmailAndPassword(
        email: correoAdmin,
        password: contrasenaAdmin,
      );
      print('✅ Credenciales del admin válidas: ${adminCred.user?.email}');

      // 3. Crear el nuevo usuario (esto sí cambia la sesión global)
      final newUserCred = await primaryAuth.createUserWithEmailAndPassword(
        email: correo,
        password: contrasena,
      );
      final uidNuevo = newUserCred.user!.uid;

      // 4. Guardar en Firestore
      final usuario = UsuarioModel(
        uid: uidNuevo,
        nombre: nombre,
        correo: correo,
        rol: rol,
        uuidDistribuidora: uuidDistribuidora,
        permisos: permisos,
      );
      await _coleccion.doc(uidNuevo).set(usuario.toMap());
      print('📦 Usuario guardado en Firestore: $uidNuevo');

      // 5. Reautenticarse como admin para restaurar sesión original
      await primaryAuth.signOut();
      await primaryAuth.signInWithEmailAndPassword(
        email: correoAdmin,
        password: contrasenaAdmin,
      );
      print('🔄 Reautenticado como admin principal');

      return usuario;
    } on FirebaseAuthException catch (e) {
      print('❌ FirebaseAuth error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('❌ Error inesperado: $e');
      rethrow;
    }
  }

  Future<void> actualizarUsuario(UsuarioModel usuario) async {
    await _coleccion.doc(usuario.uid).update(usuario.toMap());
    print('♻️ Usuario ${usuario.uid} actualizado.');
  }

  Future<void> eliminarUsuario(String uid) async {
    await _coleccion.doc(uid).delete();
    print('🗑️ Usuario $uid eliminado.');
  }
}

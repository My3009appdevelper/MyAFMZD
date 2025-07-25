import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myafmzd/models/distribuidor_model.dart';

class DistribuidorService {
  final _coleccion = FirebaseFirestore.instance.collection('distribuidoras');

  Future<List<Distribuidor>> leerDesdeCache() async {
    print('📦 ARCHIVOS[CACHE] Leyendo distribuidores desde caché local...');
    final query = await _coleccion.get(const GetOptions(source: Source.cache));
    print('📦 [CACHE] Leídos ${query.docs.length} distribuidores desde caché.');
    return query.docs
        .map((doc) => Distribuidor.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  Future<List<Distribuidor>> leerDesdeServidor() async {
    print('📡 ARCHIVOS[FIREBASE] Leyendo distribuidores desde Firebase...');
    final query = await _coleccion.get(
      const GetOptions(source: Source.serverAndCache),
    );
    print(
      '📡 ARCHIVOS[FIREBASE] Leídos ${query.docs.length} distribuidores desde servidor.',
    );
    return query.docs
        .map((doc) => Distribuidor.fromMap(doc.data(), id: doc.id))
        .toList();
  }

  Future<Distribuidor?> obtenerPorUuid(String uuid) async {
    print('📡 ARCHIVOS[FIREBASE] Buscando distribuidor con UUID $uuid');
    final doc = await _coleccion.doc(uuid).get();
    if (!doc.exists) {
      print('⚠️ ARCHIVOS[FIREBASE] No se encontró el distribuidor $uuid');
      return null;
    }
    print('📡 ARCHIVOS[FIREBASE] Distribuidor $uuid encontrado.');
    return Distribuidor.fromMap(doc.data()!, id: doc.id);
  }
}

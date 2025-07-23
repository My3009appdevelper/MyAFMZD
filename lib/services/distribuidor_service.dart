import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myafmzd/models/distribuidor_model.dart';

class DistribuidorService {
  final _coleccion = FirebaseFirestore.instance.collection('distribuidoras');

  Future<List<Distribuidor>> cargarDistribuidores() async {
    try {
      final query = await _coleccion.get();
      print("¿Viene del caché? ${query.metadata.isFromCache}");

      return query.docs.map((doc) {
        final data = doc.data();
        return Distribuidor.fromJson(data);
      }).toList();
    } catch (e) {
      print('❌ Error al cargar distribuidores desde Firestore: $e');
      return [];
    }
  }
}

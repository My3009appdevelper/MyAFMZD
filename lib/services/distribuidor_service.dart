import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:myafmzd/models/distribuidor_model.dart';

class DistribuidorService {
  Future<List<Distribuidor>> cargarDistribuidores() async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/distribuidores.json',
      );
      final List<dynamic> data = json.decode(jsonString);
      return data.map((e) => Distribuidor.fromJson(e)).toList();
    } catch (e) {
      print('❌ Error cargando distribuidores: $e');
      return [];
    }
  }
}

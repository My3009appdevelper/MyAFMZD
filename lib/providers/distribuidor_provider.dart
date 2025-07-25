import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/models/distribuidor_model.dart';
import 'package:myafmzd/services/distribuidor_service.dart';

final distribuidoresProvider =
    StateNotifierProvider<DistribuidoresNotifier, List<Distribuidor>>((ref) {
      return DistribuidoresNotifier();
    });

class DistribuidoresNotifier extends StateNotifier<List<Distribuidor>> {
  DistribuidoresNotifier() : super([]);

  final _servicio = DistribuidorService();
  bool _yaCargado = false;
  bool get yaCargado => _yaCargado;

  Future<void> cargar({required bool hayInternet, bool forzar = false}) async {
    if (_yaCargado && !forzar) {
      print(
        '🛑 ARCHIVOS[Provider] Ya estaba cargado y no se fuerza. Cancelando lectura.',
      );
      return;
    }

    final desdeCache = await _servicio.leerDesdeCache();

    if (hayInternet) {
      final desdeFirebase = await _servicio.leerDesdeServidor();
      final iguales = _listasIguales(desdeCache, desdeFirebase);

      if (!iguales) {
        print(
          "🆕 ARCHIVOS Cambios detectados en Firebase, sincronizando estado...",
        );
        state = desdeFirebase;
        _yaCargado = true;
        return;
      }

      print("✅ ARCHIVOSFirebase y caché están sincronizados");
    }

    if (desdeCache.isNotEmpty) {
      print("📦 ARCHIVOSUsando caché local (modo offline o sincronizado)");
    } else {
      print("⚠️ ARCHIVOSSin conexión y sin caché previa");
    }

    state = desdeCache;
    _yaCargado = true;
  }

  Distribuidor? obtenerPorId(String id) {
    return state.firstWhere((d) => d.id == id);
  }

  List<String> get gruposUnicos {
    final grupos = state.map((d) => d.grupo).toSet().toList();
    grupos.sort();
    grupos.insert(0, 'Todos');
    return grupos;
  }

  List<Distribuidor> filtrar({required bool mostrarInactivos, String? grupo}) {
    return state.where((d) {
      final activoOk = mostrarInactivos || d.activo;
      final grupoOk = grupo == null || grupo == 'Todos' || d.grupo == grupo;
      return activoOk && grupoOk;
    }).toList()..sort((a, b) {
      if (a.activo != b.activo) return a.activo ? -1 : 1;
      return a.nombre.compareTo(b.nombre);
    });
  }

  bool _listasIguales(List<Distribuidor> a, List<Distribuidor> b) {
    if (a.length != b.length) return false;
    a.sort((x, y) => x.id.compareTo(y.id));
    b.sort((x, y) => x.id.compareTo(y.id));
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i] != b[i]) return false;
    }
    return true;
  }
}

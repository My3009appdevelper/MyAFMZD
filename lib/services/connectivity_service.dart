import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final InternetConnectionChecker _checker = InternetConnectionChecker();

  /// Verifica si hay una conexión real a Internet (no solo a una red).
  Future<bool> hasInternet() async {
    try {
      final result = await _connectivity.checkConnectivity();

      if (result == ConnectivityResult.none) return false;

      // Ahora verificamos si realmente tiene acceso a internet
      final internet = await _checker.hasConnection;
      return internet;
    } catch (e) {
      print('❌ Error verificando conexión: $e');
      return false;
    }
  }

  /// Verifica si el dispositivo está conectado a *algún tipo* de red.
  Future<bool> isConnectedToNetwork() async {
    try {
      final result = await _connectivity.checkConnectivity();
      return result != ConnectivityResult.none;
    } catch (e) {
      print('❌ Error verificando red física: $e');
      return false;
    }
  }
}

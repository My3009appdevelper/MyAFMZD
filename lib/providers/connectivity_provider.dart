// connectivity_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, bool>((
  ref,
) {
  return ConnectivityNotifier();
});

class ConnectivityNotifier extends StateNotifier<bool> {
  ConnectivityNotifier() : super(true) {
    _init();
  }

  final _checker = InternetConnectionChecker.createInstance();
  void _init() async {
    final initial = await _checkInternet();
    state = initial;

    Connectivity().onConnectivityChanged.listen((_) async {
      final online = await _checkInternet();
      state = online;
    });
  }

  Future<bool> _checkInternet() async {
    final result = await Connectivity().checkConnectivity();
    if (result == ConnectivityResult.none) return false;
    return await _checker.hasConnection;
  }
}

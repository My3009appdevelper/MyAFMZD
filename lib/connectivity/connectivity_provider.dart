// connectivity_provider.dart
import 'dart:async';
import 'package:flutter/widgets.dart'; // para addPostFrameCallback
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:internet_connection_checker/internet_connection_checker.dart';

final connectivityProvider = StateNotifierProvider<ConnectivityNotifier, bool>((
  ref,
) {
  return ConnectivityNotifier();
});

class ConnectivityNotifier extends StateNotifier<bool> {
  ConnectivityNotifier()
    : _connectivity = Connectivity(),
      _checker = InternetConnectionChecker.createInstance(),
      super(true) {
    _configureChecker();
    _init();
  }

  final Connectivity _connectivity;
  final InternetConnectionChecker _checker;

  StreamSubscription<List<ConnectivityResult>>? _connSub;
  Timer? _debounce;

  Future<void> refreshNow() async => _refresh();

  void _configureChecker() {
    // ➊ Chequeos rápidos y en paralelo; 700–900 ms suele ser buen equilibrio
    _checker.checkInterval = const Duration(seconds: 0); // sin polling interno
    _checker.checkTimeout = const Duration(milliseconds: 900);

    // ➋ 2–3 endpoints mixtos (uno HTTP 204, uno IP pura para saltar DNS)
    _checker.addresses = <AddressCheckOption>[
      AddressCheckOption(
        uri: Uri.parse('https://connectivitycheck.gstatic.com/generate_204'),
      ),
      AddressCheckOption(
        uri: Uri.parse('https://www.msftconnecttest.com/connecttest.txt'),
      ),
      AddressCheckOption(uri: Uri.parse('https://1.1.1.1')), // Cloudflare (IP)
    ];

    // Por defecto *NO* requiere que todas respondan (es lo ideal para UX).
    // _checker.requireAllAddressesToRespond = false; // (default)
  }

  Future<void> _init() async {
    // ➌ No bloquees el primer frame: corre el primer check justo después
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh(); // fire-and-forget
    });

    // ➍ Escucha cambios de interfaz de red con debounce corto y revalida reachability
    _connSub = _connectivity.onConnectivityChanged.listen((types) {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 250), () {
        _refresh(typesHint: types);
      });
    });
  }

  Future<void> _refresh({List<ConnectivityResult>? typesHint}) async {
    final types = typesHint ?? await _connectivity.checkConnectivity();

    // Sin interfaz → offline inmediato (no gastes tiempo en pings)
    if (types.contains(ConnectivityResult.none)) {
      if (state != false) state = false;
      return;
    }

    // ➎ “Fast path” optimista con timeout: si tarda demasiado, asume true y deja que tus requests fallen/reintenten
    final bool online = await _checker.hasConnection.timeout(
      const Duration(milliseconds: 1100),
      onTimeout: () => true,
    );

    if (state != online) state = online;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _connSub?.cancel();
    super.dispose();
  }
}

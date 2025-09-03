// connectivity_provider.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
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
  Timer? _pollingFallback; // 👈 fallback si el stream falla

  // Si tienes un backend, pon aquí tu health endpoint.
  static const String? _backendHealthUrl =
      null; // p.ej. 'https://api.tuapp.com/health'

  Future<void> refreshNow() async => _refresh();

  void _configureChecker() {
    _checker.checkInterval = const Duration(seconds: 0); // sin auto-polling
    _checker.checkTimeout = const Duration(milliseconds: 900);
    _checker.addresses = <AddressCheckOption>[
      AddressCheckOption(
        uri: Uri.parse('https://connectivitycheck.gstatic.com/generate_204'),
      ),
      AddressCheckOption(
        uri: Uri.parse('https://www.msftconnecttest.com/connecttest.txt'),
      ),
    ];
    // requireAllAddressesToRespond = false (default)
  }

  Future<void> _init() async {
    // Primer check después del primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refresh(); // fire-and-forget
    });

    // Suscríbete al stream con manejo de errores
    try {
      _connSub = _connectivity.onConnectivityChanged.listen(
        (types) {
          _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 250), () {
            _refresh(typesHint: types);
          });
        },
        onError: (error, stack) {
          // Si el nativo falla (p. ej. NetworkManager ausente), usa fallback
          _startPollingFallback();
        },
        cancelOnError: false,
      );
    } catch (_) {
      _startPollingFallback();
    }
  }

  void _startPollingFallback() {
    if (_pollingFallback != null) return; // ya corriendo
    // Poll suave: cada 5s revalida reachability (+ rápido si quieres)
    _pollingFallback = Timer.periodic(const Duration(seconds: 5), (_) {
      _refresh();
    });
  }

  Future<void> _refresh({List<ConnectivityResult>? typesHint}) async {
    final types = typesHint ?? await _connectivity.checkConnectivity();

    if (types.contains(ConnectivityResult.none)) {
      if (state != false) state = false;
      return;
    }

    // Reachability: tu backend > checker genérico
    bool online = false;
    if (_backendHealthUrl != null) {
      online = await _pingBackend(_backendHealthUrl!);
    } else {
      online = await _checker.hasConnection.timeout(
        const Duration(milliseconds: 1100),
        onTimeout: () => true,
      );
    }

    if (state != online) state = online;
  }

  // Ping muy rápido a tu backend (mejor señal en redes corporativas)
  Future<bool> _pingBackend(String url) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(milliseconds: 800);
    try {
      final req = await client
          .getUrl(Uri.parse(url))
          .timeout(const Duration(milliseconds: 800));
      req.followRedirects = false;
      final res = await req.close().timeout(const Duration(milliseconds: 800));
      // Cualquier <500 lo consideramos “hay salida” (200/204 ideal).
      return res.statusCode < 500;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _connSub?.cancel();
    _pollingFallback?.cancel();
    super.dispose();
  }
}

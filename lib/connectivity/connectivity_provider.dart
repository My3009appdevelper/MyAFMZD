// connectivity_provider.dart
import 'dart:async';
import 'dart:io' show HttpClient;
import 'package:flutter/foundation.dart' show kIsWeb;
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
      super(false) {
    _configureChecker();
    _init();
  }

  final Connectivity _connectivity;
  final InternetConnectionChecker _checker;

  StreamSubscription<List<ConnectivityResult>>? _connSub;
  Timer? _debounce;
  Timer? _pollingFallback; // fallback si el stream falla

  // Si tienes un backend propio con /health, ponlo aquí (mejor señal en redes corporativas).
  static const String? _backendHealthUrl =
      null; // p.ej. 'https://api.tuapp.com/health'

  // Endpoints HTTP “ligeros” para HEAD (preferidos sobre solo sockets/DNS).
  static const List<String> _httpProbeUrls = <String>[
    'https://connectivitycheck.gstatic.com/generate_204',
    'https://www.msftconnecttest.com/connecttest.txt',
    // Tu dominio (si responde con <500 es suficiente):
    'https://mazdautofinanciamiento.mx',
  ];

  // Timeouts afinados para redes reales
  static const _httpTimeout = Duration(milliseconds: 1500);
  static const _checkerTimeout = Duration(milliseconds: 1500);

  bool _firstCheckDone = false;
  bool get firstCheckDone => _firstCheckDone;

  Future<void> refreshNow() async => _refresh();

  void _configureChecker() {
    // Sin auto-polling; nosotros controlamos la cadencia
    _checker.checkInterval = const Duration(seconds: 0);
    _checker.checkTimeout = _checkerTimeout;
    // Mantén direcciones (el paquete hará TCP connect); pueden fallar en ciertos firewalls,
    // por eso primero probamos HEAD real (_httpProbeHeads).
    _checker.addresses = <AddressCheckOption>[
      AddressCheckOption(
        uri: Uri.parse('https://connectivitycheck.gstatic.com/generate_204'),
      ),
      AddressCheckOption(
        uri: Uri.parse('https://www.msftconnecttest.com/connecttest.txt'),
      ),
      AddressCheckOption(uri: Uri.parse('https://mazdautofinanciamiento.mx')),
    ];
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
          // 👇 Hot Restart a veces dispara PlatformException al abrir el canal
          // Silenciamos y activamos fallback por polling
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
    // Poll suave: cada 5s revalida reachability
    _pollingFallback = Timer.periodic(const Duration(seconds: 5), (_) {
      _refresh();
    });
  }

  Future<void> _refresh({List<ConnectivityResult>? typesHint}) async {
    List<ConnectivityResult> types;
    try {
      types = typesHint ?? await _connectivity.checkConnectivity();
    } catch (_) {
      // En plataformas donde falle el check, asumimos "alguna red" y verificamos por HTTP.
      types = const <ConnectivityResult>[];
    }

    // Si explícitamente no hay interfaz, marca offline y corta.
    if (types.contains(ConnectivityResult.none)) {
      if (state != false) state = false;
      return;
    }

    // Si estamos en Web, HttpClient no opera igual; usamos solo el checker + timeout.
    // (Si más adelante agregas paquete http, aquí podrías hacer fetch/head en web.)
    if (kIsWeb) {
      final online = await _checker.hasConnection.timeout(
        _checkerTimeout,
        onTimeout: () => false,
      );
      if (state != online) state = online;
      return;
    }

    // 1) Preferimos HEAD HTTP real a hosts públicos/propios (menos falsos negativos)
    bool online = await _httpProbeHeads();

    // 2) Si falla, intentamos como respaldo el checker por sockets/DNS
    if (!online) {
      try {
        online = await _checker.hasConnection.timeout(
          _checkerTimeout,
          onTimeout: () => false,
        );
      } catch (_) {
        online = false;
      }
    }

    // 3) (Opcional) si definiste backend propio, prueba primero tu /health
    if (_backendHealthUrl != null) {
      final okBackend = await _pingBackend(_backendHealthUrl!);
      // Si tu backend responde, fuerza online; si no, conserva lo detectado.
      if (okBackend) online = true;
    }

    if (state != online) state = online;
    _firstCheckDone = true;
  }

  // HEAD rápido contra varias URLs; éxito si cualquiera responde con <500.
  Future<bool> _httpProbeHeads() async {
    for (final url in _httpProbeUrls) {
      final ok = await _head(url);
      if (ok) return true;
    }
    return false;
  }

  Future<bool> _head(String url) async {
    final client = HttpClient()..connectionTimeout = _httpTimeout;
    try {
      final uri = Uri.parse(url);
      // Muchos endpoints 204 aceptan GET y HEAD; algunos bloquean HEAD.
      // Intentamos HEAD y si responde 405/501, caemos a GET light.
      final headReq = await client.openUrl('HEAD', uri).timeout(_httpTimeout);
      headReq.followRedirects = false;
      final headRes = await headReq.close().timeout(_httpTimeout);
      if (headRes.statusCode < 500) return true;

      if (headRes.statusCode == 405 || headRes.statusCode == 501) {
        final getReq = await client.getUrl(uri).timeout(_httpTimeout);
        getReq.followRedirects = false;
        final getRes = await getReq.close().timeout(_httpTimeout);
        if (getRes.statusCode < 500) return true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  // Ping rápido a tu backend (si lo defines)
  Future<bool> _pingBackend(String url) async {
    final client = HttpClient()
      ..connectionTimeout = const Duration(milliseconds: 1200);
    try {
      final req = await client
          .getUrl(Uri.parse(url))
          .timeout(const Duration(milliseconds: 1200));
      req.followRedirects = false;
      final res = await req.close().timeout(const Duration(milliseconds: 1200));
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

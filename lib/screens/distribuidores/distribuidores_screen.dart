import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/screens/distribuidores/distribuidores_form_page.dart';
import 'package:myafmzd/screens/distribuidores/distribuidores_popup.dart';
import 'package:myafmzd/screens/distribuidores/distribuidores_tile.dart';
import 'package:myafmzd/widgets/my_loader_overlay.dart';

class DistribuidoresScreen extends ConsumerStatefulWidget {
  const DistribuidoresScreen({super.key});
  @override
  ConsumerState<DistribuidoresScreen> createState() =>
      _DistribuidoresScreenState();
}

class _DistribuidoresScreenState extends ConsumerState<DistribuidoresScreen>
    with TickerProviderStateMixin {
  final PopupController _popupController = PopupController();
  bool _mostrarInactivos = true;
  bool _cargandoInicial = true;
  String? _grupoSeleccionado;

  late final MapController _mapController;
  late final AnimatedMapController _animatedMapController;

  // marker ↔ data
  late List<(Marker marker, DistribuidorDb data)> _entries = const [];

  List<(Marker, DistribuidorDb)> _buildEntries(
    BuildContext ctx,
    List<DistribuidorDb> datos,
  ) {
    final cs = Theme.of(ctx).colorScheme;
    return datos.map((d) {
      final marker = Marker(
        point: LatLng(d.latitud, d.longitud),
        width: 30,
        height: 30,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: d.activo ? cs.primary : Colors.white,
            border: Border.all(color: cs.primary, width: 2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            Icons.location_pin,
            color: d.activo ? Colors.white : cs.primary,
            size: 15,
          ),
        ),
      );
      return (marker, d);
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _animatedMapController = AnimatedMapController(
      vsync: this,
      mapController: _mapController,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarDistribuidores();
    });
  }

  @override
  void dispose() {
    _popupController.dispose();
    _animatedMapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Recalcula marcadores y mantiene referencia para popups robustos
    final filtrados = _filtrados;
    _entries = _buildEntries(context, filtrados);
    final markers = _entries.map((e) => e.$1).toList();

    // Derivar grupos de forma reactiva del estado
    final distribuidoresNotifier = ref.watch(distribuidoresProvider);
    final grupos = (() {
      final set = <String>{'Todos'};
      for (final d in distribuidoresNotifier) {
        set.add(d.grupo);
      }
      final arr = set.toList()..sort();
      // asegurar 'Todos' al inicio
      arr.remove('Todos');
      arr.insert(0, 'Todos');
      return arr;
    })();

    // Lista completa (gatilla rebuild si cambia el estado)
    final distrProvider = ref.watch(distribuidoresProvider);

    // Conteos base
    final totalGeneral = distrProvider.where((d) => d.grupo != 'AFMZD').length;
    final mostrados = filtrados.where((d) => d.grupo != 'AFMZD').length;

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final hayInternet = ref.watch(connectivityProvider);

    ref.listen<bool>(connectivityProvider, (previous, next) async {
      if (!mounted || previous == next) return;
      await _cargarDistribuidores();
    });

    return MyLoaderOverlay(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Distribuidores',
            style: textTheme.titleLarge?.copyWith(color: colorScheme.onSurface),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () async {
            final resultado = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const DistribuidorFormPage()),
            );

            if (mounted && resultado == true) {
              await _cargarDistribuidores();
            }
          },
          tooltip: 'Agregar nueva distribuidora',
          child: const Icon(Icons.add),
        ),
        body: _cargandoInicial
            ? const SizedBox.shrink()
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Column(
                          children: [
                            const Text(
                              'Filtro por grupo',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            DropdownButton<String>(
                              value: _grupoSeleccionado,
                              items: [
                                for (final g in grupos)
                                  DropdownMenuItem(value: g, child: Text(g)),
                              ],
                              onChanged: (value) {
                                if (value == null) return;
                                setState(() => _grupoSeleccionado = value);
                                _resetMapaSegunFiltro();
                              },
                            ),
                          ],
                        ),
                        const SizedBox(width: 12),
                        Column(
                          children: [
                            const Text(
                              'Mostrar inactivos',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Switch.adaptive(
                              value: _mostrarInactivos,
                              onChanged: (v) {
                                setState(() => _mostrarInactivos = v);
                                _resetMapaSegunFiltro();
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                    child: Align(
                      alignment: Alignment.center,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: colorScheme.outlineVariant),
                        ),
                        child: Text(
                          'Mostrados: $mostrados / $totalGeneral',
                          style: textTheme.labelLarge?.copyWith(
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ),

                  hayInternet
                      ? SizedBox(
                          height: 250,
                          child: Stack(
                            children: [
                              FlutterMap(
                                mapController: _mapController,
                                options: MapOptions(
                                  initialCenter: const LatLng(
                                    23.6345,
                                    -102.5528,
                                  ),
                                  initialZoom: 3.8,
                                  minZoom: 3.5,
                                  interactionOptions: const InteractionOptions(
                                    flags:
                                        InteractiveFlag.all &
                                        ~InteractiveFlag.rotate,
                                  ),
                                  onTap: (_, __) =>
                                      _popupController.hideAllPopups(),
                                ),
                                children: [
                                  TileLayer(
                                    urlTemplate:
                                        Theme.of(context).brightness ==
                                            Brightness.dark
                                        ? 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                                        : 'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                                    userAgentPackageName: 'com.example.myafmzd',
                                    tileProvider:
                                        NetworkTileProvider(), // const
                                    retinaMode: RetinaMode.isHighDensity(
                                      context,
                                    ),
                                    keepBuffer: 4,
                                  ),
                                  PopupMarkerLayer(
                                    options: PopupMarkerLayerOptions(
                                      markers: markers,
                                      popupController: _popupController,
                                      popupDisplayOptions: PopupDisplayOptions(
                                        builder: (ctx, marker) {
                                          // match por instancia exacta
                                          final data = _entries
                                              .firstWhere(
                                                (e) => e.$1 == marker,
                                                orElse: () => (
                                                  marker,
                                                  DistribuidorDb(
                                                    uid: 'x',
                                                    nombre: 'Desconocido',
                                                    direccion: '',
                                                    latitud:
                                                        marker.point.latitude,
                                                    longitud:
                                                        marker.point.longitude,
                                                    activo: false,
                                                    grupo: '',
                                                    updatedAt: DateTime.now()
                                                        .toUtc(),
                                                    deleted: false,
                                                    isSynced: false,
                                                  ),
                                                ),
                                              )
                                              .$2;

                                          return DistribuidorPopup(
                                            distribuidor: data,
                                          );
                                        },
                                      ),
                                      markerCenterAnimation:
                                          const MarkerCenterAnimation(),
                                      markerTapBehavior:
                                          MarkerTapBehavior.togglePopupAndHideRest(),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        )
                      : const SizedBox(
                          height: 100,
                          child: Center(
                            child: Text('🌐 Mapa no disponible sin conexión'),
                          ),
                        ),
                  Expanded(
                    child: RefreshIndicator(
                      onRefresh: () async {
                        await _cargarDistribuidores();
                        final filtradosNow = _filtrados;
                        if (filtradosNow.isNotEmpty) {
                          await _resetMapaSegunFiltro();
                        }
                      },
                      child: ListView.builder(
                        physics: const BouncingScrollPhysics(
                          parent: AlwaysScrollableScrollPhysics(),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 24,
                        ),
                        itemCount: max(1, filtrados.length),
                        itemBuilder: (context, index) {
                          if (filtrados.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 80.0),
                              child: Center(
                                child: Text('No hay distribuidores'),
                              ),
                            );
                          }
                          final distribuidor = filtrados[index];
                          return DistribuidorItemTile(
                            key: ValueKey(distribuidor.uid),
                            distribuidor: distribuidor,
                            onTap: () => _centrarYMostrarPopup(distribuidor),
                            onActualizado: () async {
                              await _cargarDistribuidores();
                              await _resetMapaSegunFiltro();
                            },
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Future<void> _cargarDistribuidores() async {
    if (!mounted) return;

    setState(() => _cargandoInicial = true);

    // UX opcional
    FocusScope.of(context).unfocus();

    // OVERLAY
    context.loaderOverlay.show(progress: 'Cargando distribuidores…');

    final inicio = DateTime.now();

    try {
      final hayInternet = ref.read(connectivityProvider);

      await ref.read(distribuidoresProvider.notifier).cargarOfflineFirst();

      // Delay mínimo (mismo patrón)
      const duracionMinima = Duration(milliseconds: 1500);
      final duracion = DateTime.now().difference(inicio);
      if (duracion < duracionMinima) {
        await Future.delayed(duracionMinima - duracion);
      }

      if (!mounted) return;

      // grupo default
      final lista = ref.read(distribuidoresProvider);
      if (_grupoSeleccionado == null && lista.isNotEmpty) {
        _grupoSeleccionado = 'Todos';
      }

      if (!hayInternet) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📴 Estás sin conexión. Solo información local.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
      if (mounted) {
        setState(() => _cargandoInicial = false);
      }
    }
  }

  // Importante: observa el **estado** para rebuilds, y usa el helper del notifier
  List<DistribuidorDb> get _filtrados {
    // gatilla rebuild cuando el estado cambia
    final _ = ref.watch(distribuidoresProvider);
    // usa la lógica centralizada del notifier
    return ref
        .read(distribuidoresProvider.notifier)
        .filtrar(
          mostrarInactivos: _mostrarInactivos,
          grupo: _grupoSeleccionado,
        );
  }

  void _centrarYMostrarPopup(DistribuidorDb d) async {
    if (_entries.isEmpty) return;

    // Buscar la entrada por uid (robusto aunque haya coords duplicadas)
    final entry = _entries.firstWhere(
      (e) => e.$2.uid == d.uid,
      orElse: () => _entries.first,
    );

    _popupController.hideAllPopups();
    await _animatedMapController.animateTo(
      dest: entry.$1.point,
      zoom: 13.0,
      curve: Curves.easeInOut,
    );
    _popupController.showPopupsOnlyFor([entry.$1]);
  }

  Future<void> _resetMapaSegunFiltro() async {
    _popupController.hideAllPopups();

    final lista = _filtrados;
    if (lista.isEmpty || _grupoSeleccionado == 'Todos') {
      await _animatedMapController.animateTo(
        dest: const LatLng(23.6345, -102.5528),
        zoom: 3.8,
        curve: Curves.easeInOut,
      );
      return;
    }

    if (lista.length == 1) {
      final d = lista.first;
      await _animatedMapController.animateTo(
        dest: LatLng(d.latitud, d.longitud),
        zoom: 10.0,
        curve: Curves.easeInOut,
      );
      return;
    }

    final points = [for (final d in lista) LatLng(d.latitud, d.longitud)];
    await _animatedMapController.animatedFitCamera(
      cameraFit: CameraFit.coordinates(
        coordinates: points,
        padding: const EdgeInsets.all(24),
      ),
    );
  }
}

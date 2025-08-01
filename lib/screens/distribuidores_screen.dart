import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/widgets/distribuidor_popup.dart';

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

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _animatedMapController = AnimatedMapController(
      vsync: this,
      mapController: _mapController,
    );
    _cargarDistribuidores();
  }

  Future<void> _cargarDistribuidores() async {
    setState(() => _cargandoInicial = true);

    final inicio = DateTime.now();

    final hayInternet = ref.read(connectivityProvider);
    await ref
        .read(distribuidoresProvider.notifier)
        .cargar(hayInternet: hayInternet);

    final duracion = DateTime.now().difference(inicio);
    const duracionMinima = Duration(milliseconds: 1500);
    if (duracion < duracionMinima) {
      await Future.delayed(duracionMinima - duracion);
    }

    if (mounted) {
      final grupos = ref.read(distribuidoresProvider.notifier).gruposUnicos;
      if (_grupoSeleccionado == null && grupos.isNotEmpty) {
        _grupoSeleccionado = 'Todos';
      }
    }

    if (mounted) {
      setState(() => _cargandoInicial = false);
    }
  }

  List<DistribuidorDb> get _filtrados {
    return ref
        .read(distribuidoresProvider.notifier)
        .filtrar(
          mostrarInactivos: _mostrarInactivos,
          grupo: _grupoSeleccionado,
        );
  }

  void _centrarYMostrarPopup(DistribuidorDb d) async {
    final punto = LatLng(d.latitud, d.longitud);

    _popupController.hideAllPopups();

    await _animatedMapController.animateTo(
      dest: punto,
      zoom: 13.0,
      curve: Curves.easeInOut,
    );

    // Después de mover, mostrar el popup
    _popupController.showPopupsOnlyFor([
      Marker(
        point: punto,
        width: 1,
        height: 1,
        child: const SizedBox.shrink(), // marcador "dummy"
      ),
    ]);
  }

  double calcularZoom(double maxSpan) {
    // Rango de zoom deseado
    const double maxZoom = 12.0; // Muy cerca
    const double minZoom = 4.0; // Muy lejos

    // Span mínimo y máximo esperados
    const double minSpan = 0.002; // 1-2 cuadras
    const double maxSpanDefault = 40.0; // todo el país

    // Clamp para evitar valores extremos
    final clampedSpan = maxSpan.clamp(minSpan, maxSpanDefault);

    // Escala inversa logarítmica (más precisa para mapas)
    final scale =
        log((clampedSpan / minSpan)) / log((maxSpanDefault / minSpan));
    final zoom = maxZoom - scale * (maxZoom - minZoom);

    return zoom.clamp(minZoom, maxZoom);
  }

  Future<void> _resetMapaSegunFiltro() async {
    _popupController.hideAllPopups();

    if (_filtrados.isEmpty || _grupoSeleccionado == 'Todos') {
      await _animatedMapController.animateTo(
        dest: LatLng(23.6345, -102.5528),
        zoom: 3.8,
        curve: Curves.easeInOut,
      );
      return;
    }

    // Si hay solo un distribuidor, usar zoom neutral (ej. 10.0)
    if (_filtrados.length == 1) {
      final d = _filtrados.first;
      await _animatedMapController.animateTo(
        dest: LatLng(d.latitud, d.longitud),
        zoom: 10.0, // o 9.5, ajustable
        curve: Curves.easeInOut,
      );
      return;
    }

    final firstDistribuidor = _filtrados.first;
    final bounds = LatLngBounds(
      LatLng(firstDistribuidor.latitud, firstDistribuidor.longitud),
      LatLng(firstDistribuidor.latitud, firstDistribuidor.longitud),
    );
    for (var d in _filtrados) {
      bounds.extend(LatLng(d.latitud, d.longitud));
    }

    final center = LatLng(
      (bounds.south + bounds.north) / 2,
      (bounds.west + bounds.east) / 2,
    );

    final latSpan = (bounds.north - bounds.south).abs();
    final lngSpan = (bounds.east - bounds.west).abs();
    final maxSpan = [latSpan, lngSpan].reduce((a, b) => a > b ? a : b);

    final zoom = calcularZoom(maxSpan);

    await _animatedMapController.animateTo(
      dest: center,
      zoom: zoom,
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final markers = _filtrados
        .map(
          (d) => Marker(
            point: LatLng(d.latitud, d.longitud),
            width: 30,
            height: 30,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: d.activo ? colorScheme.primary : Colors.white,
                border: Border.all(color: colorScheme.primary, width: 2),
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
                color: d.activo ? Colors.white : colorScheme.primary,
                size: 15,
              ),
            ),
          ),
        )
        .toList();
    final hayInternet = ref.watch(connectivityProvider); // 🔄 reactivo
    final grupos = ref.watch(distribuidoresProvider.notifier).gruposUnicos;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "D i s t r i b u i d o r e s",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
      body: _cargandoInicial
          ? const Center(child: CircularProgressIndicator())
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
                            onChanged: (value) {
                              if (value == null) return;
                              setState(() => _grupoSeleccionado = value);
                              _resetMapaSegunFiltro();
                            },

                            items: grupos
                                .map(
                                  (g) => DropdownMenuItem(
                                    value: g,
                                    child: Text(g),
                                  ),
                                )
                                .toList(),
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

                hayInternet
                    ? SizedBox(
                        height: 250,
                        child: Stack(
                          children: [
                            FlutterMap(
                              mapController: _mapController,
                              options: MapOptions(
                                initialCenter: LatLng(23.6345, -102.5528),
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
                                  tileProvider: NetworkTileProvider(),
                                  retinaMode: RetinaMode.isHighDensity(context),
                                  keepBuffer: 4,
                                ),
                                PopupMarkerLayer(
                                  options: PopupMarkerLayerOptions(
                                    markers: markers,
                                    popupController: _popupController,
                                    popupDisplayOptions: PopupDisplayOptions(
                                      builder: (ctx, marker) {
                                        final d = _filtrados.firstWhere(
                                          (e) =>
                                              e.latitud ==
                                                  marker.point.latitude &&
                                              e.longitud ==
                                                  marker.point.longitude,
                                          orElse: () => DistribuidorDb(
                                            uid: 'x',
                                            nombre: 'Desconocido',
                                            direccion: '',
                                            latitud: marker.point.latitude,
                                            longitud: marker.point.longitude,
                                            activo: false,
                                            grupo: '',
                                            updatedAt: DateTime.now().toUtc(),
                                            deleted: false,
                                            isSynced: false,
                                          ),
                                        );

                                        return DistribuidorPopup(
                                          distribuidor: d,
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
                            ), // como ya lo tienes
                            // Attribution y popups como los tienes
                          ],
                        ),
                      )
                    : SizedBox(
                        height: 100,
                        child: const Center(
                          child: Text('🌐 Mapa no disponible sin conexión'),
                        ),
                      ),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      _cargarDistribuidores();

                      if (_filtrados.isNotEmpty) await _resetMapaSegunFiltro();
                    },

                    child: ListView.builder(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      itemCount: max(1, _filtrados.length),
                      itemBuilder: (context, index) {
                        if (_filtrados.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.only(top: 80.0),
                            child: Center(child: Text('No hay distribuidores')),
                          );
                        }

                        final d = _filtrados[index];
                        return ListTile(
                          leading: const Icon(Icons.location_city),
                          title: Text(d.nombre),
                          subtitle: Text(d.direccion),
                          trailing: d.activo
                              ? const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                )
                              : const Icon(Icons.cancel, color: Colors.grey),
                          onTap: () => _centrarYMostrarPopup(d),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

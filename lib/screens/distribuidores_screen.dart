import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_animations/flutter_map_animations.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:latlong2/latlong.dart';
import 'package:myafmzd/models/distribuidor_model.dart';
import 'package:myafmzd/services/distribuidor_service.dart';
import 'package:myafmzd/widgets/distribuidor_popup.dart';

class DistribuidoresScreen extends StatefulWidget {
  const DistribuidoresScreen({super.key});
  @override
  State<DistribuidoresScreen> createState() => _DistribuidoresScreenState();
}

class _DistribuidoresScreenState extends State<DistribuidoresScreen>
    with TickerProviderStateMixin {
  final DistribuidorService _service = DistribuidorService();
  final PopupController _popupController = PopupController();
  List<Distribuidor> _distribuidores = [];
  bool _mostrarInactivos = true;
  bool _cargandoInicial = true;
  String? _grupoSeleccionado;
  late List<String> _gruposDisponibles;
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

    _distribuidores = await _service.cargarDistribuidores();

    _gruposDisponibles = _distribuidores.map((e) => e.grupo).toSet().toList()
      ..sort();

    _gruposDisponibles.insert(0, 'Todos'); // Agrega opción "Todos"
    _grupoSeleccionado = _gruposDisponibles.first;

    final duracion = DateTime.now().difference(inicio);
    const duracionMinima = Duration(milliseconds: 1500);

    if (duracion < duracionMinima) {
      await Future.delayed(duracionMinima - duracion);
    }

    if (mounted) {
      setState(() {
        _cargandoInicial = false;
      });
    }
  }

  List<Distribuidor> get _filtrados {
    final filtrados = _distribuidores.where((d) {
      final activoOk = _mostrarInactivos || d.activo;
      final grupoOk =
          _grupoSeleccionado == null ||
          _grupoSeleccionado == 'Todos' ||
          d.grupo == _grupoSeleccionado;
      return activoOk && grupoOk;
    }).toList();

    filtrados.sort((a, b) {
      // Primero activos
      if (a.activo != b.activo) {
        return a.activo ? -1 : 1; // activos primero
      }

      // Finalmente por nombre
      return a.nombre.compareTo(b.nombre);
    });

    return filtrados;
  }

  void _centrarYMostrarPopup(Distribuidor d) async {
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

  Future<void> _resetMapaSegunFiltro() async {
    _popupController.hideAllPopups();

    // Si no hay distribuidores filtrados, centramos en México directamente
    if (_filtrados.isEmpty || _grupoSeleccionado == 'Todos') {
      await _animatedMapController.animateTo(
        dest: LatLng(23.6345, -102.5528),
        zoom: 3.8,
        curve: Curves.easeInOut,
      );
      return;
    }

    // Si hay filtrados, calcular bounds para centrar mapa
    final latitudes = _filtrados.map((d) => d.latitud).toList();
    final longitudes = _filtrados.map((d) => d.longitud).toList();

    final minLat = latitudes.reduce((a, b) => a < b ? a : b);
    final maxLat = latitudes.reduce((a, b) => a > b ? a : b);
    final minLng = longitudes.reduce((a, b) => a < b ? a : b);
    final maxLng = longitudes.reduce((a, b) => a > b ? a : b);

    final centerLat = (minLat + maxLat) / 2;
    final centerLng = (minLng + maxLng) / 2;
    final center = LatLng(centerLat, centerLng);

    const double paddingFactor = 1.2;
    final latSpan = (maxLat - minLat).abs() * paddingFactor;
    final lngSpan = (maxLng - minLng).abs() * paddingFactor;

    final maxSpan = latSpan > lngSpan ? latSpan : lngSpan;

    double zoom;
    if (maxSpan < 0.01) {
      zoom = 13.0;
    } else if (maxSpan < 0.05) {
      zoom = 11.0;
    } else if (maxSpan < 0.1) {
      zoom = 9.5;
    } else if (maxSpan < 0.25) {
      zoom = 8.0;
    } else if (maxSpan < 0.5) {
      zoom = 6.5;
    } else {
      zoom = 5.0;
    }

    await _animatedMapController.animateTo(
      dest: center,
      zoom: zoom,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _popupController.dispose();
    super.dispose();
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

    return Scaffold(
      appBar: AppBar(
        title: Text("Distribuidores", style: TextStyle(color: Colors.black)),
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

                            items: _gruposDisponibles
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

                SizedBox(
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
                                InteractiveFlag.all & ~InteractiveFlag.rotate,
                          ),

                          onTap: (_, __) => _popupController.hideAllPopups(),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                Theme.of(context).brightness == Brightness.dark
                                ? 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                                : 'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                            userAgentPackageName: 'com.example.myafmzd',
                            tileProvider: NetworkTileProvider(),
                            retinaMode: RetinaMode.isHighDensity(context),
                          ),
                          PopupMarkerLayer(
                            options: PopupMarkerLayerOptions(
                              markers: markers,
                              popupController: _popupController,
                              popupDisplayOptions: PopupDisplayOptions(
                                builder: (ctx, marker) {
                                  final d = _distribuidores.firstWhere(
                                    (e) =>
                                        LatLng(e.latitud, e.longitud) ==
                                        marker.point,
                                  );
                                  return DistribuidorPopup(distribuidor: d);
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
                ),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _cargarDistribuidores,
                    child: _filtrados.isEmpty
                        ? const Center(child: Text('No hay distribuidores'))
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            itemCount: _filtrados.length,
                            itemBuilder: (context, index) {
                              final d = _filtrados[index];
                              return ListTile(
                                leading: Icon(Icons.location_city),
                                title: Text(d.nombre),
                                subtitle: Text(d.direccion),
                                trailing: d.activo
                                    ? const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                      )
                                    : const Icon(
                                        Icons.cancel,
                                        color: Colors.grey,
                                      ),
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

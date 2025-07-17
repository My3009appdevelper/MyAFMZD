import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_popup/flutter_map_marker_popup.dart';
import 'package:latlong2/latlong.dart';
import 'package:myafmzd/models/distribuidor_model.dart';
import 'package:myafmzd/services/distribuidor_service.dart';
import 'package:myafmzd/widgets/app_drawer.dart';
import 'package:myafmzd/widgets/distribuidor_popup.dart';

class DistribuidoresScreen extends StatefulWidget {
  const DistribuidoresScreen({super.key});
  @override
  State<DistribuidoresScreen> createState() => _DistribuidoresScreenState();
}

class _DistribuidoresScreenState extends State<DistribuidoresScreen> {
  final DistribuidorService _service = DistribuidorService();
  final PopupController _popupController = PopupController();
  List<Distribuidor> _distribuidores = [];
  bool _cargando = true;
  bool _mostrarInactivos = true;

  @override
  void initState() {
    super.initState();
    _cargarDistribuidores();
  }

  Future<void> _cargarDistribuidores() async {
    _distribuidores = await _service.cargarDistribuidores();
    setState(() => _cargando = false);
  }

  @override
  void dispose() {
    _popupController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    final markers = _distribuidores
        .where((d) => _mostrarInactivos || d.activo)
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
      appBar: AppBar(title: const Text('Distribuidores'), centerTitle: true),
      drawer: const AppDrawer(),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  height: 300,

                  child: Stack(
                    children: [
                      FlutterMap(
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
                      ),
                      Positioned(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            const Text(
                              'Mostrar inactivos',
                              style: TextStyle(fontSize: 12),
                            ),
                            Switch.adaptive(
                              value: _mostrarInactivos,

                              onChanged: (value) {
                                setState(() {
                                  _mostrarInactivos = value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.background.withOpacity(0.7),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            '© OpenStreetMap, © CARTO',
                            style: TextStyle(fontSize: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}

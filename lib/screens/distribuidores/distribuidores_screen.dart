import 'dart:math';

import 'package:file_picker/file_picker.dart';
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
import 'package:myafmzd/database/grupo_distribuidores/grupos_distribuidores_provider.dart';
import 'package:myafmzd/screens/distribuidores/distribuidores_form_page.dart';
import 'package:myafmzd/screens/distribuidores/distribuidores_popup.dart';
import 'package:myafmzd/screens/distribuidores/distribuidores_tile.dart';
import 'package:myafmzd/widgets/my_expandable_fab_options.dart';

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

  bool _mapReady = false;
  bool get _puedoUsarMapa => _mapReady && mounted;

  /// Guarda el **uuid** del grupo seleccionado. `''` => Todos.
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
      _cargarGruposYDistribuidores(); // ← primero grupos, luego distribuidores
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

    // ======= Derivar grupos (uuid → nombre) de forma reactiva del estado =======
    final grupos =
        ref
            .watch(gruposDistribuidoresProvider)
            .where((g) => !g.deleted)
            .toList()
          ..sort((a, b) => a.nombre.compareTo(b.nombre));

    // Items para el dropdown: ('Todos' => value:'') + cada grupo por nombre
    final dropdownItems = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: '', child: Text('Todos')),
      ...grupos.map(
        (g) => DropdownMenuItem(value: g.uid, child: Text(g.nombre)),
      ),
    ];

    // Lista completa (gatilla rebuild si cambia el estado)
    final distrProvider = ref.watch(distribuidoresProvider);

    // Conteos base (ignorando AFMZD por **nombre** vía lookup del uuid)
    String nombreGrupo(String uuid) =>
        ref.read(gruposDistribuidoresProvider.notifier).nombrePorUid(uuid);
    final totalGeneral = distrProvider
        .where((d) => nombreGrupo(d.uuidGrupo) != 'AFMZD')
        .length;
    final mostrados = filtrados
        .where((d) => nombreGrupo(d.uuidGrupo) != 'AFMZD')
        .length;

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    ref.listen<bool>(connectivityProvider, (previous, next) async {
      if (!mounted || previous == next) return;
      await _cargarGruposYDistribuidores();
    });

    return Scaffold(
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
      floatingActionButton: FabConMenuAnchor(
        onAgregar: _abrirFormNuevoDistribuidor, // si ya lo tienes
        onImportar: _importarDistribuidores,
        onExportar: _exportarDistribuidores,
        txtAgregar: 'Agregar distribuidora',
        txtImportar: 'Importar desde CSV',
        txtExportar: 'Exportar a CSV',
        iconMain: Icons.apps,
        iconAgregar: Icons.store_mall_directory_outlined,
        iconImportar: Icons.upload,
        iconExportar: Icons.download,
        fabTooltip: 'Acciones de distribuidores',
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
                            value: _grupoSeleccionado ?? '',
                            items: dropdownItems,
                            onChanged: (value) {
                              if (value == null) return;
                              _popupController.hideAllPopups();
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
                              _popupController
                                  .hideAllPopups(); // 👈 cerrar popup antes
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

                SizedBox(
                  height: 250,
                  child: Stack(
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: const LatLng(23.6345, -102.5528),
                          initialZoom: 3.8,
                          minZoom: 3.5,
                          interactionOptions: const InteractionOptions(
                            flags:
                                InteractiveFlag.all & ~InteractiveFlag.rotate,
                          ),
                          onMapReady: () => setState(() => _mapReady = true),
                          onTap: (_, __) => _popupController.hideAllPopups(),
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                Theme.of(context).brightness == Brightness.dark
                                ? 'https://basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png'
                                : 'https://basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png',
                            userAgentPackageName: 'com.example.myafmzd',
                            tileProvider: NetworkTileProvider(), // const
                            retinaMode: RetinaMode.isHighDensity(context),
                            keepBuffer: 4,
                          ),
                          PopupMarkerLayer(
                            options: PopupMarkerLayerOptions(
                              markers: markers,
                              popupController: _popupController,
                              popupDisplayOptions: PopupDisplayOptions(
                                builder: (ctx, marker) {
                                  final match = _entries.where(
                                    (e) => e.$1 == marker,
                                  );
                                  if (match.isEmpty) {
                                    // El marker que intenta mostrar el popup ya no existe con el filtro actual.
                                    // No rendereamos nada -> el popup “desaparece”.
                                    return const SizedBox.shrink(); // 👈 en vez de “Desconocido”
                                  }
                                  final data = match.first.$2;
                                  return DistribuidorPopup(distribuidor: data);
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
                ),

                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await _cargarGruposYDistribuidores(); // ← recargar ambos
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
                            child: Center(child: Text('No hay distribuidores')),
                          );
                        }
                        final distribuidor = filtrados[index];
                        return DistribuidorItemTile(
                          key: ValueKey(distribuidor.uid),
                          distribuidor: distribuidor,
                          onTap: () {
                            if (_puedoUsarMapa) {
                              _centrarYMostrarPopup(
                                distribuidor,
                              ); // 👈 no-op si no hay mapa
                            }
                          },
                          onActualizado: () async {
                            await _cargarGruposYDistribuidores(); // ← recargar ambos
                            await _resetMapaSegunFiltro();
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  /// Carga **grupos primero** y luego distribuidores (offline-first en ambos).
  Future<void> _cargarGruposYDistribuidores() async {
    if (!mounted) return;
    _popupController.hideAllPopups();
    setState(() => _cargandoInicial = true);

    FocusScope.of(context).unfocus();
    context.loaderOverlay.show(progress: 'Cargando grupos…');

    final inicio = DateTime.now();

    try {
      final hayInternet = ref.read(connectivityProvider);

      // 1) Grupos primero (para que el dropdown exista y el nombrePorUid funcione)
      await ref
          .read(gruposDistribuidoresProvider.notifier)
          .cargarOfflineFirst();

      // 2) Luego distribuidores
      if (context.loaderOverlay.visible) {
        context.loaderOverlay.progress('Cargando distribuidores…');
      }
      await ref.read(distribuidoresProvider.notifier).cargarOfflineFirst();

      // Delay mínimo (mismo patrón)
      const duracionMinima = Duration(milliseconds: 1500);
      final duracion = DateTime.now().difference(inicio);
      if (duracion < duracionMinima) {
        await Future.delayed(duracionMinima - duracion);
      }

      if (!mounted) return;

      // Valor default del filtro una vez que ya hay datos locales
      if (_grupoSeleccionado == null) {
        _grupoSeleccionado = ''; // '' => "Todos"
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
    // usa la lógica centralizada del notifier (uuidGrupo)
    return ref
        .read(distribuidoresProvider.notifier)
        .filtrar(
          mostrarInactivos: _mostrarInactivos,
          uuidGrupo: (_grupoSeleccionado == null || _grupoSeleccionado == '')
              ? null
              : _grupoSeleccionado,
        );
  }

  void _centrarYMostrarPopup(DistribuidorDb d) async {
    if (!_puedoUsarMapa || _entries.isEmpty) return; // 👈 guarda
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
    if (!_puedoUsarMapa) return; // 👈 guarda
    _popupController.hideAllPopups();

    final lista = _filtrados;
    if (lista.isEmpty ||
        (_grupoSeleccionado == null || _grupoSeleccionado == '')) {
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

  Future<void> _importarDistribuidores() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (res == null || res.files.single.bytes == null) return;

    context.loaderOverlay.show(progress: 'Importando distribuidores…');
    try {
      final (ins, skip) = await ref
          .read(distribuidoresProvider.notifier)
          .importarCsvDistribuidores(csvBytes: res.files.single.bytes!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Importados: $ins • Saltados (duplicados): $skip'),
        ),
      );
      await _cargarGruposYDistribuidores(); // tu método de recarga
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al importar CSV: $e')));
      }
    } finally {
      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
    }
  }

  Future<void> _exportarDistribuidores() async {
    context.loaderOverlay.show(progress: 'Generando CSV…');
    try {
      final path = await ref
          .read(distribuidoresProvider.notifier)
          .exportarCsvAArchivo();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CSV guardado en:\n$path')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al exportar: $e')));
      }
    } finally {
      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
    }
  }

  // ABRIR FORMULARIO DE NUEVO DISTRIBUIDOR
  Future<void> _abrirFormNuevoDistribuidor() async {
    // Navega al formulario de creación.
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const DistribuidorFormPage(), // modo "crear"
      ),
    );

    // Si la página regresa true (guardado) o simplemente para asegurar, recarga.
    if (mounted && (resultado == true || resultado == null)) {
      await _cargarGruposYDistribuidores();
    }
  }
}

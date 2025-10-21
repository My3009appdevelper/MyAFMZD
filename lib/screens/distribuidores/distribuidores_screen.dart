import 'dart:async';

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
import 'package:myafmzd/widgets/my_text_field.dart'; // ⬅️ NUEVO: barra de búsqueda

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

  // === 🔎 Estado de búsqueda ===
  final TextEditingController _searchCtrl = TextEditingController(); // ⬅️
  String _query = ''; // ⬅️
  Timer? _debounce; // ⬅️

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

    // 🔎 Debounce búsqueda (consistente con otras screens)
    _searchCtrl.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        setState(() => _query = _searchCtrl.text);
      });
    });
  }

  @override
  void dispose() {
    _popupController.dispose();
    _animatedMapController.dispose();
    _debounce?.cancel(); // ⬅️
    _searchCtrl.dispose(); // ⬅️
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Base filtrada por grupo/activos (SIN búsqueda)
    final filtradosBase = _filtrados; // ⬅️ renombrado para claridad
    _entries = _buildEntries(context, filtradosBase);
    final markers = _entries.map((e) => e.$1).toList();

    // ======= Grupos (uuid → nombre) =======
    final grupos =
        ref
            .watch(gruposDistribuidoresProvider)
            .where((g) => !g.deleted)
            .toList()
          ..sort((a, b) => a.nombre.compareTo(b.nombre));
    final mapGrupoNombre = {for (final g in grupos) g.uid: g.nombre}; // ⬅️

    // Items para el dropdown
    final dropdownItems = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: '', child: Text('Todos')),
      ...grupos.map(
        (g) => DropdownMenuItem(value: g.uid, child: Text(g.nombre)),
      ),
    ];

    // Para contador (se mantiene la lógica original)
    final distrProvider = ref.watch(distribuidoresProvider);
    String nombreGrupo(String uuid) =>
        ref.read(gruposDistribuidoresProvider.notifier).nombrePorUid(uuid);
    final totalGeneral = distrProvider
        .where((d) => nombreGrupo(d.uuidGrupo) != 'AFMZD')
        .length;
    final mostrados = filtradosBase
        .where((d) => nombreGrupo(d.uuidGrupo) != 'AFMZD')
        .length;

    // === 🔎 Visibles = base filtrada + búsqueda por nombre/grupo ===
    final visibles = _aplicarFiltroDistribuidores(
      // ⬅️
      filtradosBase,
      _query,
      mapGrupoNombre: mapGrupoNombre,
    );

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    ref.listen<bool>(connectivityProvider, (previous, next) async {
      if (!mounted || previous == next) return;
      await _cargarGruposYDistribuidores();
    });

    return Scaffold(
      floatingActionButton: FabConMenuAnchor(
        onAgregar: _abrirFormNuevoDistribuidor,
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

      // ======= Mapa fijo arriba (no se desplaza con el scroll) =======
      body: _cargandoInicial
          ? const SizedBox.shrink()
          : Column(
              children: [
                // MAPA (FIJO)
                SizedBox(
                  height: 250,
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      initialCenter: const LatLng(23.6345, -102.5528),
                      initialZoom: 3.8,
                      minZoom: 3.5,
                      interactionOptions: const InteractionOptions(
                        flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
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
                              final match = _entries.where(
                                (e) => e.$1 == marker,
                              );
                              if (match.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              final data = match.first.$2;
                              return DistribuidorPopup(distribuidor: data);
                            },
                          ),
                          markerCenterAnimation: const MarkerCenterAnimation(),
                          markerTapBehavior:
                              MarkerTapBehavior.togglePopupAndHideRest(),
                        ),
                      ),
                    ],
                  ),
                ),

                // ======= Scroll: filtros + búsqueda + contador + lista =======
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await _cargarGruposYDistribuidores(); // ← recargar ambos
                      final filtradosNow = _filtrados;
                      if (filtradosNow.isNotEmpty) {
                        await _resetMapaSegunFiltro();
                      }
                    },
                    color: colorScheme.secondary,
                    child: ListView(
                      physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics(),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      children: [
                        // FILTROS (en scroll)
                        Row(
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
                                    _popupController.hideAllPopups();
                                    setState(() => _mostrarInactivos = v);
                                    _resetMapaSegunFiltro();
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),

                        // 🔎 BARRA DE BÚSQUEDA (debajo de filtros) — SOLO lista
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 8, 0, 0),
                          child: MyTextField(
                            controller: _searchCtrl,
                            textInputAction: TextInputAction.search,
                            showClearButton: _query.isNotEmpty,
                            labelText: 'Buscar distribuidora',
                            hintText: 'Grupo o nombre de distribuidora',
                            onClear: () {
                              _searchCtrl.clear();
                              setState(() => _query = '');
                            },
                            onSubmitted: (_) =>
                                FocusScope.of(context).unfocus(),
                          ),
                        ),

                        // CONTADOR (se mantiene con base en filtros)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
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
                                border: Border.all(
                                  color: colorScheme.outlineVariant,
                                ),
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

                        // LISTA (aplica búsqueda)
                        if (visibles.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 80.0),
                            child: Center(
                              child: Text(
                                _query.trim().isEmpty
                                    ? 'No hay distribuidores'
                                    : 'Sin coincidencias para “$_query”.',
                                style: textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurface.withOpacity(
                                    0.65,
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          ...visibles.map((distribuidor) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: DistribuidorItemTile(
                                key: ValueKey(distribuidor.uid),
                                distribuidor: distribuidor,
                                onTap: () {
                                  if (_puedoUsarMapa) {
                                    _centrarYMostrarPopup(distribuidor);
                                  }
                                },
                                onActualizado: () async {
                                  await _cargarGruposYDistribuidores();
                                  await _resetMapaSegunFiltro();
                                },
                              ),
                            );
                          }).toList(),
                      ],
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

      // 1) Grupos primero
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

      // Valor default del filtro
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
    final _ = ref.watch(distribuidoresProvider);
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
    if (!_puedoUsarMapa || _entries.isEmpty) return;
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
    if (!_puedoUsarMapa) return;
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
      await _cargarGruposYDistribuidores();
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

  // ===================== 🔎 Búsqueda / Matching =====================
  List<DistribuidorDb> _aplicarFiltroDistribuidores(
    List<DistribuidorDb> lista,
    String query, {
    required Map<String, String> mapGrupoNombre,
  }) {
    if (query.trim().isEmpty) return lista;

    final q = _normalize(query);
    final tokens = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

    return lista.where((d) {
      final nombre = _safeStr(d.nombre);
      final grupoNombre = mapGrupoNombre[_safeStr(d.uuidGrupo)] ?? '';
      final indexText = _normalize('$nombre $grupoNombre');

      // AND de tokens
      return tokens.every(indexText.contains);
    }).toList();
  }

  // utils
  String _safeStr(Object? v) => (v ?? '').toString();

  String _normalize(String input) {
    var t = input.toLowerCase();
    t = t.replaceAll(RegExp(r'[áàäâã]'), 'a');
    t = t.replaceAll(RegExp(r'[éèëê]'), 'e');
    t = t.replaceAll(RegExp(r'[íìïî]'), 'i');
    t = t.replaceAll(RegExp(r'[óòöôõ]'), 'o');
    t = t.replaceAll(RegExp(r'[úùüû]'), 'u');
    t = t.replaceAll(RegExp(r'[ñ]'), 'n');
    t = t.replaceAll(RegExp(r'[ç]'), 'c');
    t = t.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t;
  }

  // ABRIR FORMULARIO DE NUEVO DISTRIBUIDOR
  Future<void> _abrirFormNuevoDistribuidor() async {
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => const DistribuidorFormPage()),
    );

    if (mounted && (resultado == true || resultado == null)) {
      await _cargarGruposYDistribuidores();
    }
  }
}

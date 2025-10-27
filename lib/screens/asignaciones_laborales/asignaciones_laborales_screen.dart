// lib/screens/asignaciones_laborales/asignaciones_laborales_screen.dart
import 'dart:async';
import 'dart:math' as math;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';

import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/asignaciones_laborales/asignaciones_laborales_provider.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_provider.dart';
import 'package:myafmzd/screens/asignaciones_laborales/asignaciones_laborales_form_page.dart';
import 'package:myafmzd/screens/asignaciones_laborales/asignaciones_laborales_tile.dart';
import 'package:myafmzd/widgets/my_expandable_fab_options.dart';
import 'package:myafmzd/widgets/my_text_field.dart';

class AsignacionesLaboralesScreen extends ConsumerStatefulWidget {
  const AsignacionesLaboralesScreen({super.key});

  @override
  ConsumerState<AsignacionesLaboralesScreen> createState() =>
      _AsignacionesLaboralesScreenState();
}

class _AsignacionesLaboralesScreenState
    extends ConsumerState<AsignacionesLaboralesScreen> {
  bool _cargandoInicial = true;

  // ----- Estado de búsqueda -----
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  Timer? _debounce;

  // ----- Filtros -----
  String _filtroDistribuidorUid = ''; // vacío => todos
  bool _mostrarCerradas = false; // false => Activas (default), true => Cerradas

  // ----- Paginación -----
  final int _pageSize = 1000;
  int _page = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarAsignaciones());

    // Debounce búsqueda
    _searchCtrl.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        setState(() {
          _query = _searchCtrl.text;
          _page = 0; // reset paginación al buscar
        });
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Igual que Ventas: listen en build
    ref.listen<bool>(connectivityProvider, (prev, next) async {
      if (!mounted || prev == next) return;
      await _cargarAsignaciones();
    });

    // Fuente base (para rebuild)
    final _ = ref.watch(asignacionesLaboralesProvider);

    // Catálogos auxiliares
    final distribuidores =
        ref.watch(distribuidoresProvider).where((d) => !d.deleted).toList()
          ..sort((a, b) => a.nombre.compareTo(b.nombre));

    // Lookups
    final mapDistribNombre = {for (final d in distribuidores) d.uid: d.nombre};
    final colaboradores = ref.watch(colaboradoresProvider);
    final mapColabNombre = {
      for (final c in colaboradores)
        c.uid: _nombreCompletoColaborador(
          c.nombres,
          c.apellidoPaterno,
          c.apellidoMaterno,
        ),
    };
    final mapColabTelefonos = {
      for (final c in colaboradores)
        c.uid: _digitsOnly('${c.telefonoMovil ?? ''} '),
    };

    // Base visible
    final base = _mostrarCerradas
        ? ref
              .read(asignacionesLaboralesProvider.notifier)
              .listarHistoricas(
                distribuidorUid: _filtroDistribuidorUid.isEmpty
                    ? null
                    : _filtroDistribuidorUid,
              )
        : ref
              .read(asignacionesLaboralesProvider.notifier)
              .listarActivas(
                distribuidorUid: _filtroDistribuidorUid.isEmpty
                    ? null
                    : _filtroDistribuidorUid,
              );

    // 🔎 Búsqueda local
    final visibles = _aplicarFiltro(
      base,
      _query,
      mapColabNombre: mapColabNombre,
      mapDistribNombre: mapDistribNombre,
      mapColabTelefonos: mapColabTelefonos,
    );

    // ----- Paginación -----
    final total = visibles.length;
    final totalPages = (total == 0) ? 1 : ((total - 1) ~/ _pageSize) + 1;
    _page = math.min(_page, totalPages - 1);
    final start = _page * _pageSize;
    final end = math.min(start + _pageSize, total);
    final pagina = (start < end)
        ? visibles.sublist(start, end)
        : <AsignacionLaboralDb>[];

    // Mensaje vacío
    final emptyMsg = _query.trim().isEmpty
        ? 'No hay asignaciones'
        : 'Sin coincidencias para “$_query”.';

    return Scaffold(
      floatingActionButton: _cargandoInicial
          ? null
          : FabConMenuAnchor(
              onAgregar: _abrirFormNuevaAsignacion,
              onImportar: _importarAsignaciones,
              onExportar: _exportarAsignaciones,
              txtAgregar: 'Nueva asignación',
              txtImportar: 'Importar desde CSV',
              txtExportar: 'Exportar a CSV',
              iconMain: Icons.apps,
              iconAgregar: Icons.add,
              iconImportar: Icons.upload,
              iconExportar: Icons.download,
              fabTooltip: 'Acciones de asignaciones',
            ),
      body: Column(
        children: [
          // 🔎 Búsqueda SIEMPRE visible
          if (!_cargandoInicial)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: MyTextField(
                controller: _searchCtrl,
                textInputAction: TextInputAction.search,
                showClearButton: _query.isNotEmpty,
                labelText: 'Buscar asignación',
                hintText:
                    'Colaborador, distribuidor, puesto, correo, CURP/RFC…',
                onClear: () {
                  _searchCtrl.clear();
                  setState(() {
                    _query = '';
                    _page = 0;
                  });
                },
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
              ),
            ),

          // 🎛️ Filtros SIEMPRE visibles (dropdown + chip)
          if (!_cargandoInicial)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: _buildFiltros(context, distribuidores),
            ),

          Expanded(
            child: _cargandoInicial
                ? const SizedBox.shrink()
                : RefreshIndicator(
                    color: cs.secondary,
                    onRefresh: _cargarAsignaciones,
                    child: pagina.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 80),
                              Center(
                                child: Text(
                                  emptyMsg,
                                  style: tt.bodyLarge?.copyWith(
                                    color: cs.onSurface.withOpacity(0.65),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 24,
                            ),
                            itemCount: pagina.length,
                            itemBuilder: (context, index) {
                              final a = pagina[index];
                              return Card(
                                key: ValueKey(a.uid),
                                color: cs.surface,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                child: AsignacionLaboralItemTile(
                                  asignacion: a,
                                  onTap: () {},
                                  onActualizado: () async {
                                    await _cargarAsignaciones();
                                  },
                                ),
                              );
                            },
                          ),
                  ),
          ),
          if (!_cargandoInicial)
            _buildPaginador(
              context,
              total,
              start,
              end,
              totalPages,
              mostrados: pagina.length,
            ),
        ],
      ),
    );
  }

  // ----- UI: Filtros (arreglado: sin Expanded interno) -----
  Widget _buildFiltros(
    BuildContext context,
    List<DistribuidorDb> distribuidores,
  ) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final distribuidorDropdown = DropdownButtonFormField<String>(
      isExpanded: true,
      value: _filtroDistribuidorUid.isEmpty ? '' : _filtroDistribuidorUid,
      items: [
        const DropdownMenuItem(value: '', child: Text('— Todos —')),
        ...distribuidores.map(
          (d) => DropdownMenuItem(value: d.uid, child: Text(d.nombre)),
        ),
      ],
      onChanged: (v) => setState(() {
        _filtroDistribuidorUid = v ?? '';
        _page = 0; // reset paginación al filtrar
      }),
      decoration: InputDecoration(
        labelText: 'Distribuidor',
        filled: true,
        fillColor: cs.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );

    // 👇 Nunca devuelve Expanded; el padre decide si expandir o no
    Widget toggleCerradas() {
      return FilterChip(
        label: Text(_mostrarCerradas ? 'Cerradas' : 'Activas'),
        selected: _mostrarCerradas,
        onSelected: (sel) => setState(() {
          _mostrarCerradas = sel;
          _page = 0; // reset paginación
        }),
        selectedColor: cs.primary,
        checkmarkColor: cs.onPrimary,
        side: BorderSide(color: cs.outlineVariant),
        visualDensity: VisualDensity.compact,
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final bool isNarrow = constraints.maxWidth < 560;

          if (isNarrow) {
            // Column segura en pantallas pequeñas
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Filtros', style: tt.titleMedium),
                const SizedBox(height: 8),
                distribuidorDropdown,
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerLeft, child: toggleCerradas()),
              ],
            );
          }

          // Fila en pantallas anchas (sin Expanded anidado)
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Filtros', style: tt.titleMedium),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(flex: 3, child: distribuidorDropdown),
                  const SizedBox(width: 12),
                  // No lo envolvemos en Expanded para evitar ParentDataWidget issues
                  toggleCerradas(),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildPaginador(
    BuildContext context,
    int total,
    int start,
    int end,
    int totalPages, {
    required int mostrados,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Row(
        children: [
          Text(
            '$mostrados de $total',
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          IconButton(
            tooltip: 'Anterior',
            onPressed: (_page > 0) ? () => setState(() => _page--) : null,
            icon: const Icon(Icons.chevron_left),
          ),
          Text('${_page + 1} / $totalPages'),
          IconButton(
            tooltip: 'Siguiente',
            onPressed: (_page < totalPages - 1)
                ? () => setState(() => _page++)
                : null,
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  // ============================ Carga ============================

  Future<void> _cargarAsignaciones() async {
    if (!mounted) return;

    setState(() => _cargandoInicial = true);
    FocusScope.of(context).unfocus();

    context.loaderOverlay.show(progress: 'Cargando asignaciones…');
    final inicio = DateTime.now();

    try {
      final hayInternet = ref.read(connectivityProvider);

      await ref
          .read(asignacionesLaboralesProvider.notifier)
          .cargarOfflineFirst();

      const duracionMin = Duration(milliseconds: 1500);
      final delta = DateTime.now().difference(inicio);
      if (delta < duracionMin) {
        await Future.delayed(duracionMin - delta);
      }

      if (!mounted) return;
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
      if (mounted) setState(() => _cargandoInicial = false);
    }
  }

  Future<void> _abrirFormNuevaAsignacion() async {
    final ok = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AsignacionLaboralFormPage()),
    );
    if (!mounted) return;
    if (ok == true) {
      await _cargarAsignaciones();
      setState(() => _page = 0);
    }
  }

  Future<void> _importarAsignaciones() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (res == null || res.files.single.bytes == null) return;

    context.loaderOverlay.show(progress: 'Importando asignaciones…');
    try {
      final (ins, skip) = await ref
          .read(asignacionesLaboralesProvider.notifier)
          .importarCsvAsignaciones(
            csvBytes: res.files.single.bytes!,
            ignorarDuplicados: false,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Importadas: $ins • Saltadas: $skip')),
      );
      await _cargarAsignaciones();
      if (mounted) setState(() => _page = 0);
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

  Future<void> _exportarAsignaciones() async {
    context.loaderOverlay.show(progress: 'Generando CSV…');
    try {
      final path = await ref
          .read(asignacionesLaboralesProvider.notifier)
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

  // ============================ Búsqueda ============================

  List<AsignacionLaboralDb> _aplicarFiltro(
    List<AsignacionLaboralDb> lista,
    String query, {
    required Map<String, String> mapColabNombre,
    required Map<String, String> mapDistribNombre,
    required Map<String, String> mapColabTelefonos,
  }) {
    if (query.trim().isEmpty) return lista;

    final q = _normalize(query);
    final tokens = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

    return lista.where((a) {
      final (idxTexto, phoneDigits) = _buildIndex(
        a,
        mapColabNombre,
        mapDistribNombre,
        mapColabTelefonos,
      );

      final ok = tokens.every((t) {
        final isDigits = RegExp(r'^\d+$').hasMatch(t);
        if (isDigits) return phoneDigits.contains(t);
        return idxTexto.contains(t);
      });

      return ok;
    }).toList();
  }

  (String idxTexto, String phoneDigits) _buildIndex(
    AsignacionLaboralDb a,
    Map<String, String> mapColabNombre,
    Map<String, String> mapDistribNombre,
    Map<String, String> mapColabTelefonos,
  ) {
    String _tryS(String Function() f) {
      try {
        final v = f();
        return (v).toString();
      } catch (_) {
        return '';
      }
    }

    final colabUid = _tryS(() => a.colaboradorUid);
    final distUid = _tryS(() => a.distribuidorUid);

    final colaboradorNombre = mapColabNombre[colabUid] ?? '';
    final distribuidorNombre = mapDistribNombre[distUid] ?? '';
    final puesto = _tryS(() => a.puesto);
    final correo = ''; // no existe en asignación
    final curp = '';
    final rfc = '';
    final notas = _tryS(() => a.notas);
    final rol = _tryS(() => a.rol);
    final nivel = _tryS(() => a.nivel);

    final texto = [
      colaboradorNombre,
      distribuidorNombre,
      rol,
      nivel,
      puesto,
      correo,
      curp,
      rfc,
      notas,
    ].where((e) => e.isNotEmpty).join(' ');

    final idxTexto = _normalize(texto);
    final phoneDigits = mapColabTelefonos[colabUid] ?? '';

    return (idxTexto, phoneDigits);
  }

  // Helpers
  String _nombreCompletoColaborador(String? nombres, String? apP, String? apM) {
    final s = '${nombres ?? ''} ${apP ?? ''} ${apM ?? ''}'.trim();
    return s.replaceAll(RegExp(r'\s+'), ' ');
  }

  String _digitsOnly(String s) => s.replaceAll(RegExp(r'\D+'), '');

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
}

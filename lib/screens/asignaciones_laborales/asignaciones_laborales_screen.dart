import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/asignaciones_laborales/asignaciones_laborales_provider.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_provider.dart'; // ⬅️ para nombres de colaboradores
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

  // === 🔎 Estado de búsqueda ===
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  Timer? _debounce;

  // Filtros
  String _filtroDistribuidorUid = ''; // vacío => todos

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarAsignaciones();
    });

    // Búsqueda con debounce (idéntico patrón a Colaboradores)
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
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Reacciona a cambios de conectividad
    ref.listen<bool>(connectivityProvider, (prev, next) async {
      if (!mounted || prev == next) return;
      await _cargarAsignaciones();
    });

    // Disparar rebuild ante cambios de estado de asignaciones
    final _ = ref.watch(asignacionesLaboralesProvider);

    // Datos auxiliares para filtros
    final distribuidores =
        ref.watch(distribuidoresProvider).where((d) => !d.deleted).toList()
          ..sort((a, b) => a.nombre.compareTo(b.nombre));

    // 🔎 Mapas para lookup rápido de nombres
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
    // (opcional) teléfonos por colaborador para permitir búsqueda por dígitos
    final mapColabTelefonos = {
      for (final c in colaboradores)
        c.uid: _digitsOnly('${c.telefonoMovil ?? ''} '),
    };

    // Lista base visible — por distribuidor (sin activo/histórico)
    final base = ref
        .read(asignacionesLaboralesProvider.notifier)
        .listarActivas(
          distribuidorUid: _filtroDistribuidorUid.isEmpty
              ? null
              : _filtroDistribuidorUid,
        );

    // 🔎 Aplicar búsqueda usando índices enriquecidos (colaborador+distribuidor)
    final visibles = _aplicarFiltro(
      base,
      _query,
      mapColabNombre: mapColabNombre,
      mapDistribNombre: mapDistribNombre,
      mapColabTelefonos: mapColabTelefonos,
    );

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
          if (!_cargandoInicial) _buildFiltros(context, distribuidores),

          Expanded(
            child: _cargandoInicial
                ? const SizedBox.shrink()
                : RefreshIndicator(
                    color: cs.secondary,
                    onRefresh: _cargarAsignaciones,
                    child: visibles.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 80),
                              Center(
                                child: Text(
                                  _query.trim().isEmpty
                                      ? 'No hay asignaciones'
                                      : 'Sin coincidencias para “$_query”.',
                                  style: Theme.of(context).textTheme.bodyLarge
                                      ?.copyWith(
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
                            itemCount: visibles.length,
                            itemBuilder: (context, index) {
                              final a = visibles[index];
                              return Card(
                                color: cs.surface,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                child: AsignacionLaboralItemTile(
                                  key: ValueKey(a.uid),
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
        ],
      ),
    );
  }

  // ========================== Filtros UI =====================================

  Widget _buildFiltros(
    BuildContext context,
    List<DistribuidorDb> distribuidores,
  ) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        children: [
          // Filtro por Distribuidor
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  value: _filtroDistribuidorUid.isEmpty
                      ? null
                      : _filtroDistribuidorUid,
                  items: [
                    const DropdownMenuItem(value: '', child: Text('— Todos —')),
                    ...distribuidores.map(
                      (d) =>
                          DropdownMenuItem(value: d.uid, child: Text(d.nombre)),
                    ),
                  ],
                  onChanged: (v) =>
                      setState(() => _filtroDistribuidorUid = v ?? ''),
                  decoration: InputDecoration(
                    labelText: 'Distribuidor',
                    labelStyle: tt.bodyLarge?.copyWith(color: cs.onSurface),
                    filled: true,
                    fillColor: cs.surface,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // === 🔎 Barra de búsqueda ===
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: MyTextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              showClearButton: _query.isNotEmpty,
              labelText: 'Buscar asignación',
              hintText:
                  'Colaborador o distribuidor (también puesto, correo, CURP/RFC si existieran)',
              onClear: () {
                _searchCtrl.clear();
                setState(() => _query = '');
              },
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
            ),
          ),
        ],
      ),
    );
  }

  // ============================ Carga ========================================

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

      const duracionMinima = Duration(milliseconds: 1500);
      final duracion = DateTime.now().difference(inicio);
      if (duracion < duracionMinima) {
        await Future.delayed(duracionMinima - duracion);
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
      if (mounted) {
        setState(() => _cargandoInicial = false);
      }
    }
  }

  Future<void> _abrirFormNuevaAsignacion() async {
    final ok = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AsignacionLaboralFormPage(), // modo crear
      ),
    );
    if (mounted && ok == true) {
      await _cargarAsignaciones();
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

  // ===============================
  // 🔎 LÓGICA DE BÚSQUEDA / MATCHING
  // ===============================

  /// Aplica filtro local por `_query`, enriqueciendo cada asignación con:
  /// - Nombre del colaborador (mapColabNombre)
  /// - Nombre del distribuidor (mapDistribNombre)
  /// - Teléfonos del colaborador (mapColabTelefonos) — opcional
  List _aplicarFiltro(
    List lista,
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

  /// Construye índice normalizado y dígitos de teléfono para una asignación.
  /// Usa múltiples nombres posibles de campos (uuid/uid/…).
  (String idxTexto, String phoneDigits) _buildIndex(
    dynamic a,
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

    // UIDs potenciales según distintos modelos
    final colabUid = [
      _tryS(() => a.uuidColaborador),
      _tryS(() => a.colaboradorUid),
      _tryS(() => a.uidColaborador),
      _tryS(() => a.colaboradorUUID),
      _tryS(() => a.colaboradorId),
    ].firstWhere((s) => s.isNotEmpty, orElse: () => '');

    final distUid = [
      _tryS(() => a.uuidDistribuidor),
      _tryS(() => a.distribuidorUid),
      _tryS(() => a.uidDistribuidor),
      _tryS(() => a.distribuidorUUID),
      _tryS(() => a.distribuidorId),
    ].firstWhere((s) => s.isNotEmpty, orElse: () => '');

    final colaboradorNombre = mapColabNombre[colabUid] ?? '';
    final distribuidorNombre = mapDistribNombre[distUid] ?? '';

    // Otros campos locales de la asignación (si existen)
    final puesto = _tryS(() => a.puesto ?? '');
    final correo = _tryS(() => a.email ?? a.emailPersonal ?? '');
    final curp = _tryS(() => a.curp ?? '');
    final rfc = _tryS(() => a.rfc ?? '');
    final notas = _tryS(() => a.notas ?? a.observaciones ?? '');

    final texto = [
      colaboradorNombre,
      distribuidorNombre,
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

  String _nombreCompletoColaborador(String? nombres, String? apP, String? apM) {
    final s = '${nombres ?? ''} ${apP ?? ''} ${apM ?? ''}'.trim();
    return s.replaceAll(RegExp(r'\s+'), ' ');
  }

  String _digitsOnly(String s) => s.replaceAll(RegExp(r'\D+'), '');

  /// Normaliza: minúsculas, sin acentos/diéresis/ñ, y simplifica espacios.
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

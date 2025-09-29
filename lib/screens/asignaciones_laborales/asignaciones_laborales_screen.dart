import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/asignaciones_laborales/asignaciones_laborales_provider.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/screens/asignaciones_laborales/asignaciones_laborales_form_page.dart';
import 'package:myafmzd/screens/asignaciones_laborales/asignaciones_laborales_tile.dart';
import 'package:myafmzd/widgets/my_expandable_fab_options.dart';

class AsignacionesLaboralesScreen extends ConsumerStatefulWidget {
  const AsignacionesLaboralesScreen({super.key});

  @override
  ConsumerState<AsignacionesLaboralesScreen> createState() =>
      _AsignacionesLaboralesScreenState();
}

class _AsignacionesLaboralesScreenState
    extends ConsumerState<AsignacionesLaboralesScreen> {
  bool _cargandoInicial = true;

  // Filtros
  bool _soloActivas = true; // Activas (true) / Inactivas (false)
  String _filtroDistribuidorUid = ''; // vacío => todos

  @override
  void initState() {
    super.initState();
    // Mismo patrón que en las demás pantallas: disparar tras el primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarAsignaciones();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Reacciona a cambios de conectividad (con guard)
    ref.listen<bool>(connectivityProvider, (prev, next) async {
      if (!mounted || prev == next) return;
      await _cargarAsignaciones();
    });

    // Forzar rebuild ante cambios de estado
    final _ = ref.watch(asignacionesLaboralesProvider);

    // Datos auxiliares para filtros
    final distribuidores =
        ref.watch(distribuidoresProvider).where((d) => !d.deleted).toList()
          ..sort((a, b) => a.nombre.compareTo(b.nombre));

    // Lista visible (derivada del provider) — solo por distribuidor
    final visibles = _soloActivas
        ? ref
              .read(asignacionesLaboralesProvider.notifier)
              .listarActivas(
                distribuidorUid: _filtroDistribuidorUid.isEmpty
                    ? null
                    : _filtroDistribuidorUid,
              )
        : ref
              .read(asignacionesLaboralesProvider.notifier)
              .listarHistoricas(
                distribuidorUid: _filtroDistribuidorUid.isEmpty
                    ? null
                    : _filtroDistribuidorUid,
              );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Asignaciones laborales",
          style: tt.titleLarge?.copyWith(color: cs.onSurface),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
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
                ? const SizedBox.shrink() // el overlay ya muestra “Cargando…”
                : RefreshIndicator(
                    color: cs.secondary,
                    onRefresh: _cargarAsignaciones,
                    child: visibles.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: const [
                              SizedBox(height: 80),
                              Center(child: Text('No hay asignaciones')),
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
          // Línea 1: chips Activas / Inactivas
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('Activas'),
                selected: _soloActivas,
                onSelected: (v) => setState(() => _soloActivas = true),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Inactivas'),
                selected: !_soloActivas,
                onSelected: (v) => setState(() => _soloActivas = false),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Línea 2: solo filtro por Distribuidor
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _filtroDistribuidorUid.isEmpty
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
        ],
      ),
    );
  }

  // ============================ Carga ========================================

  Future<void> _cargarAsignaciones() async {
    if (!mounted) return;

    setState(() => _cargandoInicial = true);

    // UX opcional, mismo patrón
    FocusScope.of(context).unfocus();

    // OVERLAY
    context.loaderOverlay.show(progress: 'Cargando asignaciones…');

    final inicio = DateTime.now();

    try {
      final hayInternet = ref.read(connectivityProvider);

      await ref
          .read(asignacionesLaboralesProvider.notifier)
          .cargarOfflineFirst();

      // spinner mínimo para consistencia
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
            // cambia a true si quieres subir TODO sin bloquear por duplicados:
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
}

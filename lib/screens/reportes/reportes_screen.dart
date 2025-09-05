import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:myafmzd/database/reportes/reportes_provider.dart';
import 'package:myafmzd/screens/reportes/reportes_form_page.dart';
import 'package:myafmzd/widgets/visor_pdf.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/screens/reportes/reportes_tile.dart';

class ReportesScreen extends ConsumerStatefulWidget {
  const ReportesScreen({super.key});
  @override
  ConsumerState<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends ConsumerState<ReportesScreen> {
  bool _descargandoTodos = false;
  bool _cargandoInicial = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarReportes();
    });
  }

  @override
  Widget build(BuildContext context) {
    final reportesNotifier = ref.watch(reporteProvider.notifier);
    final filtrados = reportesNotifier.filtrados;
    final grupos = reportesNotifier.agruparPorTipo(filtrados);
    final tipos = grupos.keys.toList()..sort((a, b) => a.compareTo(b));
    final totalMes = filtrados.length;

    final mesesDisponibles = reportesNotifier.mesesDisponibles;
    final mesSeleccionado = reportesNotifier.mesSeleccionado;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    ref.listen<bool>(connectivityProvider, (previous, next) async {
      if (!mounted || previous == next) return;
      await _cargarReportes();
    });

    return _cargandoInicial
        // Estado inicial: sin tabs, sin filtro, sin FAB (solo el overlay visible)
        ? Scaffold(
            appBar: AppBar(
              title: Text(
                "Reportes Mensuales",
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              // OJO: sin bottom mientras carga
            ),
            body: const SizedBox.shrink(), // el overlay ya muestra “Cargando…”
            // sin FAB mientras carga
          )
        // Ya cargado: ahora sí TabController + Tabs + FAB
        : (tipos.isEmpty
              // Sin tipos: estado vacío (sin TabController para evitar length=0)
              ? Scaffold(
                  appBar: AppBar(
                    title: Text(
                      "Reportes Mensuales",
                      style: textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                    centerTitle: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    scrolledUnderElevation: 0,
                  ),
                  body: Center(
                    child: Text(
                      'No hay reportes para mostrar',
                      style: textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  floatingActionButton: FloatingActionButton(
                    onPressed: () async {
                      final resultado = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReporteFormPage(),
                        ),
                      );
                      if (mounted && resultado == true) {
                        await _cargarReportes();
                      }
                    },
                    tooltip: 'Agregar nuevo reporte',
                    child: const Icon(Icons.add),
                  ),
                )
              // Con tipos: TabController, TabBar y TabBarView sincronizados
              : DefaultTabController(
                  length: tipos.length,
                  child: Scaffold(
                    appBar: AppBar(
                      title: Text(
                        "Reportes Mensuales",
                        style: textTheme.titleLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      centerTitle: true,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      scrolledUnderElevation: 0,
                      bottom: TabBar(
                        isScrollable: true,
                        indicatorColor: colorScheme.onSurface,
                        labelColor: colorScheme.onSurface,
                        unselectedLabelColor: colorScheme.secondary.withOpacity(
                          0.6,
                        ),
                        tabs: tipos.map((t) {
                          final count = (grupos[t] ?? const []).length;
                          return Tab(text: '$t ($count)');
                        }).toList(),
                      ),
                    ),
                    floatingActionButton: FloatingActionButton(
                      onPressed: () async {
                        final resultado = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ReporteFormPage(),
                          ),
                        );
                        if (mounted && resultado == true) {
                          await _cargarReportes();
                        }
                      },
                      tooltip: 'Agregar nuevo reporte',
                      child: const Icon(Icons.add),
                    ),
                    body: Column(
                      children: [
                        if (mesesDisponibles.length > 1)
                          _buildFiltroMes(
                            mesesDisponibles,
                            mesSeleccionado,
                            totalMes,
                          ),

                        Expanded(
                          child: TabBarView(
                            children: tipos.map((tipo) {
                              final reportes = grupos[tipo] ?? [];
                              return RefreshIndicator(
                                onRefresh: _cargarReportes,
                                child: ListView.builder(
                                  physics: const BouncingScrollPhysics(
                                    parent: AlwaysScrollableScrollPhysics(),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 24,
                                  ),
                                  itemCount: reportes.length,
                                  itemBuilder: (context, index) {
                                    final reporte = reportes[index];
                                    return ReporteItemTile(
                                      key: ValueKey(reporte.uid),
                                      reporte: reporte,
                                      onTap: () async {
                                        await _abrirReporte(reporte.uid);
                                      },
                                      onActualizado: () async {
                                        await _cargarReportes();
                                      },
                                    );
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ));
  }

  Widget _buildFiltroMes(
    List<String> meses,
    String? seleccionado,
    int totalMes,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          DropdownButton<String>(
            value: seleccionado,
            onChanged: _descargandoTodos
                ? null
                : (value) {
                    if (value != null) {
                      ref.read(reporteProvider.notifier).seleccionarMes(value);
                      setState(() {});
                    }
                  },
            items: meses
                .map((mes) => DropdownMenuItem(value: mes, child: Text(mes)))
                .toList(),
          ),
          const SizedBox(width: 12),
          // 👇 Chip con el total del mes filtrado
          Chip(
            label: Text('Total reportes: $totalMes'),
            backgroundColor: colorScheme.surface,
          ),
          const SizedBox(width: 12),
          _buildAccionDescarga(),
        ],
      ),
    );
  }

  Widget _buildAccionDescarga() {
    final notifier = ref.read(reporteProvider.notifier);
    final filtrados = notifier.filtrados;

    final todos = notifier.todosDescargados(filtrados);

    return _descargandoTodos
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : todos
        ? IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Eliminar todos los reportes descargados',
            onPressed: () async {
              setState(() => _descargandoTodos = true);
              final eliminados = await notifier.eliminarTodos(filtrados);
              setState(() => _descargandoTodos = false);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('🗑️ $eliminados reporte(s) eliminado(s)'),
                ),
              );
            },
          )
        : IconButton(
            icon: const Icon(Icons.download_for_offline),
            tooltip: 'Descargar todos los reportes visibles',
            onPressed: () async {
              setState(() => _descargandoTodos = true);
              final descargados = await notifier.descargarTodos(filtrados);
              setState(() => _descargandoTodos = false);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('📥 $descargados reporte(s) descargado(s)'),
                ),
              );
            },
          );
  }

  Future<void> _cargarReportes() async {
    if (!mounted) return;

    setState(() => _cargandoInicial = true);

    // UX opcional
    FocusScope.of(context).unfocus();

    // Overlay
    context.loaderOverlay.show(progress: 'Cargando reportes…');

    final inicio = DateTime.now();

    try {
      final hayInternet = ref.read(connectivityProvider);

      await ref.read(reporteProvider.notifier).cargarOfflineFirst();

      // delay mínimo (tu mismo patrón)
      const duracionMinima = Duration(milliseconds: 1500);
      final duracion = DateTime.now().difference(inicio);
      if (duracion < duracionMinima) {
        await Future.delayed(duracionMinima - duracion);
      }

      if (!mounted) return;
      if (!hayInternet) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '📴 Estás sin conexión. Solo reportes descargados disponibles.',
            ),
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

  Future<void> _abrirReporte(String uid) async {
    final notifier = ref.read(reporteProvider.notifier);
    final reporte = notifier.obtenerPorUid(uid);
    if (reporte == null) return;

    if (!mounted) return;
    context.loaderOverlay.show(progress: 'Abriendo reporte…');
    final inicio = DateTime.now();

    File? archivo;

    try {
      // 1) Intentar local
      if (reporte.rutaLocal.isNotEmpty &&
          await File(reporte.rutaLocal).exists()) {
        archivo = File(reporte.rutaLocal);
      } else {
        // 2) Descargar si no existe local
        if (!mounted) return;
        context.loaderOverlay.progress('Descargando PDF…');

        final actualizado = await notifier.descargarPDF(reporte);
        if (actualizado != null &&
            actualizado.rutaLocal.isNotEmpty &&
            await File(actualizado.rutaLocal).exists()) {
          archivo = File(actualizado.rutaLocal);
        }
      }

      if (!mounted) return;

      if (archivo == null) {
        // Feedback si no se pudo abrir/descargar
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el reporte.')),
        );
        return;
      }

      // Delay mínimo de 1500 ms para UX consistente
      const minSpin = Duration(milliseconds: 1500);
      final elapsed = DateTime.now().difference(inicio);
      if (elapsed < minSpin) {
        await Future.delayed(minSpin - elapsed);
      }

      // Oculta overlay ANTES de navegar
      if (context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }

      // Navegar al visor
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              VisorPDF(assetPath: archivo!.path, titulo: reporte.nombre),
        ),
      );
    } finally {
      // Por si hubo excepción o return temprano
      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
    }
  }
}

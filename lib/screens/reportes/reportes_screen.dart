// lib/screens/reportes/reportes_screen.dart
// ignore_for_file: avoid_print
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

    // 🔁 Fallback de meses para UI si el provider no trae nada
    final mesesUI = _mesesParaUI(mesesDisponibles);
    // value solo si existe entre los items; si no, null + hint
    final valueUI =
        (mesSeleccionado != null && mesesUI.contains(mesSeleccionado))
        ? mesSeleccionado
        : null;

    return _cargandoInicial
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
            body: const SizedBox.shrink(),
          )
        : (tipos.isEmpty
              // ====== Estado sin tipos: mostramos SIEMPRE filtros arriba ======
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
                  body: Column(
                    children: [
                      // 👇 Filtros SIEMPRE visibles (con fallback de meses)
                      _buildFiltroMes(mesesUI, valueUI, totalMes),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Center(
                          child: Text(
                            'No hay reportes para mostrar',
                            style: textTheme.bodyLarge?.copyWith(
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    ],
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
              // ====== Con tipos: TabController + filtros SIEMPRE visibles ======
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
                        // 👇 SIEMPRE visible (antes estaba condicionado)
                        _buildFiltroMes(mesesUI, valueUI, totalMes),

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

  /// Genera lista de meses para UI. Si `backend` viene vacío, usa fallback
  /// (últimos 12 meses) en formato `YYYY-MM`, p. ej. "2025-09".
  List<String> _mesesParaUI(List<String> backend) {
    if (backend.isNotEmpty) return backend;
    final now = DateTime.now();
    return List<String>.generate(12, (i) {
      final d = DateTime(now.year, now.month - i, 1);
      final mm = d.month.toString().padLeft(2, '0');
      return '${d.year}-$mm';
    });
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
            value: seleccionado, // puede ser null → muestra hint
            hint: const Text('Selecciona mes'),
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

    FocusScope.of(context).unfocus();
    context.loaderOverlay.show(progress: 'Cargando reportes…');

    final inicio = DateTime.now();

    try {
      final hayInternet = ref.read(connectivityProvider);

      await ref.read(reporteProvider.notifier).cargarOfflineFirst();

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
      if (reporte.rutaLocal.isNotEmpty &&
          await File(reporte.rutaLocal).exists()) {
        archivo = File(reporte.rutaLocal);
      } else {
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el reporte.')),
        );
        return;
      }

      const minSpin = Duration(milliseconds: 1500);
      final elapsed = DateTime.now().difference(inicio);
      if (elapsed < minSpin) {
        await Future.delayed(minSpin - elapsed);
      }

      if (context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              VisorPDF(assetPath: archivo!.path, titulo: reporte.nombre),
        ),
      );
    } finally {
      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
    }
  }
}

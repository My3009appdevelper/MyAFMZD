import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/reportes/reportes_provider.dart';
import 'package:myafmzd/screens/reportes/reportes_form_page.dart';
import 'package:myafmzd/screens/reportes/reportes_visor_pdf.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/screens/reportes/reportes_tile.dart';

class ReportesScreen extends ConsumerStatefulWidget {
  const ReportesScreen({super.key});
  @override
  ConsumerState<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends ConsumerState<ReportesScreen> {
  bool _abriendoPdf = false;
  bool _descargandoTodos = false;
  bool _cargandoInicial = true;

  @override
  void initState() {
    super.initState();
    _cargarReportes();
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
      if (previous != next && mounted) {
        await _cargarReportes();
      }
    });

    return Stack(
      children: [
        DefaultTabController(
          key: ValueKey(tipos.join('|')),
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
              bottom: tipos.isNotEmpty
                  ? TabBar(
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
                    )
                  : null,
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                final resultado = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReporteFormPage()),
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
                  _buildFiltroMes(mesesDisponibles, mesSeleccionado, totalMes),

                Expanded(
                  child: _cargandoInicial
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
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
                                      if (_abriendoPdf) return;
                                      setState(() => _abriendoPdf = true);
                                      await _abrirReporte(reporte.uid);
                                      if (mounted) {
                                        setState(() => _abriendoPdf = false);
                                      }
                                    },
                                    onActualizado: () async {
                                      await _cargarReportes(); // ← en vez de setState()
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
        ),

        if (_abriendoPdf)
          ModalBarrier(
            dismissible: false,
            color: Colors.black.withOpacity(0.3),
          ),
        if (_abriendoPdf)
          const Center(
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text(
                      'Abriendo reporte...',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
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
            label: Text('Total: $totalMes'),
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
    final inicio = DateTime.now();

    final hayInternet = ref.read(connectivityProvider);
    await ref.read(reporteProvider.notifier).cargarOfflineFirst();

    const duracionMinima = Duration(milliseconds: 1500);
    final duracion = DateTime.now().difference(inicio);
    if (duracion < duracionMinima) {
      await Future.delayed(duracionMinima - duracion);
    }

    if (mounted) {
      setState(() => _cargandoInicial = false);

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
    }
  }

  Future<void> _abrirReporte(String uid) async {
    final notifier = ref.read(reporteProvider.notifier);
    final reporte = notifier.obtenerPorUid(uid);
    if (reporte == null) return;

    File? archivo;
    print('[📄 MENSAJES REPORTES SCREEN] Abriendo local: ${reporte.rutaLocal}');

    if (reporte.rutaLocal.isNotEmpty &&
        await File(reporte.rutaLocal).exists()) {
      archivo = File(reporte.rutaLocal);
    } else {
      print(
        '[📄 MENSAJES REPORTES SCREEN] No local → intentando descargar en línea...',
      );
      final actualizado = await notifier.descargarPDF(reporte);
      if (actualizado != null &&
          actualizado.rutaLocal.isNotEmpty &&
          await File(actualizado.rutaLocal).exists()) {
        archivo = File(actualizado.rutaLocal);
      }
    }

    if (archivo != null && mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              VisorPDF(assetPath: archivo!.path, titulo: reporte.nombre),
        ),
      );
    }
  }
}

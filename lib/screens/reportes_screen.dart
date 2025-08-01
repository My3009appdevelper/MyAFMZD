import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/reportes/reportes_provider.dart';
import 'package:myafmzd/widgets/visor_pdf.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/widgets/report_tile.dart';

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
    final notifier = ref.watch(reporteProvider.notifier);
    final filtrados = notifier.filtrados;
    final grupos = notifier.agruparPorTipo(filtrados);
    final tipos = grupos.keys.toList();

    final mesesDisponibles = notifier.mesesDisponibles;
    final mesSeleccionado = notifier.mesSeleccionado;
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
                      indicatorColor: colorScheme.primary,
                      labelColor: colorScheme.primary,
                      unselectedLabelColor: colorScheme.onSurface.withOpacity(
                        0.6,
                      ),
                      tabs: tipos.map((t) => Tab(text: t)).toList(),
                    )
                  : null,
            ),

            body: Column(
              children: [
                if (mesesDisponibles.length > 1)
                  _buildFiltroMes(mesesDisponibles, mesSeleccionado),

                Expanded(
                  child: _cargandoInicial
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          children: tipos.map((tipo) {
                            final reportes = grupos[tipo] ?? [];
                            return RefreshIndicator(
                              onRefresh: _cargarReportes,
                              child: ListView.builder(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.all(8),
                                itemCount: reportes.length,
                                itemBuilder: (context, index) {
                                  final reporte = reportes[index];
                                  return ReporteItemTile(
                                    reporte: reporte,
                                    downloading: true,
                                    onTap: () async {
                                      if (_abriendoPdf) return;
                                      setState(() => _abriendoPdf = true);
                                      await _abrirReporte(reporte.uid);
                                      if (mounted) {
                                        setState(() => _abriendoPdf = false);
                                      }
                                    },
                                    onActualizado: () => setState(() {}),
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

  Widget _buildFiltroMes(List<String> meses, String? seleccionado) {
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
    print('[📄 REPORTES SCREEN] Iniciando carga de reportes...');

    setState(() => _cargandoInicial = true);
    final inicio = DateTime.now();

    final hayInternet = ref.read(connectivityProvider);
    await ref.read(reporteProvider.notifier).cargar(hayInternet: hayInternet);

    final duracion = DateTime.now().difference(inicio);
    const duracionMinima = Duration(milliseconds: 1500);
    if (duracion < duracionMinima) {
      await Future.delayed(duracionMinima - duracion);
    }

    if (mounted) {
      setState(() => _cargandoInicial = false);

      if (!hayInternet) {
        print(
          '[📄 REPORTES SCREEN] 📴 Estás sin conexión. Solo reportes descargados disponibles.',
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '[📄 REPORTES SCREEN] 📴 Estás sin conexión. Solo reportes descargados disponibles.',
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
    print('[📄 REPORTES SCREEN] Abriendo local: ${reporte.rutaLocal}');

    if (reporte.rutaLocal.isNotEmpty &&
        await File(reporte.rutaLocal).exists()) {
      archivo = File(reporte.rutaLocal);
    } else {
      print('[📄 REPORTES SCREEN] No local → intentando descargar en línea...');
      final actualizado = await notifier.descargarPDF(reporte);
      if (actualizado != null &&
          actualizado.rutaLocal.isNotEmpty &&
          await File(actualizado.rutaLocal).exists()) {
        archivo = File(actualizado.rutaLocal);
      }
    }

    if (archivo != null && mounted) {
      print('[📄 REPORTES SCREEN] ✅ PDF abierto: ${archivo.path}');

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => VisorPDF(assetPath: archivo!.path)),
      );
    }
  }
}

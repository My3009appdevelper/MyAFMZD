import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/reportes/reportes_provider.dart';
import 'package:myafmzd/screens/reportes/visor_pdf.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/screens/reportes/report_tile.dart';

class ReportesScreen extends ConsumerStatefulWidget {
  const ReportesScreen({super.key});

  @override
  ConsumerState<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends ConsumerState<ReportesScreen> {
  bool _abriendoPdf = false;
  bool _descargandoTodos = false;
  bool _cargandoInicial = true;
  final Set<String> _descargasEnCurso = {};

  @override
  void initState() {
    super.initState();
    _cargarReportes();
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

  bool _todosDescargados(List<ReportesDb> filtrados) {
    return filtrados.every(
      (r) => r.rutaLocal.isNotEmpty && File(r.rutaLocal).existsSync(),
    );
  }

  Future<void> _descargarTodos() async {
    print('[⬇️ REPORTES SCREEN] Descargando todos los reportes visibles...');

    final notifier = ref.read(reporteProvider.notifier);
    final filtrados = notifier.filtrados;

    setState(() {
      _descargandoTodos = true;
      _descargasEnCurso
        ..clear()
        ..addAll(filtrados.map((r) => r.uid));
    });

    int descargados = 0;
    for (final r in filtrados) {
      if (r.rutaLocal.isNotEmpty && File(r.rutaLocal).existsSync()) {
        _descargasEnCurso.remove(r.uid);
        continue;
      }
      await notifier.descargarPDF(r);
      descargados++;
      setState(() => _descargasEnCurso.remove(r.uid));
    }

    setState(() => _descargandoTodos = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('📥 $descargados reporte(s) descargado(s)')),
    );
  }

  Future<void> _eliminarTodos() async {
    print('[⬇️ REPORTES SCREEN] Eliminando todos los reportes visibles...');

    final notifier = ref.read(reporteProvider.notifier);
    final filtrados = notifier.filtrados;
    int eliminados = 0;

    for (final r in filtrados) {
      if (r.rutaLocal.isNotEmpty) {
        await notifier.eliminarPDF(r);
        eliminados++;
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🗑️ $eliminados reporte(s) eliminado(s)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(reporteProvider.notifier);
    final filtrados = notifier.filtrados;
    final mesesDisponibles = notifier.mesesDisponibles;
    final mesSeleccionado = notifier.mesSeleccionado;

    ref.listen<bool>(connectivityProvider, (previous, next) async {
      if (previous != next && mounted) {
        await _cargarReportes();
      }
    });

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text(
              "Reportes Mensuales",
              style: TextStyle(color: Colors.black),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            scrolledUnderElevation: 0,
          ),

          body: Column(
            children: [
              if (mesesDisponibles.length > 1)
                _buildFiltroMes(mesesDisponibles, mesSeleccionado),

              Expanded(
                child: _cargandoInicial
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _cargarReportes,
                        child: CustomScrollView(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          slivers: [
                            if (filtrados.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: _buildEmptyState(),
                              )
                            else
                              SliverList(
                                delegate: SliverChildListDelegate(
                                  _buildSeccionesPorTipo(filtrados),
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),

        if (_abriendoPdf)
          ModalBarrier(
            dismissible: false,
            color: Colors.black.withOpacity(0.3),
          ),
        if (_abriendoPdf) _buildLoadingOverlay(),
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
          _buildAccionDescarga(ref.watch(reporteProvider.notifier).filtrados),
        ],
      ),
    );
  }

  Widget _buildAccionDescarga(List<ReportesDb> filtrados) {
    return _descargandoTodos
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : _todosDescargados(filtrados)
        ? IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Eliminar todos los reportes descargados',
            onPressed: _eliminarTodos,
          )
        : IconButton(
            icon: const Icon(Icons.download_for_offline),
            tooltip: 'Descargar todos los reportes visibles',
            onPressed: _descargarTodos,
          );
  }

  List<Widget> _buildSeccionesPorTipo(List<ReportesDb> lista) {
    final grupos = <String, List<ReportesDb>>{};
    for (final r in lista) {
      grupos.putIfAbsent(r.tipo.toUpperCase(), () => []).add(r);
    }

    return grupos.entries.map((entry) {
      final reportesOrdenados = entry.value
        ..sort((a, b) => a.nombre.compareTo(b.nombre));
      return _buildSeccion('Reportes ${entry.key}', reportesOrdenados);
    }).toList();
  }

  Widget _buildSeccion(String titulo, List<ReportesDb> reportes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Text(
            titulo,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        ...reportes.map(
          (reporte) => ReporteItemTile(
            reporte: reporte,
            onTap: () async {
              if (_abriendoPdf) return;
              setState(() => _abriendoPdf = true);
              print('[📄 REPORTES SCREEN] Tocó reporte: ${reporte.nombre}');

              try {
                File? archivo;

                // 1️⃣ Intentar abrir desde local primero
                print(
                  '[📄 REPORTES SCREEN] Abriendo local: ${reporte.rutaLocal}',
                );
                if (reporte.rutaLocal.isNotEmpty &&
                    await File(reporte.rutaLocal).exists()) {
                  archivo = File(reporte.rutaLocal);
                } else {
                  // 2️⃣ Descargar si no existe local

                  await ref
                      .read(reporteProvider.notifier)
                      .descargarPDF(reporte);
                  print(
                    '[📄 REPORTES SCREEN] No local → intentando descargar en línea...',
                  );

                  // 🔄 Obtener la versión actualizada del reporte (con rutaLocal nueva)
                  final actualizado = ref
                      .read(reporteProvider.notifier)
                      .obtenerPorUid(reporte.uid);

                  if (actualizado != null &&
                      actualizado.rutaLocal.isNotEmpty &&
                      await File(actualizado.rutaLocal).exists()) {
                    archivo = File(actualizado.rutaLocal);
                  }
                }

                if (archivo == null) {
                  if (!mounted) return;
                  print(
                    '[📄 REPORTES SCREEN] ❌ No se pudo abrir el reporte: ${reporte.nombre}',
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('❌ No se pudo abrir el reporte'),
                    ),
                  );
                  return;
                }

                if (!mounted) return;
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VisorPDF(assetPath: archivo!.path),
                  ),
                );
                print(
                  '[📄 REPORTES SCREEN] PDF abierto correctamente: ${reporte.nombre}',
                );
              } finally {
                if (mounted) setState(() => _abriendoPdf = false);
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insert_drive_file_outlined,
              size: 48,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'No hay reportes disponibles',
              style: TextStyle(fontSize: 18, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingOverlay() {
    return const Center(
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
    );
  }
}

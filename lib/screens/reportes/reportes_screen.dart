import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/models/reporte_pdf_model.dart';
import 'package:myafmzd/providers/reporte_provider.dart';
import 'package:myafmzd/screens/reportes/visor_pdf.dart';
import 'package:myafmzd/providers/connectivity_provider.dart';
import 'package:myafmzd/services/reporte_service.dart';
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

  final Set<String> _descargasEnCurso = {};

  @override
  void initState() {
    super.initState();
    _cargarReportes();
  }

  Future<void> _cargarReportes() async {
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
      setState(() {
        _cargandoInicial = false;
      });

      // 🟡 Mostrar SnackBar si no hay conexión y no lo hemos mostrado aún
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

  bool _todosDescargados(List<ReportePdf> filtrados) {
    return filtrados.every(
      (r) => r.rutaLocal != null && File(r.rutaLocal!).existsSync(),
    );
  }

  Future<void> _descargarTodos() async {
    final filtrados = ref.watch(reporteProvider.notifier).filtrados;

    setState(() {
      _descargandoTodos = true;
      _descargasEnCurso
        ..clear()
        ..addAll(filtrados.map((r) => r.rutaRemota));
    });

    int descargados = 0;

    for (final r in filtrados) {
      if (r.rutaLocal != null && File(r.rutaLocal!).existsSync()) {
        _descargasEnCurso.remove(r.rutaRemota);
        continue;
      }

      final file = await ReporteFirebaseService().descargarYGuardar(
        r.rutaRemota,
        tipo: r.tipo,
      );

      if (file != null && mounted) {
        ref
            .read(reporteProvider.notifier)
            .actualizarRutaLocal(r.rutaRemota, file.path);
        descargados++;
      }

      setState(() => _descargasEnCurso.remove(r.rutaRemota));
    }

    setState(() => _descargandoTodos = false);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('📥 $descargados reporte(s) descargado(s)')),
    );
  }

  Future<void> _eliminarTodos() async {
    final service = ReporteFirebaseService();
    final filtrados = ref.watch(reporteProvider.notifier).filtrados;
    int eliminados = 0;

    for (final r in filtrados) {
      if (r.rutaLocal != null) {
        await service.eliminarDescarga(r.rutaRemota);
        final file = File(r.rutaLocal!);
        if (await file.exists()) {
          try {
            await file.delete();
          } catch (_) {}
        }
        ref
            .read(reporteProvider.notifier)
            .actualizarRutaLocal(r.rutaRemota, null);
        eliminados++;
      }
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🗑️ $eliminados reporte(s) eliminado(s)')),
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final filtrados = ref.watch(reporteProvider.notifier).filtrados;
    final mesesDisponibles = ref
        .watch(reporteProvider.notifier)
        .mesesDisponibles;
    final mesSeleccionado = ref.watch(reporteProvider.notifier).mesSeleccionado;

    ref.listen<bool>(connectivityProvider, (previous, next) async {
      if (previous != next && mounted) {
        await _cargarReportes();
      }
    });

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: Text(
              "R e p o r t e s    M e n s u a l e s",
              style: TextStyle(color: Colors.black),
            ),
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.transparent,
            scrolledUnderElevation: 0,
          ),

          body: Column(
            children: [
              if (mesesDisponibles.length > 1)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(bottom: 4.0),
                                child: Text(
                                  'Filtro por Fecha',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              DropdownButton<String>(
                                value: mesSeleccionado,
                                onChanged: _descargandoTodos
                                    ? null
                                    : (value) {
                                        if (value != null) {
                                          setState(() {
                                            ref
                                                .read(reporteProvider.notifier)
                                                .seleccionarMes(value);
                                          });
                                        }
                                      },

                                items: mesesDisponibles.map((mes) {
                                  return DropdownMenuItem(
                                    value: mes,
                                    child: Text(mes),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),

                          const SizedBox(width: 12),
                          Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Text(
                                  _todosDescargados(filtrados)
                                      ? 'Descargado Todo'
                                      : 'Descargar Todos',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),

                              _descargandoTodos
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : _todosDescargados(filtrados)
                                  ? IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      tooltip:
                                          'Eliminar todos los reportes descargados',
                                      onPressed: () async {
                                        final confirmar = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text(
                                              '¿Eliminar reportes descargados?',
                                            ),
                                            content: const Text(
                                              '¿Quieres eliminar todos los reportes descargados actualmente visibles?',
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  false,
                                                ),
                                                child: const Text('Cancelar'),
                                              ),
                                              TextButton(
                                                onPressed: () => Navigator.pop(
                                                  context,
                                                  true,
                                                ),
                                                child: const Text('Eliminar'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirmar == true) {
                                          await _eliminarTodos();
                                        }
                                      },
                                    )
                                  : IconButton(
                                      icon: const Icon(
                                        Icons.download_for_offline,
                                      ),
                                      tooltip:
                                          'Descargar todos los reportes visibles',
                                      onPressed: _descargarTodos,
                                    ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              Expanded(
                child: _cargandoInicial
                    ? const Center(child: CircularProgressIndicator())
                    : RefreshIndicator(
                        onRefresh: _cargarReportes,
                        elevation: 0,
                        child: CustomScrollView(
                          physics: const BouncingScrollPhysics(
                            parent: AlwaysScrollableScrollPhysics(),
                          ),
                          slivers: [
                            if (filtrados.isEmpty)
                              SliverFillRemaining(
                                hasScrollBody: false,
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(32.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: const [
                                        Icon(
                                          Icons.insert_drive_file_outlined,
                                          size: 48,
                                          color: Colors.grey,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'No hay reportes disponibles',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.grey,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              )
                            else
                              SliverList(
                                delegate: SliverChildListDelegate(
                                  _buildSeccionesPorTipo(),
                                ),
                              ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),

        // Overlay de carga
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

  List<Widget> _buildSeccionesPorTipo() {
    final filtrados = ref.watch(reporteProvider.notifier).filtrados;

    final entries = filtrados
        .fold<Map<String, List<ReportePdf>>>({}, (mapa, r) {
          final tipo = r.tipo.toUpperCase();
          mapa.putIfAbsent(tipo, () => []).add(r);
          return mapa;
        })
        .entries
        .toList();

    entries.sort((a, b) => a.key.compareTo(b.key));

    return entries.map((entry) {
      final reportesOrdenados = entry.value
        ..sort((a, b) => a.nombre.compareTo(b.nombre));
      return _buildSeccion('Reportes ${entry.key}', reportesOrdenados);
    }).toList();
  }

  Widget _buildSeccion(String titulo, List<ReportePdf> reportes) {
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
            onChanged: () {
              setState(() {}); // Forzar reconstrucción del botón superior
            },
            downloading: _descargasEnCurso.contains(reporte.rutaRemota),
            onTap: () async {
              if (_abriendoPdf) return; // 🔒 Ignora si ya está abriendo uno

              setState(() => _abriendoPdf = true); // 🟡 Bloquea interacciones

              final inicio = DateTime.now();

              try {
                File? archivo;

                if (reporte.rutaLocal != null) {
                  archivo = File(reporte.rutaLocal!);
                } else {
                  archivo = await ReporteFirebaseService().descargarTemporal(
                    reporte.rutaRemota,
                  );
                }

                // ⏱ Espera que se cumplan al menos 800ms de carga visual
                final duracion = DateTime.now().difference(inicio);
                final esperaMinima = const Duration(milliseconds: 800);
                if (duracion < esperaMinima) {
                  await Future.delayed(esperaMinima - duracion);
                }

                if (!mounted || archivo == null) return;

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => VisorPDF(assetPath: archivo!.path),
                  ),
                );
              } catch (e) {
                debugPrint('❌ Error al abrir PDF: $e');
              } finally {
                if (mounted) setState(() => _abriendoPdf = false);
              }
            },
          ),
        ),
      ],
    );
  }
}

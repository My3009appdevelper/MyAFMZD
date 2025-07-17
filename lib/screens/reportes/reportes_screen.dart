import 'dart:async';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:myafmzd/models/reporte_pdf_model.dart';
import 'package:myafmzd/screens/reportes/visor_pdf.dart';
import 'package:myafmzd/services/connectivity_service.dart';
import 'package:myafmzd/services/reporte_firebase_service.dart';
import 'package:myafmzd/widgets/app_drawer.dart';
import 'package:myafmzd/widgets/report_tile.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  List<ReportePdf> _todos = [];
  List<ReportePdf> _filtrados = [];
  List<String> _mesesDisponibles = ['Todos'];
  String _mesSeleccionado = 'Todos';
  bool _abriendoPdf = false;
  bool _descargandoTodos = false;

  late StreamSubscription<List<ConnectivityResult>> _connectivitySubscription;
  bool _hayConexion = true;

  final List<String> _amdaNombres = [
    'AFMZD En El Sector De Autofinanciamiento',
    'Autofinanciamiento Por Estado',
    'Informe Ejecutivo 1P',
    'Promedios AMDA Estimado Cierre',
  ];

  @override
  void initState() {
    super.initState();
    _cargarReportes();

    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) async {
      final hasInternet = await ConnectivityService().hasInternet();

      if (mounted) {
        setState(() {
          _hayConexion = hasInternet;
        });
      }

      if (hasInternet) {
        _cargarReportes();
      } else {
        _todos = await ReporteFirebaseService().cargarSoloDescargados();
        final meses = await ReporteFirebaseService().listarFechasUnicas(_todos);

        if (mounted) {
          setState(() {
            _filtrados = _todos;
            _mesesDisponibles = meses;
          });
          _filtrar(_mesSeleccionado);
        }
      }
    });
  }

  @override
  void dispose() {
    _connectivitySubscription.cancel();
    super.dispose();
  }

  void _cargarReportes() async {
    final conn = await ConnectivityService().hasInternet();

    List<ReportePdf> nuevos;
    if (conn) {
      nuevos = await ReporteFirebaseService().listarReportesDesdeFirebase();
    } else {
      nuevos = await ReporteFirebaseService().cargarSoloDescargados();
    }

    final meses = await ReporteFirebaseService().listarFechasUnicas(nuevos);

    setState(() {
      _todos = nuevos; // ✅ Esto sí actualiza
      _mesesDisponibles = meses;
    });

    _filtrar(_mesSeleccionado); // ✅ Se aplica a la lista correcta
  }

  void _filtrar(String mes) {
    setState(() {
      _mesSeleccionado = mes;
      if (mes == 'Todos') {
        _filtrados = _todos;
      } else {
        _filtrados = _todos.where((r) {
          final formatoMes =
              '${r.fecha.year.toString().padLeft(4, '0')}-${r.fecha.month.toString().padLeft(2, '0')}';
          return formatoMes == mes;
        }).toList();
      }
    });
  }

  bool _esAmda(ReportePdf r) {
    final nombreNormalizado = r.nombre.toLowerCase().trim();
    return _amdaNombres.any((n) => n.toLowerCase().trim() == nombreNormalizado);
  }

  bool _todosDescargados() {
    return _filtrados.every(
      (r) => r.rutaLocal != null && File(r.rutaLocal!).existsSync(),
    );
  }

  Future<void> _descargarTodos() async {
    setState(() => _descargandoTodos = true);

    final reportes = _filtrados;
    int descargados = 0;

    for (final r in reportes) {
      if (r.rutaLocal != null && File(r.rutaLocal!).existsSync()) continue;

      final file = await ReporteFirebaseService().descargarYGuardar(
        r.rutaRemota,
      );
      if (file != null) {
        r.rutaLocal = file.path;
        descargados++;
      }
    }

    setState(() => _descargandoTodos = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('📥 $descargados reporte(s) descargado(s)')),
    );
  }

  Future<void> _eliminarDescargasFiltradas() async {
    final service = ReporteFirebaseService();

    int eliminados = 0;

    for (final r in _filtrados) {
      if (r.rutaLocal != null && File(r.rutaLocal!).existsSync()) {
        await service.eliminarDescarga(r.rutaRemota);
        eliminados++;
        r.rutaLocal = null; // Limpiar en memoria también
      }
    }

    setState(() {}); // Refresca UI

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('🗑️ $eliminados descarga(s) eliminada(s)')),
    );
  }

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    final amdaReportes = _filtrados.where(_esAmda).toList();
    final internosReportes = _filtrados.where((r) => !_esAmda(r)).toList();

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Center(child: Text("Reportes mensuales")),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Tooltip(
                  message: _hayConexion
                      ? 'Conectado a Internet'
                      : 'Sin conexión',
                  child: Icon(
                    _hayConexion ? Icons.wifi : Icons.wifi_off,
                    color: colorScheme.onPrimary,
                  ),
                ),
              ),
            ],
          ),
          drawer: const AppDrawer(),
          body: Column(
            children: [
              if (_mesesDisponibles.length > 1)
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
                                value: _mesSeleccionado,
                                onChanged: (value) => _filtrar(value!),
                                items: _mesesDisponibles.map((mes) {
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
                                  _todosDescargados()
                                      ? 'Descargado'
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
                                  : _todosDescargados()
                                  ? IconButton(
                                      icon: const Icon(Icons.delete_outline),
                                      tooltip:
                                          'Eliminar todos los descargados del mes',
                                      onPressed: () async {
                                        final confirmar = await showDialog<bool>(
                                          context: context,
                                          builder: (context) => AlertDialog(
                                            title: const Text(
                                              '¿Eliminar descargas?',
                                            ),
                                            content: const Text(
                                              '¿Quieres eliminar todos los reportes descargados de este filtro?',
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
                                          await _eliminarDescargasFiltradas();
                                        }
                                      },
                                    )
                                  : IconButton(
                                      icon: const Icon(
                                        Icons.download_for_offline,
                                      ),
                                      tooltip: 'Descargar todos',
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
                child: ListView(
                  children: [
                    if (amdaReportes.isNotEmpty)
                      _buildSeccion('Reportes AMDA', amdaReportes),
                    if (internosReportes.isNotEmpty)
                      _buildSeccion('Reportes Internos', internosReportes),
                  ],
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

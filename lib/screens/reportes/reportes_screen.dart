import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:myafmzd/models/reporte_pdf_model.dart';
import 'package:myafmzd/screens/reportes/visor_pdf.dart';
import 'package:myafmzd/services/connectivity_service.dart';
import 'package:myafmzd/services/reporte_firebase_service.dart';
import 'package:myafmzd/services/reporte_service.dart';
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
        final meses = await ReportesService().listarFechasUnicas(_todos);

        if (mounted) {
          setState(() {
            _filtrados = _todos;
            _mesesDisponibles = meses;
          });
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

    if (conn) {
      // Con Internet: lista remotos (con persistencia)
      _todos = await ReporteFirebaseService().listarReportesDesdeFirebase();
    } else {
      // Sin Internet: solo descargados
      _todos = await ReporteFirebaseService().cargarSoloDescargados();
    }

    final meses = await ReportesService().listarFechasUnicas(_todos);

    setState(() {
      _filtrados = _todos;
      _mesesDisponibles = meses;
    });
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

  @override
  Widget build(BuildContext context) {
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    final amdaReportes = _filtrados.where(_esAmda).toList();
    final internosReportes = _filtrados.where((r) => !_esAmda(r)).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Center(child: Text("Reportes mensuales")),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Tooltip(
              message: _hayConexion ? 'Conectado a Internet' : 'Sin conexión',
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
                      return DropdownMenuItem(value: mes, child: Text(mes));
                    }).toList(),
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
              final ruta = reporte.rutaLocal;

              if (ruta != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => VisorPDF(assetPath: ruta)),
                );
              } else {
                // abrir desde Firebase sin guardar
                final archivoTemp = await ReporteFirebaseService()
                    .descargarTemporal(reporte.rutaRemota);
                if (archivoTemp != null) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VisorPDF(assetPath: archivoTemp.path),
                    ),
                  );
                }
              }
            },
          ),
        ),
      ],
    );
  }
}

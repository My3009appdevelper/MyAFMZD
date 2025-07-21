import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/screens/distribuidores_screen.dart';
import 'package:myafmzd/screens/reportes/reportes_screen.dart';
import 'package:myafmzd/services/connectivity_provider.dart';
import 'package:myafmzd/widgets/app_drawer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _indiceActual = 0;

  final List<Widget> _pantallas = const [
    ReportesScreen(),
    DistribuidoresScreen(),
    // Agrega aquí más pantallas si tienes
  ];

  @override
  Widget build(BuildContext context) {
    final bool hayConexion = ref.watch(connectivityProvider);

    return Scaffold(
      appBar: AppBar(
        title: Center(child: const Text("AFMZD")),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Tooltip(
              message: hayConexion
                  ? 'Conectado a Internet'
                  : 'Sin conexión a Internet',
              child: Icon(
                hayConexion ? Icons.wifi : Icons.wifi_off,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _pantallas[_indiceActual],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceActual,
        onTap: (index) {
          setState(() {
            _indiceActual = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.picture_as_pdf),
            label: 'Reportes',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_on),
            label: 'Distribuidores',
          ),
          // Más items si es necesario
        ],
      ),
    );
  }
}

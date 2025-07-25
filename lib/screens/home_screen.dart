import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/providers/distribuidor_provider.dart';
import 'package:myafmzd/providers/reporte_provider.dart';
import 'package:myafmzd/providers/perfil_provider.dart';
import 'package:myafmzd/providers/usuarios_provider.dart';
import 'package:myafmzd/screens/distribuidores_screen.dart';
import 'package:myafmzd/screens/perfil_screen.dart';
import 'package:myafmzd/screens/reportes/reportes_screen.dart';
import 'package:myafmzd/providers/connectivity_provider.dart';
import 'package:myafmzd/screens/usuarios_screen.dart';
import 'package:myafmzd/widgets/app_drawer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _indiceActual = 0;

  final List<Widget> _pantallas = const [
    PerfilScreen(),
    UsuariosScreen(),
    ReportesScreen(),
    DistribuidoresScreen(),

    // Agrega aquí más pantallas si tienes
  ];

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final hayInternet = ref.read(connectivityProvider);
      await ref
          .read(reporteProvider.notifier)
          .cargar(hayInternet: hayInternet, forzar: true);

      await ref
          .read(distribuidoresProvider.notifier)
          .cargar(hayInternet: hayInternet, forzar: true);

      await ref
          .read(perfilProvider.notifier)
          .cargarUsuario(hayInternet: hayInternet, forzar: true);
      await ref
          .read(usuariosProvider.notifier)
          .cargar(hayInternet: hayInternet, forzar: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hayConexion = ref.watch(connectivityProvider);
    ColorScheme colorScheme = Theme.of(context).colorScheme;

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
        backgroundColor: colorScheme.primary,
        currentIndex: _indiceActual,
        onTap: (index) {
          setState(() {
            _indiceActual = index;
          });
        },
        items: [
          BottomNavigationBarItem(
            backgroundColor: colorScheme.primary,
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
          BottomNavigationBarItem(
            backgroundColor: colorScheme.primary,
            icon: Icon(Icons.person),
            label: 'Usuarios',
          ),
          BottomNavigationBarItem(
            backgroundColor: colorScheme.primary,
            icon: Icon(Icons.picture_as_pdf),
            label: 'Reportes',
          ),
          BottomNavigationBarItem(
            backgroundColor: colorScheme.primary,
            icon: Icon(Icons.location_on),
            label: 'Distribuidores',
          ),
          // Más items si es necesario
        ],
      ),
    );
  }
}

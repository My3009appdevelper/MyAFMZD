import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/screens/login/perfil_provider.dart';
import 'package:myafmzd/database/reportes/reportes_provider.dart';
import 'package:myafmzd/database/usuarios/usuarios_provider.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/screens/distribuidores/distribuidores_screen.dart';
import 'package:myafmzd/screens/perfil_screen.dart';
import 'package:myafmzd/screens/reportes/reportes_screen.dart';
import 'package:myafmzd/screens/usuarios/usuarios_screen.dart';
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
      await ref.read(reporteProvider.notifier).cargarOfflineFirst();

      await ref.read(usuariosProvider.notifier).cargarOfflineFirst();

      await ref.read(distribuidoresProvider.notifier).cargarOfflineFirst();

      await ref.read(perfilProvider.notifier).cargarUsuario();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hayConexion = ref.watch(connectivityProvider);
    ColorScheme colorScheme = Theme.of(context).colorScheme;
    TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            "MyAFMZD",
            style: textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Tooltip(
              message: hayConexion
                  ? 'Conectado a Internet'
                  : 'Sin conexión a Internet',
              child: Icon(
                hayConexion ? Icons.wifi : Icons.wifi_off,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _pantallas[_indiceActual],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indiceActual,
        backgroundColor: colorScheme.primary,

        selectedItemColor: colorScheme.onPrimary,
        selectedLabelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.bold,
          color: colorScheme.onPrimary,
        ),

        unselectedItemColor: colorScheme.onPrimary.withOpacity(.3),
        unselectedLabelStyle: textTheme.labelLarge?.copyWith(
          color: colorScheme.secondary,
        ),

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

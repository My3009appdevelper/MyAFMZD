import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/asignaciones_laborales/asignaciones_laborales_provider.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_provider.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/database/estatus/estatus_provider.dart';
import 'package:myafmzd/database/modelos/modelo_imagenes_provider.dart';
import 'package:myafmzd/database/modelos/modelos_provider.dart';
import 'package:myafmzd/database/perfil/perfil_provider.dart';
import 'package:myafmzd/database/productos/productos_provider.dart';
import 'package:myafmzd/database/reportes/reportes_provider.dart';
import 'package:myafmzd/database/usuarios/usuarios_provider.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/screens/asignaciones_laborales/asignaciones_laborales_screen.dart';
import 'package:myafmzd/screens/colaboradores/colaboradores_screen.dart';
import 'package:myafmzd/screens/estatus/estatus_screen.dart';
import 'package:myafmzd/screens/usuarios/usuarios_screen.dart';
import 'package:myafmzd/screens/productos/productos_screen.dart';
import 'package:myafmzd/widgets/my_app_drawer.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<AdminHomeScreen> {
  int _indiceActual = 0;

  // 👇 Nuevo orden
  final List<Widget> _pantallas = const [
    ColaboradoresScreen(), // 1
    AsignacionesLaboralesScreen(), // 2
    UsuariosScreen(), // 3
    ProductosScreen(), // 4
    EstatusScreen(), // 5
  ];

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await ref.read(perfilProvider.notifier).cargarUsuario();
      await ref.read(modelosProvider.notifier).cargarOfflineFirst();
      await ref.read(modeloImagenesProvider.notifier).cargarOfflineFirst();
      await ref.read(distribuidoresProvider.notifier).cargarOfflineFirst();
      await ref.read(reporteProvider.notifier).cargarOfflineFirst();
      await ref.read(colaboradoresProvider.notifier).cargarOfflineFirst();
      await ref
          .read(asignacionesLaboralesProvider.notifier)
          .cargarOfflineFirst();
      await ref.read(usuariosProvider.notifier).cargarOfflineFirst();
      await ref.read(productosProvider.notifier).cargarOfflineFirst();
      await ref.read(estatusProvider.notifier).cargarOfflineFirst();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hayConexion = ref.watch(connectivityProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            "Admin MyAFMZD",
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
      drawer: const MyAppDrawer(),
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
        onTap: (index) => setState(() => _indiceActual = index),
        items: [
          // 1 Colaboradores
          BottomNavigationBarItem(
            backgroundColor: colorScheme.primary,
            icon: Icon(Icons.group),
            label: 'Colaboradores',
          ),
          // 2 Asignaciones
          BottomNavigationBarItem(
            backgroundColor: colorScheme.primary,
            icon: Icon(Icons.assignment_ind),
            label: 'Asignaciones',
          ),
          // 3 Usuarios
          BottomNavigationBarItem(
            backgroundColor: colorScheme.primary,
            icon: Icon(Icons.manage_accounts),
            label: 'Usuarios',
          ),
          // 4 Productos
          BottomNavigationBarItem(
            backgroundColor: colorScheme.primary,
            icon: Icon(Icons.inventory_2),
            label: 'Productos',
          ),
          BottomNavigationBarItem(
            backgroundColor: colorScheme.primary,
            icon: Icon(Icons.label_important_outline),
            label: 'Estatus',
          ),
        ],
      ),
    );
  }
}

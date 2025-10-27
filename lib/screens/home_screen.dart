import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/asignaciones_laborales/asignaciones_laborales_provider.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_provider.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/database/grupo_distribuidores/grupos_distribuidores_provider.dart';
import 'package:myafmzd/database/modelos/modelo_imagenes_provider.dart';
import 'package:myafmzd/database/modelos/modelos_provider.dart';
import 'package:myafmzd/database/perfil/perfil_provider.dart';
import 'package:myafmzd/database/productos/productos_provider.dart';
import 'package:myafmzd/database/reportes/reportes_provider.dart';
import 'package:myafmzd/database/usuarios/usuarios_provider.dart';
import 'package:myafmzd/database/ventas/ventas_provider.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/screens/distribuidores/distribuidores_screen.dart';
import 'package:myafmzd/screens/modelos/modelos_screen.dart';
import 'package:myafmzd/screens/perfil/perfil_screen.dart';
import 'package:myafmzd/screens/reportes/reportes_screen.dart';
import 'package:myafmzd/session/pemisos_acceso.dart';
import 'package:myafmzd/widgets/my_app_drawer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _indiceActual = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      // 1) Captura notifiers una sola vez (esto NO usa ref después de awaits)
      final perfilN = ref.read(perfilProvider.notifier);
      final modelosN = ref.read(modelosProvider.notifier);
      final modeloImgsN = ref.read(modeloImagenesProvider.notifier);
      final distribuidoresN = ref.read(distribuidoresProvider.notifier);
      final gruposDistN = ref.read(gruposDistribuidoresProvider.notifier);
      final reportesN = ref.read(reporteProvider.notifier);
      final colaboradoresN = ref.read(colaboradoresProvider.notifier);
      final asignacionesN = ref.read(asignacionesLaboralesProvider.notifier);
      final usuariosN = ref.read(usuariosProvider.notifier);
      final productosN = ref.read(productosProvider.notifier);
      final ventasN = ref.read(ventasProvider.notifier);

      // 2) Llama a los métodos usando los notifiers guardados
      await perfilN.cargarUsuario();
      if (!mounted) return;

      await modelosN.cargarOfflineFirst();
      if (!mounted) return;

      await modeloImgsN.cargarOfflineFirst();
      if (!mounted) return;

      await distribuidoresN.cargarOfflineFirst();
      if (!mounted) return;

      await gruposDistN.cargarOfflineFirst();
      if (!mounted) return;

      await reportesN.cargarOfflineFirst();
      if (!mounted) return;

      await colaboradoresN.cargarOfflineFirst();
      if (!mounted) return;

      await asignacionesN.cargarOfflineFirst();
      if (!mounted) return;

      await usuariosN.cargarOfflineFirst();
      if (!mounted) return;

      await productosN.cargarOfflineFirst();
      if (!mounted) return;

      await ventasN.cargarOfflineFirst();
      if (!mounted) return;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hayConexion = ref.watch(connectivityProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 🎯 Nuevo sistema de permisos basado en Policy (RBAC)
    final policy = ref.watch(appPolicyProvider);

    // Construimos las pantallas visibles según permisos NAV
    final pantallasVisibles = <Widget>[];
    final itemsVisibles = <BottomNavigationBarItem>[];

    if (policy.can(Resource.perfil, ActionType.nav)) {
      pantallasVisibles.add(const PerfilScreen());
      itemsVisibles.add(
        BottomNavigationBarItem(
          backgroundColor: colorScheme.primary,
          icon: const Icon(Icons.person),
          label: 'Perfil',
        ),
      );
    }

    if (policy.can(Resource.modelos, ActionType.nav)) {
      pantallasVisibles.add(const ModelosScreen());
      itemsVisibles.add(
        BottomNavigationBarItem(
          backgroundColor: colorScheme.primary,
          icon: const Icon(Icons.directions_car),
          label: 'Modelos',
        ),
      );
    }

    if (policy.can(Resource.distribuidores, ActionType.nav)) {
      pantallasVisibles.add(const DistribuidoresScreen());
      itemsVisibles.add(
        BottomNavigationBarItem(
          backgroundColor: colorScheme.primary,
          icon: const Icon(Icons.location_on),
          label: 'Distribuidoras',
        ),
      );
    }

    if (policy.can(Resource.reportes, ActionType.nav)) {
      pantallasVisibles.add(const ReportesScreen());
      itemsVisibles.add(
        BottomNavigationBarItem(
          backgroundColor: colorScheme.primary,
          icon: const Icon(Icons.picture_as_pdf),
          label: 'Reportes',
        ),
      );
    }

    // 🔒 Defensa: si hay 0 o 1 tabs, mostramos esa pantalla sola
    if (pantallasVisibles.length <= 1) {
      return Scaffold(
        appBar: AppBar(
          title: Center(
            child: Text(
              "MyAFMZD",
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onPrimary,
              ),
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
        drawer: const MyAppDrawer(current: DrawerDest.home),
        body: pantallasVisibles.isEmpty
            ? const Center(
                child: Text('No tienes secciones disponibles para tu rol.'),
              )
            : pantallasVisibles.first, // ✅ Muestra la única pantalla
      );
    }

    // 🔒 Defensa: si ningún NAV está permitido, mostrar placeholder
    if (pantallasVisibles.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Center(
            child: Text(
              "MyAFMZD",
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onPrimary,
              ),
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
        body: const Center(
          child: Text('No tienes secciones disponibles para tu rol.'),
        ),
      );
    }

    // Ajuste si el índice actual se sale del rango
    if (_indiceActual >= pantallasVisibles.length) {
      _indiceActual = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            itemsVisibles[_indiceActual].label ?? 'MyAFMZD',
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
      body: pantallasVisibles[_indiceActual],
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
        items: itemsVisibles,
      ),
    );
  }
}

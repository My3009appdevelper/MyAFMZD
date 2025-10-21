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
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/usuarios/usuarios_provider.dart';
import 'package:myafmzd/database/ventas/ventas_provider.dart';
import 'package:myafmzd/screens/distribuidores/distribuidores_screen.dart';
import 'package:myafmzd/screens/modelos/modelos_screen.dart';
import 'package:myafmzd/screens/perfil/perfil_screen.dart';
import 'package:myafmzd/screens/reportes/reportes_screen.dart';
import 'package:myafmzd/widgets/my_app_drawer.dart';

// 👇 Asegúrate de importar tu provider de permisos
import 'package:myafmzd/session/permisos.dart';

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
      await ref.read(perfilProvider.notifier).cargarUsuario();
      await ref.read(modelosProvider.notifier).cargarOfflineFirst();
      await ref.read(modeloImagenesProvider.notifier).cargarOfflineFirst();
      await ref.read(distribuidoresProvider.notifier).cargarOfflineFirst();
      await ref
          .read(gruposDistribuidoresProvider.notifier)
          .cargarOfflineFirst();
      await ref.read(reporteProvider.notifier).cargarOfflineFirst();
      await ref.read(colaboradoresProvider.notifier).cargarOfflineFirst();
      await ref
          .read(asignacionesLaboralesProvider.notifier)
          .cargarOfflineFirst();
      await ref.read(usuariosProvider.notifier).cargarOfflineFirst();
      await ref.read(productosProvider.notifier).cargarOfflineFirst();
      await ref.read(ventasProvider.notifier).cargarOfflineFirst();
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool hayConexion = ref.watch(connectivityProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 👇 permisos derivados de la asignación activa
    final perms = ref.watch(appPermissionsProvider);

    // Construimos listas visibles según permisos (¡sin romper el orden!).
    final pantallasVisibles = <Widget>[];
    final itemsVisibles = <BottomNavigationBarItem>[];

    if (perms.can(Feature.navPerfil)) {
      pantallasVisibles.add(const PerfilScreen());
      itemsVisibles.add(
        BottomNavigationBarItem(
          backgroundColor: colorScheme.primary,
          icon: const Icon(Icons.person),
          label: 'Perfil',
        ),
      );
    }

    if (perms.can(Feature.navModelos)) {
      pantallasVisibles.add(const ModelosScreen());
      itemsVisibles.add(
        BottomNavigationBarItem(
          backgroundColor: colorScheme.primary,
          icon: const Icon(Icons.directions_car),
          label: 'Modelos',
        ),
      );
    }
    if (perms.can(Feature.navDistribuidores)) {
      pantallasVisibles.add(const DistribuidoresScreen());
      itemsVisibles.add(
        BottomNavigationBarItem(
          backgroundColor: colorScheme.primary,
          icon: const Icon(Icons.location_on),
          label: 'Distribuidoras',
        ),
      );
    }
    if (perms.can(Feature.navReportes)) {
      pantallasVisibles.add(const ReportesScreen());
      itemsVisibles.add(
        BottomNavigationBarItem(
          backgroundColor: colorScheme.primary,
          icon: const Icon(Icons.picture_as_pdf),
          label: 'Reportes',
        ),
      );
    }

    // 🔒 Defensa anti-crash: si por permisos no hay tabs, mostramos un placeholder.
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

    // Si el índice actual queda fuera de rango por un cambio de rol/asignación, lo reajustamos.
    if (_indiceActual >= pantallasVisibles.length) {
      _indiceActual = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            // ⬇️ título dinámico según la pestaña seleccionada
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

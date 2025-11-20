import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';

import 'package:myafmzd/connectivity/connectivity_provider.dart';

// Cargas iniciales (offline-first), igual que HomeScreen
import 'package:myafmzd/database/perfil/perfil_provider.dart';
import 'package:myafmzd/database/modelos/modelos_provider.dart';
import 'package:myafmzd/database/modelos/modelo_imagenes_provider.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/database/grupo_distribuidores/grupos_distribuidores_provider.dart';
import 'package:myafmzd/database/reportes/reportes_provider.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_provider.dart';
import 'package:myafmzd/database/asignaciones_laborales/asignaciones_laborales_provider.dart';
import 'package:myafmzd/database/usuarios/usuarios_provider.dart';
import 'package:myafmzd/database/productos/productos_provider.dart';
import 'package:myafmzd/database/estatus/estatus_provider.dart';
import 'package:myafmzd/database/ventas/ventas_provider.dart';

// Pantallas admin
import 'package:myafmzd/screens/colaboradores/colaboradores_screen.dart';
import 'package:myafmzd/screens/asignaciones_laborales/asignaciones_laborales_screen.dart';
import 'package:myafmzd/screens/usuarios/usuarios_screen.dart';
import 'package:myafmzd/screens/ventas/ventas_screen.dart';
import 'package:myafmzd/screens/productos/productos_screen.dart';
import 'package:myafmzd/screens/grupos_distribuidores/grupos_distribuidores_screen.dart';
import 'package:myafmzd/screens/estatus/estatus_screen.dart';

// Permisos RBAC
import 'package:myafmzd/session/pemisos_acceso.dart';

// Drawer
import 'package:myafmzd/widgets/my_app_drawer.dart';

// Supabase (para refreshSession)
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  int _indiceActual = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() async {
      await _recargarTodo();
    });
  }

  @override
  Widget build(BuildContext context) {
    final hayConexion = ref.watch(connectivityProvider);
    final policy = ref.watch(appPolicyProvider);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Construye tabs admin dinámicamente según permisos NAV
    final pantallasVisibles = <Widget>[];
    final itemsVisibles = <BottomNavigationBarItem>[];

    if (policy.can(Resource.colaboradores, ActionType.nav)) {
      pantallasVisibles.add(const ColaboradoresScreen());
      itemsVisibles.add(
        BottomNavigationBarItem(
          backgroundColor: colorScheme.primary,
          icon: const Icon(Icons.group),
          label: 'Colaboradores',
        ),
      );
    }

    if (policy.can(Resource.asignacionesLaborales, ActionType.nav)) {
      pantallasVisibles.add(const AsignacionesLaboralesScreen());
      itemsVisibles.add(
        BottomNavigationBarItem(
          backgroundColor: colorScheme.primary,
          icon: const Icon(Icons.assignment_ind),
          label: 'Asignaciones',
        ),
      );
    }

    if (policy.can(Resource.usuarios, ActionType.nav)) {
      pantallasVisibles.add(const UsuariosScreen());
      itemsVisibles.add(
        BottomNavigationBarItem(
          backgroundColor: colorScheme.primary,
          icon: const Icon(Icons.manage_accounts),
          label: 'Usuarios',
        ),
      );
    }

    if (policy.can(Resource.ventas, ActionType.nav)) {
      pantallasVisibles.add(const VentasScreen());
      itemsVisibles.add(
        BottomNavigationBarItem(
          backgroundColor: colorScheme.primary,
          icon: const Icon(Icons.point_of_sale),
          label: 'Ventas',
        ),
      );
    }

    if (policy.can(Resource.productos, ActionType.nav)) {
      pantallasVisibles.add(const ProductosScreen());
      itemsVisibles.add(
        BottomNavigationBarItem(
          backgroundColor: colorScheme.primary,
          icon: const Icon(Icons.inventory_2),
          label: 'Productos',
        ),
      );
    }

    if (policy.can(Resource.gruposDistribuidores, ActionType.nav)) {
      pantallasVisibles.add(const GruposDistribuidoresScreen());
      itemsVisibles.add(
        BottomNavigationBarItem(
          backgroundColor: colorScheme.primary,
          icon: const Icon(Icons.groups),
          label: 'Grupos Distribuidores',
        ),
      );
    }

    if (policy.can(Resource.estatus, ActionType.nav)) {
      pantallasVisibles.add(const EstatusScreen());
      itemsVisibles.add(
        BottomNavigationBarItem(
          backgroundColor: colorScheme.primary,
          icon: const Icon(Icons.label_important_outline),
          label: 'Estatus',
        ),
      );
    }

    // ⚠️ Si hay 0 o 1 tabs, evita BottomNavigationBar (misma defensa que HomeScreen)
    if (pantallasVisibles.length <= 1) {
      return Scaffold(
        appBar: AppBar(
          title: Center(
            child: Text(
              'Admin MyAFMZD',
              style: textTheme.titleLarge?.copyWith(
                color: colorScheme.onPrimary,
              ),
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                onPressed: _reintentarConexionConOverlay,
                icon: Icon(
                  hayConexion ? Icons.wifi : Icons.wifi_off,
                  color: colorScheme.onPrimary,
                ),
                tooltip: hayConexion ? 'Conectado' : 'Sin conexión',
              ),
            ),
          ],
        ),
        drawer: const MyAppDrawer(current: DrawerDest.admin),
        body: pantallasVisibles.isEmpty
            ? const Center(
                child: Text('No tienes secciones administrativas disponibles.'),
              )
            : pantallasVisibles.first,
      );
    }

    // Ajuste por seguridad si el índice actual se sale del rango
    if (_indiceActual >= pantallasVisibles.length) {
      _indiceActual = 0;
    }

    return Scaffold(
      appBar: AppBar(
        title: Center(
          child: Text(
            itemsVisibles[_indiceActual].label ?? 'Admin MyAFMZD',
            style: textTheme.titleLarge?.copyWith(color: colorScheme.onPrimary),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: IconButton(
              onPressed: _reintentarConexionConOverlay,
              icon: Icon(
                hayConexion ? Icons.wifi : Icons.wifi_off,
                color: colorScheme.onPrimary,
              ),
              tooltip: hayConexion ? 'Conectado' : 'Sin conexión',
            ),
          ),
        ],
      ),
      drawer: const MyAppDrawer(current: DrawerDest.admin),
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

  // ===================== Helpers =====================

  Future<void> _recargarTodo() async {
    // Captura notifiers cada vez (evitas estados stale)
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
    final estatusN = ref.read(estatusProvider.notifier);

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
    await estatusN.cargarOfflineFirst();
    if (!mounted) return;
  }

  Future<void> _reintentarConexionConOverlay() async {
    if (!mounted) return;

    // Mensaje inicial
    context.loaderOverlay.show(
      progress: 'Revisando conexión y sincronizando datos',
    );

    try {
      // 1) Revalidar red
      await ref.read(connectivityProvider.notifier).refreshNow();
      final online = ref.read(connectivityProvider);

      if (online) {
        try {
          await Supabase.instance.client.auth.refreshSession();
        } catch (_) {
          // Ignoramos errores de refresh; seguimos con recarga.
        }

        await _recargarTodo();

        if (context.loaderOverlay.visible) {
          context.loaderOverlay.progress('Listo.');
        }
        await Future.delayed(const Duration(milliseconds: 300));
      } else {
        if (context.loaderOverlay.visible) {
          context.loaderOverlay.progress(
            'Sin conexión. Trabajando con datos locales…',
          );
        }
        await Future.delayed(const Duration(milliseconds: 800));
      }
    } finally {
      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
    }
  }
}

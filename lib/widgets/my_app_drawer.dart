import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/screens/login/login_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:myafmzd/session/pemisos_acceso.dart';
import 'package:myafmzd/session/sesion_asignacion_provider.dart';
import 'package:myafmzd/session/sesion_asignacion_selectors.dart';
import 'package:myafmzd/database/perfil/perfil_provider.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/theme/theme_provider.dart';

import 'package:myafmzd/screens/home_screen.dart';
import 'package:myafmzd/screens/admin_home_screen.dart';

enum DrawerDest { home, admin }

class MyAppDrawer extends ConsumerStatefulWidget {
  const MyAppDrawer({super.key, this.current = DrawerDest.home});

  final DrawerDest current;

  @override
  ConsumerState<MyAppDrawer> createState() => _MyAppDrawerState();
}

class _MyAppDrawerState extends ConsumerState<MyAppDrawer> {
  // Controller propio para la lista de asignaciones
  final ScrollController _asigCtrl = ScrollController();
  bool _signingOut = false;

  @override
  void dispose() {
    _asigCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

    // RBAC
    final policy = ref.watch(appPolicyProvider);

    // Perfil / asignaciones
    final usuario = ref.watch(perfilProvider);
    final colabUid = usuario?.colaboradorUid ?? '';

    final activa = ref.watch(activeAssignmentProvider);
    final misAsig = ref.watch(
      myAssignmentsProvider(colabUid.isEmpty ? null : colabUid),
    );
    final distribuidores = ref.watch(distribuidoresProvider);

    // 👇 Solo ACTIVAS (no deleted, sin fechaFin), y ordenadas recientes primero
    final asigActivas =
        misAsig.where((a) => !a.deleted && a.fechaFin == null).toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    String _nombreDistrib(String uid) {
      if (uid.isEmpty) return '—';
      final d = distribuidores.where((x) => x.uid == uid).toList();
      return d.isEmpty ? uid : d.first.nombre;
    }

    // ---- AGRUPACIÓN ESPECIAL PARA "gerente de grupo" ----
    final asigGerenteGrupo = asigActivas
        .where((a) => a.rol == 'gerente de grupo')
        .toList();

    final asigNoGerenteGrupo = asigActivas
        .where((a) => a.rol != 'gerente de grupo')
        .toList();

    AsignacionLaboralDb? representanteGerenteGrupo;
    if (asigGerenteGrupo.isNotEmpty) {
      // Si la asignación activa es un gerente de grupo, usamos esa
      if (activa != null &&
          activa.rol == 'gerente de grupo' &&
          asigGerenteGrupo.any((g) => g.uid == activa.uid)) {
        representanteGerenteGrupo = asigGerenteGrupo.firstWhere(
          (g) => g.uid == activa.uid,
        );
      } else {
        // Si no, usamos la "original": la de fechaInicio más antigua
        representanteGerenteGrupo = asigGerenteGrupo.reduce(
          (a, b) => a.fechaInicio.isBefore(b.fechaInicio) ? a : b,
        );
      }
    }

    // Lista final que se muestra en el Drawer
    final asigDrawer = <AsignacionLaboralDb>[
      ...asigNoGerenteGrupo,
      if (representanteGerenteGrupo != null) representanteGerenteGrupo,
    ]..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    // Destinos
    final destinations = <_NavDest>[
      _NavDest(
        label: 'Home',
        icon: Icons.home,
        onTap: () {
          Navigator.of(context).pop();
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        },
      ),
      if (policy.can(Resource.adminHome, ActionType.nav))
        _NavDest(
          label: 'Administración',
          icon: Icons.admin_panel_settings,
          onTap: () {
            Navigator.of(context).pop();
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AdminHomeScreen()));
          },
        ),
    ];

    final selectedIndex = () {
      if (widget.current == DrawerDest.admin) {
        final i = destinations.indexWhere((d) => d.label == 'Administración');
        return i == -1 ? 0 : i;
      }
      return 0;
    }();

    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(color: cs.primary),
            child: Padding(
              padding: const EdgeInsets.only(top: 24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car, color: cs.onPrimary),
                  const SizedBox(width: 12),
                  Text(
                    'MyAFMZD',
                    style: tt.titleLarge?.copyWith(
                      color: cs.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Navegación (M3)
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const _SectionLabel('Navegación'),

                  for (var i = 0; i < destinations.length; i++)
                    ListTile(
                      leading: Icon(destinations[i].icon, color: cs.onSurface),
                      title: Text(
                        destinations[i].label,
                        style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                      ),
                      onTap: destinations[i].onTap,
                      // sin fondo seleccionado; solo un puntito a la derecha
                      trailing: AnimatedOpacity(
                        opacity: selectedIndex == i ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 150),
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: cs.onSurface,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                      dense: true,
                      visualDensity: VisualDensity.compact,
                    ),

                  const Divider(),

                  // ===== Asignación (inline) =====
                  const _SectionLabel('Asignación actual'),

                  if (asigDrawer.isEmpty)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                      child: Text(
                        'No tienes asignaciones activas.',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      child: ListView.separated(
                        controller: _asigCtrl,
                        primary: false,
                        shrinkWrap: true,
                        itemCount: asigDrawer.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 6),
                        itemBuilder: (context, i) {
                          final a = asigDrawer[i];
                          final esGerenteGrupo = a.rol == 'gerente de grupo';

                          // seleccionado:
                          // - normal: por uid
                          // - gerente de grupo: si la activa es cualquier gerente de grupo
                          final bool seleccionado = esGerenteGrupo
                              ? (activa != null &&
                                    activa.rol == 'gerente de grupo' &&
                                    activa.colaboradorUid == a.colaboradorUid)
                              : a.uid == activa?.uid;

                          // Subtítulo:
                          // - normal: nombre de distribuidora
                          // - gerente: distribuidora base + " + N más" si aplica
                          String subtitulo;
                          if (!esGerenteGrupo) {
                            subtitulo = a.distribuidorUid.isEmpty
                                ? '—'
                                : _nombreDistrib(a.distribuidorUid);
                          } else {
                            final total = asigGerenteGrupo.length;
                            if (total <= 1) {
                              subtitulo = a.distribuidorUid.isEmpty
                                  ? '—'
                                  : _nombreDistrib(a.distribuidorUid);
                            } else {
                              final baseNombre = a.distribuidorUid.isEmpty
                                  ? 'Múltiples distribuidoras'
                                  : _nombreDistrib(a.distribuidorUid);
                              final resto = total - 1;
                              subtitulo = '$baseNombre ($resto)';
                            }
                          }

                          // 🔹 Fondo SIEMPRE surface; sin highlight agresivo
                          final bg = cs.surface;
                          final fg = cs.onSurface;
                          final subFg = cs.onSurfaceVariant;

                          return InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: () async {
                              // Para gerente de grupo, activamos la representante
                              await ref
                                  .read(assignmentSessionProvider.notifier)
                                  .setActiveAssignment(a.uid);
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Asignación cambiada'),
                                  duration: Duration(milliseconds: 1200),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: bg,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: cs.outlineVariant,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          '${a.rol}${a.nivel.trim().isEmpty ? '' : ' (${a.nivel.trim()})'}',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: tt.bodyMedium?.copyWith(
                                            color: fg,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Row(
                                          children: [
                                            Icon(
                                              Icons
                                                  .store_mall_directory_outlined,
                                              size: 16,
                                              color: subFg,
                                            ),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                subtitulo,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: tt.bodyMedium?.copyWith(
                                                  color: subFg,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // 🔹 Dot a la derecha cuando está seleccionada
                                  AnimatedOpacity(
                                    opacity: seleccionado ? 1.0 : 0.0,
                                    duration: const Duration(milliseconds: 150),
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: cs.onSurface,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
          const Divider(),

          const _SectionLabel('Sesión'),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
                  title: Text(
                    isDark ? 'Modo Oscuro' : 'Modo Claro',
                    style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                  ),
                  onTap: () {
                    ref.read(themeModeProvider.notifier).toggleTheme();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: Text(
                    'Cerrar sesión',
                    style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                  ),
                  onTap: () async {
                    if (_signingOut) return; // evita doble ejecución

                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Center(child: Text('¿Cerrar sesión?')),
                        content: const Text(
                          '¿Estás seguro de que deseas cerrar sesión?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancelar'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Cerrar sesión'),
                          ),
                        ],
                      ),
                    );
                    if (confirm != true) return;
                    if (!context.mounted) return;

                    _signingOut = true;

                    try {
                      // 1) Cierra el Drawer primero para evitar jalón visual
                      await Future.delayed(
                        const Duration(milliseconds: 100),
                      ); // mini respiro

                      // 2) Overlay con minSpin para UX suave
                      const minSpin = Duration(milliseconds: 900);
                      final inicio = DateTime.now();
                      context.loaderOverlay.show(progress: 'Cerrando sesión…');
                      await Supabase.instance.client.auth.signOut();

                      // Limpiezas ligeras (sin redes)
                      await ref
                          .read(assignmentSessionProvider.notifier)
                          .clear();
                      ref.read(perfilProvider.notifier).limpiarUsuario();

                      // 3) Garantiza duración mínima del overlay
                      final elapsed = DateTime.now().difference(inicio);
                      if (elapsed < minSpin) {
                        await Future.delayed(minSpin - elapsed);
                      }

                      if (!context.mounted) return;
                      if (context.loaderOverlay.visible)
                        context.loaderOverlay.hide();

                      // 4) Navegación con transición fade (suave)
                      Navigator.of(context).pushAndRemoveUntil(
                        PageRouteBuilder(
                          pageBuilder: (_, __, ___) => const LoginScreen(),
                          transitionDuration: const Duration(milliseconds: 220),
                          transitionsBuilder: (_, anim, __, child) =>
                              FadeTransition(opacity: anim, child: child),
                        ),
                        (route) => false,
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      if (context.loaderOverlay.visible)
                        context.loaderOverlay.hide();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('❌ No se pudo cerrar sesión: $e'),
                        ),
                      );
                    } finally {
                      _signingOut = false;
                    }
                  },
                ),
              ],
            ),
          ),

          // Footer visual
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
            decoration: BoxDecoration(color: cs.primary),
          ),
        ],
      ),
    );
  }
}

class _NavDest {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  _NavDest({required this.label, required this.icon, required this.onTap});
}

/// Encabezado de sección alineado a la izquierda (M3)
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6), // compacto
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.1,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:myafmzd/session/permisos.dart';
import 'package:myafmzd/session/sesion_asignacion_provider.dart';
import 'package:myafmzd/session/sesion_asignacion_selectors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myafmzd/database/perfil/perfil_provider.dart';
import 'package:myafmzd/theme/theme_provider.dart';
import 'package:myafmzd/screens/home_screen.dart';
import 'package:myafmzd/screens/admin_home_screen.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_provider.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';

class MyAppDrawer extends ConsumerWidget {
  const MyAppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // 🔐 permisos derivados del rol de la asignación activa
    final perms = ref.watch(appPermissionsProvider);

    // Perfil → para obtener colaboradorUid del usuario autenticado
    final usuario = ref.watch(perfilProvider);
    final colabUid = usuario?.colaboradorUid ?? '';

    // Datos de asignación / catálogos para nombres bonitos
    final activa = ref.watch(activeAssignmentProvider);
    final misAsig = ref.watch(
      myAssignmentsProvider(colabUid.isEmpty ? null : colabUid),
    );
    final colaboradores = ref.watch(colaboradoresProvider);
    final distribuidores = ref.watch(distribuidoresProvider);

    // Helpers de nombres
    String _nombreColab(String uid) {
      final c = colaboradores.where((x) => x.uid == uid).cast().toList();
      if (c.isEmpty) return '—';
      final p = c.first;
      final n = '${p.nombres} ${p.apellidoPaterno} ${p.apellidoMaterno}'
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      return n.isEmpty ? '—' : n;
    }

    String _nombreDistrib(String uid) {
      if (uid.isEmpty) return '—';
      final d = distribuidores.where((x) => x.uid == uid).toList();
      return d.isEmpty ? uid : d.first.nombre;
    }

    String _labelActiva() {
      if (activa == null) return '—';
      final rol = activa.rol.trim().isEmpty ? '—' : activa.rol.trim();
      final nivel = activa.nivel.trim().isEmpty
          ? ''
          : ' (${activa.nivel.trim()})';
      final colab = _nombreColab(activa.colaboradorUid);
      final dist = _nombreDistrib(activa.distribuidorUid);
      final distTxt = activa.distribuidorUid.isEmpty ? '' : ' • $dist';
      final cerrado = activa.fechaFin == null ? '' : '  (cerrada)';
      // Rol • Colaborador • Distribuidora
      return '$rol$nivel • $colab$distTxt$cerrado';
    }

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // ===== Header visual (marca) =====
          DrawerHeader(
            decoration: BoxDecoration(color: colorScheme.primary),
            child: Center(
              child: Text(
                'AFMZD',
                style: textTheme.titleLarge?.copyWith(
                  color: colorScheme.onPrimary,
                ),
              ),
            ),
          ),

          // ===== Bloque de Asignación Activa + Selector =====
          ListTile(
            title: const Text('Asignación activa'),
            subtitle: Text(
              _labelActiva(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: PopupMenuButton<String>(
              tooltip: 'Cambiar asignación',
              onSelected: (uid) async {
                await ref
                    .read(assignmentSessionProvider.notifier)
                    .setActiveAssignment(uid);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Asignación cambiada')),
                  );
                }
              },
              itemBuilder: (_) => [
                if (misAsig.isEmpty)
                  const PopupMenuItem<String>(
                    enabled: false,
                    child: Text('Sin asignaciones'),
                  ),
                for (final a in misAsig)
                  CheckedPopupMenuItem<String>(
                    value: a.uid,
                    checked: activa?.uid == a.uid,
                    child: Text(
                      // Mismo formato que el display del header, pero compacto
                      '${a.rol}${a.nivel.trim().isEmpty ? '' : ' (${a.nivel.trim()})'}'
                      ' • ${_nombreColab(a.colaboradorUid)}'
                      '${a.distribuidorUid.isEmpty ? '' : ' • ${_nombreDistrib(a.distribuidorUid)}'}'
                      '${a.fechaFin == null ? '' : '  (cerrada)'}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              icon: const Icon(Icons.swap_horiz),
            ),
          ),

          const Divider(),

          // ===== Home =====
          ListTile(
            leading: const Icon(Icons.home),
            title: Text(
              'Home',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            onTap: () {
              Navigator.of(context).pop();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
          ),

          // ===== Administración (condicionado por permisos) =====
          if (perms.can(Feature.navAdminHome))
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: Text(
                'Administración',
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
                );
              },
            ),

          const Divider(),

          // ===== Tema =====
          ListTile(
            leading: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
            title: Text(
              isDark ? 'Modo Oscuro' : 'Modo Claro',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            onTap: () {
              ref.read(themeModeProvider.notifier).toggleTheme();
            },
          ),

          const Divider(),

          // ===== Logout =====
          ListTile(
            leading: const Icon(Icons.logout),
            title: Text(
              'Cerrar sesión',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => AlertDialog(
                  title: Center(
                    child: Text(
                      '¿Cerrar sesión?',
                      style: textTheme.titleLarge?.copyWith(
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  content: Text(
                    '¿Estás seguro de que deseas cerrar sesión?',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        'Cancelar',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        'Cerrar sesión',
                        style: textTheme.bodyLarge?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                // Muestra overlay
                if (context.mounted) {
                  context.loaderOverlay.show(progress: 'Cerrando sesión…');
                }
                final inicio = DateTime.now();

                try {
                  await Supabase.instance.client.auth.signOut();
                  await ref.read(assignmentSessionProvider.notifier).clear();
                  ref.read(perfilProvider.notifier).limpiarUsuario();

                  // Delay mínimo para UX suave (coherente con tus 900–1500 ms)
                  const minSpin = Duration(milliseconds: 1200);
                  final elapsed = DateTime.now().difference(inicio);
                  if (elapsed < minSpin) {
                    await Future.delayed(minSpin - elapsed);
                  }

                  if (context.mounted && context.loaderOverlay.visible) {
                    context.loaderOverlay.hide();
                  }
                  if (context.mounted) {
                    Navigator.of(
                      context,
                    ).pushNamedAndRemoveUntil('/', (_) => false);
                  }
                } catch (e) {
                  if (context.mounted && context.loaderOverlay.visible) {
                    context.loaderOverlay.hide();
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('❌ No se pudo cerrar sesión: $e')),
                    );
                  }
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

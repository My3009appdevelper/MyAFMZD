import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/perfil/perfil_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myafmzd/theme/theme_provider.dart';

// 👇 Importa las HomeScreens
import 'package:myafmzd/screens/home_screen.dart';
import 'package:myafmzd/screens/admin_home_screen.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
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

          // 🌐 Ir al Home principal (reset pila)
          ListTile(
            leading: const Icon(Icons.home),
            title: Text(
              'Home',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            onTap: () {
              Navigator.of(context).pop(); // cierra drawer
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
          ),

          // 🛠️ Ir al Home de Administración (con back)
          ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: Text(
              'Administración',
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            onTap: () {
              Navigator.of(context).pop(); // cierra drawer
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
              );
            },
          ),

          const Divider(),

          // 🌓 Tema
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

          // 🚪 Cerrar sesión
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
                await Supabase.instance.client.auth.signOut();
                ref.read(perfilProvider.notifier).limpiarUsuario();

                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/', // tu InitialScreen
                    (_) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }
}

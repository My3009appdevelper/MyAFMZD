// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:myafmzd/screens/login/initial_screen.dart';
import 'package:pdfrx/pdfrx.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:myafmzd/widgets/my_loader_overlay.dart';

// 👇 clave global para acceder al contexto actual del Navigator
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

// 👇 RouteObserver que auto-oculta overlay en cualquier transición
class LoaderRouteObserver extends RouteObserver<PageRoute<dynamic>> {
  void _hideIfVisible() {
    final ctx = appNavigatorKey.currentContext;
    if (ctx == null) return; // puede ser null en transiciones raras
    if (ctx.mounted && ctx.loaderOverlay.visible) {
      ctx.loaderOverlay.hide(); // usa 'visible' del helper
    }
  }

  @override
  void didPush(Route route, Route? previousRoute) {
    _hideIfVisible();
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route? newRoute, Route? oldRoute}) {
    _hideIfVisible();
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  @override
  void didPop(Route route, Route? previousRoute) {
    _hideIfVisible();
    super.didPop(route, previousRoute);
  }

  @override
  void didRemove(Route route, Route? previousRoute) {
    _hideIfVisible();
    super.didRemove(route, previousRoute);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  pdfrxFlutterInitialize();

  await Supabase.initialize(
    url: 'https://xxuldwqylkyeuvyqgtbb.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh4dWxkd3F5bGt5ZXV2eXFndGJiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3MTYxMzUsImV4cCI6MjA2OTI5MjEzNX0.c4UrViDvrSo0OehE7n7AHRYjEBmD2oDCDkUYYoAGlZU',
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'AFMZD Contrato',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      // 👇 clave global
      navigatorKey: appNavigatorKey,
      // 👇 observador que apaga el overlay en cualquier navegación
      navigatorObservers: [LoaderRouteObserver()],
      home: const InitialScreen(),
      // 👇 overlay global (una sola vez)
      builder: (context, child) =>
          MyLoaderOverlay(child: child ?? const SizedBox()),
    );
  }
}

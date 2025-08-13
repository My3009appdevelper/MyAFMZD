import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/login/initial_screen.dart';
import 'package:pdfrx/pdfrx.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  pdfrxFlutterInitialize(); // opcional, útil en algunos entornos

  await Supabase.initialize(
    url: 'https://xxuldwqylkyeuvyqgtbb.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inh4dWxkd3F5bGt5ZXV2eXFndGJiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM3MTYxMzUsImV4cCI6MjA2OTI5MjEzNX0.c4UrViDvrSo0OehE7n7AHRYjEBmD2oDCDkUYYoAGlZU',
  );

  // Mauricio1892220253009

  // ✅ Inicializar la DB de Drift una vez (Singleton)

  runApp(ProviderScope(child: const MyApp()));
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
      home: const InitialScreen(),
    );
  }
}

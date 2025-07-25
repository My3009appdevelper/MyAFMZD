import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/firebase_options.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/screens/initial_screen.dart';
import 'theme/app_theme.dart';
import 'theme/theme_provider.dart';

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  throw UnimplementedError();
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ Firebase primero
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // ✅ Habilitar persistencia offline de Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
  );

  // ✅ Inicializar la DB de Drift una vez (Singleton)
  final db = AppDatabase();

  runApp(
    ProviderScope(
      overrides: [appDatabaseProvider.overrideWithValue(db)],
      child: const MyApp(),
    ),
  );
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

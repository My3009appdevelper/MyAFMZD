// ignore_for_file: avoid_print
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:myafmzd/database/asignaciones_laborales/asignaciones_laborales_provider.dart';

/// Guarda solo el UID de la asignación activa (simple y robusto).
final assignmentSessionProvider =
    StateNotifierProvider<AssignmentSessionNotifier, String?>((ref) {
      return AssignmentSessionNotifier(ref);
    });

class AssignmentSessionNotifier extends StateNotifier<String?> {
  AssignmentSessionNotifier(this._ref) : super(null);

  final Ref _ref;
  static const _kPrefsKey = 'active_assignment_uid';

  /// Cargar de SharedPreferences (no resuelve validez, solo pinta lo guardado).
  Future<void> initFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUid = prefs.getString(_kPrefsKey);
      state = (savedUid?.isNotEmpty == true) ? savedUid : null;
      print('[🎛 ASG SESSION] initFromStorage → $state');
    } catch (e) {
      print('[🎛 ASG SESSION] ❌ initFromStorage error: $e');
    }
  }

  /// Establecer manualmente (desde el selector del Drawer).
  Future<void> setActiveAssignment(String? uid) async {
    try {
      state = (uid?.isNotEmpty == true) ? uid : null;
      final prefs = await SharedPreferences.getInstance();
      if (state == null) {
        await prefs.remove(_kPrefsKey);
      } else {
        await prefs.setString(_kPrefsKey, state!);
      }
      print('[🎛 ASG SESSION] setActiveAssignment → $state');
    } catch (e) {
      print('[🎛 ASG SESSION] ❌ setActiveAssignment error: $e');
    }
  }

  /// Limpia al cerrar sesión.
  Future<void> clear() async {
    try {
      state = null;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kPrefsKey);
      print('[🎛 ASG SESSION] clear()');
    } catch (e) {
      print('[🎛 ASG SESSION] ❌ clear error: $e');
    }
  }

  /// Asegura que haya una asignación activa coherente con los datos cargados.
  ///
  /// - Usa la guardada si sigue existiendo.
  /// - Si no, elige la activa más reciente del colaborador.
  /// - Si no hay activas, la más reciente (histórica).
  /// - Si no hay ninguna, deja null.
  Future<void> ensureActiveForUser({required String? colaboradorUid}) async {
    try {
      final all = _ref.read(asignacionesLaboralesProvider);
      // Filtra por colaborador si viene (si es null/empty mostramos todas).
      final list = (colaboradorUid == null || colaboradorUid.isEmpty)
          ? all.where((a) => !a.deleted).toList()
          : all
                .where((a) => !a.deleted && a.colaboradorUid == colaboradorUid)
                .toList();

      // 1) preferir la guardada si sigue existiendo
      final saved = state;
      final stillValid = (saved != null && list.any((a) => a.uid == saved));
      if (stillValid) {
        print(
          '[🎛 ASG SESSION] ensureActiveForUser → mantiene guardada $saved',
        );
        return; // nada que hacer
      }

      // 2) activa más reciente (sin fechaFin)
      final activas = list.where((a) => a.fechaFin == null).toList()
        ..sort((a, b) => b.fechaInicio.compareTo(a.fechaInicio));
      if (activas.isNotEmpty) {
        await setActiveAssignment(activas.first.uid);
        print(
          '[🎛 ASG SESSION] ensureActiveForUser → eligió activa ${activas.first.uid}',
        );
        return;
      }

      // 3) histórica más reciente
      final historicas = list.where((a) => a.fechaFin != null).toList()
        ..sort((a, b) {
          // por fechaFin desc (o fechaInicio si faltara)
          final af = a.fechaFin ?? a.fechaInicio;
          final bf = b.fechaFin ?? b.fechaInicio;
          return bf.compareTo(af);
        });
      if (historicas.isNotEmpty) {
        await setActiveAssignment(historicas.first.uid);
        print(
          '[🎛 ASG SESSION] ensureActiveForUser → eligió histórica ${historicas.first.uid}',
        );
        return;
      }

      // 4) nada disponible
      await setActiveAssignment(null);
      print('[🎛 ASG SESSION] ensureActiveForUser → sin asignaciones, null');
    } catch (e) {
      print('[🎛 ASG SESSION] ❌ ensureActiveForUser error: $e');
    }
  }
}

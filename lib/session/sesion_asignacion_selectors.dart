import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/asignaciones_laborales/asignaciones_laborales_provider.dart';
import 'package:myafmzd/session/sesion_asignacion_provider.dart';

/// Asignación activa (objeto) según el UID guardado en sesión.
final activeAssignmentProvider = Provider<AsignacionLaboralDb?>((ref) {
  final uid = ref.watch(assignmentSessionProvider); // <- String? UID
  final all = ref.watch(asignacionesLaboralesProvider);
  if (uid == null) return null;
  try {
    return all.firstWhere((a) => a.uid == uid && !a.deleted);
  } catch (_) {
    return null;
  }
});

/// Lista de asignaciones (activas primero, luego recientes). Puede filtrarse por colaborador.
final myAssignmentsProvider =
    Provider.family<List<AsignacionLaboralDb>, String?>((ref, colaboradorUid) {
      final all = ref.watch(asignacionesLaboralesProvider);
      final list = (colaboradorUid == null || colaboradorUid.isEmpty)
          ? all.where((a) => !a.deleted).toList()
          : all
                .where((a) => !a.deleted && a.colaboradorUid == colaboradorUid)
                .toList();

      list.sort((a, b) {
        final aa = a.fechaFin == null ? 0 : 1;
        final bb = b.fechaFin == null ? 0 : 1;
        if (aa != bb) return aa - bb; // activas primero
        return b.fechaInicio.compareTo(a.fechaInicio); // más recientes
      });
      return list;
    });

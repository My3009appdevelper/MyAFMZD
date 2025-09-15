// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/session/sesion_asignacion_selectors.dart';

/// Enum de “features” que tu UI puede proteger/mostrar
enum Feature {
  navDashboard,
  navPerfil,
  navDistribuidores,
  navModelos,
  navProductos,
  navUsuarios,
  navReportes,
  editProductos,
  editUsuarios,
  verTodo,
  navAdminHome,
}

/// Mapa de rol → features
Set<Feature> _roleToFeatures(String rol) {
  switch (rol.trim().toLowerCase()) {
    case 'master':
    case 'admin':
      return Feature.values.toSet()..add(Feature.verTodo);
    case 'gerente':
      return {
        Feature.navDashboard,
        Feature.navPerfil,
        Feature.navDistribuidores,
        Feature.navModelos,
        Feature.navReportes,
        Feature.navUsuarios,
        Feature.editUsuarios,
        Feature.navAdminHome, // 👈 puede ver Administración
      };
    case 'coordinador':
    case 'administrativo':
      return {
        Feature.navDashboard,
        Feature.navPerfil,
        Feature.navDistribuidores,
        Feature.navModelos,
        Feature.navReportes,
        Feature.navAdminHome, // 👈 si quieres que también lo vean
      };
    case 'vendedor':
    default:
      return {
        Feature.navPerfil,
        Feature.navDistribuidores,
        Feature.navModelos,
        // sin navAdminHome → no ve el tile Administración
      };
  }
}

/// Objeto de permisos en memoria
class AppPermissions {
  final Set<Feature> _allowed;
  const AppPermissions(this._allowed);

  bool can(Feature f) => _allowed.contains(f);
}

/// Deriva permisos desde la asignación activa
final appPermissionsProvider = Provider<AppPermissions>((ref) {
  final a = ref.watch(activeAssignmentProvider);
  final rol = (a?.rol ?? 'vendedor');
  final features = _roleToFeatures(rol);
  print(
    '[🔐 PERMS] Rol activo="$rol" → ${features.map((e) => e.name).join(', ')}',
  );
  return AppPermissions(features);
});

/// Gate simple de permisos para envolver widgets o pantallas
class PermissionGate extends ConsumerWidget {
  const PermissionGate({
    super.key,
    required this.feature,
    required this.child,
    this.fallback,
  });

  final Feature feature;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perms = ref.watch(appPermissionsProvider);
    return perms.can(feature) ? child : (fallback ?? const SizedBox.shrink());
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/session/sesion_asignacion_selectors.dart';

/// Enum de “features” que tu UI puede proteger/mostrar
enum Feature {
  navPerfil,
  navModelos,
  navDistribuidores,
  navReportes,
  navColaboradores,
  navAsignacionesLaborales,
  navUsuarios,
  navVentas,
  navProductos,
  navGruposDistribuidores,
  navEstatus,
  verTodo,
  navAdminHome,
  navHome,
}

/// Mapa de rol → features
Set<Feature> _roleToFeatures(String rol) {
  switch (rol.trim().toLowerCase()) {
    case 'master':
      return Feature.values.toSet()..add(Feature.verTodo);
    case 'admin':
      return Feature.values.toSet()..add(Feature.verTodo);
    case 'gerente':
      return {Feature.navPerfil, Feature.navDistribuidores, Feature.navModelos};
    case 'coordinador':
      return {Feature.navPerfil, Feature.navDistribuidores, Feature.navModelos};
    case 'administrativo':
      return {Feature.navPerfil, Feature.navDistribuidores, Feature.navModelos};
    case 'vendedor':
    default:
      return {Feature.navPerfil, Feature.navModelos};
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

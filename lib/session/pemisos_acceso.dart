import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/session/permisos.dart';
import 'package:myafmzd/session/sesion_asignacion_selectors.dart';

/// ================================================================
///  ENUMS Y MODELOS BASE
/// ================================================================

/// Recursos sobre los que se puede actuar
enum Resource {
  adminHome,
  perfil,
  modelos,
  distribuidores,
  gruposDistribuidores,
  reportes,
  colaboradores,
  usuarios,
  asignacionesLaborales,
  ventas,
  productos,
  estatus,
}

/// Acciones posibles sobre cada recurso
enum ActionType { nav, view, create, edit, delete, import, export }

/// Alcance o visibilidad del permiso (para filtrar datos)
enum Scope {
  own, // Solo registros creados por el usuario
  distribuidor, // Registros de la distribuidora actual
  grupo, // Registros del grupo completo
  all, // Acceso completo global
}

/// Representa una regla individual (recurso + acción + alcance)
class Rule {
  final Resource resource;
  final ActionType action;
  final Scope scope;

  const Rule(this.resource, this.action, this.scope);
}

/// ================================================================
///  MAPEO DE ROLES A REGLAS RBAC MODERNAS
/// ================================================================
Set<Rule> _roleToRules(String rol) {
  switch (rol.trim().toLowerCase()) {
    case 'master':
    case 'admin':
      return {
        // Admin Home
        const Rule(Resource.adminHome, ActionType.nav, Scope.all),

        // Perfil
        const Rule(Resource.perfil, ActionType.nav, Scope.all),
        const Rule(Resource.perfil, ActionType.view, Scope.all),
        const Rule(Resource.perfil, ActionType.create, Scope.all),
        const Rule(Resource.perfil, ActionType.edit, Scope.all),
        const Rule(Resource.perfil, ActionType.delete, Scope.all),
        const Rule(Resource.perfil, ActionType.import, Scope.all),
        const Rule(Resource.perfil, ActionType.export, Scope.all),

        // Modelos
        const Rule(Resource.modelos, ActionType.nav, Scope.all),
        const Rule(Resource.modelos, ActionType.view, Scope.all),
        const Rule(Resource.modelos, ActionType.create, Scope.all),
        const Rule(Resource.modelos, ActionType.edit, Scope.all),
        const Rule(Resource.modelos, ActionType.delete, Scope.all),
        const Rule(Resource.modelos, ActionType.import, Scope.all),
        const Rule(Resource.modelos, ActionType.export, Scope.all),

        // Distribuidores
        const Rule(Resource.distribuidores, ActionType.nav, Scope.all),
        const Rule(Resource.distribuidores, ActionType.view, Scope.all),
        const Rule(Resource.distribuidores, ActionType.create, Scope.all),
        const Rule(Resource.distribuidores, ActionType.edit, Scope.all),
        const Rule(Resource.distribuidores, ActionType.delete, Scope.all),
        const Rule(Resource.distribuidores, ActionType.import, Scope.all),
        const Rule(Resource.distribuidores, ActionType.export, Scope.all),

        //  Grupos de Distribuidores
        const Rule(Resource.gruposDistribuidores, ActionType.nav, Scope.all),
        const Rule(Resource.gruposDistribuidores, ActionType.view, Scope.all),
        const Rule(Resource.gruposDistribuidores, ActionType.create, Scope.all),
        const Rule(Resource.gruposDistribuidores, ActionType.edit, Scope.all),
        const Rule(Resource.gruposDistribuidores, ActionType.delete, Scope.all),
        const Rule(Resource.gruposDistribuidores, ActionType.import, Scope.all),
        const Rule(Resource.gruposDistribuidores, ActionType.export, Scope.all),

        //  Reportes
        const Rule(Resource.reportes, ActionType.nav, Scope.all),
        const Rule(Resource.reportes, ActionType.view, Scope.all),
        const Rule(Resource.reportes, ActionType.create, Scope.all),
        const Rule(Resource.reportes, ActionType.edit, Scope.all),
        const Rule(Resource.reportes, ActionType.delete, Scope.all),
        const Rule(Resource.reportes, ActionType.import, Scope.all),
        const Rule(Resource.reportes, ActionType.export, Scope.all),

        //  Colaboradores
        const Rule(Resource.colaboradores, ActionType.nav, Scope.all),
        const Rule(Resource.colaboradores, ActionType.view, Scope.all),
        const Rule(Resource.colaboradores, ActionType.create, Scope.all),
        const Rule(Resource.colaboradores, ActionType.edit, Scope.all),
        const Rule(Resource.colaboradores, ActionType.delete, Scope.all),
        const Rule(Resource.colaboradores, ActionType.import, Scope.all),
        const Rule(Resource.colaboradores, ActionType.export, Scope.all),

        // Usuarios
        const Rule(Resource.usuarios, ActionType.nav, Scope.all),
        const Rule(Resource.usuarios, ActionType.view, Scope.all),
        const Rule(Resource.usuarios, ActionType.create, Scope.all),
        const Rule(Resource.usuarios, ActionType.edit, Scope.all),
        const Rule(Resource.usuarios, ActionType.delete, Scope.all),
        const Rule(Resource.usuarios, ActionType.import, Scope.all),
        const Rule(Resource.usuarios, ActionType.export, Scope.all),

        // Asignaciones Laborales
        const Rule(Resource.asignacionesLaborales, ActionType.nav, Scope.all),
        const Rule(Resource.asignacionesLaborales, ActionType.view, Scope.all),
        const Rule(
          Resource.asignacionesLaborales,
          ActionType.create,
          Scope.all,
        ),
        const Rule(Resource.asignacionesLaborales, ActionType.edit, Scope.all),
        const Rule(
          Resource.asignacionesLaborales,
          ActionType.delete,
          Scope.all,
        ),
        const Rule(
          Resource.asignacionesLaborales,
          ActionType.import,
          Scope.all,
        ),
        const Rule(
          Resource.asignacionesLaborales,
          ActionType.export,
          Scope.all,
        ),

        // Ventas
        const Rule(Resource.ventas, ActionType.nav, Scope.all),
        const Rule(Resource.ventas, ActionType.view, Scope.all),
        const Rule(Resource.ventas, ActionType.create, Scope.all),
        const Rule(Resource.ventas, ActionType.edit, Scope.all),
        const Rule(Resource.ventas, ActionType.delete, Scope.all),
        const Rule(Resource.ventas, ActionType.import, Scope.all),
        const Rule(Resource.ventas, ActionType.export, Scope.all),

        // Productos
        const Rule(Resource.productos, ActionType.nav, Scope.all),
        const Rule(Resource.productos, ActionType.view, Scope.all),
        const Rule(Resource.productos, ActionType.create, Scope.all),
        const Rule(Resource.productos, ActionType.edit, Scope.all),
        const Rule(Resource.productos, ActionType.delete, Scope.all),
        const Rule(Resource.productos, ActionType.import, Scope.all),
        const Rule(Resource.productos, ActionType.export, Scope.all),

        // Estatus
        const Rule(Resource.estatus, ActionType.nav, Scope.all),
        const Rule(Resource.estatus, ActionType.view, Scope.all),
        const Rule(Resource.estatus, ActionType.create, Scope.all),
        const Rule(Resource.estatus, ActionType.edit, Scope.all),
        const Rule(Resource.estatus, ActionType.delete, Scope.all),
        const Rule(Resource.estatus, ActionType.import, Scope.all),
        const Rule(Resource.estatus, ActionType.export, Scope.all),
      };

    case 'gerente':
      return {
        // Perfil
        const Rule(Resource.perfil, ActionType.nav, Scope.all),
        const Rule(Resource.perfil, ActionType.view, Scope.all),

        // Modelos
        const Rule(Resource.modelos, ActionType.nav, Scope.all),
        const Rule(Resource.modelos, ActionType.view, Scope.all),

        // Distribuidores
        const Rule(Resource.distribuidores, ActionType.nav, Scope.all),
        const Rule(Resource.distribuidores, ActionType.view, Scope.all),
      };

    case 'coordinador':
      return {
        // Perfil
        const Rule(Resource.perfil, ActionType.nav, Scope.all),
        const Rule(Resource.perfil, ActionType.view, Scope.all),

        // Modelos
        const Rule(Resource.modelos, ActionType.nav, Scope.all),
        const Rule(Resource.modelos, ActionType.view, Scope.all),

        // Distribuidores
        const Rule(Resource.distribuidores, ActionType.nav, Scope.all),
        const Rule(Resource.distribuidores, ActionType.view, Scope.all),
      };

    case 'administrativo':
      return {
        // Perfil
        const Rule(Resource.perfil, ActionType.nav, Scope.all),
        const Rule(Resource.perfil, ActionType.view, Scope.all),

        // Modelos
        const Rule(Resource.modelos, ActionType.nav, Scope.all),
        const Rule(Resource.modelos, ActionType.view, Scope.all),
      };

    case 'vendedor':
    default:
      return {
        // Perfil
        const Rule(Resource.perfil, ActionType.nav, Scope.all),
        const Rule(Resource.perfil, ActionType.view, Scope.all),

        // Modelos
        const Rule(Resource.modelos, ActionType.nav, Scope.all),
        const Rule(Resource.modelos, ActionType.view, Scope.all),
      };
  }
}

/// ================================================================
///  APP POLICY (RBAC MODERNO)
/// ================================================================
class Policy {
  final Set<Rule> _rules;
  const Policy(this._rules);

  /// ¿El usuario puede realizar cierta acción sobre un recurso?
  bool can(Resource r, ActionType a) =>
      _rules.any((x) => x.resource == r && x.action == a);

  /// Alcance máximo permitido para un recurso
  Scope scopeFor(Resource r) {
    final scopes = _rules
        .where((x) => x.resource == r)
        .map((x) => x.scope)
        .toList();

    if (scopes.isEmpty) return Scope.own;
    if (scopes.contains(Scope.all)) return Scope.all;
    if (scopes.contains(Scope.grupo)) return Scope.grupo;
    if (scopes.contains(Scope.distribuidor)) return Scope.distribuidor;
    return Scope.own;
  }
}

final appPolicyProvider = Provider<Policy>((ref) {
  final a = ref.watch(activeAssignmentProvider);
  final rol = (a?.rol ?? 'vendedor');
  final rules = _roleToRules(rol);
  return Policy(rules);
});

/// ================================================================
///  WIDGETS DE GATE (VISIBILIDAD CONDICIONAL)
/// ================================================================

/// Gate para features (compatibilidad temporal)
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

/// Gate moderno basado en recurso/acción
class ActionGate extends ConsumerWidget {
  const ActionGate({
    super.key,
    required this.resource,
    required this.action,
    required this.child,
    this.fallback,
  });

  final Resource resource;
  final ActionType action;
  final Widget child;
  final Widget? fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policy = ref.watch(appPolicyProvider);
    return policy.can(resource, action)
        ? child
        : (fallback ?? const SizedBox.shrink());
  }
}

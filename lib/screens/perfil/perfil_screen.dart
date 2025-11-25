import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';

import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/asignaciones_laborales/asignaciones_laborales_provider.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_provider.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/database/perfil/perfil_provider.dart';
import 'package:myafmzd/database/usuarios/usuarios_provider.dart';
import 'package:myafmzd/database/ventas/ventas_provider.dart';
import 'package:myafmzd/database/grupo_distribuidores/grupos_distribuidores_provider.dart';

import 'package:myafmzd/screens/perfil/asesor_monthly_sales_card.dart';
import 'package:myafmzd/screens/perfil/comparison_sales_card.dart';
import 'package:myafmzd/screens/perfil/distribuidora_monthly_sales_card.dart';

import 'package:myafmzd/session/sesion_asignacion_provider.dart';
import 'package:myafmzd/session/sesion_asignacion_selectors.dart';

class PerfilScreen extends ConsumerStatefulWidget {
  const PerfilScreen({super.key});

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  bool _cargandoInicial = true;

  // Año elegido en el único selector (fuente de verdad)
  int _selectedYear = DateTime.now().year;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarPerfil();
    });
  }

  @override
  Widget build(BuildContext context) {
    final usuario = ref.watch(perfilProvider);
    final colorsTheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Datos base
    final asignacionActiva = ref.watch(activeAssignmentProvider);
    final colaboradores = ref.watch(colaboradoresProvider);
    final distribuidores = ref.watch(distribuidoresProvider);
    final ventas = ref.watch(ventasProvider);
    final asignaciones = ref.watch(asignacionesLaboralesProvider);
    final gruposNotifier = ref.watch(gruposDistribuidoresProvider.notifier);

    // Mantén el perfil sincronizado con conectividad
    ref.listen<bool>(connectivityProvider, (previous, next) async {
      if (!mounted || previous == next) return;
      await _cargarPerfil();
    });

    if (usuario == null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Usuario no disponible',
            style: textTheme.bodyLarge?.copyWith(color: colorsTheme.onSurface),
          ),
        ),
      );
    }

    // Colaborador para nombre/foto
    final colaborador = () {
      try {
        if (usuario.colaboradorUid == null) return null;
        return colaboradores.firstWhere(
          (c) => !c.deleted && c.uid == usuario.colaboradorUid,
        );
      } catch (_) {
        return null;
      }
    }();

    final nombreCompleto = _nombreColaborador(colaborador);
    final fotoLocalPath = colaborador?.fotoRutaLocal ?? '';
    final tieneFotoLocal =
        fotoLocalPath.isNotEmpty && File(fotoLocalPath).existsSync();

    // Dist origen/concentradora de la asignación ACTIVA
    final distOrigen = () {
      if (asignacionActiva == null) return null;
      try {
        return distribuidores.firstWhere(
          (d) => !d.deleted && d.uid == asignacionActiva.distribuidorUid,
        );
      } catch (_) {
        return null;
      }
    }();

    final distConcentradora = () {
      if (distOrigen == null) return null;
      final concUid = (distOrigen.concentradoraUid.isNotEmpty)
          ? distOrigen.concentradoraUid
          : distOrigen.uid;
      try {
        return distribuidores.firstWhere((d) => !d.deleted && d.uid == concUid);
      } catch (_) {
        return null;
      }
    }();

    final nombreDistOrigen = distOrigen == null
        ? '—'
        : _sinPrefijoMazda(distOrigen.nombre);
    final nombreDistConcentradora = distConcentradora == null
        ? '—'
        : _sinPrefijoMazda(distConcentradora.nombre);

    // Rol activo
    final rolActivo = (asignacionActiva?.rol ?? '').toLowerCase().trim();

    // ===== Distribuidoras para GERENTE DE GRUPO (agrupadas por grupo) =====
    int totalDistribuidorasGrupo = 0;
    int totalGruposGrupo = 0;
    List<MapEntry<String, List<DistribuidorDb>>> gruposDistribuidorasGerente =
        [];

    if (rolActivo == 'gerente de grupo' &&
        usuario.colaboradorUid != null &&
        usuario.colaboradorUid!.isNotEmpty) {
      final colaboradorUid = usuario.colaboradorUid!;

      // Asignaciones activas de este colaborador como gerente de grupo
      final asignacionesGerente = asignaciones.where(
        (a) =>
            !a.deleted &&
            a.fechaFin == null &&
            a.rol == 'gerente de grupo' &&
            a.colaboradorUid == colaboradorUid &&
            a.distribuidorUid.isNotEmpty,
      );

      // Distribuidoras únicas
      final distribsGerente = <String, DistribuidorDb>{};
      for (final asig in asignacionesGerente) {
        try {
          final dist = distribuidores.firstWhere(
            (d) => !d.deleted && d.uid == asig.distribuidorUid,
          );
          distribsGerente[dist.uid] = dist;
        } catch (_) {
          // si no se encuentra, lo ignoramos
        }
      }

      // Agrupar por uuidGrupo
      final Map<String, List<DistribuidorDb>> gruposMap = {};
      for (final dist in distribsGerente.values) {
        final grupoUid = dist.uuidGrupo.trim();
        gruposMap.putIfAbsent(grupoUid, () => []).add(dist);
      }

      // Ordenar grupos por nombre de grupo
      gruposDistribuidorasGerente = gruposMap.entries.toList()
        ..sort((a, b) {
          final nombreA = gruposNotifier.nombrePorUid(a.key);
          final nombreB = gruposNotifier.nombrePorUid(b.key);
          return nombreA.compareTo(nombreB);
        });

      totalDistribuidorasGrupo = distribsGerente.length;
      totalGruposGrupo = gruposMap.length;
    }

    // Años disponibles (derivados de ventas)
    final availableYears = () {
      final set = <int>{};
      for (final v in ventas) {
        final y = v.anioVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().year;
        set.add(y);
      }
      if (!set.contains(_selectedYear)) set.add(_selectedYear);
      final list = set.toList()..sort();
      return list;
    }();

    return Scaffold(
      body: _cargandoInicial
          ? const SizedBox.shrink()
          : RefreshIndicator(
              color: colorsTheme.secondary,
              onRefresh: _cargarPerfil,
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  // ====== CARD: Perfil ======
                  Center(
                    child: Card(
                      color: colorsTheme.surface,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            CircleAvatar(
                              radius: 40,
                              backgroundColor: colorsTheme.surfaceVariant,
                              backgroundImage: tieneFotoLocal
                                  ? FileImage(File(fotoLocalPath))
                                  : null,
                              child: (!tieneFotoLocal)
                                  ? Icon(
                                      Icons.account_circle,
                                      size: 60,
                                      color: colorsTheme.onSurface,
                                    )
                                  : null,
                            ),
                            const SizedBox(height: 16),

                            if (nombreCompleto.isNotEmpty) ...[
                              Text(
                                nombreCompleto,
                                style: textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorsTheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 8),
                            ],

                            Text(
                              usuario.userName,
                              style: textTheme.bodyLarge?.copyWith(
                                color: colorsTheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),

                            _buildUserInfoRow(
                              context,
                              Icons.email_outlined,
                              usuario.correo,
                            ),

                            const SizedBox(height: 12),
                            const Divider(height: 1),

                            const SizedBox(height: 12),
                            _buildUserInfoRow(
                              context,
                              Icons.badge_outlined,
                              asignacionActiva?.rol.isNotEmpty == true
                                  ? _capitalize(asignacionActiva!.rol)
                                  : '—',
                            ),

                            // 👇 Comportamiento según rol
                            if (rolActivo == 'gerente de grupo') ...[
                              _buildUserInfoRow(
                                context,
                                Icons.storefront_outlined,
                                totalDistribuidorasGrupo > 0
                                    ? 'Distribuidoras: $totalDistribuidorasGrupo en $totalGruposGrupo grupos'
                                    : 'Distribuidoras: —',
                              ),
                              if (gruposDistribuidorasGerente.isNotEmpty) ...[
                                const SizedBox(height: 12),

                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    for (final entry
                                        in gruposDistribuidorasGerente) ...[
                                      _GrupoDistribuidorasSection(
                                        nombreGrupo: gruposNotifier
                                            .nombrePorUid(entry.key),
                                        distribuidoras: entry.value,
                                        sinPrefijoMazda: _sinPrefijoMazda,
                                      ),
                                      const SizedBox(height: 8),
                                    ],
                                  ],
                                ),
                              ],
                            ] else ...[
                              _buildUserInfoRow(
                                context,
                                Icons.store_mall_directory_outlined,
                                'Distribuidora: $nombreDistOrigen',
                              ),
                              _buildUserInfoRow(
                                context,
                                Icons.hub_outlined,
                                'Concentradora: $nombreDistConcentradora',
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ====== ÚNICO SELECTOR DE AÑO ======
                  Center(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: _selectedYear,
                        items: [
                          for (final y in availableYears)
                            DropdownMenuItem(value: y, child: Text('$y')),
                        ],
                        onChanged: (v) {
                          if (v == null) return;
                          setState(() => _selectedYear = v);
                        },
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  // ====== CARD: Ventas del asesor ======
                  AsesorMonthlySalesCard(
                    rolActivo: rolActivo,
                    initialYear: _selectedYear, // 👈 viene del selector
                    chartHeight: 220,
                  ),

                  const SizedBox(height: 4),

                  // ====== CARD: Ventas de la distribuidora ======
                  DistribuidoraMonthlySalesCard(
                    rolActivo: rolActivo,
                    initialYear: _selectedYear, // 👈 viene del selector
                    chartHeight: 220,
                  ),

                  ComparisonSalesCard(
                    rolActivo: rolActivo,
                    initialYear: _selectedYear, // 👈 viene del selector
                    chartHeight: 300,
                  ),
                ],
              ),
            ),
    );
  }

  // ===== Helpers UI / Datos =====
  Widget _buildUserInfoRow(BuildContext context, IconData icon, String text) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 20, color: colors.onSurface),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: textTheme.bodyLarge?.copyWith(color: colors.onSurface),
            ),
          ),
        ],
      ),
    );
  }

  String _nombreColaborador(colab) {
    if (colab == null) return '';
    final s =
        '${colab.nombres} ${colab.apellidoPaterno} ${colab.apellidoMaterno}';
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _sinPrefijoMazda(String s) {
    if (s.isEmpty) return '';
    final reg = RegExp(r'^\s*mazda\b[\s\-–—:]*', caseSensitive: false);
    final out = s.replaceFirst(reg, '');
    return out.trimLeft();
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1).toLowerCase();
  }

  // ===== Carga de datos =====
  Future<void> _cargarPerfil() async {
    if (!mounted) return;
    setState(() => _cargandoInicial = true);
    FocusScope.of(context).unfocus();

    context.loaderOverlay.show(progress: 'Cargando perfil…');
    final inicio = DateTime.now();

    try {
      if (!mounted) return;
      await ref.read(usuariosProvider.notifier).cargarOfflineFirst();
      if (context.loaderOverlay.visible) {
        context.loaderOverlay.progress('Cargando colaboradores');
      }
      await ref.read(colaboradoresProvider.notifier).cargarOfflineFirst();

      if (!mounted) return;
      if (context.loaderOverlay.visible) {
        context.loaderOverlay.progress('Cargando asignaciones…');
      }
      await ref
          .read(asignacionesLaboralesProvider.notifier)
          .cargarOfflineFirst();

      // Asegurar asignación activa
      final usuario = ref.read(perfilProvider);
      await ref
          .read(assignmentSessionProvider.notifier)
          .ensureActiveForUser(colaboradorUid: usuario?.colaboradorUid);

      if (!mounted) return;
      if (context.loaderOverlay.visible) {
        context.loaderOverlay.progress('Cargando distribuidores…');
      }
      await ref.read(distribuidoresProvider.notifier).cargarOfflineFirst();

      // Perfil
      if (!mounted) return;
      if (context.loaderOverlay.visible) {
        context.loaderOverlay.progress('Obteniendo usuario…');
      }
      await ref.read(perfilProvider.notifier).cargarUsuario();

      // Ventas
      if (!mounted) return;
      if (context.loaderOverlay.visible) {
        context.loaderOverlay.progress('Cargando ventas…');
      }
      await ref.read(ventasProvider.notifier).cargarOfflineFirst();

      // Pequeño mínimo de duración
      final duracion = DateTime.now().difference(inicio);
      const duracionMinima = Duration(milliseconds: 1500);
      if (duracion < duracionMinima) {
        await Future.delayed(duracionMinima - duracion);
      }
    } finally {
      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
      if (mounted) {
        setState(() => _cargandoInicial = false);
      }
    }
  }
}

// ===== Widget auxiliar para mostrar distribuidoras por grupo =====

class _GrupoDistribuidorasSection extends StatelessWidget {
  final String nombreGrupo;
  final List<DistribuidorDb> distribuidoras;
  final String Function(String) sinPrefijoMazda;

  const _GrupoDistribuidorasSection({
    required this.nombreGrupo,
    required this.distribuidoras,
    required this.sinPrefijoMazda,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final distOrdenadas = [...distribuidoras]
      ..sort((a, b) => a.nombre.compareTo(b.nombre));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nombreGrupo,
          style: textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final d in distOrdenadas)
              Chip(
                backgroundColor: d.activo
                    ? null
                    : colors.errorContainer.withOpacity(0.9),
                side: d.activo
                    ? null
                    : BorderSide(color: colors.error, width: 0.8),
                label: Text(
                  sinPrefijoMazda(d.nombre),
                  style: textTheme.bodySmall?.copyWith(
                    color: d.activo
                        ? colors.onSurface
                        : colors.onErrorContainer,
                  ),
                ),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
          ],
        ),
      ],
    );
  }
}

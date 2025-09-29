// lib/screens/perfil/perfil_screen.dart
import 'dart:async';
import 'dart:io'; // 👈 para File y FileImage

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_provider.dart';
import 'package:myafmzd/database/usuarios/usuarios_provider.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/database/perfil/perfil_provider.dart';
import 'package:myafmzd/database/ventas/ventas_provider.dart';
import 'package:myafmzd/database/asignaciones_laborales/asignaciones_laborales_provider.dart';
import 'package:myafmzd/session/sesion_asignacion_provider.dart';
import 'package:myafmzd/session/sesion_asignacion_selectors.dart';
import 'package:myafmzd/widgets/charts/my_timeline_bar_chart.dart';
import 'package:myafmzd/widgets/charts/my_timeline_line_chart.dart';

class PerfilScreen extends ConsumerStatefulWidget {
  const PerfilScreen({super.key});

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  bool _cargandoInicial = true;

  // Año seleccionado para la gráfica
  late int _selectedYear;

  // 👇 Solo se usa cuando el rol activo es GERENTE
  String _selectedVendedorUid = '';

  @override
  void initState() {
    super.initState();
    _selectedYear = DateTime.now().year; // default
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarPerfil();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Escucha ventas para que el combo de años se actualice cuando cambie el estado
    final ventasState = ref.watch(ventasProvider);

    final usuario = ref.watch(perfilProvider);
    final colorsTheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Objeto de asignación activa (del usuario logueado)
    final asignacionActiva = ref.watch(activeAssignmentProvider);

    // Catálogo de colaboradores, asignaciones y distribuidores
    final colaboradores = ref.watch(colaboradoresProvider);
    final asignaciones = ref.watch(asignacionesLaboralesProvider);
    final distribuidores = ref.watch(distribuidoresProvider);

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

    // --- Colaborador del usuario (para nombre y foto) ---
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

    // --- Distribuidora de origen y concentradora (si hay asignación activa) ---
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

    // === Rol activo ===
    final rolActivo = (asignacionActiva?.rol ?? '').toLowerCase().trim();
    final esGerente = rolActivo == 'gerente';

    // === Años disponibles desde Ventas (globales) ===
    final availableYears = () {
      final set = <int>{};
      for (final v in ventasState) {
        final y = v.anioVenta ?? (v.fechaVenta ?? v.updatedAt).toUtc().year;
        set.add(y);
      }
      if (!set.contains(_selectedYear)) set.add(_selectedYear);
      final list = set.toList()..sort();
      return list;
    }();

    // === Vendedores disponibles (solo cuando GERENTE) ===
    final vendedoresOpciones = <MapEntry<String, String>>[];
    if (esGerente && distOrigen != null) {
      final origenUid = distOrigen.uid;
      final concUid = distConcentradora?.uid ?? origenUid;

      final vendedoresActivos = asignaciones.where((a) {
        if (a.deleted) return false;
        if (a.fechaFin != null) return false;
        if (a.rol.toLowerCase().trim() != 'vendedor') return false;
        return a.distribuidorUid == origenUid || a.distribuidorUid == concUid;
      }).toList();

      final setColabs = <String>{};
      for (final a in vendedoresActivos) {
        if (setColabs.contains(a.colaboradorUid)) continue;
        final c = _colaboradorPorUid(colaboradores, a.colaboradorUid);
        final nombre = _nombreColaborador(c);
        vendedoresOpciones.add(
          MapEntry(
            a.colaboradorUid,
            nombre.isEmpty ? a.colaboradorUid : nombre,
          ),
        );
        setColabs.add(a.colaboradorUid);
      }

      vendedoresOpciones.sort((x, y) => x.value.compareTo(y.value));

      final valido =
          _selectedVendedorUid.isNotEmpty &&
          vendedoresOpciones.any((e) => e.key == _selectedVendedorUid);
      if (!valido && _selectedVendedorUid.isNotEmpty) {
        _selectedVendedorUid = '';
      }
    } else {
      if (_selectedVendedorUid.isNotEmpty) _selectedVendedorUid = '';
    }

    // === Serie para gráfica según rol ===
    final serie = () {
      if (asignacionActiva == null) return List<int>.filled(12, 0);

      if (!esGerente) {
        return ref
            .read(ventasProvider.notifier)
            .serieMensualAnioAsignacion(
              asignacion: asignacionActiva,
              anio: _selectedYear,
              exigirDistribuidor: false,
              incluirEliminadas: false,
            );
      }

      if (_selectedVendedorUid.isEmpty) {
        return List<int>.filled(12, 0);
      }

      final asigVendedor = ref
          .read(asignacionesLaboralesProvider.notifier)
          .activaPorColaborador(_selectedVendedorUid);

      if (asigVendedor == null) {
        return List<int>.filled(12, 0);
      }

      return ref
          .read(ventasProvider.notifier)
          .serieMensualAnioAsignacion(
            asignacion: asigVendedor,
            anio: _selectedYear,
            exigirDistribuidor: false,
            incluirEliminadas: false,
          );
    }();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Perfil",
          style: textTheme.titleLarge?.copyWith(color: colorsTheme.onSurface),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
      ),
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
                  // ====== CARD: Perfil (foto, datos) ======
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
                            // Avatar con foto local si existe
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

                            // Nombre completo del colaborador (si hay)
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

                            // Usuario
                            Text(
                              usuario.userName,
                              style: textTheme.bodyLarge?.copyWith(
                                color: colorsTheme.onSurface,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 6),

                            // Correo
                            _buildUserInfoRow(
                              context,
                              Icons.email_outlined,
                              usuario.correo,
                            ),

                            const SizedBox(height: 12),
                            const Divider(height: 1),

                            // Rol actual (de asignación activa)
                            const SizedBox(height: 12),
                            _buildUserInfoRow(
                              context,
                              Icons.badge_outlined,
                              asignacionActiva?.rol.isNotEmpty == true
                                  ? _capitalize(asignacionActiva!.rol)
                                  : '—',
                            ),

                            // Distribuidora origen
                            _buildUserInfoRow(
                              context,
                              Icons.store_mall_directory_outlined,
                              'Distribuidora: $nombreDistOrigen',
                            ),

                            // Concentradora (donde se concentran ventas)
                            _buildUserInfoRow(
                              context,
                              Icons.hub_outlined,
                              'Concentradora: $nombreDistConcentradora',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ====== CARD: Ventas del año (timeline) + selectores ======
                  Card(
                    elevation: 1,
                    color: colorsTheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.bar_chart_rounded,
                                color: colorsTheme.primary,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  esGerente
                                      ? 'Ventas por mes (por asesor)'
                                      : 'Ventas por mes',
                                  style: textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorsTheme.onSurface,
                                  ),
                                ),
                              ),

                              // === Selector de año ===
                              DropdownButtonHideUnderline(
                                child: DropdownButton<int>(
                                  value: _selectedYear,
                                  items: availableYears
                                      .map(
                                        (y) => DropdownMenuItem<int>(
                                          value: y,
                                          child: Text(
                                            '$y',
                                            style: textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: colorsTheme.onSurface,
                                                ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (val) {
                                    if (val == null) return;
                                    setState(() => _selectedYear = val);
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ],
                          ),

                          // === Selector de Vendedor (solo GERENTE) ===
                          if (esGerente) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(
                                  Icons.person_search_outlined,
                                  color: colorsTheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    isDense: true,
                                    isExpanded: true, // evitar overflow
                                    decoration: const InputDecoration(
                                      labelText: 'Vendedor',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    value: _selectedVendedorUid.isEmpty
                                        ? ''
                                        : _selectedVendedorUid,
                                    items: [
                                      const DropdownMenuItem<String>(
                                        value: '',
                                        child: Text('Seleccione un vendedor'),
                                      ),
                                      ...vendedoresOpciones.map(
                                        (e) => DropdownMenuItem<String>(
                                          value: e.key,
                                          child: Text(
                                            e.value.isEmpty ? e.key : e.value,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedVendedorUid = (val ?? '');
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 12),

                          // ====== Charts (responsivo en 1 o 2 columnas) ======
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final maxW = constraints.maxWidth;
                              // Breakpoint simple: 2 columnas cuando hay espacio suficiente
                              final cols = maxW >= 1100 ? 2 : 1;

                              // Altura fija deseada para cada chart
                              const chartHeight = 220.0;
                              const spacing = 12.0;
                              final tileWidth =
                                  (maxW - spacing * (cols - 1)) / cols;
                              final childAspectRatio = tileWidth / chartHeight;

                              final charts = <Widget>[
                                SizedBox(
                                  height: chartHeight,
                                  child: MyTimelineBarChart(
                                    serie: serie,
                                    year: _selectedYear,
                                    style: TimelineBarChartStyle.minimal,
                                    compact: true,
                                    highlightCurrentMonth: true,
                                  ),
                                ),

                                SizedBox(
                                  height: chartHeight,
                                  child: MyTimelineBarChart(
                                    serie: serie,
                                    year: _selectedYear,
                                    style: TimelineBarChartStyle.goalLine,
                                    compact: true,
                                    highlightCurrentMonth: true,
                                    monthlyGoal: 12,
                                  ),
                                ),
                                SizedBox(
                                  height: chartHeight,
                                  child: MyTimelineBarChart(
                                    serie: serie,
                                    year: _selectedYear,
                                    style: TimelineBarChartStyle.avgLine,
                                    compact: true,
                                    highlightCurrentMonth: true,
                                  ),
                                ),
                              ];

                              if (cols == 1) {
                                // Una columna: lista vertical
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    for (final c in charts) ...[
                                      c,
                                      const SizedBox(height: spacing),
                                    ],
                                  ],
                                );
                              }

                              // Dos columnas: grid no desplazable dentro del ListView, con altura fijada por childAspectRatio
                              return GridView.count(
                                crossAxisCount: cols,
                                crossAxisSpacing: spacing,
                                mainAxisSpacing: spacing,
                                childAspectRatio: childAspectRatio,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                children: charts,
                              );
                            },
                          ),

                          LayoutBuilder(
                            builder: (context, constraints) {
                              final maxW = constraints.maxWidth;
                              // Breakpoint simple: 2 columnas cuando hay espacio suficiente
                              final cols = maxW >= 1100 ? 2 : 1;

                              // Altura fija deseada para cada chart
                              const chartHeight = 220.0;
                              const spacing = 12.0;
                              final tileWidth =
                                  (maxW - spacing * (cols - 1)) / cols;
                              final childAspectRatio = tileWidth / chartHeight;

                              final charts = <Widget>[
                                SizedBox(
                                  height: chartHeight,
                                  child: MyTimelineLineChart(
                                    serie: serie,
                                    year: _selectedYear,
                                    style: TimelineLineChartStyle.minimal,
                                    compact: true,
                                    highlightCurrentMonth: true,
                                  ),
                                ),

                                SizedBox(
                                  height: chartHeight,
                                  child: MyTimelineLineChart(
                                    serie: serie,
                                    year: _selectedYear,
                                    style: TimelineLineChartStyle.goalLine,
                                    compact: true,
                                    highlightCurrentMonth: true,
                                    monthlyGoal: 12,
                                  ),
                                ),
                                SizedBox(
                                  height: chartHeight,
                                  child: MyTimelineLineChart(
                                    serie: serie,
                                    year: _selectedYear,
                                    style: TimelineLineChartStyle.avgLine,
                                    compact: true,
                                    highlightCurrentMonth: true,
                                  ),
                                ),
                              ];

                              if (cols == 1) {
                                // Una columna: lista vertical
                                return Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    for (final c in charts) ...[
                                      c,
                                      const SizedBox(height: spacing),
                                    ],
                                  ],
                                );
                              }

                              // Dos columnas: grid no desplazable dentro del ListView, con altura fijada por childAspectRatio
                              return GridView.count(
                                crossAxisCount: cols,
                                crossAxisSpacing: spacing,
                                mainAxisSpacing: spacing,
                                childAspectRatio: childAspectRatio,
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                children: charts,
                              );
                            },
                          ),

                          if (esGerente && _selectedVendedorUid.isEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Seleccione un vendedor para ver sus ventas.',
                                style: textTheme.bodySmall?.copyWith(
                                  color: colorsTheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
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
              overflow: TextOverflow.ellipsis,
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

  dynamic _colaboradorPorUid(List colabs, String uid) {
    try {
      return colabs.firstWhere((c) => !c.deleted && c.uid == uid);
    } catch (_) {
      return null;
    }
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
      // 1) Catálogos base
      await ref.read(usuariosProvider.notifier).cargarOfflineFirst();
      if (!mounted) return;
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

      // 5) Asegurar asignación activa coherente para este usuario
      final usuario = ref.read(perfilProvider);
      await ref
          .read(assignmentSessionProvider.notifier)
          .ensureActiveForUser(colaboradorUid: usuario?.colaboradorUid);

      if (!mounted) return;
      if (context.loaderOverlay.visible) {
        context.loaderOverlay.progress('Cargando distribuidores…');
      }
      await ref.read(distribuidoresProvider.notifier).cargarOfflineFirst();

      // 2) Perfil de usuario
      if (!mounted) return;
      if (context.loaderOverlay.visible) {
        context.loaderOverlay.progress('Obteniendo usuario…');
      }
      await ref.read(perfilProvider.notifier).cargarUsuario();

      // 3) Ventas (para la gráfica)
      if (!mounted) return;
      if (context.loaderOverlay.visible) {
        context.loaderOverlay.progress('Cargando ventas…');
      }
      await ref.read(ventasProvider.notifier).cargarOfflineFirst();

      // Mantener una duración mínima agradable
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

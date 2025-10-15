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
import 'package:myafmzd/screens/perfil/asesor_monthly_sales_card.dart';
import 'package:myafmzd/screens/perfil/distribuidora_monthly_sales_card.dart';
import 'package:myafmzd/screens/perfil/distribuidora_pie_sales_card.dart';
import 'package:myafmzd/session/sesion_asignacion_provider.dart';
import 'package:myafmzd/session/sesion_asignacion_selectors.dart';

class PerfilScreen extends ConsumerStatefulWidget {
  const PerfilScreen({super.key});

  @override
  ConsumerState<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends ConsumerState<PerfilScreen> {
  bool _cargandoInicial = true;

  // Año seleccionado para la gráfica de distribuidora (el card de asesor maneja su propio año)

  // 👇 Solo se usa cuando el rol activo es ADMIN (ámbito de distribuidora)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarPerfil();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Escucha ventas para que el combo de años se actualice cuando cambie el estado

    final usuario = ref.watch(perfilProvider);
    final colorsTheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Objeto de asignación activa (del usuario logueado)
    final asignacionActiva = ref.watch(activeAssignmentProvider);

    // Catálogo de colaboradores y distribuidores
    final colaboradores = ref.watch(colaboradoresProvider);
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

                  // ====== CARD: Ventas del asesor ======
                  AsesorMonthlySalesCard(
                    rolActivo: rolActivo, // 'vendedor' | 'gerente' | 'admin'
                    initialYear: DateTime.now().year,
                    chartHeight: 220,
                  ),
                  const SizedBox(height: 24),

                  DistribuidoraPieChartsCard(
                    rolActivo: rolActivo,
                    distribuidorUid: distConcentradora?.uid ?? distOrigen?.uid,
                    initialYear: DateTime.now().year,
                  ),
                  const SizedBox(height: 24),

                  // ====== CARD: Ventas de la distribuidora ======
                  DistribuidoraMonthlySalesCard(
                    rolActivo: rolActivo, // 'vendedor' | 'gerente' | 'admin'
                    initialYear: DateTime.now().year,
                    chartHeight: 220,
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

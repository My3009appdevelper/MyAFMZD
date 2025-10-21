import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/usuarios/usuarios_provider.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_provider.dart';
import 'package:myafmzd/database/asignaciones_laborales/asignaciones_laborales_provider.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/screens/usuarios/usuarios_tile.dart';
import 'package:myafmzd/screens/usuarios/usuarios_form_page.dart';
import 'package:myafmzd/widgets/my_text_field.dart';

class UsuariosScreen extends ConsumerStatefulWidget {
  const UsuariosScreen({super.key});
  @override
  ConsumerState<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends ConsumerState<UsuariosScreen> {
  bool _cargandoInicial = true;

  // === 🔎 Estado de búsqueda ===
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarUsuarios();
    });

    _searchCtrl.addListener(() {
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 250), () {
        if (!mounted) return;
        setState(() => _query = _searchCtrl.text);
      });
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usuarios = ref.watch(usuariosProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    // Recargar si cambia conectividad
    ref.listen<bool>(connectivityProvider, (previous, next) async {
      if (!mounted || previous == next) return;
      await _cargarUsuarios();
    });

    // Mapa auxiliar: colaboradorUid -> nombre completo
    final colaboradores = ref.watch(colaboradoresProvider);
    final mapColabNombre = {
      for (final c in colaboradores)
        c.uid: _nombreCompleto(c.nombres, c.apellidoPaterno, c.apellidoMaterno),
    };

    // N:M distribuidoras por colaborador a partir de asignaciones activas
    final asignaciones = ref
        .read(asignacionesLaboralesProvider.notifier)
        .listarActivas(); // sin filtros extra

    final distribuidores = ref.watch(distribuidoresProvider);
    final mapDistribNombre = {for (final d in distribuidores) d.uid: d.nombre};

    // colaboradorUid -> set de nombres de distribuidoras
    final Map<String, Set<String>> mapColabDistribNombres = {};
    for (final a in asignaciones) {
      final colabUid = _tryS(() => a.colaboradorUid);

      final distUid = _tryS(() => a.distribuidorUid);
      if (colabUid == null ||
          colabUid.isEmpty ||
          distUid == null ||
          distUid.isEmpty)
        continue;
      final nombre = mapDistribNombre[distUid];
      if (nombre == null || nombre.isEmpty) continue;
      mapColabDistribNombres
          .putIfAbsent(colabUid, () => <String>{})
          .add(nombre);
    }

    // 🔎 Lista filtrada por colaborador / distribuidora / username / correo
    final filtrados = _aplicarFiltroUsuarios(
      usuarios,
      _query,
      mapColabNombre: mapColabNombre,
      mapColabDistribNombres: mapColabDistribNombres,
    );

    return Scaffold(
      body: _cargandoInicial
          ? const SizedBox.shrink()
          : Column(
              children: [
                // === 🔎 Barra de búsqueda (idéntica en diseño) ===
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: MyTextField(
                    controller: _searchCtrl,
                    textInputAction: TextInputAction.search,
                    showClearButton: _query.isNotEmpty,
                    labelText: 'Buscar usuario',
                    hintText:
                        'Colaborador o distribuidora (también username/correo)',
                    onClear: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                    onSubmitted: (_) => FocusScope.of(context).unfocus(),
                  ),
                ),

                Expanded(
                  child: RefreshIndicator(
                    color: colorScheme.secondary,
                    onRefresh: _cargarUsuarios,
                    child: filtrados.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 80),
                              Center(
                                child: Text(
                                  _query.isEmpty
                                      ? 'No hay usuarios'
                                      : 'Sin coincidencias para “$_query”.',
                                  style: textTheme.bodyLarge?.copyWith(
                                    color: colorScheme.onSurface.withOpacity(
                                      0.65,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const BouncingScrollPhysics(
                              parent: AlwaysScrollableScrollPhysics(),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 24,
                            ),
                            itemCount: filtrados.length,
                            itemBuilder: (context, index) {
                              final usuario = filtrados[index];
                              return Card(
                                color: colorScheme.surface,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                child: UsuariosItemTile(
                                  key: ValueKey(usuario.uid),
                                  usuario: usuario,
                                  onTap: () {},
                                  onActualizado: () async {
                                    await _cargarUsuarios();
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const UsuariosFormPage()),
          );
          if (result == true) {
            await _cargarUsuarios();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _cargarUsuarios() async {
    if (!mounted) return;

    setState(() => _cargandoInicial = true);
    FocusScope.of(context).unfocus();

    context.loaderOverlay.show(progress: 'Cargando usuarios…');

    final inicio = DateTime.now();

    try {
      final hayInternet = ref.read(connectivityProvider);

      await ref.read(usuariosProvider.notifier).cargarOfflineFirst();

      // delay mínimo (opcional)
      const duracionMinima = Duration(milliseconds: 1500);
      final duracion = DateTime.now().difference(inicio);
      if (duracion < duracionMinima) {
        await Future.delayed(duracionMinima - duracion);
      }

      if (!mounted) return;
      if (!hayInternet) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📴 Estás sin conexión. Solo información local.'),
            duration: Duration(seconds: 3),
          ),
        );
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

  // ===============================
  // 🔎 BÚSQUEDA / MATCHING (usuarios)
  // ===============================

  List _aplicarFiltroUsuarios(
    List usuarios,
    String query, {
    required Map<String, String> mapColabNombre,
    required Map<String, Set<String>> mapColabDistribNombres,
  }) {
    if (query.trim().isEmpty) return usuarios;

    final q = _normalize(query);
    final tokens = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

    return usuarios.where((u) {
      final colabUid = _safeStr(u.colaboradorUid);

      // Nombre de colaborador
      final colaboradorNombre = mapColabNombre[colabUid] ?? '';

      // Nombres de TODAS las distribuidoras del colaborador (N:M)
      final distribNombresSet =
          mapColabDistribNombres[colabUid] ?? const <String>{};
      final distribNombres = distribNombresSet.join(' ');

      final userName = _safeStr(u.userName);
      final correo = _safeStr(u.correo);

      // Índice normalizado
      final indexText = _normalize(
        '$colaboradorNombre $distribNombres $userName $correo',
      );

      // AND de tokens
      final ok = tokens.every(indexText.contains);
      return ok;
    }).toList();
  }

  // utils
  String _safeStr(Object? v) => (v ?? '').toString();

  String _nombreCompleto(String? n, String? apP, String? apM) =>
      '${n ?? ''} ${apP ?? ''} ${apM ?? ''}'
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

  String _normalize(String input) {
    var t = input.toLowerCase();
    t = t.replaceAll(RegExp(r'[áàäâã]'), 'a');
    t = t.replaceAll(RegExp(r'[éèëê]'), 'e');
    t = t.replaceAll(RegExp(r'[íìïî]'), 'i');
    t = t.replaceAll(RegExp(r'[óòöôõ]'), 'o');
    t = t.replaceAll(RegExp(r'[úùüû]'), 'u');
    t = t.replaceAll(RegExp(r'[ñ]'), 'n');
    t = t.replaceAll(RegExp(r'[ç]'), 'c');
    t = t.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t;
  }

  String? _tryS(String Function() f) {
    try {
      final v = f();
      return (v).toString();
    } catch (_) {
      return null;
    }
  }
}

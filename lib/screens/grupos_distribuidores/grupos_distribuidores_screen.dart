import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/grupo_distribuidores/grupos_distribuidores_provider.dart';
import 'package:myafmzd/screens/grupos_distribuidores/grupos_distribuidores_form_page.dart';
import 'package:myafmzd/screens/grupos_distribuidores/grupos_distribuidores_tile.dart';
import 'package:myafmzd/widgets/my_text_field.dart';

class GruposDistribuidoresScreen extends ConsumerStatefulWidget {
  const GruposDistribuidoresScreen({super.key});

  @override
  ConsumerState<GruposDistribuidoresScreen> createState() =>
      _GruposDistribuidoresScreenState();
}

class _GruposDistribuidoresScreenState
    extends ConsumerState<GruposDistribuidoresScreen> {
  bool _cargandoInicial = true;

  // 🔎 Estado de búsqueda
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Carga inicial
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarGrupos();
    });

    // Debounce búsqueda
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Conectividad
    ref.listen<bool>(connectivityProvider, (prev, next) async {
      if (!mounted || prev == next) return;
      await _cargarGrupos();
    });

    // Estado base
    final grupos = ref.watch(gruposDistribuidoresProvider);

    // Base visible (sin chips de activos/todos): solo no eliminados
    final base = grupos.where((g) => !g.deleted).toList()
      ..sort((a, b) => a.nombre.compareTo(b.nombre));

    // 🔎 Filtrado local por nombre (y abreviatura)
    final visibles = _aplicarFiltro(base, _query);

    return Scaffold(
      floatingActionButton: _cargandoInicial
          ? null
          : FloatingActionButton(
              onPressed: () async {
                final ok = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const GrupoDistribuidorFormPage(),
                  ),
                );
                if (mounted && ok == true) {
                  await _cargarGrupos();
                }
              },
              tooltip: 'Nuevo grupo',
              child: const Icon(Icons.add),
            ),
      body: Column(
        children: [
          // 🔎 Barra de búsqueda (mismo diseño que otras screens)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: MyTextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              showClearButton: _query.isNotEmpty,
              labelText: 'Buscar grupo',
              hintText: 'Nombre del grupo (o abreviatura)',
              onClear: () {
                _searchCtrl.clear();
                setState(() => _query = '');
              },
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
            ),
          ),

          Expanded(
            child: _cargandoInicial
                ? const SizedBox.shrink()
                : RefreshIndicator(
                    color: cs.secondary,
                    onRefresh: _cargarGrupos,
                    child: visibles.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 80),
                              Center(
                                child: Text(
                                  _query.trim().isEmpty
                                      ? 'No hay grupos'
                                      : 'Sin coincidencias para “$_query”.',
                                  style: tt.bodyLarge?.copyWith(
                                    color: cs.onSurface.withOpacity(0.65),
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
                            itemCount: visibles.length,
                            itemBuilder: (context, index) {
                              final g = visibles[index];
                              return Card(
                                color: cs.surface,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                child: GrupoDistribuidorItemTile(
                                  key: ValueKey(g.uid),
                                  grupo: g,
                                  onTap: () {},
                                  onActualizado: () async {
                                    await _cargarGrupos();
                                  },
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  // ============================ Carga ========================================
  Future<void> _cargarGrupos() async {
    if (!mounted) return;

    setState(() => _cargandoInicial = true);
    FocusScope.of(context).unfocus();

    context.loaderOverlay.show(progress: 'Cargando grupos…');
    final inicio = DateTime.now();

    try {
      final hayInternet = ref.read(connectivityProvider);

      await ref
          .read(gruposDistribuidoresProvider.notifier)
          .cargarOfflineFirst();

      // spinner mínimo para consistencia visual
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

  // ===================== Búsqueda / Matching =====================
  List _aplicarFiltro(List lista, String query) {
    if (query.trim().isEmpty) return lista;

    final q = _normalize(query);
    final tokens = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

    return lista.where((g) {
      final nombre = _safeStr(g.nombre);
      final abrev = _safeStr(g.abreviatura);

      final indexText = _normalize('$nombre $abrev');

      // AND de tokens
      return tokens.every(indexText.contains);
    }).toList();
  }

  // utils
  String _safeStr(Object? v) => (v ?? '').toString();

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
}

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/modelos/modelo_imagenes_provider.dart';
import 'package:myafmzd/database/modelos/modelos_provider.dart';
import 'package:myafmzd/screens/modelos/modelo_detalle_page.dart';
import 'package:myafmzd/screens/modelos/modelos_form_page.dart';
import 'package:myafmzd/screens/modelos/modelos_tile.dart';

class ModelosScreen extends ConsumerStatefulWidget {
  const ModelosScreen({super.key});

  @override
  ConsumerState<ModelosScreen> createState() => _ModelosScreenState();
}

class _ModelosScreenState extends ConsumerState<ModelosScreen> {
  bool _cargandoInicial = true;
  bool _abriendoPdf = false;
  bool _trabajandoMasivo = false;

  int? _anioSeleccionado; // null => Todos
  bool _soloActivos = false;

  @override
  void initState() {
    super.initState();
    _cargarModelos();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Reacciona a cambios de conectividad
    ref.listen<bool>(connectivityProvider, (prev, next) async {
      if (prev != next && mounted) {
        await _cargarModelos();
      }
    });

    final tipos = ref
        .watch(modelosProvider.notifier)
        .tiposUnicos; // incluye "Todos"
    // Para chips de años mostramos descendente (reciente primero)
    final anios = [...ref.watch(modelosProvider.notifier).aniosUnicos.reversed];

    // Mapa tipo -> lista filtrada
    final Map<String, List<ModeloDb>> grupos = {
      for (final t in tipos)
        t: ref
            .read(modelosProvider.notifier)
            .filtrar(
              tipo: t == 'Todos' ? null : t,
              incluirInactivos: !_soloActivos,
              anio: _anioSeleccionado,
            ),
    };

    return Stack(
      children: [
        DefaultTabController(
          key: ValueKey(
            '${tipos.join("|")}::${_anioSeleccionado ?? "all"}::$_soloActivos',
          ),
          length: tipos.length,
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                'Modelos',
                style: tt.titleLarge?.copyWith(color: cs.onSurface),
              ),
              centerTitle: true,
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              bottom: tipos.isNotEmpty
                  ? TabBar(
                      isScrollable: true,
                      indicatorColor: cs.onSurface,
                      labelColor: cs.onSurface,
                      unselectedLabelColor: cs.secondary.withOpacity(0.6),
                      tabs: [
                        for (final t in tipos)
                          Tab(text: '$t (${grupos[t]?.length ?? 0})'),
                      ],
                    )
                  : null,
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () async {
                final ok = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ModelosFormPage()),
                );
                if (mounted && ok == true) {
                  await _cargarModelos();
                }
              },
              tooltip: 'Agregar nuevo modelo',
              child: const Icon(Icons.add),
            ),
            body: Column(
              children: [
                _buildFiltros(
                  context,
                  anios,
                  grupos['Todos']?.length ??
                      0, // usa solo el total de la pestaña “Todos”
                ),
                Expanded(
                  child: _cargandoInicial
                      ? const Center(child: CircularProgressIndicator())
                      : TabBarView(
                          children: [
                            for (final t in tipos)
                              RefreshIndicator(
                                color: cs.secondary,
                                onRefresh: _cargarModelos,
                                child: _buildListaTab(
                                  context,
                                  grupos[t] ?? const [],
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),

        if (_abriendoPdf)
          ModalBarrier(
            dismissible: false,
            color: Colors.black.withOpacity(0.25),
          ),
        if (_abriendoPdf)
          const Center(
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 12),
                    Text('Abriendo ficha técnica...'),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ========================== Widgets auxiliares ==============================

  Widget _buildFiltros(BuildContext context, List<int> anios, int totalActual) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Column(
        children: [
          // Línea 1: Chips de año (centrados y scroll si desbordan)
          SizedBox(
            height: 44,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const labelPad = EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                );
                final textTheme = Theme.of(context).textTheme;
                final colorScheme = Theme.of(context).colorScheme;

                final chips = <Widget>[
                  // Chip "Todos"
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: Builder(
                      builder: (context) {
                        final sel = _anioSeleccionado == null;
                        return ChoiceChip(
                          label: Text(
                            'Todos',
                            style: textTheme.labelLarge?.copyWith(
                              color: sel
                                  ? colorScheme.onPrimaryContainer
                                  : colorScheme.onSurface,
                            ),
                          ),
                          selected: sel,
                          onSelected: (_) =>
                              setState(() => _anioSeleccionado = null),
                          showCheckmark: false,
                          side: BorderSide(
                            color: colorScheme.outlineVariant.withOpacity(0.45),
                            width: 1,
                          ),
                          shape: const StadiumBorder(),
                          labelPadding: labelPad,
                          padding: EdgeInsets.zero,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          backgroundColor: colorScheme.surface,
                          selectedColor: colorScheme.primaryContainer,
                        );
                      },
                    ),
                  ),

                  // Chips por año
                  for (final y in anios)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Builder(
                        builder: (context) {
                          final sel = _anioSeleccionado == y;
                          return ChoiceChip(
                            label: Text(
                              y.toString(),
                              style: textTheme.labelLarge?.copyWith(
                                color: sel
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurface,
                              ),
                            ),
                            selected: sel,
                            onSelected: (_) =>
                                setState(() => _anioSeleccionado = y),
                            showCheckmark: false,
                            side: BorderSide(
                              color: colorScheme.outlineVariant.withOpacity(
                                0.45,
                              ),
                              width: 1,
                            ),
                            shape: const StadiumBorder(),
                            labelPadding: labelPad,
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            backgroundColor: colorScheme.surface,
                            selectedColor: colorScheme.primaryContainer,
                          );
                        },
                      ),
                    ),
                ];

                // Centra cuando hay espacio; si no, permite scroll horizontal
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minWidth: constraints.maxWidth),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: chips,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 4),

          // Línea 2: Solo activos + total + acción masiva
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  const Text('Solo activos'),
                  Switch.adaptive(
                    value: _soloActivos,
                    onChanged: (v) => setState(() => _soloActivos = v),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              Chip(
                label: Text('Total: $totalActual'),
                backgroundColor: colorScheme.surface,
              ),
              const SizedBox(width: 8),
              _buildAccionMasiva(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildListaTab(BuildContext context, List<ModeloDb> modelos) {
    final cs = Theme.of(context).colorScheme;

    if (modelos.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 80),
          Center(child: Text('No hay modelos para este filtro')),
        ],
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      itemCount: modelos.length,
      itemBuilder: (context, index) {
        final m = modelos[index];
        return Card(
          color: cs.surface,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          child: ModeloItemTile(
            key: ValueKey(m.uid),
            modelo: m,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ModeloDetallePage(modeloUid: m.uid),
                ),
              );
            },

            onActualizado: () async {
              await _cargarModelos();
            },
          ),
        );
      },
    );
  }

  Widget _buildAccionMasiva() {
    // Determinar contra la pestaña activa: tomamos el DefaultTabController
    final controller = DefaultTabController.maybeOf(context);
    final tipos = ref.read(modelosProvider.notifier).tiposUnicos;
    final idx = (controller?.index ?? 0).clamp(0, tipos.length - 1);
    final tipoActivo = tipos[idx];

    final visibles = ref
        .read(modelosProvider.notifier)
        .filtrar(
          tipo: tipoActivo == 'Todos' ? null : tipoActivo,
          incluirInactivos: !_soloActivos,
          anio: _anioSeleccionado,
        );

    final todosLocales =
        visibles.isNotEmpty &&
        visibles.every((m) {
          return m.fichaRutaLocal.isNotEmpty &&
              File(m.fichaRutaLocal).existsSync();
        });

    if (_trabajandoMasivo) {
      return const SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    return IconButton(
      icon: Icon(
        todosLocales ? Icons.delete_outline : Icons.download_for_offline,
      ),
      tooltip: todosLocales
          ? 'Eliminar todas las fichas locales visibles'
          : 'Descargar todas las fichas visibles',
      onPressed: visibles.isEmpty
          ? null
          : () async {
              setState(() => _trabajandoMasivo = true);
              int ok = 0;
              if (todosLocales) {
                // Borrar locales
                for (final m in visibles) {
                  await ref
                      .read(modelosProvider.notifier)
                      .eliminarFichaLocal(m);
                  ok++;
                }
              } else {
                // Descargar visibles
                for (final m in visibles) {
                  final actualizado = await ref
                      .read(modelosProvider.notifier)
                      .descargarFicha(m);
                  if (updatedHasLocal(actualizado)) ok++;
                }
              }
              setState(() => _trabajandoMasivo = false);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    todosLocales
                        ? '🗑️ $ok ficha(s) eliminada(s)'
                        : '📥 $ok ficha(s) descargada(s)',
                  ),
                ),
              );
            },
    );
  }

  bool updatedHasLocal(ModeloDb? m) {
    if (m == null) return false;
    return m.fichaRutaLocal.isNotEmpty && File(m.fichaRutaLocal).existsSync();
  }

  // ============================ Acciones ======================================

  Future<void> _cargarModelos() async {
    if (!mounted) return;

    setState(() => _cargandoInicial = true);
    final inicio = DateTime.now();

    // 👇 Captura TODO antes de await (no vuelvas a tocar ref luego)
    final hayInternet = ref.read(connectivityProvider);
    final modelosN = ref.read(modelosProvider.notifier);
    final imgsN = ref.read(modeloImagenesProvider.notifier);

    try {
      await modelosN.cargarOfflineFirst();
      if (!mounted) return; // 👈 por si cambiaste de pestaña durante el await

      await imgsN.cargarOfflineFirst();
      if (!mounted) return;
    } finally {
      // spinner mínimo por UX consistente con tus pantallas
      const minSpin = Duration(milliseconds: 1500);
      final elapsed = DateTime.now().difference(inicio);
      if (elapsed < minSpin) {
        await Future.delayed(minSpin - elapsed);
      }

      if (!mounted) return;

      setState(() => _cargandoInicial = false);

      if (!hayInternet) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '📴 Estás sin conexión. Solo fichas descargadas disponibles.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }
}

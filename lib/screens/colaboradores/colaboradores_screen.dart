import 'dart:async';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_provider.dart';
import 'package:myafmzd/screens/colaboradores/colaboradores_form_page.dart';
import 'package:myafmzd/screens/colaboradores/colaboradores_tile.dart';
import 'package:myafmzd/widgets/my_expandable_fab_options.dart';

class ColaboradoresScreen extends ConsumerStatefulWidget {
  const ColaboradoresScreen({super.key});

  @override
  ConsumerState<ColaboradoresScreen> createState() =>
      _ColaboradoresScreenState();
}

class _ColaboradoresScreenState extends ConsumerState<ColaboradoresScreen> {
  bool _cargandoInicial = true;

  // === 🔎 Estado de búsqueda ===
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Igual que en las demás: correr carga tras el primer frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarColaboradores();
    });

    // Listener con debounce para la búsqueda
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

    // Reacciona a cambios de conectividad (mismo patrón)
    ref.listen<bool>(connectivityProvider, (prev, next) async {
      if (!mounted || prev == next) return;
      await _cargarColaboradores();
    });

    final colaboradores = ref.watch(colaboradoresProvider);

    // 🔎 Lista filtrada por la búsqueda
    final filtrados = _aplicarFiltro(colaboradores, _query);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Colaboradores",
          style: tt.titleLarge?.copyWith(color: cs.onSurface),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      floatingActionButton: FabConMenuAnchor(
        onAgregar: _abrirFormNuevoColaborador,
        onImportar: _importarColaboradores,
        onExportar: _exportarColaboradores,
        // Personaliza textos/íconos si quieres:
        txtAgregar: 'Agregar colaborador',
        txtImportar: 'Importar desde CSV',
        txtExportar: 'Exportar a CSV',
        iconMain: Icons.apps, // o Icons.menu
        iconAgregar: Icons.person_add_alt_1,
        iconImportar: Icons.upload,
        iconExportar: Icons.download,
        fabTooltip: 'Acciones de colaboradores',
      ),

      body: Column(
        children: [
          // === 🔎 Barra de búsqueda ===
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchCtrl,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                labelText: 'Buscar colaborador',
                hintText: 'Nombre, teléfono, correo, CURP o RFC',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: (_query.isNotEmpty)
                    ? IconButton(
                        tooltip: 'Limpiar búsqueda',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onSubmitted: (_) => FocusScope.of(context).unfocus(),
            ),
          ),

          if (!_cargandoInicial)
            _buildResumen(
              context,
              filtrados.length,
              total: colaboradores.length,
            ),

          Expanded(
            child: _cargandoInicial
                ? const SizedBox.shrink() // el overlay ya muestra “Cargando…”
                : RefreshIndicator(
                    color: cs.secondary,
                    onRefresh: _cargarColaboradores,
                    child: filtrados.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 80),
                              Center(
                                child: Text(
                                  _query.isEmpty
                                      ? 'No hay colaboradores'
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
                            itemCount: filtrados.length,
                            itemBuilder: (context, index) {
                              final c = filtrados[index];
                              return Card(
                                color: cs.surface,
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 2,
                                child: ColaboradorItemTile(
                                  key: ValueKey(c.uid),
                                  colaborador: c,
                                  onTap: () {},
                                  onActualizado: () async {
                                    await _cargarColaboradores();
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

  Widget _buildResumen(
    BuildContext context,
    int totalActual, {
    required int total,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Chip(
            label: Text(
              total == totalActual
                  ? 'Total: $totalActual'
                  : 'Coincidencias: $totalActual / $total',
            ),
            backgroundColor: colorScheme.surface,
          ),
        ],
      ),
    );
  }

  Future<void> _cargarColaboradores() async {
    if (!mounted) return;

    setState(() => _cargandoInicial = true);

    // UX opcional, igual que en otras screens
    FocusScope.of(context).unfocus();

    // OVERLAY (mismo patrón)
    context.loaderOverlay.show(progress: 'Cargando colaboradores…');

    final inicio = DateTime.now();

    try {
      final hayInternet = ref.read(connectivityProvider);

      await ref.read(colaboradoresProvider.notifier).cargarOfflineFirst();

      // delay mínimo para consistencia
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

  Future<void> _abrirFormNuevoColaborador() async {
    // Navega al formulario de creación.
    final resultado = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => const ColaboradorFormPage(), // modo "crear"
      ),
    );

    // Si la página regresa true (guardado) o simplemente para asegurar, recarga.
    if (mounted && (resultado == true || resultado == null)) {
      await _cargarColaboradores();
    }
  }

  // IMPORTAR (solo inserta; muestra duplicados saltados)
  Future<void> _importarColaboradores() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      withData: true,
    );
    if (res == null || res.files.single.bytes == null) return;

    context.loaderOverlay.show(progress: 'Importando colaboradores…');
    try {
      final (ins, skip) = await ref
          .read(colaboradoresProvider.notifier)
          .importarCsvColaboradores(csvBytes: res.files.single.bytes!);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Importados: $ins • Saltados (duplicados): $skip'),
        ),
      );
      await _cargarColaboradores();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al importar CSV: $e')));
      }
    } finally {
      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
    }
  }

  // EXPORTAR (ejemplo: guardar a archivo o compartir)
  Future<void> _exportarColaboradores() async {
    context.loaderOverlay.show(progress: 'Generando CSV…');
    try {
      final path = await ref
          .read(colaboradoresProvider.notifier)
          .exportarCsvAArchivo();

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('CSV guardado en:\n$path')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al exportar: $e')));
      }
    } finally {
      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
    }
  }

  // ===============================
  // 🔎 LÓGICA DE BÚSQUEDA / MATCHING
  // ===============================

  List _aplicarFiltro(List lista, String query) {
    if (query.trim().isEmpty) return lista;

    final q = _normalize(query);
    final tokens = q.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();

    return lista.where((c) {
      // Campos del colaborador según tu tabla Drift (ColaboradorDb):
      // nombres, apellidoPaterno, apellidoMaterno, telefonoMovil,
      // emailPersonal, curp, rfc
      final nombres = _safeStr(
        '${c.nombres ?? ''} ${c.apellidoPaterno ?? ''} ${c.apellidoMaterno ?? ''}',
      );
      final telefono = _safeStr(c.telefonoMovil ?? '');
      final correo = _safeStr(c.emailPersonal ?? '');
      final curp = _safeStr(c.curp ?? '');
      final rfc = _safeStr(c.rfc ?? '');

      final indexText = _normalize('$nombres $correo $curp $rfc');
      final phoneDigits = _digitsOnly(telefono);

      // AND de todos los tokens: cada token debe hacer match en texto o en teléfono
      final ok = tokens.every((t) {
        final isDigits = RegExp(r'^\d+$').hasMatch(t);
        if (isDigits) {
          // Para números, comparamos solo contra teléfono (solo dígitos)
          return phoneDigits.contains(t);
        }
        // Para texto, comparamos contra el índice normalizado (sin acentos)
        return indexText.contains(t);
      });

      return ok;
    }).toList();
  }

  String _safeStr(Object? v) => (v ?? '').toString();

  String _digitsOnly(String s) => s.replaceAll(RegExp(r'\D+'), '');

  /// Normaliza: minúsculas, sin acentos/diéresis/ñ, y simplifica espacios.
  String _normalize(String input) {
    var t = input.toLowerCase();

    // Reemplazos de acentos más comunes en ES (incluye diéresis y ç)
    t = t.replaceAll(RegExp(r'[áàäâã]'), 'a');
    t = t.replaceAll(RegExp(r'[éèëê]'), 'e');
    t = t.replaceAll(RegExp(r'[íìïî]'), 'i');
    t = t.replaceAll(RegExp(r'[óòöôõ]'), 'o');
    t = t.replaceAll(RegExp(r'[úùüû]'), 'u');
    t = t.replaceAll(RegExp(r'[ñ]'), 'n');
    t = t.replaceAll(RegExp(r'[ç]'), 'c');

    // Sustituye cualquier char que no sea alfanumérico o espacio por espacio
    t = t.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');

    // Colapsa espacios
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t;
  }
}

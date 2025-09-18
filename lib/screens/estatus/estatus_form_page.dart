// lib/database/estatus/ui/estatus_form_page.dart
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/estatus/estatus_provider.dart';
import 'package:myafmzd/widgets/my_elevated_button.dart';
import 'package:myafmzd/widgets/my_text_form_field.dart';

class EstatusFormPage extends ConsumerStatefulWidget {
  final EstatusDb? estatusEditar;
  const EstatusFormPage({super.key, this.estatusEditar});

  @override
  ConsumerState<EstatusFormPage> createState() => _EstatusFormPageState();
}

class _EstatusFormPageState extends ConsumerState<EstatusFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final bool _esEdicion;

  // Controllers
  late TextEditingController _nombreCtrl;
  late TextEditingController _categoriaCtrl;
  late TextEditingController _ordenCtrl;
  late TextEditingController _colorHexCtrl;
  late TextEditingController _iconoCtrl;
  late TextEditingController _notasCtrl;

  // Flags
  bool _visible = true;
  bool _esFinal = false;
  bool _esCancelatorio = false;

  // Categorías sugeridas
  List<String> get _categoriasSugeridas {
    // Deriva de datos existentes; si no hay, usa defaults.
    final existentes =
        ref
            .watch(estatusProvider)
            .where((e) => !e.deleted && e.categoria.trim().isNotEmpty)
            .map((e) => e.categoria.trim())
            .toSet()
            .toList()
          ..sort();

    if (existentes.isNotEmpty) return existentes;

    // Defaults propuestos (ajústalos a tus flujos)
    return const [
      'ciclo', // pipeline principal: Prospecto → Integrante → Adjudicado → …
      'preventa', // revisado, sin docs, falta comprobante
      'postventa', // liquidado, rescindido, cancelado
      'documentos', // checklist / observaciones
    ];
  }

  @override
  void initState() {
    super.initState();
    final e = widget.estatusEditar;
    _esEdicion = e != null;

    _nombreCtrl = TextEditingController(text: e?.nombre ?? '');
    _categoriaCtrl = TextEditingController(text: e?.categoria ?? 'ciclo');
    _ordenCtrl = TextEditingController(text: (e?.orden ?? 0).toString());
    _colorHexCtrl = TextEditingController(text: e?.colorHex ?? '');
    _iconoCtrl = TextEditingController(text: e?.icono ?? '');
    _notasCtrl = TextEditingController(text: e?.notas ?? '');

    _visible = e?.visible ?? true;
    _esFinal = e?.esFinal ?? false;
    _esCancelatorio = e?.esCancelatorio ?? false;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _categoriaCtrl.dispose();
    _ordenCtrl.dispose();
    _colorHexCtrl.dispose();
    _iconoCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final categorias = _categoriasSugeridas;

    // Selección inicial de categoría si match
    final catInicial = _categoriaCtrl.text.trim().isEmpty
        ? (categorias.isNotEmpty ? categorias.first : 'ciclo')
        : _categoriaCtrl.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar Estatus' : 'Nuevo Estatus'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                children: [
                  // ---------------- Nombre ----------------
                  MyTextFormField(
                    controller: _nombreCtrl,
                    labelText: 'Nombre del estatus *',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
                  ),
                  const SizedBox(height: 12),

                  // ---------------- Categoría (chips + editable) ----------------
                  Text(
                    'Categoría',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final c in categorias)
                        ChoiceChip(
                          label: Text(c),
                          selected:
                              (_categoriaCtrl.text.trim().isEmpty &&
                                  c == catInicial) ||
                              _categoriaCtrl.text.trim() == c,
                          onSelected: (_) => setState(() {
                            _categoriaCtrl.text = c;
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  MyTextFormField(
                    controller: _categoriaCtrl,
                    labelText: 'o escribe una categoría',
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Obligatorio' : null,
                  ),
                  const SizedBox(height: 12),

                  // ---------------- Orden ----------------
                  MyTextFormField(
                    controller: _ordenCtrl,
                    labelText: 'Orden (entero, para ordenar en UI)',
                    keyboardType: const TextInputType.numberWithOptions(
                      signed: true,
                      decimal: false,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty)
                        return null; // opcional
                      final i = int.tryParse(v.trim());
                      return (i == null) ? 'Debe ser entero' : null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // ---------------- Flags ----------------
                  SwitchListTile.adaptive(
                    value: _visible,
                    onChanged: (v) => setState(() => _visible = v),
                    title: const Text('Visible'),
                  ),
                  SwitchListTile.adaptive(
                    value: _esFinal,
                    onChanged: (v) => setState(() => _esFinal = v),
                    title: const Text('Estatus final (terminal)'),
                  ),
                  SwitchListTile.adaptive(
                    value: _esCancelatorio,
                    onChanged: (v) => setState(() => _esCancelatorio = v),
                    title: const Text('Estatus cancelatorio'),
                  ),
                  const SizedBox(height: 12),

                  // ---------------- Color / Icono / Notas ----------------
                  MyTextFormField(
                    controller: _colorHexCtrl,
                    labelText: 'Color HEX (opcional, p.ej. #FF0044)',
                    validator: (v) {
                      final s = v?.trim() ?? '';
                      if (s.isEmpty) return null;
                      return _validHexColor(s) ? null : 'HEX inválido';
                    },
                  ),
                  const SizedBox(height: 12),
                  MyTextFormField(
                    controller: _iconoCtrl,
                    labelText: 'Icono (opcional, nombre de icono/llave)',
                  ),
                  const SizedBox(height: 12),
                  MyTextFormField(
                    controller: _notasCtrl,
                    labelText: 'Notas (opcional)',
                  ),
                  const SizedBox(height: 24),

                  // ---------------- Guardar ----------------
                  MyElevatedButton(
                    icon: Icons.save,
                    label: 'Guardar',
                    onPressed: _guardar,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================ Acciones =============================

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;

    FocusScope.of(context).unfocus();

    // Overlay + timing UX
    final titulo = _esEdicion ? 'Editando estatus…' : 'Guardando estatus…';
    context.loaderOverlay.show(progress: titulo);
    final inicio = DateTime.now();

    // Lectura
    final nombre = _nombreCtrl.text.trim();
    final categoria = _categoriaCtrl.text.trim().isEmpty
        ? 'ciclo'
        : _categoriaCtrl.text.trim();
    final orden = int.tryParse(_ordenCtrl.text.trim()) ?? 0;
    final colorHex = _colorHexCtrl.text.trim();
    final icono = _iconoCtrl.text.trim();
    final notas = _notasCtrl.text.trim();

    final notifier = ref.read(estatusProvider.notifier);

    try {
      if (context.loaderOverlay.visible) {
        context.loaderOverlay.progress('Validando duplicados…');
      }

      final duplicado = notifier.existeDuplicado(
        uidActual: widget.estatusEditar?.uid ?? '',
        nombre: nombre,
        categoria: categoria,
      );
      if (duplicado) {
        if (context.loaderOverlay.visible) context.loaderOverlay.hide();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '❌ Ya existe un estatus con ese nombre en la categoría seleccionada',
            ),
          ),
        );
        return;
      }

      if (context.loaderOverlay.visible) {
        context.loaderOverlay.progress(
          _esEdicion ? 'Aplicando cambios…' : 'Creando estatus…',
        );
      }

      if (_esEdicion) {
        await notifier.editarEstatus(
          uid: widget.estatusEditar!.uid,
          nombre: nombre,
          categoria: categoria,
          orden: orden,
          esFinal: _esFinal,
          esCancelatorio: _esCancelatorio,
          visible: _visible,
          colorHex: colorHex.isEmpty ? null : colorHex,
          icono: icono.isEmpty ? null : icono,
          notas: notas.isEmpty ? null : notas,
        );
      } else {
        await notifier.crearEstatus(
          nombre: nombre,
          categoria: categoria,
          orden: orden,
          esFinal: _esFinal,
          esCancelatorio: _esCancelatorio,
          visible: _visible,
          colorHex: colorHex,
          icono: icono,
          notas: notas,
        );
      }

      // delay mínimo para consistencia visual
      const minSpin = Duration(milliseconds: 1200);
      final elapsed = DateTime.now().difference(inicio);
      if (elapsed < minSpin) {
        await Future.delayed(minSpin - elapsed);
      }

      if (context.loaderOverlay.visible) context.loaderOverlay.hide();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (context.loaderOverlay.visible) context.loaderOverlay.hide();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error al guardar: $e')));
    } finally {
      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
    }
  }

  // ============================ Helpers ==============================

  bool _validHexColor(String s) {
    final ss = s.startsWith('#') ? s.substring(1) : s;
    final re = RegExp(r'^[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$'); // #RRGGBB(AA)
    return re.hasMatch(ss);
  }
}

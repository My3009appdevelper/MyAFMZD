// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/grupo_distribuidores/grupos_distribuidores_provider.dart';
import 'package:myafmzd/widgets/my_elevated_button.dart';
import 'package:myafmzd/widgets/my_text_form_field.dart';

class GrupoDistribuidorFormPage extends ConsumerStatefulWidget {
  final GrupoDistribuidorDb? grupoEditar;
  const GrupoDistribuidorFormPage({super.key, this.grupoEditar});

  @override
  ConsumerState<GrupoDistribuidorFormPage> createState() =>
      _GrupoDistribuidorFormPageState();
}

class _GrupoDistribuidorFormPageState
    extends ConsumerState<GrupoDistribuidorFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombreCtrl;
  late TextEditingController _abreviaturaCtrl;
  late TextEditingController _notasCtrl;

  bool _activo = true;
  bool _esEdicion = false;

  @override
  void initState() {
    super.initState();
    final g = widget.grupoEditar;
    _esEdicion = g != null;

    _nombreCtrl = TextEditingController(text: g?.nombre ?? '');
    _abreviaturaCtrl = TextEditingController(text: g?.abreviatura ?? '');
    _notasCtrl = TextEditingController(text: g?.notas ?? '');
    _activo = g?.activo ?? true;
  }

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _abreviaturaCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _esEdicion ? 'Editar Grupo de Distribuidoras' : 'Nuevo Grupo',
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                children: [
                  // Nombre
                  MyTextFormField(
                    controller: _nombreCtrl,
                    labelText: 'Nombre',
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Campo obligatorio'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // Abreviatura
                  MyTextFormField(
                    controller: _abreviaturaCtrl,
                    labelText: 'Abreviatura (opcional)',
                  ),
                  const SizedBox(height: 12),

                  // Notas
                  MyTextFormField(
                    controller: _notasCtrl,
                    labelText: 'Notas (opcional)',
                  ),
                  const SizedBox(height: 12),

                  // Activo
                  SwitchListTile.adaptive(
                    value: _activo,
                    onChanged: (v) => setState(() => _activo = v),
                    title: const Text('Activo'),
                  ),

                  const SizedBox(height: 24),

                  // Guardar
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

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;

    // Cerrar teclado
    FocusScope.of(context).unfocus();

    // Overlay base + timer para delay mínimo (consistencia visual)
    context.loaderOverlay.show(
      progress: _esEdicion ? 'Editando grupo…' : 'Guardando grupo…',
    );
    final inicio = DateTime.now();

    // Valores
    final nombre = _nombreCtrl.text.trim();
    final abreviatura = _abreviaturaCtrl.text.trim();
    final notas = _notasCtrl.text.trim();

    final gruposNotifier = ref.read(gruposDistribuidoresProvider.notifier);

    try {
      // Paso intermedio
      if (context.loaderOverlay.visible) {
        context.loaderOverlay.progress('Validando duplicados…');
      }

      // Duplicados (nombre/abreviatura)
      final hayDuplicado = gruposNotifier.existeDuplicado(
        uidActual: widget.grupoEditar?.uid ?? '',
        nombre: nombre,
        abreviatura: abreviatura,
      );
      if (hayDuplicado) {
        if (context.loaderOverlay.visible) context.loaderOverlay.hide();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Ya existe un grupo con ese nombre o abreviatura'),
          ),
        );
        return;
      }

      // Persistencia
      if (context.loaderOverlay.visible) {
        context.loaderOverlay.progress(
          _esEdicion ? 'Aplicando cambios…' : 'Creando grupo…',
        );
      }

      if (_esEdicion) {
        await gruposNotifier.editarGrupo(
          uid: widget.grupoEditar!.uid,
          nombre: nombre,
          abreviatura: abreviatura.isEmpty ? null : abreviatura,
          notas: notas.isEmpty ? null : notas,
          activo: _activo,
        );
      } else {
        await gruposNotifier.crearGrupo(
          nombre: nombre,
          abreviatura: abreviatura,
          notas: notas,
          activo: _activo,
        );
      }

      // Delay mínimo UX
      const minSpin = Duration(milliseconds: 1500);
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
}

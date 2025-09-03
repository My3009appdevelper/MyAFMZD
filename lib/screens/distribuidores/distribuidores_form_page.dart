import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/widgets/my_elevated_button.dart';
import 'package:myafmzd/widgets/my_picker_search_field.dart';
import 'package:myafmzd/widgets/my_text_form_field.dart';

class DistribuidorFormPage extends ConsumerStatefulWidget {
  final DistribuidorDb? distribuidorEditar;
  const DistribuidorFormPage({super.key, this.distribuidorEditar});

  @override
  ConsumerState<DistribuidorFormPage> createState() =>
      _DistribuidorFormPageState();
}

class _DistribuidorFormPageState extends ConsumerState<DistribuidorFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _grupoController;
  late TextEditingController _direccionController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  bool _activo = true;
  bool _esEdicion = false;

  @override
  void initState() {
    super.initState();
    final distribuidor = widget.distribuidorEditar;
    _esEdicion = distribuidor != null;

    _nombreController = TextEditingController(text: distribuidor?.nombre ?? '');
    _grupoController = TextEditingController(
      text: distribuidor?.grupo ?? 'AFMZD',
    );
    _direccionController = TextEditingController(
      text: distribuidor?.direccion ?? '',
    );
    _latController = TextEditingController(
      text: (distribuidor?.latitud)?.toString() ?? '',
    );
    _lngController = TextEditingController(
      text: (distribuidor?.longitud)?.toString() ?? '',
    );
    _activo = distribuidor?.activo ?? true;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _grupoController.dispose();
    _direccionController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grupos = ref.watch(distribuidoresProvider.notifier).gruposUnicos;

    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar Distribuidor' : 'Nuevo Distribuidor'),
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
                    controller: _nombreController,
                    labelText: 'Nombre',
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Campo obligatorio'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // Grupo
                  MyPickerSearchField<String>(
                    items: grupos,
                    initialValue: _grupoController.text.isEmpty
                        ? null
                        : _grupoController.text,
                    itemAsString: (s) => s,
                    compareFn: (a, b) => a.toLowerCase() == b.toLowerCase(),
                    labelText: 'Grupo',
                    hintText: 'Toca para elegir…',
                    bottomSheetTitle: 'Seleccionar grupo',
                    searchHintText: 'Buscar grupo…',
                    onChanged: (value) => _grupoController.text = value ?? '',
                  ),
                  const SizedBox(height: 12),

                  // Dirección
                  MyTextFormField(
                    controller: _direccionController,
                    labelText: 'Dirección',
                  ),
                  const SizedBox(height: 12),

                  // Lat/Lng
                  Row(
                    children: [
                      Expanded(
                        // Lat
                        child: MyTextFormField(
                          controller: _latController,
                          labelText: 'Latitud',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),

                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Campo obligatorio';
                            }
                            final n = double.tryParse(v.trim());
                            if (n == null) return 'Número inválido';
                            // (Opcional) validar rango de latitudes
                            if (n < -90 || n > 90) {
                              return 'Rango válido: -90 a 90';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        // Lng
                        child: MyTextFormField(
                          controller: _lngController,
                          labelText: 'Longitud',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                            signed: true,
                          ),

                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Campo obligatorio';
                            }
                            final n = double.tryParse(v.trim());
                            if (n == null) return 'Número inválido';
                            // (Opcional) validar rango de longitudes
                            if (n < -180 || n > 180) {
                              return 'Rango válido: -180 a 180';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
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
                    onPressed: () => _guardar(),
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

    final nombre = _nombreController.text.trim();
    final grupo = _grupoController.text.trim();
    final direccion = _direccionController.text.trim();

    double toDouble(String s) => double.tryParse(s.trim()) ?? 0.0;
    final lat = toDouble(_latController.text);
    final lng = toDouble(_lngController.text);

    final distribuidoresNotifier = ref.read(distribuidoresProvider.notifier);

    // Validación de duplicados
    final duplicado = distribuidoresNotifier.existeDuplicado(
      uidActual: widget.distribuidorEditar?.uid ?? '',
      nombre: nombre,
      direccion: direccion.isEmpty ? null : direccion,
    );
    if (duplicado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '❌ Ya existe un distribuidor con ese nombre o dirección',
          ),
        ),
      );
      return;
    }

    try {
      if (_esEdicion) {
        await distribuidoresNotifier.editarDistribuidor(
          uid: widget.distribuidorEditar!.uid,
          nombre: nombre,
          grupo: grupo.isEmpty ? null : grupo,
          direccion: direccion.isEmpty ? null : direccion,
          activo: _activo,
          latitud: lat,
          longitud: lng,
        );
        if (mounted) Navigator.pop(context, true);
      } else {
        await distribuidoresNotifier.crearDistribuidor(
          nombre: nombre,
          grupo: grupo.isEmpty ? 'AFMZD' : grupo,
          direccion: direccion,
          activo: _activo,
          latitud: lat,
          longitud: lng,
        );
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error al guardar: $e')));
    }
  }
}

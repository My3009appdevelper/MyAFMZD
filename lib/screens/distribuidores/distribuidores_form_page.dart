import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/database/grupo_distribuidores/grupos_distribuidores_provider.dart'; // 👈 NUEVO
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
  late TextEditingController _uuidGrupoController; // almacena el UID del grupo
  late TextEditingController _direccionController;
  late TextEditingController _latController;
  late TextEditingController _lngController;
  late TextEditingController _concentradoraUidController;
  bool _activo = true;
  bool _esEdicion = false;

  @override
  void initState() {
    super.initState();
    final distribuidor = widget.distribuidorEditar;
    _esEdicion = distribuidor != null;

    _nombreController = TextEditingController(text: distribuidor?.nombre ?? '');
    _uuidGrupoController = TextEditingController(
      text: distribuidor?.uuidGrupo ?? '',
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

    _concentradoraUidController = TextEditingController(
      text: _esEdicion
          ? ((distribuidor!.concentradoraUid.isNotEmpty)
                ? distribuidor.concentradoraUid
                : distribuidor.uid)
          : '',
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _uuidGrupoController.dispose();
    _direccionController.dispose();
    _latController.dispose();
    _lngController.dispose();
    _concentradoraUidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Trae los grupos desde su provider y ordénalos por nombre
    final grupos =
        ref
            .watch(gruposDistribuidoresProvider)
            .where((g) => !g.deleted)
            .toList()
          ..sort((a, b) => a.nombre.compareTo(b.nombre));

    // Resuelve el valor inicial (objeto) a partir del uid guardado en el controller
    final initialGrupo = grupos.firstWhere(
      (g) => g.uid == _uuidGrupoController.text,
      orElse: () => grupos.firstWhere((g) => g.nombre == 'AFMZD'),
    );

    // Distribuidoras disponibles (muestra nombres). Filtra eliminadas.
    final distribuidoras =
        ref.watch(distribuidoresProvider).where((d) => !d.deleted).toList()
          ..sort((a, b) => a.nombre.compareTo(b.nombre));

    // Valor inicial: busca por uid en el controller (si existe)
    final initialConcentradora = _concentradoraUidController.text.isEmpty
        ? null
        : distribuidoras.firstWhere(
            (d) => d.uid == _concentradoraUidController.text,
            orElse: () => _esEdicion
                ? distribuidoras.firstWhere(
                    (d) => d.uid == (widget.distribuidorEditar?.uid ?? ''),
                    orElse: () => distribuidoras.first,
                  )
                : distribuidoras.first,
          );

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

                  // Grupo: muestra NOMBRE, guarda UID
                  MyPickerSearchField<GrupoDistribuidorDb>(
                    items: grupos,
                    initialValue: _uuidGrupoController.text.isEmpty
                        ? null
                        : initialGrupo,
                    itemAsString: (g) => g.nombre, // 👈 muestra el nombre
                    compareFn: (a, b) => a.uid == b.uid, // 👈 compara por uid
                    labelText: 'Grupo',
                    hintText: 'Toca para elegir…',
                    bottomSheetTitle: 'Seleccionar grupo',
                    searchHintText: 'Buscar grupo…',
                    onChanged: (g) => _uuidGrupoController.text = g?.uid ?? '',
                  ),
                  const SizedBox(height: 12),

                  // Distribuidora CONCENTRADORA: muestra NOMBRE, guarda UID
                  MyPickerSearchField<DistribuidorDb>(
                    items: distribuidoras,
                    initialValue: initialConcentradora,
                    itemAsString: (d) => d.nombre, // 👈 muestra nombre
                    compareFn: (a, b) => a.uid == b.uid, // 👈 compara por uid
                    labelText: 'Distribuidora concentradora',
                    hintText: 'Toca para elegir…',
                    bottomSheetTitle: 'Seleccionar distribuidora concentradora',
                    searchHintText: 'Buscar distribuidora…',
                    onChanged: (d) =>
                        _concentradoraUidController.text = d?.uid ?? '',
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
                            if (n < -90 || n > 90) {
                              return 'Rango válido: -90 a 90';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
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
    if (!mounted) return;

    FocusScope.of(context).unfocus();

    context.loaderOverlay.show(
      progress: _esEdicion
          ? 'Editando distribuidor…'
          : 'Guardando distribuidor…',
    );
    final inicio = DateTime.now();

    // Lectura de valores
    final nombre = _nombreController.text.trim();
    final uuidGrupo = _uuidGrupoController.text.trim(); // uid del grupo
    final direccion = _direccionController.text.trim();
    double toDouble(String s) => double.tryParse(s.trim()) ?? 0.0;
    final lat = toDouble(_latController.text);
    final lng = toDouble(_lngController.text);
    final concentradoraUid = _concentradoraUidController.text.trim();

    final distribuidoresNotifier = ref.read(distribuidoresProvider.notifier);

    try {
      if (context.loaderOverlay.visible) {
        context.loaderOverlay.progress('Validando datos…');
      }

      final duplicado = distribuidoresNotifier.existeDuplicado(
        uidActual: widget.distribuidorEditar?.uid ?? '',
        nombre: nombre,
        direccion: direccion.isEmpty ? null : direccion,
      );
      if (duplicado) {
        if (context.loaderOverlay.visible) context.loaderOverlay.hide();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              '❌ Ya existe un distribuidor con ese nombre o dirección',
            ),
          ),
        );
        return;
      }

      if (context.loaderOverlay.visible) {
        context.loaderOverlay.progress(
          _esEdicion ? 'Aplicando cambios…' : 'Creando distribuidor…',
        );
      }

      if (_esEdicion) {
        await distribuidoresNotifier.editarDistribuidor(
          uid: widget.distribuidorEditar!.uid,
          nombre: nombre,
          uuidGrupo: uuidGrupo.isEmpty ? null : uuidGrupo,
          direccion: direccion.isEmpty ? null : direccion,
          activo: _activo,
          latitud: lat,
          longitud: lng,
          concentradoraUid: concentradoraUid.isEmpty ? null : concentradoraUid,
        );
      } else {
        await distribuidoresNotifier.crearDistribuidor(
          nombre: nombre,
          uuidGrupo: uuidGrupo, // puede ir vacío si no selecciona
          direccion: direccion,
          activo: _activo,
          latitud: lat,
          longitud: lng,
          concentradoraUid: concentradoraUid.isEmpty ? null : concentradoraUid,
        );
      }

      const minSpin = Duration(milliseconds: 1500);
      final elapsed = DateTime.now().difference(inicio);
      if (elapsed < minSpin) {
        await Future.delayed(minSpin - elapsed);
      }

      if (context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
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

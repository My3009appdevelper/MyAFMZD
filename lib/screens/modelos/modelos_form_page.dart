import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/modelos/modelos_provider.dart';
import 'package:myafmzd/widgets/chip_picker.dart';
import 'package:myafmzd/widgets/my_elevated_button.dart';
import 'package:myafmzd/widgets/my_text_form_field.dart';

class ModelosFormPage extends ConsumerStatefulWidget {
  final ModeloDb? modeloEditar;
  const ModelosFormPage({super.key, this.modeloEditar});

  @override
  ConsumerState<ModelosFormPage> createState() => _ModelosFormPageState();
}

class _ModelosFormPageState extends ConsumerState<ModelosFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Text fields (solo los que no deben “homologarse” con catálogo)
  late TextEditingController _claveController;
  late TextEditingController _precioBaseController;
  late TextEditingController _rutaRemotaController;

  // Selecciones normalizadas
  String _marcaSel = 'Mazda';
  String _modeloSel = '';
  int? _anioSel;
  String _tipoSel = '';
  String _transmisionSel = '';
  String _descripcionSel = '';
  bool _activo = true;

  // Para permitir “Agregar…”, mantenemos añadidos locales
  final _addMarcas = <String>{};
  final _addModelos = <String>{};
  final _addTipos = <String>{};
  final _addTransmisiones = <String>{};
  final _addDescripciones = <String>{};
  final _addAnios = <int>{};

  bool _esEdicion = false;
  File? _archivoPDFSeleccionado;

  @override
  void initState() {
    super.initState();
    final m = widget.modeloEditar;
    _esEdicion = m != null;

    _claveController = TextEditingController(text: m?.claveCatalogo ?? '');
    _precioBaseController = TextEditingController(
      text: (m?.precioBase ?? 0).toString(),
    );

    // Selecciones base
    final marcaInicial = (m?.marca ?? '').trim();
    _marcaSel = marcaInicial.isEmpty ? 'Mazda' : marcaInicial;
    _modeloSel = (m?.modelo ?? 'Mazda 2').trim();
    _anioSel = m?.anio ?? DateTime.now().year;
    _tipoSel = (m?.tipo ?? '').trim();
    _transmisionSel = (m?.transmision ?? '').trim();
    _descripcionSel = (m?.descripcion ?? '').trim();
    _activo = m?.activo ?? true;

    // Ruta remota (si viene vacía, la calculamos)
    _rutaRemotaController = TextEditingController(
      text: (m?.fichaRutaRemota ?? '').isNotEmpty
          ? m!.fichaRutaRemota
          : _buildRutaRemota(),
    );
  }

  @override
  void dispose() {
    _claveController.dispose();
    _precioBaseController.dispose();
    _rutaRemotaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(modelosProvider.notifier);

    // Listas desde DB + añadidos locales (para permitir “Agregar…”)
    final marcas = _mergeStr(notifier.marcasDisponibles, _addMarcas);
    final modelos = _mergeStr(
      notifier.modelosDisponibles(marca: _marcaSel),
      _addModelos,
    );
    final anios = _mergeInt(notifier.aniosDisponiblesForm, _addAnios);
    final tipos = _mergeStr(notifier.tiposDisponiblesForm, _addTipos);
    final transmisiones = _mergeStr(
      notifier.transmisionesDisponiblesForm,
      _addTransmisiones,
    );
    final descripciones = _mergeStr(
      notifier.descripcionesDisponiblesForm,
      _addDescripciones,
    );

    // Asegurar selección válida
    String _ensureStr(String current, List<String> list, String fallback) {
      if (current.trim().isEmpty)
        return list.isNotEmpty ? list.first : fallback;
      return list.contains(current)
          ? current
          : (list.isNotEmpty ? list.first : fallback);
    }

    int? _ensureInt(int? current, List<int> list, int fallback) {
      if (current == null) return list.isNotEmpty ? list.last : fallback;
      return list.contains(current)
          ? current
          : (list.isNotEmpty ? list.last : fallback);
    }

    _marcaSel = _ensureStr(_marcaSel, marcas, 'Mazda');
    _modeloSel = _ensureStr(_modeloSel, modelos, '');
    _anioSel = _ensureInt(_anioSel, anios, DateTime.now().year);
    _tipoSel = _ensureStr(_tipoSel, tipos, tipos.isNotEmpty ? tipos.first : '');
    _transmisionSel = _ensureStr(
      _transmisionSel,
      transmisiones,
      transmisiones.isNotEmpty ? transmisiones.first : '',
    );
    _descripcionSel = _ensureStr(
      _descripcionSel,
      descripciones,
      descripciones.isNotEmpty ? descripciones.first : '',
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar modelo' : 'Nuevo modelo'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                children: [
                  // Clave catálogo
                  MyTextFormField(
                    controller: _claveController,
                    labelText: 'Clave catálogo',
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Campo obligatorio'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // Marca
                  ChipPickerSingle(
                    label: 'Marca',
                    options: marcas,
                    selected: _marcaSel,
                    onSelected: (val) {
                      setState(() {
                        _marcaSel = val;
                        // al cambiar marca, refrescamos modelos permitidos y selección
                        final nuevosModelos = _mergeStr(
                          notifier.modelosDisponibles(marca: _marcaSel),
                          _addModelos,
                        );
                        _modeloSel = _ensureStr(
                          _modeloSel,
                          nuevosModelos,
                          nuevosModelos.isNotEmpty ? nuevosModelos.first : '',
                        );
                        // ← siempre recalcular (ya no depende de tener PDF elegido)
                        _rutaRemotaController.text = _buildRutaRemota();
                      });
                    },
                    onAddNew: (nuevo) => setState(() => _addMarcas.add(nuevo)),
                  ),
                  const SizedBox(height: 12),

                  // Modelo
                  ChipPickerSingle(
                    label: 'Modelo',
                    options: modelos,
                    selected: _modeloSel,
                    validator: (v) =>
                        v!.trim().isEmpty ? 'Campo obligatorio' : null,
                    onSelected: (val) {
                      setState(() {
                        _modeloSel = val;
                        _rutaRemotaController.text = _buildRutaRemota();
                      });
                    },

                    onAddNew: (nuevo) => setState(() => _addModelos.add(nuevo)),
                  ),
                  const SizedBox(height: 12),

                  // Año (reusa ChipPickerSingle con mapeo int<->String)
                  ChipPickerSingle(
                    label: 'Año',
                    options: anios.map((e) => e.toString()).toList(),
                    selected: (_anioSel ?? DateTime.now().year).toString(),
                    onSelected: (v) {
                      setState(() {
                        _anioSel = int.parse(v); // ← mantiene int
                        _rutaRemotaController.text =
                            _buildRutaRemota(); // ← recalcula ruta
                      });
                    },
                    onAddNew: (nuevo) {
                      final y = int.tryParse(nuevo);
                      if (y == null || y < 1990 || y > 2100) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Ingresa un año válido (1990–2100)'),
                          ),
                        );
                        return;
                      }
                      setState(() {
                        _addAnios.add(y); // ← entra a tu merge + sort
                        _anioSel = y; // ← mantiene int
                        _rutaRemotaController.text =
                            _buildRutaRemota(); // ← recalcula ruta
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  MyTextFormField(
                    controller: _precioBaseController,
                    labelText: 'Precio base',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return null;
                      final n = double.tryParse(v.trim());
                      if (n == null) return 'Número inválido';
                      if (n < 0) return 'No puede ser negativo';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Tipo
                  ChipPickerSingle(
                    label: 'Tipo',
                    options: tipos,
                    selected: _tipoSel,
                    onSelected: (val) => setState(() {
                      _tipoSel = val;
                      _rutaRemotaController.text =
                          _buildRutaRemota(); // 👈 importante
                    }),
                    onAddNew: (nuevo) => setState(() => _addTipos.add(nuevo)),
                  ),
                  const SizedBox(height: 12),

                  // Transmisión
                  ChipPickerSingle(
                    label: 'Transmisión',
                    options: transmisiones,
                    selected: _transmisionSel,
                    onSelected: (val) => setState(() => _transmisionSel = val),
                    onAddNew: (nuevo) =>
                        setState(() => _addTransmisiones.add(nuevo)),
                  ),
                  const SizedBox(height: 12),

                  // Descripción
                  ChipPickerSingle(
                    label: 'Descripción',
                    options: descripciones,
                    selected: _descripcionSel,
                    onSelected: (val) => setState(() => _descripcionSel = val),
                    onAddNew: (nuevo) =>
                        setState(() => _addDescripciones.add(nuevo)),
                  ),
                  const SizedBox(height: 12),

                  // Activo
                  SwitchListTile.adaptive(
                    value: _activo,
                    onChanged: (v) => setState(() => _activo = v),
                    title: const Text('Activo'),
                  ),
                  const SizedBox(height: 12),

                  // Ruta remota (simétrico a Reportes: editable, validada)
                  // Ruta remota (solo lectura; se actualiza con el controller y permite copiar)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _rutaRemotaController,
                      builder: (context, value, _) {
                        final ruta = value.text;
                        return InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Ruta remota de ficha (PDF)',
                            border: OutlineInputBorder(),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: SelectableText(
                                  ruta.isEmpty ? '—' : ruta,
                                  maxLines: 2,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Copiar ruta',
                                icon: const Icon(Icons.copy),
                                onPressed: ruta.isEmpty
                                    ? null
                                    : () async {
                                        await Clipboard.setData(
                                          ClipboardData(text: ruta),
                                        );
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          const SnackBar(
                                            content: Text('Ruta copiada'),
                                          ),
                                        );
                                      },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Seleccionar PDF (como Reportes)
                  MyElevatedButton(
                    icon: Icons.upload_file,
                    label:
                        (_archivoPDFSeleccionado != null &&
                            _archivoPDFSeleccionado!.path.isNotEmpty)
                        ? 'Archivo seleccionado'
                        : 'Subir nueva ficha (PDF)',
                    onPressed: _seleccionarPDF,
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

    double _toDouble(String s) => double.tryParse(s.trim()) ?? 0.0;

    final clave = _claveController.text.trim();
    final marca = _marcaSel.trim().isEmpty ? 'Mazda' : _marcaSel.trim();
    final modelo = _modeloSel.trim();
    final anio = _anioSel ?? DateTime.now().year;
    final tipo = _tipoSel.trim();
    final transmision = _transmisionSel.trim();
    final descripcion = _descripcionSel.trim();
    final precioBase = _toDouble(_precioBaseController.text);
    final rutaRemota = _rutaRemotaController.text.trim();
    // validación defensiva, por si acaso
    if (rutaRemota.isEmpty ||
        !rutaRemota.toLowerCase().endsWith('.pdf') ||
        rutaRemota.contains(' ')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Ruta remota inválida generada')),
      );
      return;
    }

    final modelosNotifier = ref.read(modelosProvider.notifier);

    final duplicado = modelosNotifier.existeDuplicado(
      uidActual: widget.modeloEditar?.uid ?? '',
      claveCatalogo: clave,
      modelo: modelo,
      anio: anio,
    );
    if (duplicado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Ya existe un modelo con esa clave o (modelo + año)'),
        ),
      );
      return;
    }

    try {
      if (_esEdicion) {
        final actualizado = widget.modeloEditar!.copyWith(
          claveCatalogo: clave,
          marca: marca,
          modelo: modelo,
          anio: anio,
          tipo: tipo,
          transmision: transmision,
          descripcion: descripcion,
          activo: _activo,
          precioBase: precioBase,
          fichaRutaRemota: rutaRemota,
          updatedAt: DateTime.now().toUtc(),
          isSynced: false,
        );

        final nuevo = await modelosNotifier.editarModelo(
          actualizado: actualizado,
        );

        if (_archivoPDFSeleccionado != null &&
            await _archivoPDFSeleccionado!.exists()) {
          await modelosNotifier.subirNuevaFicha(
            modelo: nuevo,
            archivo: _archivoPDFSeleccionado!,
            nuevoPath: rutaRemota,
          );
        }
        if (mounted) Navigator.pop(context, true);
      } else {
        final nuevo = await modelosNotifier.crearModelo(
          claveCatalogo: clave,
          marca: marca,
          modelo: modelo,
          anio: anio,
          tipo: tipo,
          transmision: transmision,
          descripcion: descripcion,
          activo: _activo,
          precioBase: precioBase,
          fichaRutaRemota: rutaRemota,
        );

        if (_archivoPDFSeleccionado != null &&
            await _archivoPDFSeleccionado!.exists()) {
          await modelosNotifier.subirNuevaFicha(
            modelo: nuevo,
            archivo: _archivoPDFSeleccionado!,
            nuevoPath: rutaRemota,
          );
        }
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error al guardar: $e')));
    }
  }

  Future<void> _seleccionarPDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result == null || result.files.single.path == null) return;

    _archivoPDFSeleccionado = File(result.files.single.path!);

    setState(() {
      _rutaRemotaController.text = _buildRutaRemota();
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('PDF preparado para subir')));
  }

  // Utilidades pequeñas locales
  String slugify(String texto) {
    return texto
        .toLowerCase()
        .replaceAll(RegExp(r'[áàä]'), 'a')
        .replaceAll(RegExp(r'[éèë]'), 'e')
        .replaceAll(RegExp(r'[íìï]'), 'i')
        .replaceAll(RegExp(r'[óòö]'), 'o')
        .replaceAll(RegExp(r'[úùü]'), 'u')
        .replaceAll(RegExp(r'ñ'), 'n')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  List<String> _mergeStr(List<String> a, Set<String> b) {
    final set = <String>{}
      ..addAll(a.map((e) => e.trim()).where((e) => e.isNotEmpty))
      ..addAll(b.map((e) => e.trim()).where((e) => e.isNotEmpty));
    final out = set.toList()
      ..sort((x, y) => x.toLowerCase().compareTo(y.toLowerCase()));
    return out;
  }

  List<int> _mergeInt(List<int> a, Set<int> b) {
    final set = <int>{}
      ..addAll(a)
      ..addAll(b);
    final out = set.toList()..sort();
    return out;
  }

  String _tipoToSuffix(String tipo) {
    final t = tipo.toLowerCase();
    if (t.contains('hatch')) return '_hb'; // Hatchback
    if (t.contains('sed')) return '_sdn'; // Sedán/Sedan
    return '';
  }

  String _buildRutaRemota() {
    final anio = _anioSel ?? DateTime.now().year;
    final marca = slugify(_marcaSel);
    final modelo = slugify(_modeloSel);
    final sufijo = _tipoToSuffix(_tipoSel);

    final base = (modelo.isEmpty) ? 'ficha' : modelo;
    final file = '$base$sufijo.pdf';

    return 'fichas/$anio/$marca/$file';
  }
}

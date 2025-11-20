import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/modelos/modelos_provider.dart';
import 'package:myafmzd/widgets/my_chip_picker.dart';
import 'package:myafmzd/widgets/my_elevated_button.dart';
import 'package:myafmzd/widgets/my_text_form_field.dart';
import 'package:crypto/crypto.dart' show sha256;
import 'package:path/path.dart' as p;
import 'package:myafmzd/database/modelos/modelo_imagenes_provider.dart';

class ModelosFormPage extends ConsumerStatefulWidget {
  final ModeloDb? modeloEditar;
  const ModelosFormPage({super.key, this.modeloEditar});

  @override
  ConsumerState<ModelosFormPage> createState() => _ModelosFormPageState();
}

class _ModelosFormPageState extends ConsumerState<ModelosFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Imagenes
  final List<File> _imagenesPendientes = [];
  final Set<String> _imagenesPorEliminar = {};
  final Set<String> _imagenesParaRestaurar = {};

  bool _guardando = false;

  // NUEVO: portada pendiente (solo se persiste al Guardar)
  String? _coverSelUid;

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

  bool _abriendoPickerPDF = false;
  bool _abriendoPickerImgs = false;

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
    final _ = ref.watch(modelosProvider);
    final notifier = ref.read(modelosProvider.notifier);

    // Listas desde DB + añadidos locales (para permitir “Agregar…”)
    final marcas = _mergeStr(notifier.marcasDisponibles, _addMarcas);
    final modelosDisp = _mergeStr(
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
    String ensureStr(String current, List<String> list, String fallback) {
      if (current.trim().isEmpty) {
        return list.isNotEmpty ? list.first : fallback;
      }
      return list.contains(current)
          ? current
          : (list.isNotEmpty ? list.first : fallback);
    }

    int? ensureInt(int? current, List<int> list, int fallback) {
      if (current == null) return list.isNotEmpty ? list.last : fallback;
      return list.contains(current)
          ? current
          : (list.isNotEmpty ? list.last : fallback);
    }

    _marcaSel = ensureStr(_marcaSel, marcas, 'Mazda');
    _modeloSel = ensureStr(_modeloSel, modelosDisp, '');
    _anioSel = ensureInt(_anioSel, anios, DateTime.now().year);
    _tipoSel = ensureStr(_tipoSel, tipos, tipos.isNotEmpty ? tipos.first : '');
    _transmisionSel = ensureStr(
      _transmisionSel,
      transmisiones,
      transmisiones.isNotEmpty ? transmisiones.first : '',
    );
    _descripcionSel = ensureStr(
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
                  MyChipPickerSingle(
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
                        _modeloSel = ensureStr(
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
                  MyChipPickerSingle(
                    label: 'Modelo',
                    options: modelosDisp,
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
                  MyChipPickerSingle(
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
                  MyChipPickerSingle(
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
                  MyChipPickerSingle(
                    label: 'Transmisión',
                    options: transmisiones,
                    selected: _transmisionSel,
                    onSelected: (val) => setState(() => _transmisionSel = val),
                    onAddNew: (nuevo) =>
                        setState(() => _addTransmisiones.add(nuevo)),
                  ),
                  const SizedBox(height: 12),

                  // Descripción
                  MyChipPickerSingle(
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

                  const SizedBox(height: 12),

                  // --------------------- IMÁGENES DEL MODELO ---------------------
                  const SizedBox(height: 24),
                  Text(
                    'Imágenes del modelo',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.center,
                    children: [
                      MyElevatedButton(
                        icon: Icons.photo_library_outlined,
                        label: 'Agregar imágenes',
                        onPressed: _pickImagenes,
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Grid: si es edición mostramos las del provider; si es creación mostramos las pendientes
                  Builder(
                    builder: (_) {
                      final _ = ref.watch(
                        modeloImagenesProvider,
                      ); // mantiene el rebuild
                      final imgNotifier = ref.read(
                        modeloImagenesProvider.notifier,
                      );

                      final imgs = widget.modeloEditar == null
                          ? <ModeloImagenDb>[]
                          : imgNotifier.imagenesDeModelo(
                              widget.modeloEditar!.uid,
                              incluirEliminadas:
                                  true, // 👈 importante para ver ambos bloques
                            );

                      final activas = imgs.where((i) => !i.deleted).toList();
                      final eliminadas = imgs.where((i) => i.deleted).toList();

                      // Portada actual (del provider) y portada efectiva (pendiente o actual)
                      ModeloImagenDb? currentCover;
                      for (final i in activas) {
                        if (i.isCover) {
                          currentCover = i;
                          break;
                        }
                      }
                      final effectiveCoverUid =
                          _coverSelUid ?? currentCover?.uid;

                      final sectionTitleStyle = Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(fontWeight: FontWeight.w600);

                      final bloques = <Widget>[];

                      // (Opcional) mostrar thumbnails pendientes
                      if (_imagenesPendientes.isNotEmpty) {
                        bloques.add(
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6, top: 8),
                            child: Text(
                              'Pendientes (${_imagenesPendientes.length})',
                              style: sectionTitleStyle,
                            ),
                          ),
                        );

                        bloques.add(
                          GridView.extent(
                            maxCrossAxisExtent: 180,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 1,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: _imagenesPendientes.map((f) {
                              return AspectRatio(
                                aspectRatio: 1,
                                child: _ThumbPendiente(
                                  file: f,
                                  onRemove: () => setState(
                                    () => _imagenesPendientes.remove(f),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        );
                      }

                      // Bloque: Activas
                      if (activas.isNotEmpty) {
                        bloques.add(
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6, top: 8),
                            child: Text(
                              'Activas (${activas.length})',
                              style: sectionTitleStyle,
                            ),
                          ),
                        );
                        bloques.add(
                          GridView.extent(
                            maxCrossAxisExtent: 180,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 1,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: activas.map((i) {
                              final marcadaEliminar = _imagenesPorEliminar
                                  .contains(i.uid);
                              final isCoverUi = i.uid == effectiveCoverUid;
                              return _ThumbImagen(
                                img: i,
                                estaSoftDeleted: false,
                                marcadaParaEliminar: marcadaEliminar,
                                marcadaParaRestaurar: false,
                                onToggleDelete: () => _toggleEliminar(i),
                                onToggleRestore: () {}, // no aplica en activas
                                isCover: isCoverUi,
                                onSetCover: () => _toggleCover(i),
                              );
                            }).toList(),
                          ),
                        );
                      }

                      // Bloque: Eliminadas (si existen)
                      if (eliminadas.isNotEmpty) {
                        bloques.add(
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6, top: 12),
                            child: Text(
                              'Eliminadas (${eliminadas.length})',
                              style: sectionTitleStyle,
                            ),
                          ),
                        );
                        bloques.add(
                          GridView.extent(
                            maxCrossAxisExtent: 180,
                            mainAxisSpacing: 8,
                            crossAxisSpacing: 8,
                            childAspectRatio: 1,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: eliminadas.map((i) {
                              final marcadaRestaurar = _imagenesParaRestaurar
                                  .contains(i.uid);
                              final isCoverUi = i.uid == effectiveCoverUid;
                              return _ThumbImagen(
                                img: i,
                                estaSoftDeleted: true,
                                marcadaParaEliminar: false,
                                marcadaParaRestaurar: marcadaRestaurar,
                                onToggleDelete:
                                    () {}, // no aplica en eliminadas
                                onToggleRestore: () => _toggleRestaurar(i),
                                isCover: isCoverUi,
                                onSetCover: () {}, // no aplica en eliminadas
                              );
                            }).toList(),
                          ),
                        );
                      }

                      if (bloques.isEmpty) {
                        return const Text('Sin imágenes aún');
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: bloques,
                      );
                    },
                  ),

                  const SizedBox(height: 24),

                  // Guardar
                  MyElevatedButton(
                    icon: Icons.save,
                    label: 'Guardar',
                    onPressed: _guardando ? null : _guardar,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _limpiarFichaLocalSiRutaCambio(String nuevaRutaRemota) async {
    if (!_esEdicion) return;
    final anterior = widget.modeloEditar!;
    final cambioRuta = anterior.fichaRutaRemota != nuevaRutaRemota;

    if (cambioRuta && anterior.fichaRutaLocal.isNotEmpty) {
      // Usa el método del provider para borrar el archivo y limpiar Drift
      await ref.read(modelosProvider.notifier).eliminarFichaLocal(anterior);
    }
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (mounted) setState(() => _guardando = true);

    // 0) Overlay base + primer mensaje
    FocusScope.of(context).unfocus();
    final overlayMsg = _esEdicion
        ? 'Editando modelo…'
        : 'Guardando nuevo modelo…';
    context.loaderOverlay.show(progress: overlayMsg);

    final inicio = DateTime.now();

    // ---------- Validaciones iniciales ----------
    if (context.loaderOverlay.visible) {
      context.loaderOverlay.progress('Validando datos…');
    }

    double toDouble(String s) => double.tryParse(s.trim()) ?? 0.0;

    final clave = _claveController.text.trim();
    final marca = _marcaSel.trim().isEmpty ? 'Mazda' : _marcaSel.trim();
    final modelo = _modeloSel.trim();
    final anio = _anioSel ?? DateTime.now().year;
    final tipo = _tipoSel.trim();
    final transmision = _transmisionSel.trim();
    final descripcion = _descripcionSel.trim();
    final precioBase = toDouble(_precioBaseController.text);
    final rutaRemota = _rutaRemotaController.text.trim();

    // validación defensiva de la ruta PDF
    if (rutaRemota.isEmpty ||
        !rutaRemota.toLowerCase().endsWith('.pdf') ||
        rutaRemota.contains(' ')) {
      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Ruta remota inválida generada')),
      );
      if (mounted) setState(() => _guardando = false);
      return;
    }

    final modelosNotifier = ref.read(modelosProvider.notifier);

    final duplicado = modelosNotifier.existeDuplicado(
      uidActual: widget.modeloEditar?.uid ?? '',
      claveCatalogo: clave,
      anio: anio,
    );
    if (duplicado) {
      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '❌ Duplicado: clave de catálogo o (modelo + año) ya existen',
          ),
        ),
      );
      if (mounted) setState(() => _guardando = false);
      return;
    }

    try {
      if (_esEdicion) {
        // ---------- Persistir cambios base ----------
        if (context.loaderOverlay.visible) {
          context.loaderOverlay.progress('Aplicando cambios…');
        }

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

        // ---------- Subir ficha PDF (si se seleccionó) ----------
        if (_archivoPDFSeleccionado != null &&
            await _archivoPDFSeleccionado!.exists()) {
          if (context.loaderOverlay.visible) {
            context.loaderOverlay.progress('Subiendo ficha PDF…');
          }
          await modelosNotifier.subirNuevaFicha(
            modelo: nuevo,
            archivo: _archivoPDFSeleccionado!,
            nuevoPath: rutaRemota,
          );
        }

        // ---------- Subir imágenes pendientes ----------
        if (_imagenesPendientes.isNotEmpty) {
          if (context.loaderOverlay.visible) {
            context.loaderOverlay.progress('Subiendo imágenes…');
          }
          await _subirImagenesParaModelo(nuevo.uid, _imagenesPendientes);
          setState(() => _imagenesPendientes.clear());
        }

        // ---------- Eliminar/Restaurar/Portada ----------
        if (_imagenesPorEliminar.isNotEmpty ||
            _imagenesParaRestaurar.isNotEmpty ||
            _coverSelUid != null) {
          if (context.loaderOverlay.visible) {
            context.loaderOverlay.progress('Aplicando cambios en imágenes…');
          }
        }

        // 1) aplicar eliminaciones pendientes
        if (_imagenesPorEliminar.isNotEmpty) {
          final imgNotifier = ref.read(modeloImagenesProvider.notifier);
          for (final uid in _imagenesPorEliminar.toList()) {
            final img = imgNotifier.obtenerPorUid(uid);
            if (img != null) {
              await imgNotifier.eliminarImagen(img); // soft delete real
            }
          }
          if (!mounted) return;
          setState(() => _imagenesPorEliminar.clear());
        }

        // 2) aplicar restauraciones pendientes
        if (_imagenesParaRestaurar.isNotEmpty) {
          final imgNotifier = ref.read(modeloImagenesProvider.notifier);
          for (final uid in _imagenesParaRestaurar.toList()) {
            final img = imgNotifier.obtenerPorUid(uid);
            if (img != null) {
              final restaurada = await imgNotifier.editarImagen(
                actualizada: img.copyWith(
                  deleted: false,
                  isSynced: false,
                  updatedAt: DateTime.now().toUtc(),
                ),
              );
              if (restaurada.rutaLocal.isEmpty ||
                  !File(restaurada.rutaLocal).existsSync()) {
                await imgNotifier.descargarImagen(restaurada);
              }
            }
          }
          setState(() => _imagenesParaRestaurar.clear());
        }

        // 3) portada pendiente
        if (_coverSelUid != null) {
          final imgNotifier = ref.read(modeloImagenesProvider.notifier);
          await imgNotifier.setCover(
            modeloUid: nuevo.uid,
            imagenUid: _coverSelUid!,
          );
        }

        // asegurar que quede al menos una portada
        final imgNotifier = ref.read(modeloImagenesProvider.notifier);
        await imgNotifier.ensureCover(nuevo.uid);

        // si cambió la ruta de la ficha, limpia local
        await _limpiarFichaLocalSiRutaCambio(rutaRemota);

        // ---------- Final ----------
        if (context.loaderOverlay.visible) {
          context.loaderOverlay.progress('Finalizando…');
        }

        // delay mínimo 1500 ms
        const minSpin = Duration(milliseconds: 1500);
        final elapsed = DateTime.now().difference(inicio);
        if (elapsed < minSpin) {
          await Future.delayed(minSpin - elapsed);
        }

        if (mounted && context.loaderOverlay.visible) {
          context.loaderOverlay.hide();
        }
        if (mounted) Navigator.pop(context, true);
      } else {
        // ---------- Crear modelo ----------
        if (context.loaderOverlay.visible) {
          context.loaderOverlay.progress('Creando modelo…');
        }

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

        // ---------- Subir ficha PDF (si se seleccionó) ----------
        if (_archivoPDFSeleccionado != null &&
            await _archivoPDFSeleccionado!.exists()) {
          if (context.loaderOverlay.visible) {
            context.loaderOverlay.progress('Subiendo ficha PDF…');
          }
          await modelosNotifier.subirNuevaFicha(
            modelo: nuevo,
            archivo: _archivoPDFSeleccionado!,
            nuevoPath: rutaRemota,
          );
        }

        // ---------- Subir imágenes pendientes ----------
        if (_imagenesPendientes.isNotEmpty) {
          if (context.loaderOverlay.visible) {
            context.loaderOverlay.progress('Subiendo imágenes…');
          }
          await _subirImagenesParaModelo(nuevo.uid, _imagenesPendientes);
          setState(() => _imagenesPendientes.clear());
        }

        // ---------- Eliminar/Restaurar/Portada (si aplica) ----------
        if (_imagenesPorEliminar.isNotEmpty ||
            _imagenesParaRestaurar.isNotEmpty ||
            _coverSelUid != null) {
          if (context.loaderOverlay.visible) {
            context.loaderOverlay.progress('Aplicando cambios en imágenes…');
          }
        }

        // 1) eliminaciones
        if (_imagenesPorEliminar.isNotEmpty) {
          final imgNotifier = ref.read(modeloImagenesProvider.notifier);
          for (final uid in _imagenesPorEliminar.toList()) {
            final img = imgNotifier.obtenerPorUid(uid);
            if (img != null) {
              await imgNotifier.eliminarImagen(img);
            }
          }
          if (!mounted) return;
          setState(() => _imagenesPorEliminar.clear());
        }

        // 2) restauraciones
        if (_imagenesParaRestaurar.isNotEmpty) {
          final imgNotifier = ref.read(modeloImagenesProvider.notifier);
          for (final uid in _imagenesParaRestaurar.toList()) {
            final img = imgNotifier.obtenerPorUid(uid);
            if (img != null) {
              final restaurada = await imgNotifier.editarImagen(
                actualizada: img.copyWith(
                  deleted: false,
                  isSynced: false,
                  updatedAt: DateTime.now().toUtc(),
                ),
              );
              if (restaurada.rutaLocal.isEmpty ||
                  !File(restaurada.rutaLocal).existsSync()) {
                await imgNotifier.descargarImagen(restaurada);
              }
            }
          }
          setState(() => _imagenesParaRestaurar.clear());
        }

        // 3) portada pendiente
        if (_coverSelUid != null) {
          final imgNotifier = ref.read(modeloImagenesProvider.notifier);
          await imgNotifier.setCover(
            modeloUid: nuevo.uid,
            imagenUid: _coverSelUid!,
          );
        }

        // asegurar que quede al menos una portada
        final imgNotifier = ref.read(modeloImagenesProvider.notifier);
        await imgNotifier.ensureCover(nuevo.uid);

        // ---------- Final ----------
        if (context.loaderOverlay.visible) {
          context.loaderOverlay.progress('Finalizando…');
        }

        // delay mínimo 1500 ms
        const minSpin = Duration(milliseconds: 1500);
        final elapsed = DateTime.now().difference(inicio);
        if (elapsed < minSpin) {
          await Future.delayed(minSpin - elapsed);
        }

        if (mounted && context.loaderOverlay.visible) {
          context.loaderOverlay.hide();
        }
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Error al guardar: $e')));
      }
    } finally {
      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
      if (mounted) setState(() => _guardando = false);
    }
  }

  Future<void> _seleccionarPDF() async {
    if (_abriendoPickerPDF) return;
    _abriendoPickerPDF = true;

    try {
      if (mounted) {
        context.loaderOverlay.show(progress: 'Abriendo selector…');
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result == null || result.files.single.path == null) return;

      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.progress('Preparando archivo…');
      }

      _archivoPDFSeleccionado = File(result.files.single.path!);
      setState(() => _rutaRemotaController.text = _buildRutaRemota());

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('PDF preparado para subir')));
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ No se pudo abrir el selector: ${e.code}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error seleccionando PDF: $e')));
    } finally {
      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
      _abriendoPickerPDF = false;
    }
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

  // Imágenes
  Future<String> _sha256DeArchivo(File f) async {
    final digest = await sha256.bind(f.openRead()).first;
    return digest.toString();
  }

  // Sanitiza clave: MAYÚSCULAS, espacios→ '-', solo A-Z0-9_-
  String _sanitizarClave(String s) {
    final up = s.trim().toUpperCase().replaceAll(' ', '-');
    final basic = up.replaceAll(RegExp(r'[^A-Z0-9_-]'), '');
    return basic.replaceAll(RegExp(r'-{2,}'), '-');
  }

  // Construye ruta remota de la imagen (NO incluye el nombre del bucket)
  String _buildRutaRemotaImagen({
    required int anio,
    required String claveCatalogo,
    required String shaHex,
    required String originalPath,
  }) {
    var ext = p.extension(originalPath).toLowerCase();
    if (ext.startsWith('.')) ext = ext.substring(1); // "jpg" | "png" | ...
    final clave = _sanitizarClave(claveCatalogo);
    // Estructura que definiste: <año>/<clave>/<sha>.<ext>
    return '$anio/$clave/$shaHex.$ext';
  }

  // Validar extensión imagen
  bool _esImagenSoportada(File f) {
    final e = p.extension(f.path).toLowerCase();
    return ['.jpg', '.jpeg', '.png', '.webp'].contains(e);
  }

  Future<void> _pickImagenes() async {
    if (_abriendoPickerImgs) return;
    _abriendoPickerImgs = true;

    try {
      if (mounted) {
        context.loaderOverlay.show(progress: 'Abriendo selector…');
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowMultiple: true,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      );
      if (result == null || result.files.isEmpty) return;

      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.progress('Procesando imágenes…');
      }

      final archivos = result.files
          .map((f) => f.path)
          .whereType<String>()
          .map((p) => File(p))
          .where(_esImagenSoportada)
          .toList();

      if (archivos.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se seleccionaron imágenes válidas')),
        );
        return;
      }

      // SIEMPRE pendientiza (tanto en nuevo como en edición).
      if (!mounted) return;
      setState(() {
        _imagenesPendientes.addAll(archivos);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imágenes agregadas: ${archivos.length}')),
        );
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ No se pudo abrir el selector: ${e.code}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error seleccionando imágenes: $e')),
      );
    } finally {
      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
      _abriendoPickerImgs = false;
    }
  }

  Future<void> _subirImagenesParaModelo(
    String modeloUid,
    List<File> files,
  ) async {
    if (!mounted) return;
    int errores = 0, duplicadas = 0;

    try {
      final imgNotifier = ref.read(modeloImagenesProvider.notifier);

      bool yaHayPortada = imgNotifier
          .imagenesDeModelo(modeloUid, incluirEliminadas: false)
          .any((x) => x.isCover);

      for (final file in files) {
        try {
          final sha = await _sha256DeArchivo(file);
          final yaExiste = await imgNotifier.buscarPorShaEnModelo(
            modeloUid,
            sha,
          );
          if (yaExiste != null) {
            duplicadas++;
            continue;
          }

          final reg = await imgNotifier.crearImagenLocal(modeloUid: modeloUid);
          final rutaRemotaImg = _buildRutaRemotaImagen(
            anio: _anioSel ?? DateTime.now().year,
            claveCatalogo: _claveController.text,
            shaHex: sha,
            originalPath: file.path,
          );

          await imgNotifier.subirNuevaImagen(
            imagen: reg,
            archivo: file,
            nuevoPath: rutaRemotaImg,
            sha256Override: sha,
          );

          // Auto-portada si no existe aún (sin cambios)
          if (!yaHayPortada) {
            await imgNotifier.setCover(
              modeloUid: modeloUid,
              imagenUid: reg.uid,
            );
            yaHayPortada = true;
          }
        } catch (e) {
          errores++;
        }
      }
    } finally {
      if (!mounted) return;
      if (errores > 0 || duplicadas > 0) {
        final msg = [
          if (duplicadas > 0) 'ℹ️ $duplicadas duplicada(s) omitida(s)',
          if (errores > 0) '⚠️ $errores con error',
        ].join(' · ');
        if (msg.isNotEmpty) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        }
      }
    }
  }

  void _toggleEliminar(ModeloImagenDb img) {
    final id = img.uid;
    // Si estaba seleccionada como portada pendiente, la deseleccionamos
    if (_coverSelUid == id) {
      _coverSelUid = null;
    }

    if (_imagenesPorEliminar.contains(id)) {
      setState(() => _imagenesPorEliminar.remove(id)); // deshacer
    } else {
      setState(() {
        _imagenesParaRestaurar.remove(id); // no pueden coexistir
        _imagenesPorEliminar.add(id); // marcar para borrar
      });
    }
  }

  void _toggleRestaurar(ModeloImagenDb img) {
    final id = img.uid;
    if (_imagenesParaRestaurar.contains(id)) {
      setState(() => _imagenesParaRestaurar.remove(id)); // deshacer
    } else {
      setState(() {
        _imagenesPorEliminar.remove(id); // no pueden coexistir
        _imagenesParaRestaurar.add(id); // marcar para restaurar
      });
    }
  }

  // NUEVO: seleccionar/deseleccionar portada pendiente (solo imágenes activas)
  void _toggleCover(ModeloImagenDb img) {
    if (img.deleted) return; // seguridad
    setState(() {
      if (_coverSelUid == img.uid) {
        _coverSelUid = null; // quitar selección pendiente
      } else {
        _coverSelUid = img.uid; // seleccionar esta como portada pendiente
      }
      // por coherencia, si estaba marcada para borrar/restaurar, las limpiamos
      _imagenesPorEliminar.remove(img.uid);
      _imagenesParaRestaurar.remove(img.uid);
    });
  }
}

class _ThumbPendiente extends StatelessWidget {
  final File file;
  final VoidCallback onRemove;
  const _ThumbPendiente({required this.file, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        fit: StackFit.expand, // ahora OK, hay tamaño fijo
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(file, fit: BoxFit.cover),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: InkWell(
              onTap: onRemove,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThumbImagen extends StatelessWidget {
  final ModeloImagenDb img;
  final bool estaSoftDeleted;
  final bool marcadaParaEliminar;
  final bool marcadaParaRestaurar;
  final VoidCallback onToggleDelete;
  final VoidCallback onToggleRestore;
  final bool isCover;
  final VoidCallback onSetCover;

  const _ThumbImagen({
    required this.img,
    required this.estaSoftDeleted,
    required this.marcadaParaEliminar,
    required this.marcadaParaRestaurar,
    required this.onToggleDelete,
    required this.onToggleRestore,
    // 👇 nuevo
    required this.isCover,
    required this.onSetCover,
  });

  @override
  Widget build(BuildContext context) {
    final haveLocal =
        img.rutaLocal.isNotEmpty && File(img.rutaLocal).existsSync();

    Widget badge(String text, Color color) => Positioned(
      left: 6,
      top: 6,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontSize: 11),
        ),
      ),
    );

    return Container(
      decoration: estaSoftDeleted
          ? BoxDecoration(
              border: Border.all(color: Colors.redAccent, width: 2),
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: haveLocal
                ? Image.file(File(img.rutaLocal), fit: BoxFit.cover)
                : Container(
                    color: Colors.black12,
                    alignment: Alignment.center,
                    child: const Icon(Icons.image_not_supported_outlined),
                  ),
          ),

          // Overlays por estado
          if (marcadaParaEliminar)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(color: Colors.redAccent.withOpacity(0.35)),
            ),
          if (marcadaParaRestaurar)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(color: Colors.green.withOpacity(0.35)),
            ),
          if (estaSoftDeleted && !marcadaParaRestaurar)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(color: Colors.black45.withOpacity(0.35)),
            ),

          // Badges
          if (isCover) badge('Portada', Colors.indigo),
          if (marcadaParaEliminar) badge('A borrar', Colors.redAccent),
          if (marcadaParaRestaurar) badge('A restaurar', Colors.green),
          if (estaSoftDeleted && !marcadaParaRestaurar)
            badge('Eliminada', Colors.black54),

          // Botonera (incluye estrella para portada)
          Positioned(
            top: 4,
            right: 4,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ⭐ Marcar portada (solo si no está eliminada)
                if (!estaSoftDeleted)
                  _IconBtn(
                    icon: isCover ? Icons.star : Icons.star_border,
                    tooltip: isCover
                        ? 'Portada (pendiente)'
                        : 'Marcar como portada',
                    onTap: onSetCover,
                  ),
                if (!estaSoftDeleted)
                  _IconBtn(
                    icon: marcadaParaEliminar
                        ? Icons.undo
                        : Icons.delete_forever,
                    tooltip: marcadaParaEliminar
                        ? 'Deshacer'
                        : 'Marcar para eliminar',
                    onTap: onToggleDelete,
                  ),
                if (estaSoftDeleted)
                  _IconBtn(
                    icon: marcadaParaRestaurar
                        ? Icons.undo
                        : Icons.restore_from_trash,
                    tooltip: marcadaParaRestaurar
                        ? 'Deshacer'
                        : 'Marcar para restaurar',
                    onTap: onToggleRestore,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _IconBtn extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  const _IconBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: InkWell(
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, size: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }
}

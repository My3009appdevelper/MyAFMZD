import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:myafmzd/database/reportes/reportes_provider.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/widgets/chip_picker.dart';
import 'package:myafmzd/widgets/my_elevated_button.dart';
import 'package:myafmzd/widgets/my_text_form_field.dart';
import 'package:path/path.dart' as p;

class ReporteFormPage extends ConsumerStatefulWidget {
  final ReportesDb? reporteEditar;
  const ReporteFormPage({super.key, this.reporteEditar});

  @override
  ConsumerState<ReporteFormPage> createState() => _ReporteFormPageState();
}

class _ReporteFormPageState extends ConsumerState<ReporteFormPage> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nombreController;
  late TextEditingController _tipoController;
  late TextEditingController _rutaRemotaController;
  late DateTime _fecha;

  bool _esEdicion = false;
  File? _archivoPDFSeleccionado;

  // Añadidos locales (como en modelos)
  final _addTipos = <String>{};

  // Selección normalizada (como en modelos)
  String _tipoSel = '';

  bool _guardando = false; // evita doble 'Guardar'
  bool _abriendoPicker = false; // evita abrir el picker varias veces

  @override
  void initState() {
    super.initState();
    final r = widget.reporteEditar;
    _esEdicion = r != null;

    _nombreController = TextEditingController(text: r?.nombre ?? '');
    _tipoController = TextEditingController(
      text: (r?.tipo ?? 'INTERNO').trim(),
    );
    _tipoSel = _tipoController.text; // espejo del controller para el picker

    _fecha = r?.fecha ?? DateTime.now();

    _rutaRemotaController = TextEditingController(text: r?.rutaRemota ?? '');
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _tipoController.dispose();
    _rutaRemotaController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Lista de tipos: DB + añadidos locales (como en modelos)
    final tipos = _mergeStr(
      ref.watch(reporteProvider.notifier).tiposDisponibles,
      _addTipos,
    );

    // Asegurar selección válida (como en modelos: ensureStr)
    String _ensureTipo(String current, List<String> list, String fallback) {
      final cur = current.trim();
      if (cur.isEmpty) {
        return list.isNotEmpty ? list.first : fallback;
      }
      return list.contains(cur)
          ? cur
          : (list.isNotEmpty ? list.first : fallback);
    }

    _tipoSel = _ensureTipo(_tipoSel, tipos, 'INTERNO');
    if (_tipoController.text.trim().isEmpty ||
        _tipoController.text != _tipoSel) {
      // mantener ambos sincronizados
      _tipoController.text = _tipoSel;
    }

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyle = theme.textTheme.bodyLarge;

    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar Reporte' : 'Nuevo Reporte'),
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
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Campo obligatorio'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // ✅ Tipo con MyChipPickerSingle (patrón de Modelos)
                  MyChipPickerSingle(
                    label: 'Tipo',
                    options: tipos,
                    selected: _tipoSel,
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Selecciona un tipo'
                        : null,
                    onSelected: (val) {
                      setState(() {
                        _tipoSel = val;
                        _tipoController.text = val; // espejo
                      });
                    },
                    onAddNew: (nuevo) {
                      setState(() {
                        final canon = nuevo.trim();
                        if (canon.isNotEmpty) {
                          _addTipos.add(canon);
                          _tipoSel = canon; // selecciona de inmediato
                          _tipoController.text = canon;
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // Fecha
                  Text(
                    "Fecha",
                    style: textStyle?.copyWith(color: colorScheme.onSurface),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${_fecha.year}-${_fecha.month.toString().padLeft(2, '0')}-${_fecha.day.toString().padLeft(2, '0')}',
                    ),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: _seleccionarFecha,
                  ),
                  const SizedBox(height: 12),

                  // Ruta Remota
                  MyTextFormField(
                    controller: _rutaRemotaController,
                    labelText: 'Ruta remota',
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Campo obligatorio'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // Subir archivo
                  MyElevatedButton(
                    icon: Icons.upload_file,
                    label:
                        (_archivoPDFSeleccionado != null &&
                            _archivoPDFSeleccionado!.path.isNotEmpty)
                        ? 'Archivo seleccionado'
                        : 'Subir nuevo PDF',
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
    if (_guardando) return;
    _guardando = true;

    // UX: cerrar teclado
    FocusScope.of(context).unfocus();

    // Overlay + cronómetro para delay mínimo
    context.loaderOverlay.show(
      progress: _esEdicion ? 'Editando reporte…' : 'Guardando reporte…',
    );
    final inicio = DateTime.now();

    final nombre = _nombreController.text.trim();
    final tipo = _tipoController.text.trim();
    final reporteNotifier = ref.read(reporteProvider.notifier);

    try {
      if (_esEdicion) {
        if (context.loaderOverlay.visible) {
          context.loaderOverlay.progress('Aplicando cambios…');
        }

        final actualizado = widget.reporteEditar!.copyWith(
          nombre: nombre,
          tipo: tipo,
          rutaRemota: _rutaRemotaController.text.trim(),
          fecha: _fecha,
          updatedAt: DateTime.now().toUtc(),
          isSynced: false,
        );

        final nuevo = await reporteNotifier.editarReporte(
          actualizado: actualizado,
        );

        if (_archivoPDFSeleccionado != null &&
            await _archivoPDFSeleccionado!.exists()) {
          if (context.loaderOverlay.visible) {
            context.loaderOverlay.progress('Subiendo PDF…');
          }
          await reporteNotifier.subirNuevoPDF(
            reporte: nuevo,
            archivo: _archivoPDFSeleccionado!,
            nuevoPath: _rutaRemotaController.text.trim(),
          );
        }
      } else {
        if (context.loaderOverlay.visible) {
          context.loaderOverlay.progress('Creando reporte…');
        }

        final nuevo = await reporteNotifier.crearReporteLocal(
          nombre: nombre,
          tipo: tipo,
          fecha: _fecha,
          rutaRemota: _rutaRemotaController.text.trim(),
        );

        if (_archivoPDFSeleccionado != null &&
            await _archivoPDFSeleccionado!.exists()) {
          if (context.loaderOverlay.visible) {
            context.loaderOverlay.progress('Subiendo PDF…');
          }
          await reporteNotifier.subirNuevoPDF(
            reporte: nuevo,
            archivo: _archivoPDFSeleccionado!,
            nuevoPath: _rutaRemotaController.text.trim(),
          );
        }
      }

      // Delay mínimo para UX consistente
      const minSpin = Duration(milliseconds: 1500);
      final elapsed = DateTime.now().difference(inicio);
      if (elapsed < minSpin) {
        await Future.delayed(minSpin - elapsed);
      }

      // Oculta overlay ANTES de cerrar
      if (context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
      _guardando = false;
    }
  }

  Future<void> _seleccionarPDF() async {
    if (_abriendoPicker) return; // evita múltiples diálogos
    _abriendoPicker = true;

    // Muestra overlay mientras se abre y procesa el archivo
    context.loaderOverlay.show(progress: 'Abriendo selector…');

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result == null || result.files.single.path == null) return;

      if (context.loaderOverlay.visible) {
        context.loaderOverlay.progress('Preparando archivo…');
      }

      _archivoPDFSeleccionado = File(result.files.single.path!);

      // Normaliza nombre → slug + .pdf
      final nombreOriginal = result.files.single.name;
      final base = p.basenameWithoutExtension(nombreOriginal);
      final safeBase = slugify(base.trim());
      final fileName = safeBase.isEmpty ? 'reporte' : safeBase;
      final nombreArchivo = '$fileName.pdf';

      // Ruta: reportes/YYYY-MM/archivo.pdf (respeta _fecha seleccionada)
      final mes =
          '${_fecha.year.toString().padLeft(4, '0')}-${_fecha.month.toString().padLeft(2, '0')}';
      final rutaRemota = 'reportes/$mes/$nombreArchivo';

      if (!mounted) return;
      setState(() {
        _rutaRemotaController.text = rutaRemota;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF preparado para subir')),
        );
      }
    } on PlatformException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el selector: ${e.code}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error seleccionando PDF: $e')));
      }
    } finally {
      if (mounted && context.loaderOverlay.visible) {
        context.loaderOverlay.hide();
      }
      _abriendoPicker = false;
    }
  }

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

  Future<void> _seleccionarFecha() async {
    final nuevaFecha = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (nuevaFecha != null) {
      setState(() {
        _fecha = nuevaFecha;

        // Mantengo tu lógica: si ya hay PDF seleccionado, recalcula ruta con el nombre del archivo
        if (_archivoPDFSeleccionado != null) {
          final base = p.basenameWithoutExtension(
            _archivoPDFSeleccionado!.path,
          );
          final fileName =
              '${slugify(base.trim().isEmpty ? "reporte" : base.trim())}.pdf';

          final mes =
              '${nuevaFecha.year.toString().padLeft(4, '0')}-${nuevaFecha.month.toString().padLeft(2, '0')}';
          final rutaRemota = 'reportes/$mes/$fileName';
          _rutaRemotaController.text = rutaRemota;
        }
      });
    }
  }

  List<String> _mergeStr(List<String> a, Set<String> b) {
    final set = <String>{}
      ..addAll(a.map((e) => e.trim()).where((e) => e.isNotEmpty))
      ..addAll(b.map((e) => e.trim()).where((e) => e.isNotEmpty));
    final out = set.toList()
      ..sort((x, y) => x.toLowerCase().compareTo(y.toLowerCase()));
    return out;
  }
}

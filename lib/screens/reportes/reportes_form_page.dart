import 'dart:io';

import 'package:dropdown_search/dropdown_search.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/reportes/reportes_provider.dart';
import 'package:myafmzd/database/app_database.dart';
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

  @override
  void initState() {
    super.initState();
    final reporte = widget.reporteEditar;
    _esEdicion = reporte != null;
    _nombreController = TextEditingController(text: reporte?.nombre ?? '');
    _tipoController = TextEditingController(text: reporte?.tipo ?? 'INTERNO');
    _fecha = reporte?.fecha ?? DateTime.now();
    _rutaRemotaController = TextEditingController(
      text: reporte?.rutaRemota ?? '',
    );
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
    final tipos = ref.watch(reporteProvider.notifier).tiposDisponibles;
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
              child: ListView(
                children: [
                  // Nombre
                  MyTextFormField(
                    controller: _nombreController,
                    labelText: 'Nombre',
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 12),

                  // Tipo de reporte
                  DropdownSearch<String>(
                    items: (String filtro, LoadProps? props) async {
                      return tipos
                          .where(
                            (d) =>
                                d.toLowerCase().contains(filtro.toLowerCase()),
                          )
                          .toList();
                    },
                    selectedItem: _tipoController.text,

                    onChanged: (value) {
                      if (value != null) _tipoController.text = value;
                    },
                    compareFn: (a, b) => a.toLowerCase() == b.toLowerCase(),
                    dropdownBuilder: (context, selectedItem) {
                      return MyTextFormField(
                        controller: _tipoController,
                        labelText: 'Tipo',
                      );
                    },
                    decoratorProps: DropDownDecoratorProps(
                      decoration: InputDecoration(
                        labelStyle: textStyle?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                        filled: true,
                        fillColor: colorScheme.surface,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colorScheme.error),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: colorScheme.error,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Fecha
                  Text("Fecha"),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${_fecha.year}-${_fecha.month.toString().padLeft(2, '0')}-'
                      '${_fecha.day.toString().padLeft(2, '0')}',
                    ),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: _seleccionarFecha,
                  ),
                  const SizedBox(height: 12),

                  // Ruta Remota
                  MyTextFormField(
                    controller: _rutaRemotaController,
                    labelText: 'Ruta remota',
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Campo obligatorio' : null,
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

    final nombre = _nombreController.text.trim();
    final tipo = _tipoController.text.trim();

    final reporteNotifier = ref.read(reporteProvider.notifier);

    try {
      if (_esEdicion) {
        final actualizado = widget.reporteEditar!.copyWith(
          nombre: nombre,
          tipo: tipo,
          rutaRemota: _rutaRemotaController.text,
          fecha: _fecha,
          updatedAt: DateTime.now().toUtc(),
          isSynced: false,
        );

        final nuevo = await reporteNotifier.editarReporte(
          actualizado: actualizado,
        );

        // 🟢 Solo subir si el usuario seleccionó un nuevo archivo manualmente
        if (_archivoPDFSeleccionado != null &&
            await _archivoPDFSeleccionado!.exists()) {
          await reporteNotifier.subirNuevoPDF(
            reporte: nuevo,
            archivo: _archivoPDFSeleccionado!,
            nuevoPath: _rutaRemotaController.text,
          );
        }
        if (mounted) Navigator.pop(context, true);
      } else {
        final nuevo = await reporteNotifier.crearReporteLocal(
          nombre: nombre,
          tipo: tipo,
          fecha: _fecha,
          rutaRemota: _rutaRemotaController.text,
        );

        // Subir PDF si se seleccionó
        if (_archivoPDFSeleccionado != null &&
            await _archivoPDFSeleccionado!.exists()) {
          await reporteNotifier.subirNuevoPDF(
            reporte: nuevo,
            archivo: _archivoPDFSeleccionado!,
            nuevoPath: _rutaRemotaController.text,
          );
        }
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    }
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

        if (_archivoPDFSeleccionado != null) {
          final nombreOriginal = _archivoPDFSeleccionado!.path
              .split(Platform.pathSeparator)
              .last;
          final nombreSanitizado = nombreOriginal.trim().replaceAll(' ', '_');
          final nombreArchivo = nombreSanitizado.replaceAll('.PDF', '.pdf');

          final mes =
              '${nuevaFecha.year.toString().padLeft(4, '0')}-${nuevaFecha.month.toString().padLeft(2, '0')}';
          final rutaRemota = 'reportes/$mes/$nombreArchivo';

          _rutaRemotaController.text = rutaRemota;
        }
      });
    }
  }

  Future<void> _seleccionarPDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.single.path == null) return;

    _archivoPDFSeleccionado = File(result.files.single.path!);

    final nombreOriginal =
        result.files.single.name; // e.g. "Cotización Ñ 2025.PDF"
    final base = p.basenameWithoutExtension(nombreOriginal);
    final safeBase = slugify(base.trim()); // "cotizacion_n_2025"
    final fileName = safeBase.isEmpty ? 'reporte' : safeBase;

    // fuerza la extensión .pdf en minúsculas
    final nombreArchivo = '$fileName.pdf';

    final mes =
        '${_fecha.year.toString().padLeft(4, '0')}-${_fecha.month.toString().padLeft(2, '0')}';
    final rutaRemota = 'reportes/$mes/$nombreArchivo';

    setState(() {
      _rutaRemotaController.text = rutaRemota;
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('PDF preparado para subir')));
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
}

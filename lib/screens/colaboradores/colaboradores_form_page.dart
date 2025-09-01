// ignore_for_file: avoid_print

import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_provider.dart';
import 'package:myafmzd/widgets/my_elevated_button.dart';
import 'package:myafmzd/widgets/my_text_form_field.dart';
import 'package:path/path.dart' as p;

class ColaboradorFormPage extends ConsumerStatefulWidget {
  final ColaboradorDb? colaboradorEditar;
  const ColaboradorFormPage({super.key, this.colaboradorEditar});

  @override
  ConsumerState<ColaboradorFormPage> createState() =>
      _ColaboradorFormPageState();
}

class _ColaboradorFormPageState extends ConsumerState<ColaboradorFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Foto
  File? _fotoSeleccionada;
  String _generoSel = '';

  // Text controllers
  late TextEditingController _nombresController;
  late TextEditingController _apPatController;
  late TextEditingController _apMatCtrl;
  DateTime? _fechaNac;
  late TextEditingController _curpController;
  late TextEditingController _rfcController;
  late TextEditingController _telController;
  late TextEditingController _emailController;
  late TextEditingController _generoController;
  late TextEditingController _notasController;

  bool _esEdicion = false;

  @override
  void initState() {
    super.initState();
    final c = widget.colaboradorEditar;
    _esEdicion = c != null;

    _nombresController = TextEditingController(text: c?.nombres ?? '');
    _apPatController = TextEditingController(text: c?.apellidoPaterno ?? '');
    _apMatCtrl = TextEditingController(text: c?.apellidoMaterno ?? '');
    _fechaNac = c?.fechaNacimiento;
    _generoSel = (c?.genero ?? '').trim();
    _curpController = TextEditingController(text: c?.curp ?? '');
    _rfcController = TextEditingController(text: c?.rfc ?? '');
    _telController = TextEditingController(text: c?.telefonoMovil ?? '');
    _emailController = TextEditingController(text: c?.emailPersonal ?? '');
    _generoController = TextEditingController(text: (c?.genero ?? '').trim());
    _notasController = TextEditingController(text: c?.notas ?? '');
  }

  @override
  void dispose() {
    _nombresController.dispose();
    _apPatController.dispose();
    _apMatCtrl.dispose();
    _curpController.dispose();
    _rfcController.dispose();
    _telController.dispose();
    _emailController.dispose();
    _generoController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _ = ref.watch(colaboradoresProvider); // rebuild ante cambios

    // Foto mostrada: prioriza seleccionada, luego local de DB
    final rutaLocalActual = widget.colaboradorEditar?.fotoRutaLocal ?? '';
    final tieneLocal =
        rutaLocalActual.isNotEmpty && File(rutaLocalActual).existsSync();
    final imagenPreview = _fotoSeleccionada != null
        ? FileImage(_fotoSeleccionada!)
        : (tieneLocal ? FileImage(File(rutaLocalActual)) : null);

    final generos = const [
      'Masculino',
      'Femenino',
      'No binario',
      'Prefiero no decir',
      'Otro',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar colaborador' : 'Nuevo colaborador'),
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
                  // ===================== FOTO (arriba) ======================
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundImage: imagenPreview,
                          child: imagenPreview == null
                              ? const Icon(Icons.person, size: 48)
                              : null,
                        ),
                        const SizedBox(height: 8),
                        MyElevatedButton(
                          icon: Icons.photo_library_outlined,
                          label: _fotoSeleccionada != null
                              ? 'Foto seleccionada'
                              : 'Seleccionar foto',
                          onPressed: _pickFoto,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ====================== CAMPOS ============================
                  MyTextFormField(
                    controller: _nombresController,
                    labelText: 'Nombres*',
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Campo obligatorio'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  MyTextFormField(
                    controller: _apPatController,
                    labelText: 'Apellido paterno',
                  ),
                  const SizedBox(height: 12),

                  MyTextFormField(
                    controller: _apMatCtrl,
                    labelText: 'Apellido materno',
                  ),
                  const SizedBox(height: 12),

                  // Fecha de nacimiento
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Fecha de nacimiento: ${_fechaNac != null ? _fmtFecha(_fechaNac!) : '—'}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_fechaNac != null)
                          IconButton(
                            tooltip: 'Limpiar',
                            icon: const Icon(Icons.clear),
                            onPressed: () => setState(() => _fechaNac = null),
                          ),
                        IconButton(
                          tooltip: 'Elegir fecha',
                          icon: const Icon(Icons.calendar_month),
                          onPressed: _pickFechaNacimiento,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // CURP / RFC
                  MyTextFormField(
                    controller: _curpController,
                    labelText: 'CURP',
                  ),
                  const SizedBox(height: 12),
                  MyTextFormField(controller: _rfcController, labelText: 'RFC'),
                  const SizedBox(height: 12),

                  // Tel / Email
                  MyTextFormField(
                    controller: _telController,
                    labelText: 'Teléfono móvil',
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 12),
                  MyTextFormField(
                    controller: _emailController,
                    labelText: 'Email personal',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return null; // opcional
                      if (!s.contains('@') || !s.contains('.'))
                        return 'Correo inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // Género (chips de selección única con feedback visual)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final g in generos)
                        ChoiceChip(
                          label: Text(g),
                          selected: _generoSel == g,
                          onSelected: (bool sel) {
                            setState(() {
                              _generoSel = sel && _generoSel != g
                                  ? g
                                  : (sel ? g : ''); // toggle
                              _generoController.text =
                                  _generoSel; // sincroniza con tu lógica actual
                            });
                          },
                          // (Opcional) estilos para que destaque más
                          avatar: _generoSel == g
                              ? const Icon(Icons.check, size: 16)
                              : null,
                          shape: StadiumBorder(
                            side: BorderSide(
                              color: _generoSel == g
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).dividerColor,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Notas
                  MyTextFormField(
                    controller: _notasController,
                    labelText: 'Notas',
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

  // ============================ Acciones =============================

  Future<void> _pickFoto() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      );
      if (result == null || result.files.single.path == null) return;
      setState(() => _fotoSeleccionada = File(result.files.single.path!));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto preparada para subir')),
      );
    } on PlatformException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ No se pudo abrir el selector: ${e.code}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error seleccionando imagen: $e')),
      );
    }
  }

  Future<void> _pickFechaNacimiento() async {
    final init = _fechaNac ?? DateTime(1990, 1, 1);
    final sel = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(1900),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (sel != null) setState(() => _fechaNac = sel);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final nombres = _nombresController.text.trim();
    final apPat = _apPatController.text.trim();
    final apMat = _apMatCtrl.text.trim();
    final curp = _curpController.text.trim();
    final rfc = _rfcController.text.trim();
    final tel = _telController.text.trim();
    final email = _emailController.text.trim();
    final genero = _generoController.text.trim();
    final notas = _notasController.text.trim();

    final notifier = ref.read(colaboradoresProvider.notifier);

    final duplicado = notifier.existeDuplicado(
      uidActual: widget.colaboradorEditar?.uid ?? '',
      nombres: nombres,
      apellidoPaterno: apPat,
      apellidoMaterno: apMat,
      fechaNacimiento: _fechaNac,
      curp: curp,
      rfc: rfc,
      telefonoMovil: tel,
      emailPersonal: email,
    );

    if (duplicado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            '❌ Ya existe un colaborador con estos datos (CURP/RFC/email/teléfono o nombre+fecha).',
          ),
        ),
      );
      return;
    }

    try {
      if (_esEdicion) {
        // Editar datos básicos (LOCAL → isSynced=false)
        await notifier.editarColaborador(
          uid: widget.colaboradorEditar!.uid,
          nombres: nombres,
          apellidoPaterno: apPat.isEmpty ? null : apPat,
          apellidoMaterno: apMat.isEmpty ? null : apMat,
          fechaNacimiento: _fechaNac,
          curp: curp.isEmpty ? null : curp,
          rfc: rfc.isEmpty ? null : rfc,
          telefonoMovil: tel.isEmpty ? null : tel,
          emailPersonal: email.isEmpty ? null : email,
          genero: genero.isEmpty ? null : genero,
          notas: notas.isEmpty ? null : notas,
          // fotoRutaRemota/Local no se tocan aquí: van por subirNuevaFoto()
        );

        // Si hay nueva foto, súbela y actualiza rutas
        if (_fotoSeleccionada != null && await _fotoSeleccionada!.exists()) {
          final nuevoPath = _buildRutaRemotaAvatar(
            uid: widget.colaboradorEditar!.uid,
            originalPath: _fotoSeleccionada!.path,
          );
          await notifier.subirNuevaFoto(
            colaborador: widget.colaboradorEditar!,
            archivo: _fotoSeleccionada!,
            nuevoPath: nuevoPath,
          );
        }

        if (mounted) Navigator.pop(context, true);
      } else {
        // Crear primero el registro local
        final nuevo = await notifier.crearColaborador(
          nombres: nombres,
          apellidoPaterno: apPat,
          apellidoMaterno: apMat,
          fechaNacimiento: _fechaNac,
          curp: curp,
          rfc: rfc,
          telefonoMovil: tel,
          emailPersonal: email,
          genero: genero,
          notas: notas,
          // fotoRutaRemota/Local: se llenan si subimos
        );

        // Si seleccionó foto, súbela y vincula
        if (nuevo != null &&
            _fotoSeleccionada != null &&
            await _fotoSeleccionada!.exists()) {
          final nuevoPath = _buildRutaRemotaAvatar(
            uid: nuevo.uid,
            originalPath: _fotoSeleccionada!.path,
          );
          await notifier.subirNuevaFoto(
            colaborador: nuevo,
            archivo: _fotoSeleccionada!,
            nuevoPath: nuevoPath,
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

  // ============================ Helpers ==============================

  String _fmtFecha(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _buildRutaRemotaAvatar({
    required String uid,
    required String originalPath,
  }) {
    var ext = p.extension(originalPath).toLowerCase();
    if (ext.startsWith('.')) ext = ext.substring(1);
    if (ext.isEmpty) ext = 'jpg';
    // Estructura simple y estable por uid:
    return 'colaboradores/$uid/avatar.$ext';
  }
}

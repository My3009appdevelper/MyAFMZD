import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_provider.dart';
import 'package:myafmzd/database/usuarios/usuarios_provider.dart';
import 'package:myafmzd/widgets/my_picker_search_field.dart';
import 'package:myafmzd/widgets/my_elevated_button.dart';
import 'package:myafmzd/widgets/my_text_form_field.dart';

class UsuariosFormPage extends ConsumerStatefulWidget {
  final UsuarioDb? usuarioEditar;
  const UsuariosFormPage({super.key, this.usuarioEditar});

  @override
  ConsumerState<UsuariosFormPage> createState() => _UsuariosFormPageState();
}

class _UsuariosFormPageState extends ConsumerState<UsuariosFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _enviando = false;

  late TextEditingController _userNameCtrl;
  late TextEditingController _correoCtrl;
  late TextEditingController _passwordCtrl;

  bool _esEdicion = false;
  bool _correoFueEditado = false;
  String? _colaboradorUidSel;

  @override
  void initState() {
    super.initState();
    final u = widget.usuarioEditar;
    _esEdicion = u != null;

    _userNameCtrl = TextEditingController(text: u?.userName ?? '');
    _correoCtrl = TextEditingController(text: u?.correo ?? '');
    _passwordCtrl = TextEditingController();

    _colaboradorUidSel = u?.colaboradorUid;

    // Autollenado simple: si userName luce como correo y el usuario no tocó "correo"
    _userNameCtrl.addListener(() {
      if (_correoFueEditado) return;
      final un = _userNameCtrl.text.trim();

      // Solo autollenar si está vacío o si coincide con el autollenado previo
      if (_correoCtrl.text.isEmpty || _correoCtrl.text == _ultimoAutoCorreo) {
        _correoCtrl.text = un;
        _ultimoAutoCorreo = un;
      }
    });
    _correoCtrl.addListener(() {
      // Si el usuario cambia "correo" manualmente, no volvemos a autollenar
      final c = _correoCtrl.text.trim();
      _correoFueEditado = true;
      _ultimoAutoCorreo = c;
    });
  }

  String _ultimoAutoCorreo = '';

  @override
  void dispose() {
    _userNameCtrl.dispose();
    _correoCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colaboradores = ref.watch(colaboradoresProvider);

    ColaboradorDb? _selInicial() {
      if (_colaboradorUidSel == null || _colaboradorUidSel!.isEmpty) {
        return null;
      }
      try {
        return colaboradores.firstWhere((c) => c.uid == _colaboradorUidSel);
      } catch (_) {
        return null;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar usuario' : 'Crear usuario'),
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
                  // =================== Colaborador ===================
                  MyPickerSearchField<ColaboradorDb>(
                    items: colaboradores,
                    initialValue: _selInicial(),
                    itemAsString: (c) =>
                        '${c.nombres} ${c.apellidoPaterno} ${c.apellidoMaterno}'
                            .replaceAll(RegExp(r'\s+'), ' ')
                            .trim(),
                    compareFn: (a, b) => a.uid == b.uid,
                    labelText: 'Colaborador (opcional)',
                    hintText: 'Toca para buscar…',
                    bottomSheetTitle: 'Buscar colaborador',
                    searchHintText: 'Nombre, correo o teléfono',
                    onChanged: (c) =>
                        setState(() => _colaboradorUidSel = c?.uid),
                  ),

                  const SizedBox(height: 12),

                  // =================== userName ===================
                  MyTextFormField(
                    controller: _userNameCtrl,
                    labelText: 'Usuario (userName)',
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Campo requerido'
                        : null,
                  ),
                  const SizedBox(height: 12),

                  // =================== Correo ===================
                  MyTextFormField(
                    controller: _correoCtrl,
                    labelText: 'Correo',
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) {
                      final value = v?.trim() ?? '';
                      if (value.isEmpty) return 'Campo requerido';
                      if (!value.contains('@')) return 'Correo inválido';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),

                  // =================== Contraseña (solo crear) ===================
                  if (!_esEdicion)
                    MyTextFormField(
                      controller: _passwordCtrl,
                      labelText: 'Contraseña',
                      obscureText: true,
                      validator: (v) => (v == null || v.length < 6)
                          ? 'Mínimo 6 caracteres'
                          : null,
                    ),

                  const SizedBox(height: 24),

                  // =================== Guardar ===================
                  MyElevatedButton(
                    onPressed: _guardar,
                    icon: Icons.save,
                    label: 'Guardar',
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
    if (_enviando) return; // evita doble tap
    if (!_formKey.currentState!.validate()) return;

    setState(() => _enviando = true);

    // Overlay: mensaje inicial según modo
    if (mounted) {
      final msg = _esEdicion ? 'Editando usuario…' : 'Creando usuario…';
      context.loaderOverlay.show(progress: msg);
    }
    final inicio = DateTime.now();

    final userName = _userNameCtrl.text.trim();
    final correo = _correoCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final usuariosNotifier = ref.read(usuariosProvider.notifier);

    // Validación local de duplicados
    if (mounted && context.loaderOverlay.visible) {
      context.loaderOverlay.progress('Validando duplicados…');
    }
    final hayDuplicado = usuariosNotifier.existeDuplicado(
      uidActual: widget.usuarioEditar?.uid ?? '',
      userName: userName,
      correo: correo,
    );
    if (hayDuplicado) {
      if (mounted && context.loaderOverlay.visible)
        context.loaderOverlay.hide();
      setState(() => _enviando = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Ya existe un usuario con ese userName o correo'),
        ),
      );
      return;
    }

    try {
      if (_esEdicion) {
        if (mounted && context.loaderOverlay.visible) {
          context.loaderOverlay.progress('Aplicando cambios…');
        }
        await usuariosNotifier.editarUsuario(
          uid: widget.usuarioEditar!.uid,
          userName: userName,
          correo: correo,
          colaboradorUid: _colaboradorUidSel,
        );

        if (mounted && context.loaderOverlay.visible) {
          context.loaderOverlay.progress('Finalizando…');
        }
        // Delay mínimo UX
        const minSpin = Duration(milliseconds: 1500);
        final elapsed = DateTime.now().difference(inicio);
        if (elapsed < minSpin) {
          await Future.delayed(minSpin - elapsed);
        }

        if (mounted && context.loaderOverlay.visible)
          context.loaderOverlay.hide();
        if (mounted) Navigator.pop(context, true);
      } else {
        if (mounted && context.loaderOverlay.visible) {
          context.loaderOverlay.progress('Creando usuario…');
        }
        await usuariosNotifier.crearUsuario(
          userName: userName,
          correo: correo,
          password: password,
          colaboradorUid: _colaboradorUidSel,
        );

        if (mounted && context.loaderOverlay.visible) {
          context.loaderOverlay.progress('Finalizando…');
        }
        // Delay mínimo UX
        const minSpin = Duration(milliseconds: 1500);
        final elapsed = DateTime.now().difference(inicio);
        if (elapsed < minSpin) {
          await Future.delayed(minSpin - elapsed);
        }

        if (mounted && context.loaderOverlay.visible)
          context.loaderOverlay.hide();
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted && context.loaderOverlay.visible)
        context.loaderOverlay.hide();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error al guardar: $e')));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }
}

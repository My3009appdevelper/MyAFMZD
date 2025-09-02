import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_provider.dart';
import 'package:myafmzd/database/usuarios/usuarios_provider.dart';
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final labelStyle = theme.textTheme.bodyMedium;

    // Para el DropdownSearch: item y búsqueda por nombre completo
    List<ColaboradorDb> _filtrarColabs(String filtro) {
      final f = filtro.trim().toLowerCase();
      if (f.isEmpty) return colaboradores;
      return colaboradores.where((c) {
        final nombre = '${c.nombres} ${c.apellidoPaterno} ${c.apellidoMaterno}'
            .trim()
            .toLowerCase();
        return nombre.contains(f) ||
            c.emailPersonal.toLowerCase().contains(f) ||
            c.telefonoMovil.toLowerCase().contains(f);
      }).toList();
    }

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
                  DropdownSearch<ColaboradorDb>(
                    selectedItem: _selInicial(),
                    items: (String filtro, LoadProps? props) async {
                      return _filtrarColabs(filtro);
                    },
                    itemAsString: (c) =>
                        '${c.nombres} ${c.apellidoPaterno} ${c.apellidoMaterno}'
                            .trim(),
                    compareFn: (a, b) => a.uid == b.uid,
                    onChanged: (c) {
                      setState(() => _colaboradorUidSel = c?.uid);
                    },
                    popupProps: const PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          hintText: 'Buscar colaborador...',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                    suffixProps: DropdownSuffixProps(
                      clearButtonProps: ClearButtonProps(
                        isVisible: (_colaboradorUidSel ?? '').isNotEmpty,
                        tooltip: 'Quitar selección',
                      ),
                    ),
                    decoratorProps: DropDownDecoratorProps(
                      decoration: InputDecoration(
                        labelText: 'Colaborador (opcional)',
                        labelStyle: labelStyle,
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

    final userName = _userNameCtrl.text.trim();
    final correo = _correoCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final usuariosNotifier = ref.read(usuariosProvider.notifier);

    // Validación local de duplicados
    final hayDuplicado = usuariosNotifier.existeDuplicado(
      uidActual: widget.usuarioEditar?.uid ?? '',
      userName: userName,
      correo: correo,
    );
    if (hayDuplicado) {
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
        await usuariosNotifier.editarUsuario(
          uid: widget.usuarioEditar!.uid,
          userName: userName,
          correo: correo,
          colaboradorUid: _colaboradorUidSel,
        );
        if (mounted) Navigator.pop(context, true);
      } else {
        await usuariosNotifier.crearUsuario(
          userName: userName,
          correo: correo,
          password: password,
          colaboradorUid: _colaboradorUidSel,
        );
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('❌ Error al guardar: $e')));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }
}

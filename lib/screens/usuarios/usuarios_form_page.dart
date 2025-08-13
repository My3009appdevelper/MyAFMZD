import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/database/usuarios/usuarios_provider.dart';
import 'package:myafmzd/widgets/my_dropdown_button.dart';
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
  late TextEditingController _nombreController;
  late TextEditingController _correoController;
  late TextEditingController _contrasenaController;
  late TextEditingController _rolController;

  String _uuidDistribuidora = 'AFMZD';
  Map<String, bool> _permisos = {};
  bool _esEdicion = false;

  @override
  void initState() {
    super.initState();
    final usuario = widget.usuarioEditar;
    _esEdicion = usuario != null;

    _nombreController = TextEditingController(text: usuario?.nombre ?? '');
    _correoController = TextEditingController(text: usuario?.correo ?? '');
    _contrasenaController = TextEditingController();
    _rolController = TextEditingController(text: usuario?.rol ?? '');
    _uuidDistribuidora = usuario?.uuidDistribuidora ?? 'AFMZD';
    _permisos =
        usuario?.permisos ?? {'Ver reportes': true, 'Ver usuarios': false};
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _correoController.dispose();
    _contrasenaController.dispose();
    _rolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const List<String> rolesDisponibles = [
      'admin',
      'usuario',
      'distribuidor',
      'vendedor',
      'supervisor',
    ];

    final distribuidores = ref
        .watch(distribuidoresProvider)
        .where((d) => d.activo)
        .toList();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyle = theme.textTheme.bodyLarge;

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
                  MyTextFormField(
                    controller: _nombreController,
                    labelText: 'Nombre',
                    validator: (value) => value == null || value.isEmpty
                        ? 'Campo requerido'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  MyTextFormField(
                    controller: _correoController,
                    labelText: 'Correo',
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) => value == null || !value.contains('@')
                        ? 'Correo inválido'
                        : null,
                  ),

                  if (!_esEdicion)
                    MyTextFormField(
                      controller: _contrasenaController,
                      labelText: "Contraseña",
                      obscureText: true,
                      validator: (value) => value == null || value.length < 6
                          ? 'Mínimo 6 caracteres'
                          : null,
                    ),
                  const SizedBox(height: 20),

                  DropdownSearch<DistribuidorDb>(
                    selectedItem: distribuidores.firstWhere(
                      (d) => d.uid == _uuidDistribuidora,
                      orElse: () => distribuidores.first,
                    ),
                    items: (String filtro, LoadProps? props) async {
                      return distribuidores
                          .where(
                            (d) => d.nombre.toLowerCase().contains(
                              filtro.toLowerCase(),
                            ),
                          )
                          .toList();
                    },
                    itemAsString: (DistribuidorDb d) => d.nombre,
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _uuidDistribuidora = value.uid);
                      }
                    },
                    compareFn: (a, b) => a.uid == b.uid,
                    popupProps: const PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          hintText: 'Buscar distribuidora...',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                    decoratorProps: DropDownDecoratorProps(
                      decoration: InputDecoration(
                        labelText: "Distribuidora",
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

                  const SizedBox(height: 20),
                  MyDropdownButton<String>(
                    labelText: "Rol",
                    value: _rolController.text.isNotEmpty
                        ? _rolController.text
                        : null,
                    items: rolesDisponibles,

                    onChanged: (value) {
                      if (value != null) {
                        _rolController.text = value;
                        setState(() {});
                      }
                    },
                  ),
                  const SizedBox(height: 20),
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
    if (!_formKey.currentState!.validate()) return;

    final nombre = _nombreController.text.trim();
    final correo = _correoController.text.trim();
    final contrasena = _contrasenaController.text.trim();
    final rol = _rolController.text.trim();

    final usuariosNotifier = ref.read(usuariosProvider.notifier);

    final hayDuplicado = usuariosNotifier.existeDuplicado(
      uidActual: widget.usuarioEditar?.uid ?? '',
      nombre: nombre,
      correo: correo,
    );

    if (hayDuplicado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Ya existe un usuario con ese nombre o correo'),
        ),
      );
      return;
    }

    try {
      if (_esEdicion) {
        await ref
            .read(usuariosProvider.notifier)
            .editarUsuario(
              uid: widget.usuarioEditar!.uid,
              nombre: nombre,
              correo: correo,
              rol: rol,
              uuidDistribuidora: _uuidDistribuidora,
              permisos: _permisos,
            );
        if (mounted) Navigator.pop(context, true);
      } else {
        await ref
            .read(usuariosProvider.notifier)
            .crearUsuario(
              nombre: nombre,
              correo: correo,
              password: contrasena,
              rol: rol,
              uuidDistribuidora: _uuidDistribuidora,
              permisos: _permisos,
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

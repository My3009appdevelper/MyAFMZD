import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/usuarios/usuarios_provider.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_provider.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/screens/usuarios/usuarios_form_page.dart';
import 'package:myafmzd/widgets/my_sheet_action.dart';
import 'package:myafmzd/widgets/my_show_detail_dialog.dart';

class UsuariosItemTile extends ConsumerStatefulWidget {
  final UsuarioDb usuario;
  final VoidCallback onTap;
  final VoidCallback? onActualizado;

  const UsuariosItemTile({
    super.key,
    required this.usuario,
    required this.onTap,
    this.onActualizado,
  });

  @override
  ConsumerState<UsuariosItemTile> createState() => _UsuariosItemTileState();
}

class _UsuariosItemTileState extends ConsumerState<UsuariosItemTile> {
  @override
  Widget build(BuildContext context) {
    final u = ref
        .watch(usuariosProvider)
        .firstWhere(
          (x) => x.uid == widget.usuario.uid,
          orElse: () => widget.usuario,
        );

    final colaboradores = ref.watch(colaboradoresProvider);
    final distribuidores = ref.watch(distribuidoresProvider);

    final colaborador = u.colaboradorUid == null
        ? null
        : colaboradores.firstWhere((c) => c.uid == u.colaboradorUid);

    final distribuidora = distribuidores.isNotEmpty
        ? distribuidores.firstWhere(
            (d) => d.uid == 'AFMZD', // ejemplo: si quieres ligarlo por default
            orElse: () => distribuidores.first,
          )
        : null;

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      key: ValueKey(u.uid),
      leading: const Icon(Icons.person),
      title: Text(
        u.userName,
        style: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (colaborador != null)
            Text(
              'Colaborador: ${colaborador.nombres} ${colaborador.apellidoPaterno}',
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,

                color: colorScheme.onSurfaceVariant,
              ),
            ),
          Text(
            'Correo: ${u.correo}',
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
          ),
          if (distribuidora != null)
            Text(
              'Distribuidora: ${distribuidora.nombre}',
              style: textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),

          Text(
            'Actualizado: ${u.updatedAt}',
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
          ),
        ],
      ),
      isThreeLine: true,
      onTap: widget.onTap,
      onLongPress: () => _mostrarOpcionesUsuario(context, u),
    );
  }

  Future<void> _mostrarOpcionesUsuario(BuildContext context, UsuarioDb u) {
    return showActionSheet(
      context,
      title: 'Acciones',
      actions: [
        SheetAction(
          icon: Icons.info_outline,
          label: 'Ver detalles',
          onTap: () => _mostrarDetalles(context, u),
        ),
        SheetAction(
          icon: Icons.edit,
          label: 'Editar',
          onTap: () => _abrirFormularioEdicion(context, u),
        ),
      ],
    );
  }

  void _mostrarDetalles(BuildContext context, UsuarioDb u) {
    showDetailsDialog(
      context,
      title: 'Detalles del usuario',
      fields: {
        'UID': u.uid,
        'Nombre de Usuario': u.userName,
        'Correo': u.correo,
        'Colaborador UID': u.colaboradorUid ?? '-',
        'Eliminado': u.deleted ? 'Sí' : 'No',
        'Synced': u.isSynced ? 'Sí' : 'No',
        'Actualizado': u.updatedAt.toLocal().toString(),
      },
    );
  }

  Future<void> _abrirFormularioEdicion(
    BuildContext context,
    UsuarioDb u,
  ) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UsuariosFormPage(usuarioEditar: u)),
    );

    if (resultado == true && widget.onActualizado != null) {
      widget.onActualizado!();
    }
  }
}

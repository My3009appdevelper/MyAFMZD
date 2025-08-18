import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/database/usuarios/usuarios_provider.dart';
import 'package:myafmzd/screens/usuarios/usuarios_form_page.dart';
import 'package:myafmzd/widgets/sheet_action.dart';
import 'package:myafmzd/widgets/show_detail_dialog.dart';

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
    // Versión viva desde el provider (por si cambió al sincronizar)
    final u = ref
        .watch(usuariosProvider)
        .firstWhere(
          (x) => x.uid == widget.usuario.uid,
          orElse: () => widget.usuario,
        );

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      key: ValueKey(u.uid),
      leading: const Icon(Icons.person),
      title: Text(
        u.nombre,
        style: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Correo: ${u.correo}',
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            'Rol: ${u.rol}',
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
          ),
          Text(
            'Distribuidora: ${_nombreDistribuidora(u.uuidDistribuidora)}',
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
          ),
          Text(
            'Actualizado: ${u.updatedAt}',
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
          ),
          Text(
            'Eliminado: ${u.deleted ? "Sí" : "No"}',
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
          ),
          Text(
            'Sincronizado: ${u.isSynced ? "Sí" : "No"}',
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
          ),
        ],
      ),
      isThreeLine: true,
      onTap: widget.onTap,
      onLongPress: () => _mostrarOpcionesUsuario(context, u),
    );
  }

  String _nombreDistribuidora(String uuid) {
    if (uuid == 'AFMZD') return 'AFMZD';
    final d = ref.read(distribuidoresProvider.notifier).obtenerPorId(uuid);
    return d?.nombre ?? 'Sin distribuidora';
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
        'Nombre': u.nombre,
        'Correo': u.correo,
        'Rol': u.rol,
        'Distribuidora': _nombreDistribuidora(u.uuidDistribuidora),
        'Permisos': u.permisos.keys.join(', '),
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
      widget.onActualizado!(); // dispara el refresh (cargarOfflineFirst)
    }
  }
}

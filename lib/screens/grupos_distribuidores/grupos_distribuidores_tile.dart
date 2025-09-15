// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/grupo_distribuidores/grupos_distribuidores_provider.dart';
import 'package:myafmzd/screens/grupos_distribuidores/grupos_distribuidores_form_page.dart';
import 'package:myafmzd/widgets/sheet_action.dart';
import 'package:myafmzd/widgets/show_detail_dialog.dart';

class GrupoDistribuidorItemTile extends ConsumerStatefulWidget {
  final GrupoDistribuidorDb grupo;
  final VoidCallback onTap;
  final VoidCallback? onActualizado;

  const GrupoDistribuidorItemTile({
    super.key,
    required this.grupo,
    required this.onTap,
    this.onActualizado,
  });

  @override
  ConsumerState<GrupoDistribuidorItemTile> createState() =>
      _GrupoDistribuidorItemTileState();
}

class _GrupoDistribuidorItemTileState
    extends ConsumerState<GrupoDistribuidorItemTile> {
  @override
  Widget build(BuildContext context) {
    // Obtener versión “viva” desde el provider
    final g = ref
        .watch(gruposDistribuidoresProvider)
        .firstWhere(
          (x) => x.uid == widget.grupo.uid,
          orElse: () => widget.grupo,
        );

    return ListTile(
      key: ValueKey(g.uid),
      leading: const Icon(Icons.groups_2),
      title: Text(g.nombre),
      subtitle: Text(
        (g.abreviatura.isNotEmpty ? 'Abrev: ${g.abreviatura} — ' : '') +
            (g.notas.isNotEmpty ? g.notas : '—'),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: g.activo
          ? const Icon(Icons.check_circle, color: Colors.green)
          : const Icon(Icons.cancel, color: Colors.grey),
      onTap: widget.onTap,
      onLongPress: () => _mostrarOpcionesGrupo(context, g),
    );
  }

  Future<void> _mostrarOpcionesGrupo(
    BuildContext context,
    GrupoDistribuidorDb g,
  ) {
    return showActionSheet(
      context,
      title: 'Acciones',
      actions: [
        SheetAction(
          icon: Icons.info_outline,
          label: 'Ver detalles',
          onTap: () => _mostrarDetalles(context, g),
        ),
        if (!g.deleted)
          SheetAction(
            icon: Icons.edit,
            label: 'Editar',
            onTap: () => _abrirFormularioEdicion(context, g),
          ),
        // Aquí puedes añadir activar/desactivar o eliminar suave si lo deseas
      ],
    );
  }

  void _mostrarDetalles(BuildContext context, GrupoDistribuidorDb g) {
    showDetailsDialog(
      context,
      title: 'Detalles del grupo',
      fields: {
        'UID': g.uid,
        'Nombre': g.nombre,
        'Abreviatura': g.abreviatura.isNotEmpty ? g.abreviatura : '—',
        'Notas': g.notas.isNotEmpty ? g.notas : '—',
        'Activo': g.activo ? 'Sí' : 'No',
        'Synced': g.isSynced ? 'Sí' : 'No',
        'Creado': g.createdAt.toLocal().toString(),
        'Actualizado': g.updatedAt.toLocal().toString(),
        'Eliminado': g.deleted ? 'Sí' : 'No',
      },
    );
  }

  Future<void> _abrirFormularioEdicion(
    BuildContext context,
    GrupoDistribuidorDb g,
  ) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GrupoDistribuidorFormPage(grupoEditar: g),
      ),
    );

    if (resultado == true && widget.onActualizado != null) {
      widget.onActualizado!();
    }
  }
}

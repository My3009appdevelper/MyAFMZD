import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/screens/distribuidores/distribuidores_form_page.dart';
import 'package:myafmzd/widgets/sheet_action.dart';
import 'package:myafmzd/widgets/show_detail_dialog.dart';

class DistribuidorItemTile extends ConsumerStatefulWidget {
  final DistribuidorDb distribuidor;
  final VoidCallback onTap;
  final VoidCallback? onActualizado;

  const DistribuidorItemTile({
    super.key,
    required this.distribuidor,
    required this.onTap,
    this.onActualizado,
  });

  @override
  ConsumerState<DistribuidorItemTile> createState() =>
      _DistribuidorItemTileState();
}

class _DistribuidorItemTileState extends ConsumerState<DistribuidorItemTile> {
  @override
  Widget build(BuildContext context) {
    // Obtener versión “viva” desde el provider (por si cambió el estado)
    final d = ref
        .watch(distribuidoresProvider)
        .firstWhere(
          (x) => x.uid == widget.distribuidor.uid,
          orElse: () => widget.distribuidor,
        );

    return ListTile(
      key: ValueKey(d.uid),
      leading: const Icon(Icons.location_city),
      title: Text(d.nombre),
      subtitle: Text(d.direccion),
      trailing: d.activo
          ? const Icon(Icons.check_circle, color: Colors.green)
          : const Icon(Icons.cancel, color: Colors.grey),
      onTap: widget.onTap,
      onLongPress: () => _mostrarOpcionesDistribuidor(context, d),
    );
  }

  Future<void> _mostrarOpcionesDistribuidor(
    BuildContext context,
    DistribuidorDb d,
  ) {
    return showActionSheet(
      context,
      title: 'Acciones',
      actions: [
        SheetAction(
          icon: Icons.info_outline,
          label: 'Ver detalles',
          onTap: () => _mostrarDetalles(context, d),
        ),
        SheetAction(
          icon: Icons.edit,
          label: 'Editar',
          onTap: () => _abrirFormularioEdicion(context, d),
        ),
        // aquí luego puedes añadir Eliminar / Activar/Desactivar sin tocar los otros
      ],
    );
  }

  void _mostrarDetalles(BuildContext context, DistribuidorDb d) {
    showDetailsDialog(
      context,
      title: 'Detalles del distribuidor',
      fields: {
        'UID': d.uid,
        'Nombre': d.nombre,
        'Grupo': d.grupo,
        'Dirección': d.direccion,
        'Coordenadas': '${d.latitud}, ${d.longitud}',
        'Activo': d.activo ? 'Sí' : 'No',
        'Synced': d.isSynced ? 'Sí' : 'No',
        'Actualizado': d.updatedAt.toLocal().toString(),
      },
    );
  }

  Future<void> _abrirFormularioEdicion(
    BuildContext context,
    DistribuidorDb d,
  ) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DistribuidorFormPage(distribuidorEditar: d),
      ),
    );

    if (resultado == true && widget.onActualizado != null) {
      widget.onActualizado!();
    }
  }
}

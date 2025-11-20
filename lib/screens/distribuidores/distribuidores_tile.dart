import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/database/grupo_distribuidores/grupos_distribuidores_provider.dart';
import 'package:myafmzd/screens/distribuidores/distribuidores_form_page.dart';
import 'package:myafmzd/widgets/my_sheet_action.dart';
import 'package:myafmzd/widgets/my_show_detail_dialog.dart';

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
    // Versión viva del distribuidor
    final d = ref
        .watch(distribuidoresProvider)
        .firstWhere(
          (x) => x.uid == widget.distribuidor.uid,
          orElse: () => widget.distribuidor,
        );

    // Buscar el grupo por UUID
    final grupo = ref
        .watch(gruposDistribuidoresProvider)
        .firstWhere(
          (g) => g.uid == d.uuidGrupo,
          orElse: () => GrupoDistribuidorDb(
            uid: d.uuidGrupo,
            nombre: d.uuidGrupo, // fallback: muestra el UUID si no se encuentra
            abreviatura: '',
            notas: '',
            activo: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            deleted: false,
            isSynced: true,
          ),
        );

    return ListTile(
      key: ValueKey(d.uid),
      leading: const Icon(Icons.location_city),
      title: Text(d.nombre),
      subtitle: Align(
        alignment: Alignment.centerLeft,
        child: Chip(
          label: Text(grupo.nombre, style: const TextStyle(fontSize: 12)),
          visualDensity: VisualDensity.compact,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
        ),
      ),
      trailing: d.activo
          ? const Icon(Icons.check_circle, color: Colors.green)
          : const Icon(Icons.cancel, color: Colors.grey),
      onTap: widget.onTap,
      onLongPress: () => _mostrarOpcionesDistribuidor(context, d, grupo),
    );
  }

  Future<void> _mostrarOpcionesDistribuidor(
    BuildContext context,
    DistribuidorDb d,
    GrupoDistribuidorDb grupo,
  ) {
    return showActionSheet(
      context,
      title: 'Acciones',
      actions: [
        SheetAction(
          icon: Icons.info_outline,
          label: 'Ver detalles',
          onTap: () => _mostrarDetalles(context, d, grupo),
        ),
        SheetAction(
          icon: Icons.edit,
          label: 'Editar',
          onTap: () => _abrirFormularioEdicion(context, d),
        ),
      ],
    );
  }

  void _mostrarDetalles(
    BuildContext context,
    DistribuidorDb d,
    GrupoDistribuidorDb grupo,
  ) {
    showDetailsDialog(
      context,
      title: 'Detalles del distribuidor',
      fields: {
        'UID': d.uid,
        'Nombre': d.nombre,
        'Grupo': grupo.nombre, // 👈 ahora muestra el nombre real
        'Dirección': d.direccion,
        'Estado': d.estado,
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

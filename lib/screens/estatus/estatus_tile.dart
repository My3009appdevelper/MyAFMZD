import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/estatus/estatus_provider.dart';
import 'package:myafmzd/screens/estatus/estatus_form_page.dart';
import 'package:myafmzd/widgets/my_sheet_action.dart';
import 'package:myafmzd/widgets/my_show_detail_dialog.dart';

class EstatusItemTile extends ConsumerStatefulWidget {
  final EstatusDb estatus;
  final VoidCallback onTap;
  final VoidCallback? onActualizado;

  const EstatusItemTile({
    super.key,
    required this.estatus,
    required this.onTap,
    this.onActualizado,
  });

  @override
  ConsumerState<EstatusItemTile> createState() => _EstatusItemTileState();
}

class _EstatusItemTileState extends ConsumerState<EstatusItemTile> {
  @override
  Widget build(BuildContext context) {
    // Versión “viva” desde provider (si no, usa la prop)
    final e = ref
        .watch(estatusProvider)
        .firstWhere(
          (x) => x.uid == widget.estatus.uid,
          orElse: () => widget.estatus,
        );

    final color = _parseColorHex(e.colorHex);
    final trailing = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (e.esCancelatorio)
          const Tooltip(
            message: 'Cancelatorio',
            child: Icon(Icons.block, color: Colors.redAccent),
          ),
        const SizedBox(width: 6),
        if (e.esFinal)
          const Tooltip(
            message: 'Final',
            child: Icon(Icons.flag, color: Colors.blueGrey),
          ),
        const SizedBox(width: 6),
        if (!e.visible)
          const Tooltip(
            message: 'Oculto',
            child: Icon(Icons.visibility_off, color: Colors.grey),
          ),
        const SizedBox(width: 6),
        // Indicador de color
        Tooltip(
          message: e.colorHex.isEmpty ? 'Sin color' : e.colorHex,
          child: CircleAvatar(
            radius: 10,
            backgroundColor: color ?? Colors.transparent,
            child: color == null
                ? const Icon(
                    Icons.palette_outlined,
                    size: 14,
                    color: Colors.grey,
                  )
                : null,
          ),
        ),
      ],
    );

    return ListTile(
      key: ValueKey(e.uid),
      leading: const Icon(Icons.label_important_outline),
      title: Text(e.nombre),
      subtitle: Wrap(
        spacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Chip(
            label: Text(e.categoria.isEmpty ? '—' : e.categoria),
            visualDensity: VisualDensity.compact,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          _OrdenBadge(orden: e.orden),
          if (e.icono.trim().isNotEmpty)
            Tooltip(
              message: 'Icono: ${e.icono}',
              child: const Icon(Icons.info_outline, size: 16),
            ),
        ],
      ),
      trailing: trailing,
      onTap: widget.onTap,
      onLongPress: () => _mostrarOpcionesEstatus(context, e),
    );
  }

  Future<void> _mostrarOpcionesEstatus(BuildContext context, EstatusDb e) {
    return showActionSheet(
      context,
      title: 'Acciones',
      actions: [
        SheetAction(
          icon: Icons.info_outline,
          label: 'Ver detalles',
          onTap: () => _mostrarDetalles(context, e),
        ),
        if (!e.deleted)
          SheetAction(
            icon: Icons.edit,
            label: 'Editar',
            onTap: () => _abrirFormularioEdicion(context, e),
          ),
      ],
    );
  }

  void _mostrarDetalles(BuildContext context, EstatusDb e) {
    showDetailsDialog(
      context,
      title: 'Detalles del estatus',
      fields: {
        'UID': e.uid,
        'Nombre': e.nombre,
        'Categoría': e.categoria.isNotEmpty ? e.categoria : '—',
        'Orden': e.orden.toString(),
        'Final': e.esFinal ? 'Sí' : 'No',
        'Cancelatorio': e.esCancelatorio ? 'Sí' : 'No',
        'Visible': e.visible ? 'Sí' : 'No',
        'Color HEX': e.colorHex.isNotEmpty ? e.colorHex : '—',
        'Icono': e.icono.isNotEmpty ? e.icono : '—',
        'Notas': e.notas.isNotEmpty ? e.notas : '—',
        'Synced': e.isSynced ? 'Sí' : 'No',
        'Eliminado': e.deleted ? 'Sí' : 'No',
        'Creado': e.createdAt.toLocal().toString(),
        'Actualizado': e.updatedAt.toLocal().toString(),
      },
    );
  }

  Future<void> _abrirFormularioEdicion(
    BuildContext context,
    EstatusDb e,
  ) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EstatusFormPage(estatusEditar: e)),
    );

    if (resultado == true && widget.onActualizado != null) {
      widget.onActualizado!();
    }
  }

  // -------------------- Helpers --------------------

  Color? _parseColorHex(String hex) {
    final h = hex.trim();
    if (h.isEmpty) return null;
    final raw = h.startsWith('#') ? h.substring(1) : h;
    final ok = RegExp(r'^[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$').hasMatch(raw);
    if (!ok) return null;
    // #RRGGBB or #RRGGBBAA → Flutter usa AARRGGBB
    if (raw.length == 6) {
      final val = int.parse('FF$raw', radix: 16);
      return Color(val);
    }
    final aarrggbb = raw.substring(6, 8) + raw.substring(0, 6); // AA + RRGGBB
    return Color(int.parse(aarrggbb, radix: 16));
  }
}

class _OrdenBadge extends StatelessWidget {
  const _OrdenBadge({required this.orden});
  final int orden;

  @override
  Widget build(BuildContext context) {
    final txt = orden.toString();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.surfaceVariant,
      ),
      child: Text('Orden: $txt', style: const TextStyle(fontSize: 12)),
    );
  }
}

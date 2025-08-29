// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/productos/productos_provider.dart';
import 'package:myafmzd/screens/productos/productos_form_page.dart';
import 'package:myafmzd/widgets/sheet_action.dart';
import 'package:myafmzd/widgets/show_detail_dialog.dart';

class ProductoItemTile extends ConsumerStatefulWidget {
  final ProductoDb producto;
  final VoidCallback onTap;
  final VoidCallback? onActualizado;

  const ProductoItemTile({
    super.key,
    required this.producto,
    required this.onTap,
    this.onActualizado,
  });

  @override
  ConsumerState<ProductoItemTile> createState() => _ProductoItemTileState();
}

class _ProductoItemTileState extends ConsumerState<ProductoItemTile> {
  @override
  Widget build(BuildContext context) {
    // Tomar versión actualizada desde provider (por si cambió en sync)
    final p = ref
        .watch(productosProvider)
        .firstWhere(
          (x) => x.uid == widget.producto.uid,
          orElse: () => widget.producto,
        );

    final vigente = _estaVigente(p);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      key: ValueKey(p.uid),
      leading: Icon(
        Icons.calculate_rounded,
        color: vigente && p.activo ? colorScheme.primary : colorScheme.outline,
      ),
      title: Text(
        p.nombre,
        style: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Plazo: ${p.plazoMeses} meses · Entrega ${p.mesEntregaMin}-${p.mesEntregaMax} · Adelanto ${p.adelantoMinMens}-${p.adelantoMaxMens}',
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
          ),
          Text(
            'Adm: ${_pct(p.cuotaAdministracionPct)} (+IVA ${_pct(p.ivaCuotaAdministracionPct)})',
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
          ),
          Text(
            'Inscripción: ${_pct(p.cuotaInscripcionPct)}',
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
          ),
          Text(
            'Seguro de Vida: ${_pct(p.cuotaSeguroVidaPct)}',
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
          ),
          Text(
            'Factor integrante: ${_pct(p.factorIntegrante)}',
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
          ),
          Text(
            'Factor propietario: ${_pct(p.factorPropietario)}',
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
          ),

          // Línea 4: vigencia + sync
        ],
      ),
      isThreeLine: true,
      trailing: Icon(
        vigente && p.activo ? Icons.check_circle : Icons.cancel,
        color: vigente && p.activo ? Colors.green : Colors.grey,
      ),
      onTap: widget.onTap,
      onLongPress: () => _mostrarOpcionesProducto(context, p),
    );
  }

  String _pct(double v) => '${(v * 100).toStringAsFixed(2)}%';

  bool _estaVigente(ProductoDb p, {DateTime? fecha}) {
    if (p.deleted) return false;
    final f = (fecha ?? DateTime.now().toUtc());
    final desdeOk = p.vigenteDesde == null || !f.isBefore(p.vigenteDesde!);
    final hastaOk = p.vigenteHasta == null || !f.isAfter(p.vigenteHasta!);
    return desdeOk && hastaOk;
  }

  Future<void> _mostrarOpcionesProducto(BuildContext context, ProductoDb p) {
    return showActionSheet(
      context,
      title: 'Acciones',
      actions: [
        SheetAction(
          icon: Icons.info_outline,
          label: 'Ver detalles',
          onTap: () => _mostrarDetalles(context, p),
        ),
        SheetAction(
          icon: Icons.edit,
          label: 'Editar',
          onTap: () => _abrirFormularioEdicion(context, p),
        ),
      ],
    );
  }

  void _mostrarDetalles(BuildContext context, ProductoDb p) {
    showDetailsDialog(
      context,
      title: 'Detalles del producto',
      fields: {
        'UID': p.uid,
        'Nombre': p.nombre,
        'Activo': p.activo ? 'Sí' : 'No',
        'Plazo (meses)': p.plazoMeses.toString(),
        'Factor integrante': p.factorIntegrante.toString(),
        'Factor propietario': p.factorPropietario.toString(),
        'Inscripción (%)': _pct(p.cuotaInscripcionPct),
        'Administración (%)': _pct(p.cuotaAdministracionPct),
        'IVA Adm. (%)': _pct(p.ivaCuotaAdministracionPct),
        'Seguro vida (%)': _pct(p.cuotaSeguroVidaPct),
        'Notas': p.notas.isNotEmpty ? p.notas : '—',
        'Vigente desde': p.vigenteDesde?.toLocal().toString() ?? '—',
        'Synced': p.isSynced ? 'Sí' : 'No',
        'Creado': p.createdAt.toLocal().toString(),
        'Actualizado': p.updatedAt.toLocal().toString(),
        'Eliminado': p.deleted ? 'Sí' : 'No',
      },
    );
  }

  Future<void> _abrirFormularioEdicion(
    BuildContext context,
    ProductoDb p,
  ) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ProductoFormPage(productoEditar: p)),
    );

    if (resultado == true && widget.onActualizado != null) {
      widget.onActualizado!(); // dispara un refresh externo si lo necesitas
    }
  }
}

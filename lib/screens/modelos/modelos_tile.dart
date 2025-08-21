import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/modelos/modelos_provider.dart';
import 'package:myafmzd/screens/modelos/modelos_form_page.dart';
import 'package:myafmzd/widgets/sheet_action.dart';
import 'package:myafmzd/widgets/show_detail_dialog.dart';

class ModeloItemTile extends ConsumerStatefulWidget {
  final ModeloDb modelo;
  final VoidCallback onTap;
  final VoidCallback? onActualizado;

  const ModeloItemTile({
    super.key,
    required this.modelo,
    required this.onTap,
    this.onActualizado,
  });

  @override
  ConsumerState<ModeloItemTile> createState() => _ModeloItemTileState();
}

class _ModeloItemTileState extends ConsumerState<ModeloItemTile> {
  bool _descargando = false;

  @override
  Widget build(BuildContext context) {
    // Versión “viva” del modelo desde el provider (por si cambió al sincronizar)
    final modeloActual = ref
        .watch(modelosProvider)
        .firstWhere(
          (x) => x.uid == widget.modelo.uid,
          orElse: () => widget.modelo,
        );

    final existeFichaLocal =
        modeloActual.fichaRutaLocal.isNotEmpty &&
        File(modeloActual.fichaRutaLocal).existsSync();

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return ListTile(
      key: ValueKey(modeloActual.uid),
      leading: const Icon(Icons.directions_car),
      title: Text(
        '${modeloActual.modelo} ${modeloActual.anio}',
        style: textTheme.bodyLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${modeloActual.tipo} · ${modeloActual.transmision} · ${modeloActual.descripcion.isNotEmpty ? modeloActual.descripcion : '—'}',
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            'Precio lista: \$${_fmtPrecio(modeloActual.precioBase)} · Clave: ${modeloActual.claveCatalogo.isNotEmpty ? modeloActual.claveCatalogo : '—'}',
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      isThreeLine: true,
      trailing: SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: _descargando
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : existeFichaLocal
              ? IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Eliminar ficha local',
                  onPressed: () async {
                    setState(() => _descargando = true);
                    await ref
                        .read(modelosProvider.notifier)
                        .eliminarFichaLocal(modeloActual);
                    setState(() => _descargando = false);
                  },
                )
              : IconButton(
                  icon: const Icon(Icons.cloud_download),
                  tooltip: 'Descargar ficha técnica',
                  onPressed: () async {
                    setState(() => _descargando = true);
                    final actualizado = await ref
                        .read(modelosProvider.notifier)
                        .descargarFicha(modeloActual);
                    setState(() => _descargando = false);
                    if (actualizado != null && widget.onActualizado != null) {
                      widget.onActualizado!();
                    }
                  },
                ),
        ),
      ),
      onTap: widget.onTap,
      onLongPress: () => _mostrarOpcionesModelo(context, modeloActual),
    );
  }

  String _fmtPrecio(double v) {
    // Formateo simple sin dependencia de intl (000,000)
    final s = v.toStringAsFixed(0);
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final pos = s.length - i;
      buf.write(s[i]);
      if (pos > 1 && pos % 3 == 1) buf.write(',');
    }
    // El algoritmo anterior inserta comas después de cada grupo al revés; más simple:
    final rev = s.split('').reversed.toList();
    final chunks = <String>[];
    for (var i = 0; i < rev.length; i += 3) {
      chunks.add(rev.sublist(i, (i + 3).clamp(0, rev.length)).join());
    }
    return chunks
        .map((c) => c.split('').reversed.join())
        .toList()
        .reversed
        .join(',');
  }

  Future<void> _mostrarOpcionesModelo(BuildContext context, ModeloDb m) {
    return showActionSheet(
      context,
      title: 'Acciones',
      actions: [
        SheetAction(
          icon: Icons.info_outline,
          label: 'Ver detalles',
          onTap: () => _mostrarDetalles(context, m),
        ),
        SheetAction(
          icon: Icons.edit,
          label: 'Editar',
          onTap: () => _abrirFormularioEdicion(context, m),
        ),
      ],
    );
  }

  void _mostrarDetalles(BuildContext context, ModeloDb m) {
    showDetailsDialog(
      context,
      title: 'Detalles del modelo',
      fields: {
        'UID': m.uid,
        'Marca': m.marca,
        'Modelo': m.modelo,
        'Año': m.anio.toString(),
        'Tipo': m.tipo,
        'Transmisión': m.transmision,
        'Descripción': m.descripcion.isNotEmpty ? m.descripcion : '—',
        'Clave catálogo': m.claveCatalogo.isNotEmpty ? m.claveCatalogo : '—',
        'Activo': m.activo ? 'Sí' : 'No',
        'Precio base': '\$${_fmtPrecio(m.precioBase)}',
        'Ficha remota': m.fichaRutaRemota.isNotEmpty ? m.fichaRutaRemota : '—',
        'Ficha local': m.fichaRutaLocal.isNotEmpty ? m.fichaRutaLocal : '—',
        'Synced': m.isSynced ? 'Sí' : 'No',
        'Creado': m.createdAt.toLocal().toString(),
        'Actualizado': m.updatedAt.toLocal().toString(),
        'Eliminado': m.deleted ? 'Sí' : 'No',
      },
    );
  }

  Future<void> _abrirFormularioEdicion(BuildContext context, ModeloDb m) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ModelosFormPage(modeloEditar: m)),
    );

    if (resultado == true && widget.onActualizado != null) {
      widget.onActualizado!();
    }
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/modelos/modelo_imagenes_provider.dart';
import 'package:myafmzd/database/modelos/modelos_provider.dart';
import 'package:myafmzd/screens/modelos/modelos_form_page.dart';
import 'package:myafmzd/widgets/my_sheet_action.dart';
import 'package:myafmzd/widgets/my_show_detail_dialog.dart';

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
  @override
  Widget build(BuildContext context) {
    final modeloActual = ref
        .watch(modelosProvider)
        .firstWhere(
          (x) => x.uid == widget.modelo.uid,
          orElse: () => widget.modelo,
        );

    // obtener cover
    final cover = ref
        .read(modeloImagenesProvider.notifier)
        .coverOrFallback(modeloActual.uid);

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return InkWell(
      onTap: widget.onTap,
      onLongPress: () => _mostrarOpcionesModelo(context, modeloActual),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: colorScheme.surfaceContainerHighest,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
          image: cover != null && cover.rutaLocal.isNotEmpty
              ? DecorationImage(
                  image: FileImage(File(cover.rutaLocal)),
                  fit: BoxFit.cover,
                  colorFilter: ColorFilter.mode(
                    Colors.black.withOpacity(0.35),
                    BlendMode.darken,
                  ),
                )
              : null,
        ),
        child: Stack(
          children: [
            // Texto principal
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${modeloActual.modelo} · ${modeloActual.descripcion}',
                      style: textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        shadows: [
                          Shadow(
                            color: Colors.black.withOpacity(0.7),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${modeloActual.tipo} · ${modeloActual.transmision}',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Precio lista: \$${_fmtPrecio(modeloActual.precioBase)}',
                          style: textTheme.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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

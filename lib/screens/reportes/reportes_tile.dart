import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/reportes/reportes_provider.dart';
import 'package:myafmzd/screens/reportes/reportes_form_page.dart';
import 'package:myafmzd/widgets/my_sheet_action.dart';
import 'package:myafmzd/widgets/my_show_detail_dialog.dart';

class ReporteItemTile extends ConsumerStatefulWidget {
  final ReportesDb reporte;
  final VoidCallback onTap;
  final VoidCallback? onActualizado; // o ValueChanged<String>

  const ReporteItemTile({
    super.key,
    required this.reporte,
    required this.onTap,
    this.onActualizado,
  });

  @override
  ConsumerState<ReporteItemTile> createState() => _ReporteItemTileState();
}

class _ReporteItemTileState extends ConsumerState<ReporteItemTile> {
  Uint8List? _thumbnail;
  bool _descargando = false;

  @override
  void initState() {
    super.initState();
    _cargarMiniatura();
  }

  @override
  void didUpdateWidget(covariant ReporteItemTile oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 🔁 Si la ruta local cambió → recargar miniatura
    if (widget.reporte.rutaLocal != oldWidget.reporte.rutaLocal) {
      _cargarMiniatura();
    }
  }

  /// 📌 Llama al provider para obtener/generar miniatura
  Future<void> _cargarMiniatura() async {
    final notifier = ref.read(reporteProvider.notifier);

    final bytes = await notifier.obtenerMiniatura(widget.reporte);
    if (bytes != null && mounted) {
      setState(() => _thumbnail = bytes);
    } else {}
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(reporteProvider.notifier);

    // ✅ Buscar versión actualizada del reporte en Provider
    final reporteActual = ref
        .watch(reporteProvider)
        .firstWhere(
          (r) => r.uid == widget.reporte.uid,
          orElse: () => widget.reporte,
        );

    final existePDFLocal =
        reporteActual.rutaLocal.isNotEmpty &&
        File(reporteActual.rutaLocal).existsSync();

    return ListTile(
      leading: _thumbnail != null
          ? Image.memory(_thumbnail!, width: 50, fit: BoxFit.contain)
          : const SizedBox(
              width: 50,
              child: Center(child: Icon(Icons.picture_as_pdf)),
            ),

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
              : existePDFLocal
              ? IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Eliminar este reporte',
                  onPressed: () async {
                    setState(() => _descargando = true);

                    await notifier.eliminarPDF(reporteActual);

                    setState(() {
                      _descargando = false;
                    });
                  },
                )
              : IconButton(
                  icon: const Icon(Icons.cloud_download),
                  tooltip: 'Descargar este reporte',
                  onPressed: () async {
                    setState(() => _descargando = true);

                    final actualizado = await ref
                        .read(reporteProvider.notifier)
                        .descargarPDF(reporteActual);

                    setState(() => _descargando = false);

                    // ✅ Generar miniatura nueva desde PDF local
                    if (actualizado != null && widget.onActualizado != null) {
                      widget.onActualizado!();
                    }
                  },
                ),
        ),
      ),

      title: Text(reporteActual.nombre),
      subtitle: Text(
        '${reporteActual.fecha.year}-${reporteActual.fecha.month.toString().padLeft(2, '0')}',
      ),
      onTap: widget.onTap,
      onLongPress: () {
        _mostrarOpcionesReporte(context, reporteActual);
      },
    );
  }

  Future<void> _mostrarOpcionesReporte(BuildContext context, ReportesDb r) {
    return showActionSheet(
      context,
      title: 'Acciones',
      actions: [
        SheetAction(
          icon: Icons.info_outline,
          label: 'Ver detalles',
          onTap: () => _mostrarDetalles(context, r),
        ),
        SheetAction(
          icon: Icons.edit,
          label: 'Editar',
          onTap: () => _abrirFormularioEdicion(context, r),
        ),
      ],
    );
  }

  void _mostrarDetalles(BuildContext context, ReportesDb r) {
    showDetailsDialog(
      context,
      title: 'Detalles de reporte',
      fields: {
        'UID': r.uid,
        'Nombre': r.nombre,
        'Fecha': r.fecha.toIso8601String(),
        'Tipo': r.tipo,
        'Local': r.rutaLocal.isNotEmpty ? 'Sí' : 'No',
        'Synced': r.isSynced ? 'Sí' : 'No',
        'Actualizado': r.updatedAt.toLocal().toString(),
      },
    );
  }

  void _abrirFormularioEdicion(BuildContext context, ReportesDb reporte) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReporteFormPage(reporteEditar: reporte),
      ),
    );

    if (resultado == true && widget.onActualizado != null) {
      widget.onActualizado!();
    }
  }
}

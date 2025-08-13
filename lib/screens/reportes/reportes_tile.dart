import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/reportes/reportes_provider.dart';
import 'package:myafmzd/screens/reportes/reportes_form_page.dart';

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
      print(
        '[🧾 MENSAJES REPORTES TILE] 📌 Ruta local actualizada, recargando miniatura...',
      );
      _cargarMiniatura();
    }
  }

  /// 📌 Llama al provider para obtener/generar miniatura
  Future<void> _cargarMiniatura() async {
    final notifier = ref.read(reporteProvider.notifier);
    print(
      '[🧾 MENSAJES REPORTES TILE] Cargando miniatura: ${widget.reporte.nombre}',
    );
    final bytes = await notifier.obtenerMiniatura(widget.reporte);
    if (bytes != null && mounted) {
      print(
        '[🧾 MENSAJES REPORTES TILE] ✅ Miniatura lista para: ${widget.reporte.uid}',
      );
      setState(() => _thumbnail = bytes);
    } else {
      print(
        '[🧾 MENSAJES REPORTES TILE] ⚠️ No se pudo generar miniatura: ${widget.reporte.uid}',
      );
    }
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

    final existeLocal =
        reporteActual.rutaLocal.isNotEmpty &&
        File(reporteActual.rutaLocal).existsSync();

    return ListTile(
      leading: _thumbnail != null
          ? Image.memory(_thumbnail!, width: 50, fit: BoxFit.cover)
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
              : existeLocal
              ? IconButton(
                  icon: const Icon(Icons.delete_outline),
                  tooltip: 'Eliminar este reporte',
                  onPressed: () async {
                    setState(() => _descargando = true);

                    print(
                      '[🧾 MENSAJES REPORTES TILE] Eliminando PDF: ${reporteActual.uid}',
                    );
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

                    print(
                      '[🧾 MENSAJES REPORTES TILE] Descargando PDF: ${reporteActual.uid}',
                    );
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

  void _mostrarOpcionesReporte(BuildContext context, ReportesDb reporte) async {
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(
          runSpacing: 12,
          children: [
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Ver detalles'),
              onTap: () {
                Navigator.pop(context);
                _mostrarDetalles(context, reporte);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Editar'),
              onTap: () {
                Navigator.pop(context);
                _abrirFormularioEdicion(context, reporte);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDetalles(BuildContext context, ReportesDb r) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Detalles de reporte'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('UID: ${r.uid}'),
            Text('Nombre: ${r.nombre}'),
            Text('Fecha: ${r.fecha.toIso8601String()}'),
            Text('Tipo: ${r.tipo}'),
            Text('Local: ${r.rutaLocal.isNotEmpty ? "Sí" : "No"}'),
            Text('Synced: ${r.isSynced ? "Sí" : "No"}'),
            Text('Actualizado: ${(r.updatedAt.toLocal().toString())}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Cerrar'),
          ),
        ],
      ),
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
      widget.onActualizado!(); // para actualizar miniatura o estado
    }
  }
}

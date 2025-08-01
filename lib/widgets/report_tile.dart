import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/reportes/reportes_provider.dart';

class ReporteItemTile extends ConsumerStatefulWidget {
  final ReportesDb reporte;
  final VoidCallback onTap;
  final bool downloading;
  final VoidCallback? onActualizado; // o ValueChanged<String>

  const ReporteItemTile({
    super.key,
    required this.reporte,
    required this.onTap,
    this.downloading = false,
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

  /// 📌 Llama al provider para obtener/generar miniatura
  Future<void> _cargarMiniatura() async {
    final notifier = ref.read(reporteProvider.notifier);
    print('[🖼️ TILE] Cargando miniatura: ${widget.reporte.nombre}');
    final bytes = await notifier.obtenerMiniatura(widget.reporte);
    if (bytes != null && mounted) {
      print('[🖼️ TILE] ✅ Miniatura lista para: ${widget.reporte.uid}');
      setState(() => _thumbnail = bytes);
    } else {
      print(
        '[🖼️ TILE] ⚠️ No se pudo generar miniatura: ${widget.reporte.uid}',
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
          child: _descargando && widget.downloading
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

                    print('[🗑️ TILE] Eliminando PDF: ${reporteActual.uid}');
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

                    print('[⬇️ TILE] Descargando PDF: ${reporteActual.uid}');
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
    );
  }
}

import 'package:flutter/material.dart';
import 'package:myafmzd/services/reporte_firebase_service.dart';
import 'package:pdfx/pdfx.dart';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:myafmzd/models/reporte_pdf_model.dart';

class ReporteItemTile extends StatefulWidget {
  final ReportePdf reporte;
  final VoidCallback onTap;
  final void Function() onChanged;
  final bool downloading;

  const ReporteItemTile({
    super.key,
    required this.reporte,
    required this.onTap,
    required this.onChanged,
    this.downloading = false,
  });

  @override
  State<ReporteItemTile> createState() => _ReporteItemTileState();
}

class _ReporteItemTileState extends State<ReporteItemTile> {
  PdfPageImage? _thumbnail;
  bool _descargando = false;

  // 🧠 Cache estático compartido entre instancias
  static final Map<String, PdfPageImage> _miniaturaCache = {};

  @override
  void initState() {
    super.initState();
    _cargarMiniatura();
  }

  Future<void> _cargarMiniatura() async {
    // 🧠 Si ya está en cache, usarla directamente
    if (_miniaturaCache.containsKey(widget.reporte.nombre)) {
      setState(() => _thumbnail = _miniaturaCache[widget.reporte.nombre]);
      return;
    }

    try {
      File? tempFile;

      if (widget.reporte.rutaLocal != null &&
          widget.reporte.rutaLocal!.startsWith('/')) {
        tempFile = File(widget.reporte.rutaLocal!);
      } else if (widget.reporte.rutaLocal != null) {
        final data = await rootBundle.load(widget.reporte.rutaLocal!);
        final tempDir = await getTemporaryDirectory();
        tempFile = File(
          '${tempDir.path}/${widget.reporte.nombre.hashCode}.pdf',
        );
        await tempFile.writeAsBytes(data.buffer.asUint8List(), flush: true);
      } else {
        tempFile = await ReporteFirebaseService().descargarTemporal(
          widget.reporte.rutaRemota,
        );
      }

      if (tempFile == null || !await tempFile.exists()) return;

      final doc = await PdfDocument.openFile(tempFile.path);
      final page = await doc.getPage(1);
      final image = await page.render(width: 110, height: 80);
      await page.close();

      setState(() {
        _thumbnail = image;
        _miniaturaCache[widget.reporte.nombre] = image!;
      });
    } catch (e) {
      debugPrint("❌ Error cargando miniatura: $e");
    }
  }

  Future<bool> _archivoExiste(String? path) async {
    if (path == null) return false;
    return File(path).exists();
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: _thumbnail != null
          ? Image.memory(_thumbnail!.bytes, width: 50, fit: BoxFit.cover)
          : const SizedBox(
              width: 50,
              child: Center(child: Icon(Icons.picture_as_pdf)),
            ),

      trailing: FutureBuilder<bool>(
        future: _archivoExiste(widget.reporte.rutaLocal),
        builder: (context, snapshot) {
          final existe = snapshot.data ?? false;

          return SizedBox(
            width: 40,
            height: 40,
            child: Center(
              child: _descargando || widget.downloading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : existe
                  ? IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Eliminar este reporte',
                      onPressed: () async {
                        await ReporteFirebaseService().eliminarDescarga(
                          widget.reporte.rutaRemota,
                        );

                        final path = widget.reporte.rutaLocal;
                        if (path != null && await File(path).exists()) {
                          try {
                            await File(path).delete();
                          } catch (_) {}
                        }

                        setState(() => widget.reporte.rutaLocal = null);
                        widget.onChanged(); // Notifica al padre

                        final messenger = ScaffoldMessenger.of(context);
                        messenger.hideCurrentSnackBar();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('🗑️ Reporte eliminado'),
                          ),
                        );
                      },
                    )
                  : IconButton(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.cloud_download),
                      tooltip: 'Descargar este reporte',
                      onPressed: () async {
                        setState(() => _descargando = true);

                        final file = await ReporteFirebaseService()
                            .descargarYGuardar(
                              widget.reporte.rutaRemota,
                              tipo: widget.reporte.tipo,
                            );

                        if (!mounted) return;

                        setState(() {
                          _descargando = false;
                          if (file != null)
                            widget.reporte.rutaLocal = file.path;
                          widget.onChanged(); // Notifica al padre
                        });

                        final messenger = ScaffoldMessenger.of(context);
                        messenger.hideCurrentSnackBar();
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(
                              file != null
                                  ? '📥 Reporte descargado'
                                  : '❌ Error al descargar',
                            ),
                          ),
                        );
                      },
                    ),
            ),
          );
        },
      ),

      title: Text(widget.reporte.nombre),
      subtitle: Text(
        '${widget.reporte.fecha.year}-${widget.reporte.fecha.month.toString().padLeft(2, '0')}',
      ),
      onTap: widget.onTap,
    );
  }
}

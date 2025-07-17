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

  const ReporteItemTile({
    super.key,
    required this.reporte,
    required this.onTap,
  });

  @override
  State<ReporteItemTile> createState() => _ReporteItemTileState();
}

class _ReporteItemTileState extends State<ReporteItemTile> {
  PdfPageImage? _thumbnail;

  @override
  void initState() {
    super.initState();
    _cargarMiniatura();
  }

  Future<void> _cargarMiniatura() async {
    try {
      File? tempFile;

      if (widget.reporte.rutaLocal != null &&
          widget.reporte.rutaLocal!.startsWith('/')) {
        // Es archivo local (descargado de Firebase)
        tempFile = File(widget.reporte.rutaLocal!);
      } else if (widget.reporte.rutaLocal != null) {
        // Es un asset
        final data = await rootBundle.load(widget.reporte.rutaLocal!);
        final tempDir = await getTemporaryDirectory();
        tempFile = File(
          '${tempDir.path}/${widget.reporte.nombre.hashCode}.pdf',
        );
        await tempFile.writeAsBytes(data.buffer.asUint8List(), flush: true);
      }

      if (tempFile == null || !await tempFile.exists()) return;

      final doc = await PdfDocument.openFile(tempFile.path);
      final page = await doc.getPage(1);
      final image = await page.render(width: 110, height: 80);
      await page.close();

      setState(() {
        _thumbnail = image;
      });
    } catch (e) {
      debugPrint("❌ Error cargando miniatura: $e");
    }
  }

  Future<bool> _archivoExiste(String? path) async {
    if (path == null) return false;
    final file = File(path);
    return await file.exists();
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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SizedBox(width: 24, height: 24);
          }

          final existe = snapshot.data ?? false;

          return existe
              ? const Icon(Icons.check_circle, color: Colors.green)
              : IconButton(
                  icon: const Icon(Icons.cloud_download),
                  onPressed: () async {
                    final file = await ReporteFirebaseService()
                        .descargarYGuardar(widget.reporte.rutaRemota);

                    if (file != null) {
                      setState(() {
                        widget.reporte.rutaLocal = file.path;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('📥 Reporte descargado')),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('❌ Error al descargar')),
                      );
                    }
                  },
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

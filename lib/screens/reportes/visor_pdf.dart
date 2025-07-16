import 'package:flutter/material.dart';
import 'package:myafmzd/models/reporte_pdf_model.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

class VisorPdfScreen extends StatelessWidget {
  final ReportePdf reporte;

  const VisorPdfScreen({super.key, required this.reporte});

  @override
  Widget build(BuildContext context) {
    final rutaParaFlutter = reporte.rutaLocal.replaceFirst('assets/', '');

    print(rutaParaFlutter);
    return Scaffold(
      appBar: AppBar(title: Text(reporte.nombre)),
      body: SfPdfViewer.asset(
        rutaParaFlutter,
        canShowScrollHead: false,
        canShowScrollStatus: false,
        enableDoubleTapZooming: true,
        enableDocumentLinkAnnotation: true,
        enableTextSelection: true,
        pageSpacing: 0.0,
      ),
    );
  }
}

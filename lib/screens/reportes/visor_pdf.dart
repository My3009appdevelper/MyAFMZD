import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class VisorPDF extends StatefulWidget {
  final String assetPath; // Ruta local o asset

  const VisorPDF({super.key, required this.assetPath});

  @override
  State<VisorPDF> createState() => _VisorPDFState();
}

class _VisorPDFState extends State<VisorPDF> {
  late final PdfControllerPinch _pdfController;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfControllerPinch(document: _abrirDocumento());
  }

  Future<PdfDocument> _abrirDocumento() {
    if (widget.assetPath.startsWith('/')) {
      return PdfDocument.openFile(widget.assetPath);
    } else {
      return PdfDocument.openAsset(widget.assetPath);
    }
  }

  @override
  void dispose() {
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visor PDF')),
      body: PdfViewPinch(
        controller: _pdfController,
        onDocumentLoaded: (doc) {
          debugPrint('✅ PDF cargado (${doc.pagesCount} páginas)');
        },
        onDocumentError: (error) {
          debugPrint('❌ Error cargando PDF: $error');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error al abrir el PDF')),
          );
        },
        onPageChanged: (page) {
          debugPrint('📄 Página actual: $page');
        },
      ),
    );
  }
}

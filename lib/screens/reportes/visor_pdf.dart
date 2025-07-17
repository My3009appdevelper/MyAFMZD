import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

class VisorPDF extends StatefulWidget {
  final String assetPath; // puede ser asset o ruta local

  const VisorPDF({super.key, required this.assetPath});

  @override
  State<VisorPDF> createState() => _VisorPDFState();
}

class _VisorPDFState extends State<VisorPDF> {
  late final PdfControllerPinch _pdfController;

  @override
  void initState() {
    super.initState();

    if (widget.assetPath.startsWith('/')) {
      _pdfController = PdfControllerPinch(
        document: PdfDocument.openFile(widget.assetPath),
      );
    } else {
      _pdfController = PdfControllerPinch(
        document: PdfDocument.openAsset(widget.assetPath),
      );
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
        onDocumentLoaded: (doc) {},
        onPageChanged: (page) {},
      ),
    );
  }
}

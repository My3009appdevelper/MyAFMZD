import 'dart:io' show File, Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

class VisorPDF extends StatefulWidget {
  final String assetPath;
  final String titulo;
  const VisorPDF({super.key, required this.assetPath, required this.titulo});

  @override
  State<VisorPDF> createState() => _VisorPDFState();
}

class _VisorPDFState extends State<VisorPDF> {
  final _controller = PdfViewerController();
  int _page = 1;
  int _total = 0;
  bool _cargando = true;
  bool _esArchivoLocal = false;

  bool get _isDesktop =>
      !kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  @override
  void initState() {
    super.initState();
    // Decidir una vez si es archivo local (rápido y sync: ya tienes la ruta)
    _esArchivoLocal = !kIsWeb && File(widget.assetPath).existsSync();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorsScheme = Theme.of(context).colorScheme;

    // Elegimos constructor sin FutureBuilder; la decisión ya se tomó en initState
    final viewer = _esArchivoLocal
        ? PdfViewer.file(
            widget.assetPath,
            controller: _controller,
            params: _params(colorsScheme),
            initialPageNumber: _page,
          )
        : PdfViewer.asset(
            widget.assetPath,
            controller: _controller,
            params: _params(colorsScheme),
            initialPageNumber: _page,
          );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.titulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: _isDesktop
            ? [
                IconButton(
                  tooltip: 'Ajustar a página',
                  icon: const Icon(Icons.fit_screen),
                  onPressed: () async {
                    if (!_controller.isReady) return;
                    final m = _controller.calcMatrixForFit(
                      pageNumber: _controller.pageNumber ?? 1,
                    );
                    if (m != null) {
                      await _controller.goTo(m);
                    }
                  },
                ),
                IconButton(
                  tooltip: 'Alejar',
                  icon: const Icon(Icons.zoom_out),
                  onPressed: () => _controller.zoomDown(), // API oficial
                ),
                IconButton(
                  tooltip: 'Acercar',
                  icon: const Icon(Icons.zoom_in),
                  onPressed: () => _controller.zoomUp(), // API oficial
                ),
                const SizedBox(width: 4),
              ]
            : null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'Anterior',
                  icon: Icon(Icons.chevron_left, color: colorsScheme.onPrimary),
                  onPressed: (_page > 1)
                      ? () => _controller.goToPage(pageNumber: _page - 1)
                      : null,
                ),

                // DESKTOP: slider + contador al centro
                if (_isDesktop) ...[
                  Expanded(
                    child: Slider(
                      activeColor: colorsScheme.secondary,
                      thumbColor: colorsScheme.secondary,
                      value: _page
                          .clamp(1, _total == 0 ? 1 : _total)
                          .toDouble(),
                      min: 1,
                      max: (_total > 0 ? _total : 1).toDouble(),
                      onChanged: (v) =>
                          _controller.goToPage(pageNumber: v.round()),
                    ),
                  ),
                  Text(
                    _total > 0 ? '$_page / $_total' : '$_page / ?',
                    style: TextStyle(color: colorsScheme.onPrimary),
                  ),
                ],
                // MÓVIL: solo contador compacto (el slider suele sobrar en pantallas chicas)
                if (!_isDesktop)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      _total > 0 ? '$_page / $_total' : '$_page / ?',
                      style: TextStyle(color: colorsScheme.onPrimary),
                    ),
                  ),

                // Página siguiente
                IconButton(
                  tooltip: 'Siguiente',
                  icon: Icon(
                    Icons.chevron_right,
                    color: colorsScheme.onPrimary,
                  ),
                  onPressed: (_total > 0 && _page < _total)
                      ? () => _controller.goToPage(pageNumber: _page + 1)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Positioned.fill(child: viewer),
          if (_cargando)
            Container(
              color: colorsScheme.surface,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation(colorsScheme.primary),
                ),
              ),
            ),
        ],
      ),
    );
  }

  PdfViewerParams _params(ColorScheme colors) {
    return PdfViewerParams(
      // ✅ Señales de carga estables: apagamos overlay cuando el visor está listo
      onViewerReady: (doc, ctrl) {
        if (mounted) {
          setState(() {
            _total = ctrl.pageCount;
            _page = ctrl.pageNumber ?? 1;
            _cargando = false;
          });
        }
      },

      // Si el documento cambia (p.ej., reintento o relayout), ajusta la UI
      onDocumentChanged: (doc) {
        // Si vuelve a cargar, muestra overlay; si quedó cargado, apágalo
        if (mounted && _cargando) {
          setState(() => _cargando = false);
        }
      },

      // ✅ Paginación
      onPageChanged: (page) {
        if (page != null && mounted) setState(() => _page = page);
      },

      // ✅ Render scale: deja el valor por defecto en móvil; sube (ligero) en desktop
      getPageRenderingScale: (ctx, page, ctrl, estimated) {
        if (_isDesktop) {
          final v = (estimated * 1.4);
          return v < 1.0 ? 1.0 : (v > 4.0 ? 4.0 : v);
        }
        return estimated;
      },

      // ✅ Banners nativos (sin setState dentro del build del banner)
      loadingBannerBuilder: (context, received, total) {
        // No tocamos _cargando aquí; solo mostramos un indicador pequeño arriba
        return const SizedBox.shrink();
      },
      errorBannerBuilder: (context, error, stack, docRef) {
        // No apagamos el overlay aquí; lo hacemos por onDocumentChanged
        final msg = error is PdfException ? error.message : error.toString();
        return Material(
          color: Colors.transparent,
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.90),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Text(
                      'No se pudo abrir el PDF.\n$msg',
                      style: const TextStyle(color: Colors.white),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },

      // ✅ UX
      scrollByMouseWheel: _isDesktop ? 0.28 : null,
      scrollHorizontallyByMouseWheel: false,
      enableKeyboardNavigation: true,

      minScale: 0.10,
      maxScale: 8.0,

      // ✅ Apariencia
      backgroundColor: colors.surface,
      pageDropShadow: BoxShadow(
        color: colors.shadow.withOpacity(0.25),
        blurRadius: 4,
        spreadRadius: 1,
        offset: const Offset(2, 2),
      ),

      // Opcionales para reducir picos de memoria/parpadeo en móviles muy justos:
      // limitRenderingCache: true,
      // maxImageBytesCachedOnMemory: 60 * 1024 * 1024, // 60MB
    );
  }
}

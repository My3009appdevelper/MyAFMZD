import 'package:flutter/material.dart';
import 'package:loader_overlay/loader_overlay.dart';

class MyLoaderOverlay extends StatelessWidget {
  final Widget child;

  const MyLoaderOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LoaderOverlay(
      useDefaultLoading: false,
      overlayColor: Colors.black.withOpacity(0.35),
      overlayWidgetBuilder: (dynamic progress) {
        final String msg = (progress is String && progress.isNotEmpty)
            ? progress
            : 'Procesando…';

        return Center(
          // Accesibilidad: región viva para lectores de pantalla
          child: Semantics(
            container: true,
            liveRegion: true,
            label: 'Cargando',
            value: msg,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 140, maxWidth: 260),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 12),
                      Text(
                        msg,
                        style: theme.textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }
}

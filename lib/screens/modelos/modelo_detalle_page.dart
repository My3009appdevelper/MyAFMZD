import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/modelos/modelo_imagenes_provider.dart';
import 'package:myafmzd/database/modelos/modelos_provider.dart';
import 'package:myafmzd/screens/modelos/cotizar_screen.dart';
import 'package:myafmzd/widgets/my_elevated_button.dart';
import 'package:myafmzd/widgets/visor_pdf.dart';

class ModeloDetallePage extends ConsumerWidget {
  final String modeloUid;
  const ModeloDetallePage({super.key, required this.modeloUid});

  // Helper local para precio 000,000
  String _fmtPrecio(double v) {
    final s = v.toStringAsFixed(0);
    final rev = s.split('').reversed.toList();
    final chunks = <String>[];
    for (var i = 0; i < rev.length; i += 3) {
      chunks.add(rev.sublist(i, (i + 3).clamp(0, rev.length)).join());
    }
    return chunks
        .map((c) => c.split('').reversed.join())
        .toList()
        .reversed
        .join(',');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final modelo = ref
        .watch(modelosProvider)
        .firstWhere(
          (m) => m.uid == modeloUid,
          orElse: () => throw Exception("Modelo no encontrado"),
        );

    final cover = ref
        .read(modeloImagenesProvider.notifier)
        .coverOrFallback(modeloUid);

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    Future<void> _abrirFicha() async {
      final notifier = ref.read(modelosProvider.notifier);
      ModeloDb? actualizado;

      // Mostrar overlay
      if (context.mounted) {
        context.loaderOverlay.show(progress: 'Abriendo ficha…');
      }

      try {
        // 1) Intentar abrir local
        if (modelo.fichaRutaLocal.isNotEmpty &&
            File(modelo.fichaRutaLocal).existsSync()) {
          actualizado = modelo;
        } else if (modelo.fichaRutaRemota.isNotEmpty) {
          // 2) Descargar si no existe local
          if (context.mounted && context.loaderOverlay.visible) {
            context.loaderOverlay.progress('Descargando PDF…');
          }
          actualizado = await notifier.descargarFicha(modelo);
        }

        // 3) Validar y navegar
        if (actualizado != null &&
            actualizado.fichaRutaLocal.isNotEmpty &&
            File(actualizado.fichaRutaLocal).existsSync()) {
          // Oculta overlay ANTES de navegar (consistente con tus Screens)
          if (context.mounted && context.loaderOverlay.visible) {
            context.loaderOverlay.hide();
          }
          if (context.mounted) {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VisorPDF(
                  assetPath: actualizado!.fichaRutaLocal,
                  titulo: '${modelo.modelo} ${modelo.anio}',
                ),
              ),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Ficha técnica no disponible')),
            );
          }
        }
      } finally {
        // Seguridad: por si saliste por excepciones sin alcanzar el hide previo
        if (context.mounted && context.loaderOverlay.visible) {
          context.loaderOverlay.hide();
        }
      }
    }

    // Estilos de etiqueta/valor (negritas para etiqueta, normal para valor)
    final labelStyle = tt.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: cs.onSurface,
    );
    final valueStyle = tt.titleMedium?.copyWith(
      fontWeight: FontWeight.w400,
      color: cs.onSurface,
    );
    final subInfoStyle = tt.bodyLarge?.copyWith(
      color: cs.secondary,
      fontWeight: FontWeight.w500,
    );

    return Scaffold(
      appBar: AppBar(title: Text(modelo.modelo), centerTitle: true),
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Imagen de portada
          if (cover != null &&
              cover.rutaLocal.isNotEmpty &&
              File(cover.rutaLocal).existsSync())
            Image.file(
              File(cover.rutaLocal),
              fit: BoxFit.cover,
              height: 220,
              width: double.infinity,
              filterQuality: FilterQuality.high,
            )
          else
            Container(
              height: 220,
              color: Colors.grey[300],
              child: const Center(child: Icon(Icons.directions_car, size: 80)),
            ),

          const SizedBox(height: 16),

          // Datos importantes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Título principal
                Text(
                  '${modelo.modelo} ${modelo.descripcion}',
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),

                const SizedBox(height: 8),
                Text(
                  '${modelo.tipo} · ${modelo.transmision}',
                  style: subInfoStyle,
                ),

                const SizedBox(height: 12),

                // Precio: etiqueta en bold, valor normal
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(text: 'Precio lista: ', style: labelStyle),
                      TextSpan(
                        text: '\$${_fmtPrecio(modelo.precioBase)}',
                        style: valueStyle?.copyWith(color: cs.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Botones de acción (Wrap para respuesta en móvil/escritorio)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                // MyElevatedButton (ancho adaptable)
                SizedBox(
                  width: 280, // se adapta en Wrap; en móvil cae a nueva línea
                  child: MyElevatedButton(
                    icon: Icons.request_quote,
                    label: 'Cotizar',
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CotizadorScreen(modelo: modelo),
                        ),
                      );
                    },
                  ),
                ),

                // Outlined (PDF) – mismo alto
                SizedBox(
                  width: 280,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text("Ver ficha técnica"),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: _abrirFicha,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:myafmzd/database/app_database.dart';

class DistribuidorPopup extends StatelessWidget {
  final DistribuidorDb distribuidor;

  const DistribuidorPopup({super.key, required this.distribuidor});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final d = distribuidor;

    // Tamaño fijo integrado (sin parámetros externos)
    const double width = 260;
    const double maxHeight = 130;

    return SizedBox(
      width: width,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: maxHeight),
        child: Card(
          margin: const EdgeInsets.all(8),
          elevation: 6,
          color: cs.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: cs.primary.withOpacity(0.6)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título
                  Row(
                    children: [
                      Icon(Icons.store, color: cs.primary, size: 14),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          d.nombre,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),

                  // Dirección
                  Text(
                    d.direccion,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: cs.onSurface, fontSize: 10),
                  ),
                  const SizedBox(height: 4),

                  // Estado
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Icon(
                        d.activo ? Icons.check_circle : Icons.cancel,
                        color: d.activo ? Colors.green : Colors.red,
                        size: 12,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        d.activo ? 'Activo' : 'Inactivo',
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                          color: d.activo ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

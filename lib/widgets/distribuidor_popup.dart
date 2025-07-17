import 'package:flutter/material.dart';
import 'package:myafmzd/models/distribuidor_model.dart';

class DistribuidorPopup extends StatelessWidget {
  final Distribuidor distribuidor;

  const DistribuidorPopup({super.key, required this.distribuidor});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final d = distribuidor;

    return Card(
      margin: const EdgeInsets.all(8),
      elevation: 6,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: colorScheme.primary.withOpacity(0.6)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.store, color: colorScheme.primary, size: 14),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    d.nombre,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    d.direccion,
                    style: TextStyle(
                      color: colorScheme.onSurface,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),

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
                    fontSize: 8,
                    color: d.activo ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

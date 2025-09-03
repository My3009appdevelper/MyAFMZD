import 'package:flutter/material.dart';

Future<void> showDetailsDialog(
  BuildContext context, {
  required String title,
  required Map<String, String> fields,
}) async {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;
  final tt = theme.textTheme;

  return showDialog(
    context: context,
    builder: (dialogCtx) => AlertDialog(
      title: Text(
        title,
        style: tt.titleMedium?.copyWith(
          color: cs.onSurface,
          fontWeight: FontWeight.w600,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: fields.entries.map((e) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${e.key}: ',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextSpan(
                      text: e.value,
                      style: tt.bodyMedium?.copyWith(color: cs.onSurface),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogCtx).pop(),
          child: const Text('Cerrar'),
        ),
      ],
    ),
  );
}

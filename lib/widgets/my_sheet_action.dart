import 'package:flutter/material.dart';

class SheetAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const SheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

Future<void> showActionSheet(
  BuildContext context, {
  String? title,
  required List<SheetAction> actions,
}) async {
  final theme = Theme.of(context);
  final cs = theme.colorScheme;

  await showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                ...actions.map(
                  (a) => ListTile(
                    leading: Icon(a.icon, color: cs.primary),
                    title: Text(
                      a.label,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: cs.onSurface,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(ctx); // cierra el sheet
                      // corre la acción al cerrar el sheet
                      Future.microtask(a.onTap);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

import 'package:flutter/material.dart';

class MyElevatedButton extends StatelessWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;

  const MyElevatedButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyle = theme.textTheme.labelLarge;

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: colorScheme.onPrimary),
      label: Text(
        label,
        style: textStyle?.copyWith(color: colorScheme.onPrimary),
      ),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        backgroundColor: colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ).merge(theme.elevatedButtonTheme.style),
    );
  }
}

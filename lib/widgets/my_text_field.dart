import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final bool showClearButton;
  final VoidCallback? onClear;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onSubmitted;

  const MyTextField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    this.showClearButton = false,
    this.onClear,
    this.textInputAction = TextInputAction.search,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textStyle = theme.textTheme.bodyLarge;

    return TextField(
      controller: controller,
      textInputAction: textInputAction,
      style: textStyle?.copyWith(color: colorScheme.onSurface),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        labelStyle: textStyle?.copyWith(color: colorScheme.onSurface),
        prefixIcon: const Icon(Icons.search),
        suffixIcon: showClearButton
            ? IconButton(
                tooltip: 'Limpiar búsqueda',
                icon: const Icon(Icons.clear),
                onPressed: onClear,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: colorScheme.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        filled: true,
        fillColor: Colors.transparent,
        isDense: true,
      ),
      onSubmitted: onSubmitted,
    );
  }
}

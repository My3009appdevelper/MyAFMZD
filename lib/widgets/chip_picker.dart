import 'package:flutter/material.dart';

class ChipPickerSingle extends StatefulWidget {
  final String label;
  final List<String> options;
  final String selected;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String> onSelected;
  final ValueChanged<String>? onAddNew;

  const ChipPickerSingle({
    super.key,
    required this.label,
    required this.options,
    required this.selected,
    required this.onSelected,
    this.validator,
    this.onAddNew,
  });

  @override
  State<ChipPickerSingle> createState() => _ChipPickerSingleState();
}

class _ChipPickerSingleState extends State<ChipPickerSingle> {
  // padding unificado para que todas queden del mismo alto
  static const _kLabelPadding = EdgeInsets.symmetric(
    horizontal: 8,
    vertical: 4,
  );

  late String _current;

  @override
  void initState() {
    super.initState();
    _current = widget.selected;
  }

  @override
  void didUpdateWidget(covariant ChipPickerSingle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != _current) _current = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final labelStyle = textTheme.labelLarge;

    return FormField<String>(
      initialValue: widget.selected,
      validator: widget.validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      builder: (state) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(widget.label, style: textTheme.labelLarge),
            ),

            // Caja a todo el ancho con borde sutil
            Container(
              width: double.infinity, // 👈 ocupa todo el ancho disponible
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.20),
                  width: 1,
                ),
              ),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final opt in widget.options)
                    ChoiceChip(
                      label: Text(
                        opt,
                        style: labelStyle?.copyWith(
                          color: _current == opt
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurface,
                        ),
                      ),
                      selected: _current == opt,
                      onSelected: (_) {
                        setState(() => _current = opt);
                        state.didChange(opt);
                        widget.onSelected(opt);
                      },
                      showCheckmark: false, // 👈 sin palomita
                      side: BorderSide(
                        // borde siempre visible
                        color: colorScheme.outlineVariant.withOpacity(0.45),
                        width: 1,
                      ),
                      shape: const StadiumBorder(),
                      labelPadding: _kLabelPadding, // 👈 altura consistente
                      padding: EdgeInsets.zero,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      elevation: 0,
                      pressElevation: 0,
                      backgroundColor: colorScheme.surface,
                      selectedColor: colorScheme.primaryContainer,
                    ),

                  // “Agregar…” centrado, mismo alto que ChoiceChip (usa el mismo _kLabelPadding)
                  Tooltip(
                    message: 'Agregar ${widget.label.toLowerCase()}',
                    child: ActionChip(
                      // OJO: el icono va en label (no en avatar) para que quede centrado
                      label: Icon(
                        Icons.add,
                        size:
                            18, // 16–18 mantiene la altura pareja con texto + padding
                        color: colorScheme.onSecondaryContainer,
                      ),
                      onPressed: () async {
                        final nuevo = await showDialog<String>(
                          context: context,
                          builder: (ctx) {
                            final c = TextEditingController();
                            return AlertDialog(
                              title: Text(
                                'Agregar ${widget.label.toLowerCase()}',
                              ),
                              content: TextField(
                                controller: c,
                                autofocus: true,
                                textInputAction: TextInputAction.done,
                                decoration: const InputDecoration(
                                  hintText: 'Escribe aquí',
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancelar'),
                                ),
                                FilledButton(
                                  onPressed: () {
                                    final v = c.text.trim();
                                    if (v.isEmpty) return;
                                    Navigator.pop(ctx, v);
                                  },
                                  child: const Text('Agregar'),
                                ),
                              ],
                            );
                          },
                        );
                        if (nuevo != null) {
                          widget.onAddNew?.call(nuevo);
                          setState(() => _current = nuevo);
                          state.didChange(nuevo);
                          widget.onSelected(nuevo);
                        }
                      },

                      // Mismo look & feel que tus ChoiceChip
                      labelPadding: _kLabelPadding, // 👈 misma altura
                      side: BorderSide(
                        color: colorScheme.outlineVariant.withOpacity(0.45),
                        width: 1,
                      ),
                      shape: const StadiumBorder(),
                      backgroundColor: colorScheme.secondaryContainer,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      elevation: 0,
                      pressElevation: 0,
                      // (sin avatar, sin showCheckmark)
                    ),
                  ),
                ],
              ),
            ),

            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  state.errorText!,
                  style: TextStyle(color: colorScheme.error, fontSize: 12),
                ),
              ),
          ],
        );
      },
    );
  }
}

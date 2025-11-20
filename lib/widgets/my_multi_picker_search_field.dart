import 'package:flutter/material.dart';

typedef ItemAsString<T extends Object> = String Function(T item);
typedef CompareFn<T extends Object> = bool Function(T a, T b);

class MyMultiPickerSearchField<T extends Object> extends StatefulWidget {
  const MyMultiPickerSearchField({
    super.key,
    required this.items,
    required this.itemAsString,
    required this.compareFn,
    this.initialValues,
    this.onChanged,
    this.labelText,
    this.hintText,
    this.enabled = true,
    this.clearable = true,
    this.validator,
    this.autovalidateMode = AutovalidateMode.disabled,
    this.bottomSheetTitle,
    this.emptyText = 'Sin resultados',
    this.searchHintText = 'Buscar...',
    this.sheetHeightFactor = 0.7,
    this.selectedTextBuilder,
  });

  final List<T> items;
  final ItemAsString<T> itemAsString;
  final CompareFn<T> compareFn;

  /// Valores seleccionados inicialmente
  final List<T>? initialValues;

  /// Callback con la lista completa seleccionada
  final ValueChanged<List<T>>? onChanged;

  final String? labelText, hintText;
  final bool enabled, clearable;

  /// Validador sobre la lista completa
  final String? Function(List<T>)? validator;
  final AutovalidateMode autovalidateMode;

  final String? bottomSheetTitle;
  final String emptyText;
  final String searchHintText;
  final double sheetHeightFactor;

  /// Permite personalizar el texto mostrado en el TextFormField
  /// a partir de la lista seleccionada. Si es null, se usa uno por defecto.
  final String Function(List<T>)? selectedTextBuilder;

  @override
  State<MyMultiPickerSearchField<T>> createState() =>
      _MyMultiPickerSearchFieldState<T>();
}

class _MyMultiPickerSearchFieldState<T extends Object>
    extends State<MyMultiPickerSearchField<T>> {
  late final TextEditingController _textCtrl;
  final FocusNode _focusNode = FocusNode();
  List<T> _selected = [];
  FormFieldState<List<T>>? _formState;

  @override
  void initState() {
    super.initState();
    _selected = List<T>.from(widget.initialValues ?? const []);
    _textCtrl = TextEditingController(text: _buildSelectedLabel(_selected));
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // Normaliza para búsqueda y comparación: minúsculas + sin tildes
  String _fold(String s) {
    var out = s.toLowerCase();
    const repl = {
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'â': 'a',
      'ã': 'a',
      'é': 'e',
      'è': 'e',
      'ë': 'e',
      'ê': 'e',
      'í': 'i',
      'ì': 'i',
      'ï': 'i',
      'î': 'i',
      'ó': 'o',
      'ò': 'o',
      'ö': 'o',
      'ô': 'o',
      'õ': 'o',
      'ú': 'u',
      'ù': 'u',
      'ü': 'u',
      'û': 'u',
      'ñ': 'n',
      'ç': 'c',
    };
    repl.forEach((k, v) => out = out.replaceAll(k, v));
    out = out.replaceAll(RegExp(r'\s+'), ' ').trim();
    return out;
  }

  String _buildSelectedLabel(List<T> items) {
    if (widget.selectedTextBuilder != null) {
      return widget.selectedTextBuilder!(items);
    }
    if (items.isEmpty) return '';
    if (items.length <= 3) {
      return items.map(widget.itemAsString).join(', ');
    }
    final primeros = items.take(2).map(widget.itemAsString).join(', ');
    final resto = items.length - 2;
    return '$primeros +$resto más';
  }

  bool _listContains(List<T> list, T item) {
    return list.any((e) => widget.compareFn(e, item));
  }

  List<T> _addOrRemove(List<T> list, T item) {
    final copy = List<T>.from(list);
    final idx = copy.indexWhere((e) => widget.compareFn(e, item));
    if (idx >= 0) {
      copy.removeAt(idx);
    } else {
      copy.add(item);
    }
    return copy;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final txt = theme.textTheme.bodyLarge;

    return FormField<List<T>>(
      initialValue: _selected,
      autovalidateMode: widget.autovalidateMode,
      validator: (value) => widget.validator?.call(value ?? const []),
      builder: (state) {
        _formState = state;
        return TextFormField(
          controller: _textCtrl,
          focusNode: _focusNode,
          readOnly: true,
          enabled: widget.enabled,
          style: txt?.copyWith(color: cs.onSurface),
          decoration: InputDecoration(
            labelText: widget.labelText,
            labelStyle: txt?.copyWith(color: cs.onSurface),
            hintText: widget.hintText,
            filled: true,
            fillColor: Colors.transparent,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: cs.primary.withOpacity(0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: cs.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: cs.error),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: cs.error, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            errorText: state.errorText,
            suffixIcon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.clearable && _selected.isNotEmpty)
                  IconButton(
                    tooltip: 'Limpiar',
                    icon: const Icon(Icons.clear),
                    onPressed: !widget.enabled
                        ? null
                        : () {
                            setState(() {
                              _selected = [];
                              _textCtrl.clear();
                            });
                            _formState?.didChange(_selected);
                            Form.maybeOf(context)?.validate();
                            widget.onChanged?.call(_selected);
                            _focusNode.unfocus();
                          },
                  ),
                IconButton(
                  tooltip: 'Elegir',
                  icon: const Icon(Icons.arrow_drop_down),
                  onPressed: !widget.enabled ? null : _openSheet,
                ),
              ],
            ),
          ),
          onTap: !widget.enabled ? null : _openSheet,
        );
      },
    );
  }

  Future<void> _openSheet() async {
    final ctx = context;
    final theme = Theme.of(ctx);
    final height = MediaQuery.of(ctx).size.height * widget.sheetHeightFactor;

    final result = await showModalBottomSheet<List<T>>(
      context: ctx,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        final searchCtrl = TextEditingController();
        final query = ValueNotifier<String>('');
        // Copia local para ir marcando checks sin afectar hasta Aceptar
        List<T> tempSelected = List<T>.from(_selected);

        List<T> filtered(String q) {
          final t = _fold(q);
          if (t.isEmpty) return widget.items;
          return widget.items.where((e) {
            final label = widget.itemAsString(e);
            return _fold(label).contains(t);
          }).toList();
        }

        return StatefulBuilder(
          builder: (context, setModalState) {
            return SizedBox(
              height: height,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            widget.bottomSheetTitle ??
                                (widget.labelText ?? 'Selecciona'),
                            style: theme.textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Cerrar',
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: searchCtrl,
                      onChanged: (v) {
                        query.value = v;
                        setModalState(() {});
                      },
                      decoration: InputDecoration(
                        hintText: widget.searchHintText,
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ValueListenableBuilder<String>(
                        valueListenable: query,
                        builder: (_, q, __) {
                          final data = filtered(q);
                          if (data.isEmpty) {
                            return Center(
                              child: Text(
                                widget.emptyText,
                                style: theme.textTheme.bodyMedium,
                              ),
                            );
                          }
                          return ListView.separated(
                            itemCount: data.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (_, i) {
                              final item = data[i];
                              final isSel = _listContains(tempSelected, item);
                              return CheckboxListTile(
                                value: isSel,
                                title: Text(widget.itemAsString(item)),
                                onChanged: (_) {
                                  setModalState(() {
                                    tempSelected = _addOrRemove(
                                      tempSelected,
                                      item,
                                    );
                                  });
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () {
                            setModalState(() {
                              tempSelected = [];
                            });
                          },
                          child: const Text('Limpiar'),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, tempSelected);
                          },
                          child: const Text('Aceptar'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (!mounted || result == null) return;

    setState(() {
      _selected = List<T>.from(result);
      _textCtrl.text = _buildSelectedLabel(_selected);
      _textCtrl.selection = TextSelection.collapsed(
        offset: _textCtrl.text.length,
      );
      _focusNode.unfocus();
    });
    _formState?.didChange(_selected);
    Form.maybeOf(ctx)?.validate();
    widget.onChanged?.call(_selected);
  }
}

// lib/widgets/my_picker_search_field.dart
import 'package:flutter/material.dart';

typedef ItemAsString<T extends Object> = String Function(T item);
typedef CompareFn<T extends Object> = bool Function(T a, T b);

class MyPickerSearchField<T extends Object> extends StatefulWidget {
  const MyPickerSearchField({
    super.key,
    required this.items,
    required this.itemAsString,
    required this.compareFn,
    this.initialValue,
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
  });

  final List<T> items;
  final ItemAsString<T> itemAsString;
  final CompareFn<T> compareFn;

  final T? initialValue;
  final ValueChanged<T?>? onChanged;

  final String? labelText, hintText;
  final bool enabled, clearable;
  final String? Function(T?)? validator;
  final AutovalidateMode autovalidateMode;

  final String? bottomSheetTitle;
  final String emptyText;
  final String searchHintText;
  final double sheetHeightFactor;

  @override
  State<MyPickerSearchField<T>> createState() => _MyPickerSearchFieldState<T>();
}

class _MyPickerSearchFieldState<T extends Object>
    extends State<MyPickerSearchField<T>> {
  late final TextEditingController _textCtrl;
  final FocusNode _focusNode = FocusNode();
  T? _selected;
  FormFieldState<T?>? _formState;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValue;
    _textCtrl = TextEditingController(
      text: _selected != null ? widget.itemAsString(_selected as T) : '',
    );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final txt = theme.textTheme.bodyLarge;

    return FormField<T?>(
      initialValue: _selected,
      autovalidateMode: widget.autovalidateMode,
      validator: widget.validator,
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
                if (widget.clearable && _selected != null)
                  IconButton(
                    tooltip: 'Limpiar',
                    icon: const Icon(Icons.clear),
                    onPressed: !widget.enabled
                        ? null
                        : () {
                            setState(() => _selected = null);
                            _textCtrl.clear();
                            _formState?.didChange(null);
                            Form.maybeOf(context)?.validate();
                            widget.onChanged?.call(null);
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

    final result = await showModalBottomSheet<T>(
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

        List<T> filtered(String q) {
          final t = _fold(q);
          if (t.isEmpty) return widget.items;
          return widget.items.where((e) {
            final label = widget.itemAsString(e);
            return _fold(label).contains(t);
          }).toList();
        }

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
                  onChanged: (v) => query.value = v,
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
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, i) {
                          final item = data[i];
                          final isSel =
                              _selected != null &&
                              widget.compareFn(_selected as T, item);
                          return ListTile(
                            title: Text(widget.itemAsString(item)),
                            trailing: isSel ? const Icon(Icons.check) : null,
                            onTap: () => Navigator.pop(context, item),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || result == null) return;

    setState(() {
      _selected = result;
      _textCtrl.text = widget.itemAsString(result);
      _textCtrl.selection = TextSelection.collapsed(
        offset: _textCtrl.text.length,
      );
      _focusNode.unfocus();
    });
    _formState?.didChange(result);
    Form.maybeOf(ctx)?.validate();
    widget.onChanged?.call(result);
  }
}

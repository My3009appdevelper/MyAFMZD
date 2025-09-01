// ignore_for_file: avoid_print

import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/asignaciones_laborales/asignaciones_laborales_provider.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_provider.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';

import 'package:myafmzd/widgets/my_elevated_button.dart';
import 'package:myafmzd/widgets/my_text_form_field.dart';

class AsignacionLaboralFormPage extends ConsumerStatefulWidget {
  final AsignacionLaboralDb? asignacionEditar;
  final String? preColaboradorUid;
  final String? preDistribuidorUid;

  const AsignacionLaboralFormPage({
    super.key,
    this.asignacionEditar,
    this.preColaboradorUid,
    this.preDistribuidorUid,
  });

  @override
  ConsumerState<AsignacionLaboralFormPage> createState() =>
      _AsignacionLaboralFormPageState();
}

class _AsignacionLaboralFormPageState
    extends ConsumerState<AsignacionLaboralFormPage> {
  final _formKey = GlobalKey<FormState>();

  late final bool _esEdicion;

  String? _colaboradorUidSel;
  String _distribuidorUidSel = '';
  String _managerUidSel = '';
  String _rolSel = 'vendedor';
  String _nivelSel = '';
  DateTime _fechaInicio = DateTime.now();
  DateTime? _fechaFin;

  late TextEditingController _puestoCtrl;
  late TextEditingController _notasCtrl;

  // Listas locales
  List<ColaboradorDb> get _colaboradores =>
      ref.watch(colaboradoresProvider).where((c) => !c.deleted).toList()
        ..sort((a, b) => _nombreColab(a).compareTo(_nombreColab(b)));

  List<DistribuidorDb> get _distribuidores =>
      ref.watch(distribuidoresProvider).where((d) => !d.deleted).toList()
        ..sort((a, b) => a.nombre.compareTo(b.nombre));

  @override
  void initState() {
    super.initState();
    final a = widget.asignacionEditar;
    _esEdicion = a != null;

    _colaboradorUidSel = a?.colaboradorUid ?? widget.preColaboradorUid;
    _distribuidorUidSel = a?.distribuidorUid.isNotEmpty == true
        ? a!.distribuidorUid
        : (widget.preDistribuidorUid ?? '');
    _managerUidSel = a?.managerColaboradorUid ?? '';
    _rolSel = a?.rol ?? 'vendedor';
    _nivelSel = a?.nivel ?? '';

    _fechaInicio = a?.fechaInicio ?? DateTime.now().toUtc();
    _fechaFin = a?.fechaFin;

    _puestoCtrl = TextEditingController(text: a?.puesto ?? '');
    _notasCtrl = TextEditingController(text: a?.notas ?? '');
  }

  @override
  void dispose() {
    _puestoCtrl.dispose();
    _notasCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final _ = ref.watch(asignacionesLaboralesProvider);

    final notifier = ref.read(asignacionesLaboralesProvider.notifier);
    final roles = notifier.opcionesRol;
    final niveles = notifier.opcionesNivel;

    final colabInicial = _buscarColab(_colaboradorUidSel);
    final distInicial = _buscarDistribuidor(_distribuidorUidSel);
    final managerInicial = _buscarColab(_managerUidSel);

    // Estilos como en tu ejemplo
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final labelStyle = theme.textTheme.bodyLarge?.copyWith(
      color: colorScheme.onSurface,
    );

    final managerInicialSeguro = (managerInicial?.uid == _colaboradorUidSel)
        ? null
        : managerInicial;

    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar asignación' : 'Nueva asignación'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: ListView(
                children: [
                  // =================== Colaborador ====================
                  DropdownSearch<ColaboradorDb>(
                    selectedItem: colabInicial,
                    items: (String filtro, LoadProps? props) async {
                      final f = filtro.toLowerCase();
                      return _colaboradores
                          .where(
                            (c) => _nombreColab(c).toLowerCase().contains(f),
                          )
                          .toList();
                    },
                    itemAsString: (c) => _nombreColab(c),
                    compareFn: (a, b) => a.uid == b.uid,
                    onChanged: (value) {
                      setState(() {
                        _colaboradorUidSel = value?.uid;

                        // Si el manager actual es el mismo colaborador, límpialo
                        if (_managerUidSel.isNotEmpty &&
                            _managerUidSel == _colaboradorUidSel) {
                          _managerUidSel = '';
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'El colaborador no puede ser su propio manager. Se limpió la selección de manager.',
                              ),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      });
                    },

                    popupProps: const PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          hintText: 'Buscar colaborador...',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),

                    decoratorProps: DropDownDecoratorProps(
                      decoration: InputDecoration(
                        labelText: 'Colaborador *',
                        labelStyle: labelStyle,
                        filled: true,
                        fillColor: colorScheme.surface,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colorScheme.error),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: colorScheme.error,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                    ),
                    validator: (c) =>
                        c == null ? 'El colaborador es obligatorio' : null,
                  ),

                  const SizedBox(height: 12),

                  // =================== Distribuidor ===================
                  DropdownSearch<DistribuidorDb>(
                    selectedItem: distInicial,
                    items: (String filtro, LoadProps? props) async {
                      final f = filtro.toLowerCase();
                      return _distribuidores
                          .where((d) => d.nombre.toLowerCase().contains(f))
                          .toList();
                    },
                    itemAsString: (d) => d.nombre,
                    compareFn: (a, b) => a.uid == b.uid,
                    onChanged: (d) {
                      setState(() => _distribuidorUidSel = d?.uid ?? '');
                    },
                    popupProps: const PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          hintText: 'Buscar distribuidor...',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                    suffixProps: DropdownSuffixProps(
                      clearButtonProps: ClearButtonProps(
                        isVisible: _distribuidorUidSel.isNotEmpty,
                        tooltip: 'Quitar selección',
                      ),
                    ),
                    decoratorProps: DropDownDecoratorProps(
                      decoration: InputDecoration(
                        labelText: 'Distribuidor',
                        labelStyle: labelStyle,
                        filled: true,
                        fillColor: colorScheme.surface,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colorScheme.error),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: colorScheme.error,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // =================== Manager (opcional) ==============
                  DropdownSearch<ColaboradorDb>(
                    selectedItem: managerInicialSeguro,
                    items: (String filtro, LoadProps? props) async {
                      final f = filtro.toLowerCase();
                      return _colaboradores
                          .where(
                            (c) => c.uid != _colaboradorUidSel,
                          ) // ← excluye al mismo
                          .where(
                            (c) => _nombreColab(c).toLowerCase().contains(f),
                          )
                          .toList();
                    },

                    itemAsString: (c) => _nombreColab(c),
                    compareFn: (a, b) => a.uid == b.uid,
                    onChanged: (c) {
                      setState(() => _managerUidSel = c?.uid ?? '');
                    },
                    popupProps: const PopupProps.menu(
                      showSearchBox: true,
                      searchFieldProps: TextFieldProps(
                        decoration: InputDecoration(
                          hintText: 'Buscar manager...',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ),
                    suffixProps: DropdownSuffixProps(
                      clearButtonProps: ClearButtonProps(
                        isVisible: _managerUidSel.isNotEmpty,
                        tooltip: 'Quitar selección',
                      ),
                    ),
                    decoratorProps: DropDownDecoratorProps(
                      decoration: InputDecoration(
                        labelText: 'Manager directo',
                        labelStyle: labelStyle,
                        filled: true,
                        fillColor: colorScheme.surface,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: colorScheme.primary.withOpacity(0.3),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: colorScheme.primary,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: colorScheme.error),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: colorScheme.error,
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 14,
                        ),
                        suffixIcon: _managerUidSel.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Quitar selección',
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  setState(() {
                                    _managerUidSel = '';
                                  });
                                },
                              ),
                        suffixIconConstraints: const BoxConstraints(
                          minHeight: 24,
                          minWidth: 24,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // =================== Rol (chips) =====================
                  Text('Rol', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final r in roles)
                        ChoiceChip(
                          label: Text(r),
                          selected: _rolSel == r,
                          onSelected: (sel) => setState(() => _rolSel = r),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // =================== Nivel (dropdown simple) =========
                  DropdownButtonFormField<String>(
                    value: _nivelSel.isEmpty ? null : _nivelSel,
                    items: niveles
                        .map(
                          (n) => DropdownMenuItem(
                            value: n,
                            child: Text(n.isEmpty ? '—' : n),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _nivelSel = v ?? ''),
                    decoration: const InputDecoration(labelText: 'Nivel'),
                  ),
                  const SizedBox(height: 12),

                  // =================== Puesto ==========================
                  MyTextFormField(controller: _puestoCtrl, labelText: 'Puesto'),
                  const SizedBox(height: 12),

                  // =================== Fechas =========================
                  _tileFecha(
                    context: context,
                    etiqueta: 'Fecha inicio *',
                    valor: _fechaInicio,
                    onPick: () async {
                      final sel = await _pickFecha(
                        context: context,
                        initial: _fechaInicio,
                        first: DateTime(2000),
                        last: DateTime(2100),
                      );
                      if (sel != null) {
                        setState(
                          () => _fechaInicio = DateTime(
                            sel.year,
                            sel.month,
                            sel.day,
                          ),
                        );
                      }
                    },
                    onClear: null,
                  ),
                  const SizedBox(height: 6),
                  _tileFecha(
                    context: context,
                    etiqueta: 'Fecha fin',
                    valor: _fechaFin,
                    onPick: () async {
                      final base = _fechaFin ?? _fechaInicio;
                      final sel = await _pickFecha(
                        context: context,
                        initial: base,
                        first: _fechaInicio,
                        last: DateTime(2100),
                      );
                      if (sel != null) {
                        setState(
                          () => _fechaFin = DateTime(
                            sel.year,
                            sel.month,
                            sel.day,
                          ),
                        );
                      }
                    },
                    onClear: () => setState(() => _fechaFin = null),
                  ),
                  const SizedBox(height: 12),

                  // =================== Notas ==========================
                  MyTextFormField(controller: _notasCtrl, labelText: 'Notas'),

                  const SizedBox(height: 24),

                  // =================== Acciones =======================
                  Row(
                    children: [
                      Expanded(
                        child: MyElevatedButton(
                          icon: Icons.save,
                          label: 'Guardar',
                          onPressed: _guardar,
                        ),
                      ),
                      if (_esEdicion) const SizedBox(width: 12),
                      if (_esEdicion &&
                          widget.asignacionEditar?.fechaFin == null)
                        Expanded(
                          child: MyElevatedButton(
                            icon: Icons.lock_outline,
                            label: 'Cerrar ahora',
                            onPressed: _cerrarAhora,
                          ),
                        ),
                      if (_esEdicion &&
                          widget.asignacionEditar?.fechaFin != null)
                        Expanded(
                          child: MyElevatedButton(
                            icon: Icons.lock_open,
                            label: 'Reabrir',
                            onPressed: _reabrirAhora,
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

  // ============================ Acciones =============================

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    final asignNotifier = ref.read(asignacionesLaboralesProvider.notifier);
    final uidEditar = widget.asignacionEditar?.uid;
    final esEdicion = _esEdicion;

    if (_colaboradorUidSel == null || _colaboradorUidSel!.isEmpty) {
      _snack('❌ Debes seleccionar un colaborador');
      return;
    }
    if (_fechaFin != null && _fechaFin!.isBefore(_fechaInicio)) {
      _snack('❌ La fecha fin no puede ser anterior a la fecha inicio');
      return;
    }

    final traslapa = asignNotifier.tieneTraslapeEnRango(
      colaboradorUid: _colaboradorUidSel!,
      inicio: _fechaInicio,
      fin: _fechaFin,
      excluirUid: uidEditar,
    );
    if (traslapa) {
      _snack('❌ Existe una asignación traslapada/activa para este colaborador');
      return;
    }

    try {
      if (!esEdicion) {
        await asignNotifier.crearAsignacion(
          colaboradorUid: _colaboradorUidSel!,
          fechaInicio: _fechaInicio.toUtc(),
          fechaFin: _fechaFin?.toUtc(),
          distribuidorUid: _distribuidorUidSel,
          managerColaboradorUid: _managerUidSel,
          rol: _rolSel,
          puesto: _puestoCtrl.text.trim(),
          nivel: _nivelSel,
          createdByUsuarioUid: '',
          notas: _notasCtrl.text.trim(),
        );
        if (_managerUidSel.isNotEmpty && _managerUidSel == _colaboradorUidSel) {
          _snack('❌ El colaborador no puede ser su propio manager');
          return;
        }

        if (mounted) Navigator.pop(context, true);
        return;
      }

      final original = widget.asignacionEditar!;
      final originalFin = original.fechaFin;

      if (originalFin == null && _fechaFin != null) {
        await asignNotifier.cerrarAsignacion(
          uid: original.uid,
          closedByUsuarioUid: '',
          fechaFin: _fechaFin,
          notasAppend: null,
        );
      } else if (originalFin != null && _fechaFin == null) {
        await asignNotifier.reabrirAsignacion(uid: original.uid);
      }

      await asignNotifier.editarAsignacion(
        uid: original.uid,
        distribuidorUid: _distribuidorUidSel == original.distribuidorUid
            ? null
            : _distribuidorUidSel,
        managerColaboradorUid: _managerUidSel == original.managerColaboradorUid
            ? null
            : _managerUidSel,
        rol: _rolSel == original.rol ? null : _rolSel,
        puesto: _puestoCtrl.text.trim() == original.puesto
            ? null
            : _puestoCtrl.text.trim(),
        nivel: _nivelSel == original.nivel ? null : _nivelSel,
        fechaInicio: _mismoDia(_fechaInicio, original.fechaInicio)
            ? null
            : _fechaInicio,
        notas: _notasCtrl.text.trim() == original.notas
            ? null
            : _notasCtrl.text.trim(),
      );
      if (_managerUidSel.isNotEmpty && _managerUidSel == _colaboradorUidSel) {
        _snack('❌ El colaborador no puede ser su propio manager');
        return;
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _snack('❌ Error al guardar: $e');
    }
  }

  Future<void> _cerrarAhora() async {
    if (!_esEdicion) return;
    final a = widget.asignacionEditar!;
    final asignNotifier = ref.read(asignacionesLaboralesProvider.notifier);

    try {
      final fin = DateTime.now();
      await asignNotifier.cerrarAsignacion(
        uid: a.uid,
        closedByUsuarioUid: '',
        fechaFin: fin,
        notasAppend: null,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _snack('❌ No se pudo cerrar: $e');
    }
  }

  Future<void> _reabrirAhora() async {
    if (!_esEdicion) return;
    final a = widget.asignacionEditar!;
    final asignNotifier = ref.read(asignacionesLaboralesProvider.notifier);

    try {
      await asignNotifier.reabrirAsignacion(uid: a.uid);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _snack('❌ No se pudo reabrir: $e');
    }
  }

  // ============================ Helpers ==============================

  ColaboradorDb? _buscarColab(String? uid) {
    if (uid == null || uid.isEmpty) return null;
    try {
      return _colaboradores.firstWhere((c) => c.uid == uid);
    } catch (_) {
      return null;
    }
  }

  DistribuidorDb? _buscarDistribuidor(String? uid) {
    if (uid == null || uid.isEmpty) return null;
    try {
      return _distribuidores.firstWhere((d) => d.uid == uid);
    } catch (_) {
      return null;
    }
  }

  String _nombreColab(ColaboradorDb c) =>
      '${c.nombres} ${c.apellidoPaterno} ${c.apellidoMaterno}'
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

  Future<DateTime?> _pickFecha({
    required BuildContext context,
    required DateTime initial,
    required DateTime first,
    required DateTime last,
  }) async {
    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
  }

  Widget _tileFecha({
    required BuildContext context,
    required String etiqueta,
    required DateTime? valor,
    required VoidCallback onPick,
    required VoidCallback? onClear,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('$etiqueta: ${valor != null ? _fmtFecha(valor) : '—'}'),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (onClear != null && valor != null)
            IconButton(
              tooltip: 'Limpiar',
              icon: const Icon(Icons.clear),
              onPressed: onClear,
            ),
          IconButton(
            tooltip: 'Elegir fecha',
            icon: const Icon(Icons.calendar_month),
            onPressed: onPick,
          ),
        ],
      ),
    );
  }

  String _fmtFecha(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  bool _mismoDia(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

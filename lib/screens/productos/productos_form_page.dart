// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/productos/productos_provider.dart';
import 'package:myafmzd/widgets/my_elevated_button.dart';
import 'package:myafmzd/widgets/my_text_form_field.dart';

class ProductoFormPage extends ConsumerStatefulWidget {
  final ProductoDb? productoEditar;
  const ProductoFormPage({super.key, this.productoEditar});

  @override
  ConsumerState<ProductoFormPage> createState() => _ProductoFormPageState();
}

class _ProductoFormPageState extends ConsumerState<ProductoFormPage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nombreController;
  late TextEditingController _plazoController;
  late TextEditingController _factorIntController;
  late TextEditingController _factorPropController;
  late TextEditingController _inscripcionPctController;
  late TextEditingController _admPctController;
  late TextEditingController _ivaAdmPctController;
  late TextEditingController _seguroVidaPctController;
  late TextEditingController _adelantoMinController;
  late TextEditingController _adelantoMaxController;
  late TextEditingController _mesEntregaMinController;
  late TextEditingController _mesEntregaMaxController;
  late TextEditingController _prioridadController;
  late TextEditingController _notasController;
  bool _activo = true;
  bool _esEdicion = false;
  DateTime? _vigenteDesde;
  DateTime? _vigenteHasta;

  @override
  void initState() {
    super.initState();
    final p = widget.productoEditar;
    _esEdicion = p != null;

    _nombreController = TextEditingController(
      text: p?.nombre ?? 'Autofinanciamiento Puro',
    );
    _plazoController = TextEditingController(
      text: (p?.plazoMeses ?? 60).toString(),
    );
    _factorIntController = TextEditingController(
      text: (p?.factorIntegrante ?? 0.01667).toString(),
    );
    _factorPropController = TextEditingController(
      text: (p?.factorPropietario ?? 0.0206).toString(),
    );
    _inscripcionPctController = TextEditingController(
      text: (p?.cuotaInscripcionPct ?? 0.005).toString(),
    );
    _admPctController = TextEditingController(
      text: (p?.cuotaAdministracionPct ?? 0.002).toString(),
    );
    _ivaAdmPctController = TextEditingController(
      text: (p?.ivaCuotaAdministracionPct ?? 0.16).toString(),
    );
    _seguroVidaPctController = TextEditingController(
      text: (p?.cuotaSeguroVidaPct ?? 0.00065).toString(),
    );

    _adelantoMinController = TextEditingController(
      text: (p?.adelantoMinMens ?? 0).toString(),
    );
    _adelantoMaxController = TextEditingController(
      text: (p?.adelantoMaxMens ?? 59).toString(),
    );
    _mesEntregaMinController = TextEditingController(
      text: (p?.mesEntregaMin ?? 1).toString(),
    );
    _mesEntregaMaxController = TextEditingController(
      text: (p?.mesEntregaMax ?? 60).toString(),
    );

    _prioridadController = TextEditingController(
      text: (p?.prioridad ?? 0).toString(),
    );
    _notasController = TextEditingController(text: p?.notas ?? '');

    _activo = p?.activo ?? true;
    _vigenteDesde = p?.vigenteDesde;
    _vigenteHasta = p?.vigenteHasta;
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _plazoController.dispose();
    _factorIntController.dispose();
    _factorPropController.dispose();
    _inscripcionPctController.dispose();
    _admPctController.dispose();
    _ivaAdmPctController.dispose();
    _seguroVidaPctController.dispose();
    _adelantoMinController.dispose();
    _adelantoMaxController.dispose();
    _mesEntregaMinController.dispose();
    _mesEntregaMaxController.dispose();
    _prioridadController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  // Helpers
  int _toInt(String s, {int fallback = 0}) =>
      int.tryParse(s.trim()) ?? fallback;
  double _toDouble(String s, {double fallback = 0.0}) =>
      double.tryParse(s.trim()) ?? fallback;

  String? _valInt(String? v, {int? min, int? max, bool required = true}) {
    if ((v == null || v.trim().isEmpty) && required) return 'Campo obligatorio';
    if (v == null || v.trim().isEmpty) return null;
    final n = int.tryParse(v.trim());
    if (n == null) return 'Número inválido';
    if (min != null && n < min) return 'Mínimo $min';
    if (max != null && n > max) return 'Máximo $max';
    return null;
  }

  String? _valDouble(
    String? v, {
    double? min,
    double? max,
    bool required = true,
  }) {
    if ((v == null || v.trim().isEmpty) && required) return 'Campo obligatorio';
    if (v == null || v.trim().isEmpty) return null;
    final n = double.tryParse(v.trim());
    if (n == null) return 'Número inválido';
    if (min != null && n < min) return 'Mínimo $min';
    if (max != null && n > max) return 'Máximo $max';
    return null;
  }

  Future<void> _pickFecha({required bool desde}) async {
    final init = (desde ? _vigenteDesde : _vigenteHasta) ?? DateTime.now();
    final sel = await showDatePicker(
      context: context,
      initialDate: init,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (sel != null) {
      setState(() {
        if (desde) {
          _vigenteDesde = DateTime(sel.year, sel.month, sel.day);
        } else {
          _vigenteHasta = DateTime(sel.year, sel.month, sel.day);
        }
      });
    }
  }

  void _limpiarFecha({required bool desde}) {
    setState(() {
      if (desde) {
        _vigenteDesde = null;
      } else {
        _vigenteHasta = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final _ = ref.watch(productosProvider); // rebuild
    final textTheme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar producto' : 'Nuevo producto'),
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
                  // ==================== Identidad / Estado =====================
                  const SizedBox(height: 12),

                  MyTextFormField(
                    controller: _nombreController,
                    labelText: 'Nombre',
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Campo obligatorio'
                        : null,
                  ),

                  const SizedBox(height: 12),

                  // Plazo
                  MyTextFormField(
                    controller: _plazoController,
                    labelText: 'Plazo (meses)',
                    keyboardType: const TextInputType.numberWithOptions(),
                    validator: (v) => _valInt(v, min: 1, max: 120),
                  ),
                  const SizedBox(height: 8),

                  // ---------- Factores ----------
                  Text('Factores', style: textTheme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const gap = 12.0;
                      final isNarrow = constraints.maxWidth < 600;
                      final itemWidth = isNarrow
                          ? constraints.maxWidth
                          : (constraints.maxWidth - gap) / 2;

                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          SizedBox(
                            width: itemWidth,
                            child: MyTextFormField(
                              controller: _factorIntController,
                              labelText: 'Factor integrante',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (v) => _valDouble(v, min: 0, max: 1),
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: MyTextFormField(
                              controller: _factorPropController,
                              labelText: 'Factor propietario',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (v) => _valDouble(v, min: 0, max: 1),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  // Factores

                  // ---------- Cuotas ----------
                  Text('Cuotas', style: textTheme.textTheme.titleMedium),
                  const SizedBox(height: 8),

                  LayoutBuilder(
                    builder: (context, constraints) {
                      const gap = 12.0;
                      final isNarrow = constraints.maxWidth < 600;
                      final itemWidth = isNarrow
                          ? constraints.maxWidth
                          : (constraints.maxWidth - gap) / 2;

                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          SizedBox(
                            width: itemWidth,
                            child: MyTextFormField(
                              controller: _inscripcionPctController,
                              labelText: 'Cuota inscripción (proporción)',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (v) => _valDouble(v, min: 0, max: 1),
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: MyTextFormField(
                              controller: _admPctController,
                              labelText: 'Cuota administración (prop)',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (v) => _valDouble(v, min: 0, max: 1),
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: MyTextFormField(
                              controller: _ivaAdmPctController,
                              labelText: 'IVA cuota administración (prop)',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (v) => _valDouble(v, min: 0, max: 1),
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: MyTextFormField(
                              controller: _seguroVidaPctController,
                              labelText: 'Cuota seguro de vida (prop)',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: (v) => _valDouble(v, min: 0, max: 1),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  // ============ Límites / reglas operativas ====================
                  Text('Límites', style: textTheme.textTheme.titleMedium),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      const gap = 12.0;
                      final isNarrow = constraints.maxWidth < 600;
                      final itemWidth = isNarrow
                          ? constraints.maxWidth
                          : (constraints.maxWidth - gap) / 2;

                      return Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          SizedBox(
                            width: itemWidth,
                            child: MyTextFormField(
                              controller: _adelantoMinController,
                              labelText: 'Adelanto mínimo (mens)',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: false,
                                  ),
                              validator: (v) => _valInt(v, min: 0, max: 120),
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: MyTextFormField(
                              controller: _adelantoMaxController,
                              labelText: 'Adelanto máximo (mens)',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: false,
                                  ),
                              validator: (v) => _valInt(v, min: 0, max: 120),
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: MyTextFormField(
                              controller: _mesEntregaMinController,
                              labelText: 'Mes entrega mínimo',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: false,
                                  ),
                              validator: (v) => _valInt(v, min: 1, max: 360),
                            ),
                          ),
                          SizedBox(
                            width: itemWidth,
                            child: MyTextFormField(
                              controller: _mesEntregaMaxController,
                              labelText: 'Mes entrega máximo',
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: false,
                                  ),
                              validator: (v) => _valInt(v, min: 1, max: 360),
                            ),
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 8),

                  // ================== Presentación / selección ==================
                  Text('Presentación', style: textTheme.textTheme.titleMedium),
                  const SizedBox(height: 8),

                  MyTextFormField(
                    controller: _prioridadController,
                    labelText: 'Prioridad (orden en UI)',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: false,
                    ),
                    validator: (v) => _valInt(v, min: -9999, max: 9999),
                  ),
                  const SizedBox(height: 8),

                  MyTextFormField(
                    controller: _notasController,
                    labelText: 'Notas',
                  ),
                  const SizedBox(height: 16),

                  // ======================== Vigencia ============================
                  // Desde
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Vigente desde: ${_vigenteDesde != null ? _fmtFecha(_vigenteDesde!) : '—'}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_vigenteDesde != null)
                          IconButton(
                            tooltip: 'Limpiar',
                            icon: const Icon(Icons.clear),
                            onPressed: () => _limpiarFecha(desde: true),
                          ),
                        IconButton(
                          tooltip: 'Elegir fecha',
                          icon: const Icon(Icons.calendar_month),
                          onPressed: () => _pickFecha(desde: true),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Hasta
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Vigente hasta: ${_vigenteHasta != null ? _fmtFecha(_vigenteHasta!) : '—'}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_vigenteHasta != null)
                          IconButton(
                            tooltip: 'Limpiar',
                            icon: const Icon(Icons.clear),
                            onPressed: () => _limpiarFecha(desde: false),
                          ),
                        IconButton(
                          tooltip: 'Elegir fecha',
                          icon: const Icon(Icons.calendar_month),
                          onPressed: () => _pickFecha(desde: false),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile.adaptive(
                    value: _activo,
                    onChanged: (v) => setState(() => _activo = v),
                    title: const Text('Activo'),
                  ),
                  const SizedBox(height: 24),

                  // ======================== Guardar =============================
                  MyElevatedButton(
                    icon: Icons.save,
                    label: 'Guardar',
                    onPressed: _guardar,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _fmtFecha(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    // Parse
    final nombre = _nombreController.text.trim();
    final plazoMeses = _toInt(_plazoController.text, fallback: 60);
    final factorIntegrante = _toDouble(
      _factorIntController.text,
      fallback: 0.01667,
    );
    final factorPropietario = _toDouble(
      _factorPropController.text,
      fallback: 0.0206,
    );
    final cuotaInscripcionPct = _toDouble(
      _inscripcionPctController.text,
      fallback: 0.005,
    );
    final cuotaAdministracionPct = _toDouble(
      _admPctController.text,
      fallback: 0.002,
    );
    final ivaCuotaAdministracionPct = _toDouble(
      _ivaAdmPctController.text,
      fallback: 0.16,
    );
    final cuotaSeguroVidaPct = _toDouble(
      _seguroVidaPctController.text,
      fallback: 0.00065,
    );

    final adelantoMin = _toInt(_adelantoMinController.text, fallback: 0);
    final adelantoMax = _toInt(_adelantoMaxController.text, fallback: 59);
    final mesEntMin = _toInt(_mesEntregaMinController.text, fallback: 1);
    final mesEntMax = _toInt(_mesEntregaMaxController.text, fallback: 60);

    final prioridad = _toInt(_prioridadController.text, fallback: 0);
    final notas = _notasController.text;

    // Validaciones cruzadas
    if (adelantoMin > adelantoMax) {
      _snack('❌ Adelanto mínimo no puede ser mayor que el máximo');
      return;
    }
    if (mesEntMin > mesEntMax) {
      _snack('❌ Mes de entrega mínimo no puede ser mayor que el máximo');
      return;
    }
    if (mesEntMax > plazoMeses) {
      _snack('❌ Mes de entrega máximo no puede exceder el plazo');
      return;
    }
    if (_vigenteDesde != null && _vigenteHasta != null) {
      final d0 = DateTime(
        _vigenteDesde!.year,
        _vigenteDesde!.month,
        _vigenteDesde!.day,
      );
      final d1 = DateTime(
        _vigenteHasta!.year,
        _vigenteHasta!.month,
        _vigenteHasta!.day,
      );
      if (d1.isBefore(d0)) {
        _snack('❌ Vigente hasta no puede ser anterior a vigente desde');
        return;
      }
    }

    final productosNotifier = ref.read(productosProvider.notifier);

    // Duplicado por nombre
    final hayDuplicado = productosNotifier.existeDuplicado(
      uidActual: widget.productoEditar?.uid ?? '',
      nombre: nombre,
    );
    if (hayDuplicado) {
      _snack('❌ Ya existe un producto con ese nombre');
      return;
    }

    try {
      if (_esEdicion) {
        final actualizado = widget.productoEditar!.copyWith(
          nombre: nombre,
          activo: _activo,
          plazoMeses: plazoMeses,
          factorIntegrante: factorIntegrante,
          factorPropietario: factorPropietario,
          cuotaInscripcionPct: cuotaInscripcionPct,
          cuotaAdministracionPct: cuotaAdministracionPct,
          ivaCuotaAdministracionPct: ivaCuotaAdministracionPct,
          cuotaSeguroVidaPct: cuotaSeguroVidaPct,
          adelantoMinMens: adelantoMin,
          adelantoMaxMens: adelantoMax,
          mesEntregaMin: mesEntMin,
          mesEntregaMax: mesEntMax,
          prioridad: prioridad,
          notas: notas,
          vigenteDesde: Value(_vigenteDesde),
          vigenteHasta: Value(_vigenteHasta),
          updatedAt: DateTime.now().toUtc(),
          isSynced: false,
        );

        await productosNotifier.editarProducto(actualizado: actualizado);
        if (mounted) Navigator.pop(context, true);
      } else {
        await productosNotifier.crearProductoLocal(
          nombre: nombre,
          activo: _activo,
          plazoMeses: plazoMeses,
          factorIntegrante: factorIntegrante,
          factorPropietario: factorPropietario,
          cuotaInscripcionPct: cuotaInscripcionPct,
          cuotaAdministracionPct: cuotaAdministracionPct,
          ivaCuotaAdministracionPct: ivaCuotaAdministracionPct,
          cuotaSeguroVidaPct: cuotaSeguroVidaPct,
          adelantoMinMens: adelantoMin,
          adelantoMaxMens: adelantoMax,
          mesEntregaMin: mesEntMin,
          mesEntregaMax: mesEntMax,
          prioridad: prioridad,
          notas: notas,
          vigenteDesde: _vigenteDesde,
          vigenteHasta: _vigenteHasta,
        );
        if (mounted) Navigator.pop(context, true);
      }
    } catch (e) {
      _snack('❌ Error al guardar: $e');
    }
  }

  void _snack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }
}

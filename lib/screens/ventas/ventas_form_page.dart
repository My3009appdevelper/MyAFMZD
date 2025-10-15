// lib/features/ventas/ventas_form_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:loader_overlay/loader_overlay.dart';

import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/widgets/my_text_form_field.dart';
import 'package:myafmzd/widgets/my_picker_search_field.dart';
import 'package:myafmzd/widgets/my_chip_picker.dart';
import 'package:myafmzd/widgets/my_elevated_button.dart';

import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_provider.dart';
import 'package:myafmzd/database/asignaciones_laborales/asignaciones_laborales_provider.dart';
import 'package:myafmzd/database/modelos/modelos_provider.dart';
import 'package:myafmzd/database/estatus/estatus_provider.dart';
import 'package:myafmzd/database/ventas/ventas_provider.dart';

class VentasFormPage extends ConsumerStatefulWidget {
  final VentaDb? ventaEditar;
  const VentasFormPage({super.key, this.ventaEditar});

  @override
  ConsumerState<VentasFormPage> createState() => _VentasFormPageState();
}

class _VentasFormPageState extends ConsumerState<VentasFormPage> {
  final _formKey = GlobalKey<FormState>();
  bool _esEdicion = false;
  bool _guardando = false;

  // Controllers texto
  late TextEditingController _folioContratoCtrl;
  late TextEditingController _grupoCtrl;
  late TextEditingController _integranteCtrl;

  // Controllers de UIDs
  late TextEditingController _distribuidoraOrigenUidCtrl;
  late TextEditingController _distribuidoraUidCtrl; // derivada (concentradora)
  late TextEditingController _vendedorUidCtrl; // 👉 guarda UID de ASIGNACIÓN
  late TextEditingController _modeloUidCtrl; // desde chip (display→uid)
  late TextEditingController _estatusUidCtrl;

  // Fechas
  DateTime? _fechaContrato;
  DateTime? _fechaVenta;

  // (Opcional) Soft delete visible aquí
  bool _deleted = false;

  // Modelo chip mapping
  Map<String, String> _modeloDisplayByUid = {};
  Map<String, String> _uidByModeloDisplay = {};
  String _selectedModeloDisplay = '';

  @override
  void initState() {
    super.initState();
    final v = widget.ventaEditar;
    _esEdicion = v != null;

    _folioContratoCtrl = TextEditingController(text: v?.folioContrato ?? '');
    _grupoCtrl = TextEditingController(text: (v?.grupo ?? 0).toString());
    _integranteCtrl = TextEditingController(
      text: (v?.integrante ?? 0).toString(),
    );

    _distribuidoraOrigenUidCtrl = TextEditingController(
      text: v?.distribuidoraOrigenUid ?? '',
    );
    _distribuidoraUidCtrl = TextEditingController(
      text: v?.distribuidoraUid ?? '',
    ); // derivada
    _vendedorUidCtrl = TextEditingController(text: v?.vendedorUid ?? '');
    _modeloUidCtrl = TextEditingController(text: v?.modeloUid ?? '');
    _estatusUidCtrl = TextEditingController(text: v?.estatusUid ?? '');

    _fechaContrato = v?.fechaContrato;
    _fechaVenta = v?.fechaVenta;

    _deleted = v?.deleted ?? false;
  }

  @override
  void dispose() {
    _folioContratoCtrl.dispose();
    _grupoCtrl.dispose();
    _integranteCtrl.dispose();
    _distribuidoraOrigenUidCtrl.dispose();
    _distribuidoraUidCtrl.dispose();
    _vendedorUidCtrl.dispose();
    _modeloUidCtrl.dispose();
    _estatusUidCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ======= Catálogos =======
    final distribuidores =
        ref.watch(distribuidoresProvider).where((d) => !d.deleted).toList()
          ..sort((a, b) => a.nombre.compareTo(b.nombre));

    final colaboradores = ref
        .watch(colaboradoresProvider)
        .where((c) => !(c.deleted))
        .toList();

    final asignaciones = ref
        .watch(asignacionesLaboralesProvider)
        .where((a) => !a.deleted && (a.rol.toLowerCase().trim() == 'vendedor'))
        .toList();

    final estatusList =
        ref.watch(estatusProvider).where((e) => !e.deleted).toList()
          ..sort((a, b) => a.nombre.compareTo(b.nombre));

    final modelosAll =
        ref.watch(modelosProvider).where((m) => m.activo && !m.deleted).toList()
          ..sort((a, b) {
            final x = '${a.marca} ${a.modelo} ${a.anio}'.toLowerCase();
            final y = '${b.marca} ${b.modelo} ${b.anio}'.toLowerCase();
            return x.compareTo(y);
          });

    // Mapas display<->uid para el chip de Modelo
    _modeloDisplayByUid = {
      for (final m in modelosAll) m.uid: '${m.marca} ${m.modelo} ${m.anio}',
    };
    _uidByModeloDisplay = {
      for (final e in _modeloDisplayByUid.entries) e.value: e.key,
    };

    // Valor inicial del chip de modelo
    _selectedModeloDisplay = _modeloUidCtrl.text.isEmpty
        ? (modelosAll.isEmpty ? '' : _modeloDisplayByUid[modelosAll.first.uid]!)
        : (_modeloDisplayByUid[_modeloUidCtrl.text] ?? '');

    // ======= Vendedores: mostrar NOMBRE del colaborador pero guardar UID de ASIGNACIÓN =======
    final _vendedores = <_VendedorItem>[];
    for (final a in asignaciones) {
      try {
        final c = colaboradores.firstWhere((c) => c.uid == a.colaboradorUid);
        final display = _nombreColaborador(c);
        if (display.isEmpty) continue;
        _vendedores.add(_VendedorItem(asign: a, colab: c, display: display));
      } catch (_) {
        /* omit */
      }
    }
    _vendedores.sort(
      (x, y) => x.display.toLowerCase().compareTo(y.display.toLowerCase()),
    );

    // Valor inicial del vendedor: buscar la asignación por uid almacenado
    _VendedorItem? _vendedorInicial;
    if (_vendedorUidCtrl.text.isNotEmpty) {
      try {
        final asign = asignaciones.firstWhere(
          (a) => a.uid == _vendedorUidCtrl.text,
        );
        final colab = colaboradores.firstWhere(
          (c) => c.uid == asign.colaboradorUid,
        );
        _vendedorInicial = _VendedorItem(
          asign: asign,
          colab: colab,
          display: _nombreColaborador(colab),
        );
      } catch (_) {
        /* null */
      }
    }

    // ===== Helper para mostrar nombre de concentradora derivada =====
    String _nombreConcentradora(String uid) {
      if (uid.isEmpty) return '—';
      try {
        return distribuidores.firstWhere((d) => d.uid == uid).nombre;
      } catch (_) {
        return '—';
      }
    }

    return Scaffold(
      appBar: AppBar(title: Text(_esEdicion ? 'Editar venta' : 'Nueva venta')),
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
                  // ===== Distribuidora ORIGEN =====
                  MyPickerSearchField<DistribuidorDb>(
                    items: distribuidores,
                    initialValue: _valueOrNull<DistribuidorDb>(
                      distribuidores,
                      _distribuidoraOrigenUidCtrl.text,
                      (d) => d.uid,
                    ),
                    itemAsString: (d) => d.nombre,
                    compareFn: (a, b) => a.uid == b.uid,
                    labelText: 'Distribuidora origen',
                    hintText: 'Toca para elegir…',
                    bottomSheetTitle: 'Seleccionar distribuidora origen',
                    searchHintText: 'Buscar distribuidora…',
                    onChanged: (d) {
                      _distribuidoraOrigenUidCtrl.text = d?.uid ?? '';
                      // Auto-derivar distribuidora actual = concentradora (NO editable)
                      if (d == null) {
                        _distribuidoraUidCtrl.text = '';
                      } else {
                        final concUid = (d.concentradoraUid.isNotEmpty)
                            ? d.concentradoraUid
                            : d.uid;
                        _distribuidoraUidCtrl.text = concUid;
                      }
                      setState(() {});
                    },
                    validator: (d) => d == null ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 12),

                  // ===== Distribuidora (concentradora) — SOLO LECTURA =====
                  InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Distribuidora (concentradora)',
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _nombreConcentradora(_distribuidoraUidCtrl.text),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ===== Vendedor (asignación) =====
                  MyPickerSearchField<_VendedorItem>(
                    items: _vendedores,
                    initialValue: _vendedorInicial,
                    itemAsString: (v) => v.display, // 👈 nombre del colaborador
                    compareFn: (a, b) => a.asign.uid == b.asign.uid,
                    labelText: 'Vendedor',
                    hintText: 'Toca para elegir…',
                    bottomSheetTitle: 'Seleccionar vendedor',
                    searchHintText: 'Buscar por nombre…',
                    onChanged: (v) =>
                        _vendedorUidCtrl.text = v?.asign.uid ?? '',
                    validator: (v) => v == null ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 12),

                  // ===== Folio de contrato =====
                  MyTextFormField(
                    controller: _folioContratoCtrl,
                    labelText: 'Folio de contrato',
                  ),
                  const SizedBox(height: 12),

                  // ===== Modelo (chip) =====
                  MyChipPickerSingle(
                    label: 'Modelo',
                    options: _uidByModeloDisplay.keys.toList(),
                    selected: _selectedModeloDisplay,
                    validator: (val) => (val == null || val.trim().isEmpty)
                        ? 'Campo obligatorio'
                        : null,
                    onSelected: (display) {
                      setState(() {
                        _selectedModeloDisplay = display;
                        _modeloUidCtrl.text =
                            _uidByModeloDisplay[display] ?? '';
                      });
                    },
                  ),
                  const SizedBox(height: 12),

                  // ===== Estatus =====
                  MyPickerSearchField<EstatusDb>(
                    items: estatusList,
                    initialValue: _valueOrNull<EstatusDb>(
                      estatusList,
                      _estatusUidCtrl.text,
                      (e) => e.uid,
                    ),
                    itemAsString: (e) => e.nombre,
                    compareFn: (a, b) => a.uid == b.uid,
                    labelText: 'Estatus',
                    hintText: 'Toca para elegir…',
                    bottomSheetTitle: 'Seleccionar estatus',
                    searchHintText: 'Buscar estatus…',
                    onChanged: (e) => _estatusUidCtrl.text = e?.uid ?? '',
                    validator: (e) => e == null ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 12),

                  // ===== Grupo / Integrante =====
                  Row(
                    children: [
                      Expanded(
                        child: MyTextFormField(
                          controller: _grupoCtrl,
                          labelText: 'Grupo',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: false,
                            signed: false,
                          ),
                          validator: _validaEnteroNoNegativo,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: MyTextFormField(
                          controller: _integranteCtrl,
                          labelText: 'Integrante',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: false,
                            signed: false,
                          ),
                          validator: _validaEnteroNoNegativo,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // ===== Fechas =====
                  _FechaField(
                    label: 'Fecha de contrato',
                    value: _fechaContrato,
                    onPick: (d) => setState(() => _fechaContrato = d),
                  ),
                  const SizedBox(height: 12),
                  _FechaField(
                    label: 'Fecha de venta',
                    value: _fechaVenta,
                    onPick: (d) => setState(
                      () => _fechaVenta = d,
                    ), // mes/año ya NO se muestran
                  ),
                  const SizedBox(height: 12),

                  // (Opcional) Deleted
                  SwitchListTile.adaptive(
                    value: _deleted,
                    onChanged: (v) => setState(() => _deleted = v),
                    title: const Text('Marcar como eliminada'),
                  ),

                  const SizedBox(height: 24),

                  MyElevatedButton(
                    icon: Icons.save,
                    label: 'Guardar',
                    onPressed: _guardando ? null : _guardar,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ================= Guardar =================

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (!mounted) return;

    FocusScope.of(context).unfocus();
    setState(() => _guardando = true);
    context.loaderOverlay.show(
      progress: _esEdicion ? 'Editando venta…' : 'Guardando venta…',
    );

    int _toIntOr(String s, int def) =>
        int.tryParse(s.trim().isEmpty ? '$def' : s.trim()) ?? def;

    final uidActual = widget.ventaEditar?.uid ?? '';
    final distribuidoraOrigenUid = _distribuidoraOrigenUidCtrl.text.trim();

    // 👇 Derivar SIEMPRE la concentradora desde el catálogo (seguro)
    String _concentradoraDe(String origenUid) {
      try {
        final d = ref
            .read(distribuidoresProvider)
            .firstWhere((x) => x.uid == origenUid);
        return (d.concentradoraUid.isNotEmpty) ? d.concentradoraUid : d.uid;
      } catch (_) {
        // Si no se encuentra, fallback al mismo origen
        return origenUid;
      }
    }

    final distribuidoraUidFinal = _concentradoraDe(distribuidoraOrigenUid);
    _distribuidoraUidCtrl.text = distribuidoraUidFinal; // coherencia interna

    final vendedorAsignUid = _vendedorUidCtrl.text.trim(); // 👈 asignación
    final folioContrato = _folioContratoCtrl.text.trim();
    final modeloUid = _modeloUidCtrl.text.trim();
    final estatusUid = _estatusUidCtrl.text.trim();
    final grupo = _toIntOr(_grupoCtrl.text, 0);
    final integrante = _toIntOr(_integranteCtrl.text, 0);

    // Deriva SIEMPRE mes/año EXCLUSIVAMENTE de _fechaVenta
    final int? mesVentaDef = _fechaVenta?.month;
    final int? anioVentaDef = _fechaVenta?.year;

    // ===== Validaciones de duplicado =====
    final ventasNotifier = ref.read(ventasProvider.notifier);

    final dupFolio = ventasNotifier.existeDuplicadoFolio(
      uidActual: uidActual,
      folio: folioContrato,
      incluirEliminados: false,
    );
    if (dupFolio) {
      _fail('❌ Ya existe una venta con ese folio de contrato');
      return;
    }

    final dupSlot = ventasNotifier.existeDuplicadoSlot(
      uidActual: uidActual,
      grupo: grupo,
      integrante: integrante,
      mesVenta: mesVentaDef,
      anioVenta: anioVentaDef,
      incluirEliminados: false,
    );
    if (dupSlot) {
      _fail('❌ Ya existe una venta para este grupo/integrante en ese periodo');
      return;
    }

    try {
      if (_esEdicion) {
        if (context.loaderOverlay.visible) {
          context.loaderOverlay.progress('Aplicando cambios…');
        }
        await ventasNotifier.editarVenta(
          uid: uidActual,
          distribuidoraOrigenUid: distribuidoraOrigenUid,
          distribuidoraUid: distribuidoraUidFinal, // 👈 DERIVADA
          vendedorUid: vendedorAsignUid, // 👈 asignación
          folioContrato: folioContrato,
          modeloUid: modeloUid,
          estatusUid: estatusUid,
          grupo: grupo,
          integrante: integrante,
          fechaContrato: _fechaContrato,
          fechaVenta: _fechaVenta,
          mesVenta: mesVentaDef,
          anioVenta: anioVentaDef,
          deleted: _deleted,
        );
      } else {
        if (context.loaderOverlay.visible) {
          context.loaderOverlay.progress('Creando venta…');
        }
        await ventasNotifier.crearVenta(
          distribuidoraOrigenUid: distribuidoraOrigenUid,
          distribuidoraUid: distribuidoraUidFinal, // 👈 DERIVADA
          vendedorUid: vendedorAsignUid, // 👈 asignación
          folioContrato: folioContrato,
          modeloUid: modeloUid,
          estatusUid: estatusUid,
          grupo: grupo,
          integrante: integrante,
          fechaContrato: _fechaContrato,
          fechaVenta: _fechaVenta,
          mesVenta: mesVentaDef,
          anioVenta: anioVentaDef,
        );
      }

      // UX: retardo mínimo
      const minSpin = Duration(milliseconds: 1200);
      await Future.delayed(minSpin);

      if (mounted && context.loaderOverlay.visible)
        context.loaderOverlay.hide();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      _fail('❌ Error al guardar: $e');
    } finally {
      if (mounted && context.loaderOverlay.visible)
        context.loaderOverlay.hide();
      if (mounted) setState(() => _guardando = false);
    }
  }

  void _fail(String msg) {
    if (mounted && context.loaderOverlay.visible) {
      context.loaderOverlay.hide();
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      setState(() => _guardando = false);
    }
  }

  // ================= Helpers UI / Validaciones =================

  T? _valueOrNull<T>(
    List<T> lista,
    String uid,
    String Function(T) uidSelector,
  ) {
    if (uid.isEmpty) return null;
    try {
      return lista.firstWhere((e) => uidSelector(e) == uid);
    } catch (_) {
      return null;
    }
  }

  String? _validaEnteroNoNegativo(String? v) {
    if (v == null || v.trim().isEmpty) return null;
    final n = int.tryParse(v.trim());
    if (n == null) return 'Número inválido';
    if (n < 0) return 'No puede ser negativo';
    return null;
  }

  String _nombreColaborador(ColaboradorDb c) {
    final ap = c.apellidoPaterno ?? '';
    final am = c.apellidoMaterno ?? '';
    final s = '${c.nombres} $ap $am';
    return s.replaceAll(RegExp(r'\s+'), ' ').trim();
  }
}

// ================= Widgets auxiliares =================

class _FechaField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onPick;
  const _FechaField({
    required this.label,
    required this.value,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final texto = value == null
        ? '—'
        : '${value!.day.toString().padLeft(2, '0')}/'
              '${value!.month.toString().padLeft(2, '0')}/'
              '${value!.year}';

    return InputDecorator(
      decoration: const InputDecoration(
        labelText: '',
        border: OutlineInputBorder(),
      ).copyWith(labelText: label),
      child: Row(
        children: [
          Expanded(child: Text(texto)),
          IconButton(
            icon: const Icon(Icons.event),
            onPressed: () async {
              final now = DateTime.now();
              final base = value ?? now;
              final picked = await showDatePicker(
                context: context,
                initialDate: base,
                firstDate: DateTime(1990),
                lastDate: DateTime(2100),
              );
              onPick(picked);
            },
          ),
          if (value != null)
            IconButton(
              tooltip: 'Limpiar',
              icon: const Icon(Icons.clear),
              onPressed: () => onPick(null),
            ),
        ],
      ),
    );
  }
}

// Item compuesto para el picker de Vendedor
class _VendedorItem {
  final AsignacionLaboralDb asign;
  final ColaboradorDb colab;
  final String display;
  _VendedorItem({
    required this.asign,
    required this.colab,
    required this.display,
  });
}

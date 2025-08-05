import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/reportes/reportes_provider.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/widgets/my_dropdown_button.dart';
import 'package:myafmzd/widgets/my_elevated_button.dart';
import 'package:myafmzd/widgets/my_text_form_field.dart';

class ReporteFormPage extends ConsumerStatefulWidget {
  final ReportesDb? reporteEditar;
  const ReporteFormPage({super.key, this.reporteEditar});

  @override
  ConsumerState<ReporteFormPage> createState() => _ReporteFormPageState();
}

class _ReporteFormPageState extends ConsumerState<ReporteFormPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nombreController;
  late TextEditingController _tipoController;
  late DateTime _fecha;

  bool _esEdicion = false;

  @override
  void initState() {
    super.initState();
    final r = widget.reporteEditar;
    _esEdicion = r != null;
    _nombreController = TextEditingController(text: r?.nombre ?? '');
    _tipoController = TextEditingController(text: r?.tipo ?? 'INTERNO');
    _fecha = r?.fecha ?? DateTime.now();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _tipoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.watch(reporteProvider.notifier);
    final filtrados = notifier.filtrados;
    final grupos = notifier.agruparPorTipo(filtrados);
    final tipos = grupos.keys.toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(_esEdicion ? 'Editar Reporte' : 'Nuevo Reporte'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: ListView(
                children: [
                  MyTextFormField(
                    controller: _nombreController,
                    labelText: 'Nombre',
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Campo obligatorio' : null,
                  ),
                  const SizedBox(height: 12),
                  MyDropdownButton<String>(
                    labelText: "Tipo",
                    value: _tipoController.text.isNotEmpty
                        ? _tipoController.text
                        : null,
                    items: tipos,
                    onChanged: (value) {
                      if (value != null) _tipoController.text = value;
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 12),
                  Text("Fecha"),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      '${_fecha.year}-${_fecha.month.toString().padLeft(2, '0')}-'
                      '${_fecha.day.toString().padLeft(2, '0')}',
                    ),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: _seleccionarFecha,
                  ),
                  const SizedBox(height: 24),
                  MyElevatedButton(
                    onPressed: _guardar,
                    icon: Icons.save,
                    label: 'Guardar',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _seleccionarFecha() async {
    final nuevaFecha = await showDatePicker(
      context: context,
      initialDate: _fecha,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (nuevaFecha != null) {
      setState(() => _fecha = nuevaFecha);
    }
  }

  Future<void> _guardar() async {
    final hayInternet = ref.read(connectivityProvider);

    if (!_formKey.currentState!.validate()) return;

    final nombre = _nombreController.text.trim();
    final tipo = _tipoController.text.trim();

    final reporteNotifier = ref.read(reporteProvider.notifier);

    try {
      if (_esEdicion) {
        final original = widget.reporteEditar!;
        final actualizado = original.copyWith(
          nombre: nombre,
          tipo: tipo,
          fecha: _fecha,
          updatedAt: DateTime.now().toUtc(),
          isSynced: false,
        );

        await reporteNotifier.editarReporte(
          actualizado: actualizado,
          hayInternet: hayInternet,
        );
        print('[📝 FORM] Editado: ${actualizado.uid}');
      } else {
        await reporteNotifier.crearReporteLocal(
          nombre: nombre,
          tipo: tipo,
          fecha: _fecha,
        );
        print('[📝 FORM] Creado: $nombre');
      }

      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      print('[📝 FORM] ❌ Error al guardar: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
    }
  }
}

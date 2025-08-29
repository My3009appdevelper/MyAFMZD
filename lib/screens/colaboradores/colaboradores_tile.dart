import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_provider.dart';
import 'package:myafmzd/screens/colaboradores/colaboradores_form_page.dart';
import 'package:myafmzd/widgets/sheet_action.dart';
import 'package:myafmzd/widgets/show_detail_dialog.dart';

class ColaboradorItemTile extends ConsumerStatefulWidget {
  final ColaboradorDb colaborador;
  final VoidCallback onTap;
  final VoidCallback? onActualizado;

  const ColaboradorItemTile({
    super.key,
    required this.colaborador,
    required this.onTap,
    this.onActualizado,
  });

  @override
  ConsumerState<ColaboradorItemTile> createState() =>
      _ColaboradorItemTileState();
}

class _ColaboradorItemTileState extends ConsumerState<ColaboradorItemTile> {
  bool _trabajandoFoto = false;

  @override
  Widget build(BuildContext context) {
    // versión viva desde el provider
    final c = ref
        .watch(colaboradoresProvider)
        .firstWhere(
          (x) => x.uid == widget.colaborador.uid,
          orElse: () => widget.colaborador,
        );

    final tieneLocal =
        c.fotoRutaLocal.isNotEmpty && File(c.fotoRutaLocal).existsSync();
    final tieneRemota = c.fotoRutaRemota.trim().isNotEmpty;

    return ListTile(
      key: ValueKey(c.uid),
      leading: _buildAvatar(c),
      title: Text(_nombreCompleto(c)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (c.telefonoMovil.trim().isNotEmpty)
            Text('Tel: ${c.telefonoMovil}'),
          if (c.emailPersonal.trim().isNotEmpty)
            Text('Email: ${c.emailPersonal}'),
          if ((c.curp ?? '').trim().isNotEmpty ||
              (c.rfc ?? '').trim().isNotEmpty)
            Text(
              [
                if ((c.curp ?? '').trim().isNotEmpty) 'CURP: ${c.curp}',
                if ((c.rfc ?? '').trim().isNotEmpty) 'RFC: ${c.rfc}',
              ].join(' · '),
            ),
        ],
      ),
      isThreeLine: true,
      trailing: SizedBox(
        width: 40,
        height: 40,
        child: Center(
          child: _trabajandoFoto
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : tieneLocal
              ? IconButton(
                  tooltip: 'Eliminar foto local',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _eliminarFotoLocal(c),
                )
              : (tieneRemota
                    ? IconButton(
                        tooltip: 'Descargar foto',
                        icon: const Icon(Icons.cloud_download),
                        onPressed: () => _descargarFoto(c),
                      )
                    : const SizedBox.shrink()),
        ),
      ),
      onTap: widget.onTap,
      onLongPress: () => _mostrarOpcionesColaborador(context, c),
    );
  }

  Widget _buildAvatar(ColaboradorDb c) {
    final haveLocal =
        c.fotoRutaLocal.isNotEmpty && File(c.fotoRutaLocal).existsSync();
    if (haveLocal) {
      return CircleAvatar(backgroundImage: FileImage(File(c.fotoRutaLocal)));
    }
    final initials = _iniciales(_nombreCompleto(c));
    return CircleAvatar(child: Text(initials));
  }

  String _nombreCompleto(ColaboradorDb c) =>
      '${c.nombres} ${c.apellidoPaterno} ${c.apellidoMaterno}'.trim();

  String _iniciales(String nombre) {
    final parts = nombre
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }

  Future<void> _descargarFoto(ColaboradorDb c) async {
    setState(() => _trabajandoFoto = true);
    try {
      await ref.read(colaboradoresProvider.notifier).descargarFoto(c);
      if (widget.onActualizado != null) widget.onActualizado!();
    } finally {
      if (mounted) setState(() => _trabajandoFoto = false);
    }
  }

  Future<void> _eliminarFotoLocal(ColaboradorDb c) async {
    setState(() => _trabajandoFoto = true);
    try {
      await ref.read(colaboradoresProvider.notifier).eliminarFotoLocal(c);
      if (widget.onActualizado != null) widget.onActualizado!();
    } finally {
      if (mounted) setState(() => _trabajandoFoto = false);
    }
  }

  Future<void> _mostrarOpcionesColaborador(
    BuildContext context,
    ColaboradorDb c,
  ) {
    return showActionSheet(
      context,
      title: 'Acciones',
      actions: [
        SheetAction(
          icon: Icons.info_outline,
          label: 'Ver detalles',
          onTap: () => _mostrarDetalles(context, c),
        ),
        SheetAction(
          icon: Icons.edit,
          label: 'Editar',
          onTap: () => _abrirFormularioEdicion(context, c),
        ),
        // aquí podrías agregar eliminar/restaurar si lo necesitas
      ],
    );
  }

  void _mostrarDetalles(BuildContext context, ColaboradorDb c) {
    showDetailsDialog(
      context,
      title: 'Detalles del colaborador',
      fields: {
        'UID': c.uid,
        'Nombre': _nombreCompleto(c),
        'Fecha nac.': c.fechaNacimiento != null
            ? c.fechaNacimiento!.toLocal().toString()
            : '—',
        'CURP': (c.curp ?? '').isNotEmpty ? (c.curp ?? '') : '—',
        'RFC': (c.rfc ?? '').isNotEmpty ? (c.rfc ?? '') : '—',
        'Teléfono': c.telefonoMovil.isNotEmpty ? c.telefonoMovil : '—',
        'Email': c.emailPersonal.isNotEmpty ? c.emailPersonal : '—',
        'Género': (c.genero ?? '').isNotEmpty ? (c.genero ?? '') : '—',
        'Notas': c.notas.isNotEmpty ? c.notas : '—',
        'Foto remota': c.fotoRutaRemota.isNotEmpty ? c.fotoRutaRemota : '—',
        'Foto local': c.fotoRutaLocal.isNotEmpty ? c.fotoRutaLocal : '—',
        'Synced': c.isSynced ? 'Sí' : 'No',
        'Eliminado': c.deleted ? 'Sí' : 'No',
        'Creado': c.createdAt.toLocal().toString(),
        'Actualizado': c.updatedAt.toLocal().toString(),
      },
    );
  }

  Future<void> _abrirFormularioEdicion(
    BuildContext context,
    ColaboradorDb c,
  ) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ColaboradorFormPage(colaboradorEditar: c),
      ),
    );

    if (resultado == true && widget.onActualizado != null) {
      widget.onActualizado!();
    }
  }
}

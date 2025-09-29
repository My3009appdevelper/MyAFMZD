import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/asignaciones_laborales/asignaciones_laborales_provider.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_provider.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/screens/asignaciones_laborales/asignaciones_laborales_form_page.dart';
import 'package:myafmzd/widgets/my_sheet_action.dart';
import 'package:myafmzd/widgets/my_show_detail_dialog.dart';

class AsignacionLaboralItemTile extends ConsumerStatefulWidget {
  final AsignacionLaboralDb asignacion;
  final VoidCallback onTap;
  final VoidCallback? onActualizado;

  const AsignacionLaboralItemTile({
    super.key,
    required this.asignacion,
    required this.onTap,
    this.onActualizado,
  });

  @override
  ConsumerState<AsignacionLaboralItemTile> createState() =>
      _AsignacionLaboralItemTileState();
}

class _AsignacionLaboralItemTileState
    extends ConsumerState<AsignacionLaboralItemTile> {
  @override
  Widget build(BuildContext context) {
    // versión viva desde provider
    final a = ref
        .watch(asignacionesLaboralesProvider)
        .firstWhere(
          (x) => x.uid == widget.asignacion.uid,
          orElse: () => widget.asignacion,
        );

    // lookups auxiliares
    final colab = _buscarColab(a.colaboradorUid);
    final dist = _buscarDistribuidor(a.distribuidorUid);
    final manager = _buscarColab(a.managerColaboradorUid);

    return ListTile(
      key: ValueKey(a.uid),
      leading: _buildAvatar(colab),
      title: Text(colab != null ? _nombreColab(colab) : '— colaborador —'),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // línea 1: Rol (nivel) — Distribuidor
          Text(
            [
              a.rol,
              if ((a.nivel).trim().isNotEmpty) '(${a.nivel})',
              if ((dist?.nombre ?? '').trim().isNotEmpty)
                '— ${dist!.nombre}'
              else if (a.distribuidorUid.trim().isNotEmpty)
                '— ${a.distribuidorUid}', // fallback por UID
            ].join(' ').replaceAll('  ', ' '),
          ),
          // línea 2: fechas
          Text(
            'Inicio: ${_fmtFecha(a.fechaInicio)} • '
            'Fin: ${a.fechaFin != null ? _fmtFecha(a.fechaFin!) : '—'}',
          ),
          // línea 3: manager (si aplica)
          if ((a.managerColaboradorUid).trim().isNotEmpty)
            Text(
              'Manager: ${manager != null ? _nombreColab(manager) : a.managerColaboradorUid}',
            ),
          // línea 4: notas (si cortitas)
          if (a.notas.trim().isNotEmpty)
            Text(
              a.notas,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.black54),
            ),
        ],
      ),
      isThreeLine: true,

      onTap: widget.onTap,
      onLongPress: () =>
          _mostrarOpcionesAsignacion(context, a, colab, dist, manager),
    );
  }

  // ============================ Acciones =============================

  Future<void> _abrirEdicion(AsignacionLaboralDb a) async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AsignacionLaboralFormPage(asignacionEditar: a),
      ),
    );
    if (resultado == true) widget.onActualizado?.call();
  }

  Future<void> _mostrarOpcionesAsignacion(
    BuildContext context,
    AsignacionLaboralDb a,
    ColaboradorDb? colab,
    DistribuidorDb? dist,
    ColaboradorDb? manager,
  ) {
    final acciones = <SheetAction>[
      SheetAction(
        icon: Icons.info_outline,
        label: 'Ver detalles',
        onTap: () => _mostrarDetalles(context, a, colab, dist, manager),
      ),
      if (!a.deleted)
        SheetAction(
          icon: Icons.edit,
          label: 'Editar',
          onTap: () => _abrirEdicion(a),
        ),
    ];

    return showActionSheet(context, title: 'Acciones', actions: acciones);
  }

  void _mostrarDetalles(
    BuildContext context,
    AsignacionLaboralDb a,
    ColaboradorDb? colab,
    DistribuidorDb? dist,
    ColaboradorDb? manager,
  ) {
    showDetailsDialog(
      context,
      title: 'Detalles de la asignación',
      fields: {
        'UID': a.uid,
        'Colaborador': colab != null ? _nombreColab(colab) : a.colaboradorUid,
        'Distribuidor': dist != null
            ? dist.nombre
            : (a.distribuidorUid.isEmpty ? '—' : a.distribuidorUid),
        'Manager': manager != null
            ? _nombreColab(manager)
            : (a.managerColaboradorUid.isEmpty ? '—' : a.managerColaboradorUid),
        'Rol': a.rol,
        'Nivel': a.nivel.isNotEmpty ? a.nivel : '—',
        'Puesto': a.puesto.isNotEmpty ? a.puesto : '—',
        'Inicio': _fmtFecha(a.fechaInicio),
        'Fin': a.fechaFin != null ? _fmtFecha(a.fechaFin!) : '—',
        'Notas': a.notas.isNotEmpty ? a.notas : '—',
        'Synced': a.isSynced ? 'Sí' : 'No',
        'Eliminado': a.deleted ? 'Sí' : 'No',
        'Creado': a.createdAt.toLocal().toString(),
        'Actualizado': a.updatedAt.toLocal().toString(),
      },
    );
  }

  // ============================ Helpers ==============================

  ColaboradorDb? _buscarColab(String? uid) {
    if (uid == null || uid.isEmpty) return null;
    try {
      return ref
          .read(colaboradoresProvider)
          .firstWhere((c) => c.uid == uid && !c.deleted);
    } catch (_) {
      return null;
    }
  }

  DistribuidorDb? _buscarDistribuidor(String? uid) {
    if (uid == null || uid.isEmpty) return null;
    try {
      return ref
          .read(distribuidoresProvider)
          .firstWhere((d) => d.uid == uid && !d.deleted);
    } catch (_) {
      return null;
    }
  }

  Widget _buildAvatar(ColaboradorDb? c) {
    if (c == null) {
      return const CircleAvatar(child: Icon(Icons.person));
    }
    final haveLocal =
        c.fotoRutaLocal != null &&
        c.fotoRutaLocal!.isNotEmpty &&
        File(c.fotoRutaLocal!).existsSync();
    if (haveLocal) {
      return CircleAvatar(backgroundImage: FileImage(File(c.fotoRutaLocal!)));
    }
    return CircleAvatar(child: Text(_iniciales(_nombreColab(c))));
  }

  String _nombreColab(ColaboradorDb c) =>
      '${c.nombres} ${c.apellidoPaterno} ${c.apellidoMaterno}'
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();

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

  String _fmtFecha(DateTime d) {
    final dl = d.toLocal();
    final dd = dl.day.toString().padLeft(2, '0');
    final mm = dl.month.toString().padLeft(2, '0');
    final yy = dl.year.toString();
    return '$dd/$mm/$yy';
  }
}

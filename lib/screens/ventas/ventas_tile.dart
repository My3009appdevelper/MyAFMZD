// lib/screens/ventas/ventas_item_tile.dart
// ignore_for_file: avoid_print

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/widgets/my_sheet_action.dart';
import 'package:myafmzd/widgets/my_show_detail_dialog.dart';

// Providers que usamos para “resolver” nombres
import 'package:myafmzd/database/ventas/ventas_provider.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_provider.dart';
import 'package:myafmzd/database/modelos/modelos_provider.dart';
import 'package:myafmzd/database/estatus/estatus_provider.dart';

/// Tile para mostrar una venta con información resumida.
/// - Lee la versión “viva” desde [ventasProvider] para mantenerse actualizada.
/// - Resuelve nombres de catálogo (distribuidor, vendedor, modelo, estatus).
/// - Long press: ver detalles / editar.
class VentaItemTile extends ConsumerStatefulWidget {
  final VentaDb venta;
  final VoidCallback onTap;
  final VoidCallback? onActualizado;

  const VentaItemTile({
    super.key,
    required this.venta,
    required this.onTap,
    this.onActualizado,
  });

  @override
  ConsumerState<VentaItemTile> createState() => _VentaItemTileState();
}

class _VentaItemTileState extends ConsumerState<VentaItemTile> {
  @override
  Widget build(BuildContext context) {
    // Versión “viva” desde provider (si no, usa la prop)
    final v = ref
        .watch(ventasProvider)
        .firstWhere(
          (x) => x.uid == widget.venta.uid,
          orElse: () => widget.venta,
        );

    // ======= Lookups (nombres legibles) =======
    final distNombre = _buscarDistribuidorNombre(v.distribuidoraUid);
    final distOrigenNombre = _buscarDistribuidorNombre(
      v.distribuidoraOrigenUid,
    );
    final vendedorNombre = _buscarColaboradorNombre(v.vendedorUid);
    final gerenteNombre = v.gerenteGrupoUid.isEmpty
        ? ''
        : _buscarColaboradorNombre(v.gerenteGrupoUid);
    final modeloStr = _modeloResumen(v.modeloUid);
    final estatus = _buscarEstatus(v.estatusUid);
    final estatusColor = _parseColorHex(estatus?.colorHex ?? '');

    // ======= UI =======
    final leading = CircleAvatar(
      backgroundColor:
          estatusColor ?? Theme.of(context).colorScheme.surfaceVariant,
      child: const Icon(Icons.receipt_long),
    );

    final titulo = [
      (v.folioContrato.trim().isEmpty ? '— folio —' : v.folioContrato.trim()),
      if (modeloStr.isNotEmpty) '· $modeloStr',
    ].join(' ');

    final linea1 = [
      // Dist actual y (si cambió) origen
      distNombre.isNotEmpty
          ? distNombre
          : (v.distribuidoraUid.isEmpty ? '—' : v.distribuidoraUid),
      if (v.distribuidoraOrigenUid.isNotEmpty &&
          v.distribuidoraOrigenUid != v.distribuidoraUid)
        ' (origen: ${distOrigenNombre.isNotEmpty ? distOrigenNombre : v.distribuidoraOrigenUid})',
    ].join('');

    final linea2 = [
      'Vendedor: ${vendedorNombre.isNotEmpty ? vendedorNombre : v.vendedorUid}',
      if (v.gerenteGrupoUid.isNotEmpty)
        ' • Gte: ${gerenteNombre.isNotEmpty ? gerenteNombre : v.gerenteGrupoUid}',
    ].join('');

    final linea3 = [
      'G/I: ${v.grupo}-${v.integrante}',
      '• Venta: ${v.fechaVenta != null ? _fmtFecha(v.fechaVenta!) : '—'}',
      if (v.mesVenta != null && v.anioVenta != null)
        '(${_fmtMesAnio(v.mesVenta!, v.anioVenta!)})',
    ].join(' ');

    final linea4 = [
      if (v.fechaContrato != null) 'Contrato: ${_fmtFecha(v.fechaContrato!)}',
    ].join(' ');

    return ListTile(
      key: ValueKey(v.uid),
      leading: leading,
      title: Text(titulo),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(linea1, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(linea2, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(linea3, maxLines: 1, overflow: TextOverflow.ellipsis),
          if (linea4.isNotEmpty)
            Text(linea4, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
      isThreeLine: true,
      onTap: widget.onTap,
      onLongPress: () => _mostrarOpcionesVenta(context, v),
    );
  }

  // ============================ Acciones =============================

  Future<void> _mostrarOpcionesVenta(BuildContext context, VentaDb v) {
    print('[💸 MENSAJES VENTAS TILE] opciones → ${v.uid}');
    return showActionSheet(
      context,
      title: 'Acciones',
      actions: [
        SheetAction(
          icon: Icons.info_outline,
          label: 'Ver detalles',
          onTap: () => _mostrarDetalles(context, v),
        ),
      ],
    );
  }

  void _mostrarDetalles(BuildContext context, VentaDb v) {
    final distNombre = _buscarDistribuidorNombre(v.distribuidoraUid);
    final distOrigenNombre = _buscarDistribuidorNombre(
      v.distribuidoraOrigenUid,
    );
    final vendedorNombre = _buscarColaboradorNombre(v.vendedorUid);
    final gerenteNombre = v.gerenteGrupoUid.isEmpty
        ? ''
        : _buscarColaboradorNombre(v.gerenteGrupoUid);
    final modeloStr = _modeloResumen(v.modeloUid);
    final estatus = _buscarEstatus(v.estatusUid);

    showDetailsDialog(
      context,
      title: 'Detalles de la venta',
      fields: {
        'UID': v.uid,
        'Folio': v.folioContrato.isNotEmpty ? v.folioContrato : '—',
        'Modelo': modeloStr.isNotEmpty ? modeloStr : v.modeloUid,
        'Distribuidora': distNombre.isNotEmpty
            ? distNombre
            : v.distribuidoraUid,
        'Origen': distOrigenNombre.isNotEmpty
            ? distOrigenNombre
            : (v.distribuidoraOrigenUid.isEmpty
                  ? '—'
                  : v.distribuidoraOrigenUid),
        'Vendedor': vendedorNombre.isNotEmpty ? vendedorNombre : v.vendedorUid,
        'Gerente grupo': v.gerenteGrupoUid.isEmpty
            ? '—'
            : (gerenteNombre.isNotEmpty ? gerenteNombre : v.gerenteGrupoUid),
        'Grupo': v.grupo.toString(),
        'Integrante': v.integrante.toString(),
        'Fecha venta': v.fechaVenta != null ? _fmtFecha(v.fechaVenta!) : '—',
        'Mes/Año venta': (v.mesVenta != null && v.anioVenta != null)
            ? '${v.mesVenta}/${v.anioVenta}'
            : '—',
        'Fecha contrato': v.fechaContrato != null
            ? _fmtFecha(v.fechaContrato!)
            : '—',
        'Estatus':
            estatus?.nombre ?? (v.estatusUid.isEmpty ? '—' : v.estatusUid),
        'Synced': v.isSynced ? 'Sí' : 'No',
        'Eliminado': v.deleted ? 'Sí' : 'No',
        'Creado': v.createdAt.toLocal().toString(),
        'Actualizado': v.updatedAt.toLocal().toString(),
      },
    );
  }

  // ============================ Helpers ==============================

  String _buscarDistribuidorNombre(String uid) {
    if (uid.isEmpty) return '';
    try {
      final list = ref.read(distribuidoresProvider);
      final d = list.firstWhere((x) => x.uid == uid && !x.deleted);
      return d.nombre.trim();
    } catch (_) {
      return '';
    }
  }

  String _buscarColaboradorNombre(String uid) {
    if (uid.isEmpty) return '';
    try {
      final list = ref.read(colaboradoresProvider);
      final c = list.firstWhere((x) => x.uid == uid && !x.deleted);
      final nom = '${c.nombres} ${c.apellidoPaterno} ${c.apellidoMaterno}'
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      return nom;
    } catch (_) {
      return '';
    }
  }

  String _modeloResumen(String modeloUid) {
    if (modeloUid.isEmpty) return '';
    try {
      final list = ref.read(modelosProvider);
      final m = list.firstWhere((x) => x.uid == modeloUid && !x.deleted);
      // “Modelo (año)” o “marca modelo (año)” si quieres mayor contexto
      return '${m.modelo} ${m.anio}';
    } catch (_) {
      return '';
    }
  }

  EstatusDb? _buscarEstatus(String uid) {
    if (uid.isEmpty) return null;
    try {
      final list = ref.read(estatusProvider);
      return list.firstWhere((x) => x.uid == uid && !x.deleted);
    } catch (_) {
      return null;
    }
  }

  String _fmtFecha(DateTime d) {
    final dl = d.toLocal();
    final dd = dl.day.toString().padLeft(2, '0');
    final mm = dl.month.toString().padLeft(2, '0');
    final yy = dl.year.toString();
    return '$dd/$mm/$yy';
  }

  String _fmtMesAnio(int mes, int anio) {
    final mm = mes.toString().padLeft(2, '0');
    return '$mm/$anio';
  }

  Color? _parseColorHex(String hex) {
    final h = hex.trim();
    if (h.isEmpty) return null;
    final raw = h.startsWith('#') ? h.substring(1) : h;
    final ok = RegExp(r'^[0-9a-fA-F]{6}([0-9a-fA-F]{2})?$').hasMatch(raw);
    if (!ok) return null;
    // #RRGGBB or #RRGGBBAA → Flutter usa AARRGGBB
    if (raw.length == 6) {
      final val = int.parse('FF$raw', radix: 16);
      return Color(val);
    }
    final aarrggbb = raw.substring(6, 8) + raw.substring(0, 6); // AA + RRGGBB
    return Color(int.parse(aarrggbb, radix: 16));
  }
}

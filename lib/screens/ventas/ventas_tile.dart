import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/asignaciones_laborales/asignaciones_laborales_provider.dart';
import 'package:myafmzd/widgets/my_sheet_action.dart';
import 'package:myafmzd/widgets/my_show_detail_dialog.dart';
import 'package:myafmzd/database/ventas/ventas_provider.dart';
import 'package:myafmzd/database/distribuidores/distribuidores_provider.dart';
import 'package:myafmzd/database/colaboradores/colaboradores_provider.dart';
import 'package:myafmzd/database/estatus/estatus_provider.dart';

/// Tile para mostrar una venta con información resumida.
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
    final v = ref
        .watch(ventasProvider)
        .firstWhere(
          (x) => x.uid == widget.venta.uid,
          orElse: () => widget.venta,
        );

    // ======= Lookups (nombres legibles) =======
    final distNombre = _sinPrefijoMazda(
      _buscarDistribuidorNombre(v.distribuidoraUid),
    );
    final distOrigenNombre = _sinPrefijoMazda(
      _buscarDistribuidorNombre(v.distribuidoraOrigenUid),
    );

    // 👇 AHORA: vendedor desde Asignación Laboral -> Colaborador
    final vendedorNombre = _buscarVendedorDesdeAsignacion(v.vendedorUid);

    final estatus = _buscarEstatus(v.estatusUid);
    final estatusColor = _parseColorHex(estatus?.colorHex ?? '');

    // Mes/Año
    final mm = v.mesVenta ?? v.fechaVenta?.toUtc().month;
    final aa = v.anioVenta ?? v.fechaVenta?.toUtc().year;
    final mesAnioStr = (mm != null && aa != null) ? _fmtMesAnio(mm, aa) : '—';

    // ======= UI =======
    final leading = CircleAvatar(
      backgroundColor:
          estatusColor ?? Theme.of(context).colorScheme.surfaceVariant,
      child: const Icon(Icons.receipt_long),
    );

    final titulo = (v.folioContrato.trim().isEmpty
        ? '— folio —'
        : v.folioContrato.trim());

    final linea1 = [
      (distNombre.isNotEmpty
          ? distNombre
          : (v.distribuidoraUid.isEmpty ? '—' : v.distribuidoraUid)),
      if (v.distribuidoraOrigenUid.isNotEmpty &&
          v.distribuidoraOrigenUid != v.distribuidoraUid)
        ' (origen: ${distOrigenNombre.isNotEmpty ? distOrigenNombre : v.distribuidoraOrigenUid})',
    ].join('');

    final linea2 =
        'Vendedor: ${vendedorNombre.isNotEmpty ? vendedorNombre : v.vendedorUid}';
    final linea3 =
        'Estatus: ${estatus?.nombre ?? (v.estatusUid.isEmpty ? "—" : v.estatusUid)}';
    final linea4 = 'Mes/Año venta: $mesAnioStr';

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
          Text(linea4, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
      isThreeLine: true,
      onTap: widget.onTap,
      onLongPress: () => _mostrarOpcionesVenta(context, v),
    );
  }

  Future<void> _mostrarOpcionesVenta(BuildContext context, VentaDb v) {
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

    // 👇 mismo lookup correcto para el vendedor
    final vendedorNombre = _buscarVendedorDesdeAsignacion(v.vendedorUid);

    final estatus = _buscarEstatus(v.estatusUid);

    showDetailsDialog(
      context,
      title: 'Detalles de la venta',
      fields: {
        'UID': v.uid,
        'Folio': v.folioContrato.isNotEmpty ? v.folioContrato : '—',
        'Distribuidora': distNombre.isNotEmpty
            ? distNombre
            : v.distribuidoraUid,
        'Origen': distOrigenNombre.isNotEmpty
            ? distOrigenNombre
            : (v.distribuidoraOrigenUid.isEmpty
                  ? '—'
                  : v.distribuidoraOrigenUid),
        'Vendedor': vendedorNombre.isNotEmpty ? vendedorNombre : v.vendedorUid,
        'Grupo': v.grupo.toString(),
        'Integrante': v.integrante.toString(),
        'Fecha venta': v.fechaVenta != null ? _fmtFecha(v.fechaVenta!) : '—',
        'Mes/Año venta': (v.mesVenta != null && v.anioVenta != null)
            ? _fmtMesAnio(v.mesVenta!, v.anioVenta!)
            : (v.fechaVenta != null
                  ? _fmtMesAnio(
                      v.fechaVenta!.toUtc().month,
                      v.fechaVenta!.toUtc().year,
                    )
                  : '—'),
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

  // ✅ Quitar prefijos "Mazda" robusto (case-insensitive, varios separadores)
  String _sinPrefijoMazda(String s) {
    if (s.isEmpty) return '';
    final reg = RegExp(r'^\s*mazda\b[\s\-–—:]*', caseSensitive: false);
    final out = s.replaceFirst(reg, '');
    return out.trimLeft();
  }

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

  // 🔎 VENDEDOR: resolve desde Asignación → Colaborador
  String _buscarVendedorDesdeAsignacion(String asignacionUid) {
    if (asignacionUid.isEmpty) return '';
    try {
      final asignaciones = ref.read(asignacionesLaboralesProvider);
      final asg = asignaciones.firstWhere(
        (a) => a.uid == asignacionUid && !a.deleted,
      );

      // si la asignación está cerrada también vale; ya la encontramos
      final colabUid = asg.colaboradorUid;
      if (colabUid.isEmpty) return '';

      final colaboradores = ref.read(colaboradoresProvider);
      final c = colaboradores.firstWhere(
        (x) => x.uid == colabUid && !x.deleted,
      );
      final nom = '${c.nombres} ${c.apellidoPaterno} ${c.apellidoMaterno}'
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      return nom;
    } catch (_) {
      // fallback defensivo: si por error el vendedorUid viniera como colaboradorUid,
      // intentamos resolver directo para no dejar el tile en blanco.
      try {
        final colaboradores = ref.read(colaboradoresProvider);
        final c = colaboradores.firstWhere(
          (x) => x.uid == asignacionUid && !x.deleted,
        );
        final nom = '${c.nombres} ${c.apellidoPaterno} ${c.apellidoMaterno}'
            .replaceAll(RegExp(r'\s+'), ' ')
            .trim();
        return nom;
      } catch (_) {
        return '';
      }
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
    if (raw.length == 6) {
      final val = int.parse('FF$raw', radix: 16);
      return Color(val);
    }
    final aarrggbb = raw.substring(6, 8) + raw.substring(0, 6);
    return Color(int.parse(aarrggbb, radix: 16));
  }
}

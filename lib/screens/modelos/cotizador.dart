import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/app_database.dart';

final cotizadorProvider = Provider<Cotizador>((ref) => Cotizador());

class CotizacionParams {
  final double precio; // precio del vehículo
  final int plazoMeses;
  final int mesEntrega; // 1..plazo-1
  final int adelanto; // 0..(plazo - mesEntrega)

  // Factores/cuotas (proporciones)
  final double factorIntegrante;
  final double factorPropietario;
  final double cuotaInscripcionPct;
  final double cuotaAdministracionPct;
  final double ivaCuotaAdministracionPct;
  final double cuotaSeguroVidaPct;

  const CotizacionParams({
    required this.precio,
    required this.plazoMeses,
    required this.mesEntrega,
    required this.adelanto,
    required this.factorIntegrante,
    required this.factorPropietario,
    required this.cuotaInscripcionPct,
    required this.cuotaAdministracionPct,
    required this.ivaCuotaAdministracionPct,
    required this.cuotaSeguroVidaPct,
  });

  CotizacionParams clampWithProducto(ProductoDb p) {
    final minMes = (p.mesEntregaMin <= 0 ? 1 : p.mesEntregaMin);
    final maxMes = (p.mesEntregaMax <= 0 ? (plazoMeses - 1) : p.mesEntregaMax)
        .clamp(1, plazoMeses - 1);

    final mesOk = mesEntrega.clamp(minMes, maxMes);

    final maxAdelantoPorMes = (plazoMeses - mesOk).clamp(0, plazoMeses);
    // También respetar límites de producto
    final adelMin = p.adelantoMinMens.clamp(0, plazoMeses);
    final adelMax = p.adelantoMaxMens.clamp(0, plazoMeses);
    final adelOk = adelanto.clamp(adelMin, adelMax).clamp(0, maxAdelantoPorMes);

    return CotizacionParams(
      precio: precio,
      plazoMeses: plazoMeses,
      mesEntrega: mesOk,
      adelanto: adelOk,
      factorIntegrante: factorIntegrante,
      factorPropietario: factorPropietario,
      cuotaInscripcionPct: cuotaInscripcionPct,
      cuotaAdministracionPct: cuotaAdministracionPct,
      ivaCuotaAdministracionPct: ivaCuotaAdministracionPct,
      cuotaSeguroVidaPct: cuotaSeguroVidaPct,
    );
  }
}

class CotizacionResumen {
  // Aportaciones y gastos base (mensuales)
  final double aportacionIntegrante;
  final double aportacionPropietario;
  final double montoInscripcion;
  final double montoAdministracion;
  final double montoIvaAdministracion;
  final double montoSeguroVida;

  // Mensualidades (mientras-integrante / ya-propietario)
  final double mensualidadIntegrante;
  final double mensualidadPropietario;

  // Adelanto en el mes de adjudicación
  final double adelantoAportacion;
  final double adelantoMontoAdministracion;
  final double adelantoMontoIvaAdministracion;
  final double adelantoMontoTotal;

  // Conteos/ayudas
  final int integrantMonths; // mesEntrega - 1
  final int proprietorMonths; // plazo - mesEntrega - adelanto + 1
  final int pagosTotales; // plazo - adelanto

  const CotizacionResumen({
    required this.aportacionIntegrante,
    required this.aportacionPropietario,
    required this.montoInscripcion,
    required this.montoAdministracion,
    required this.montoIvaAdministracion,
    required this.montoSeguroVida,
    required this.mensualidadIntegrante,
    required this.mensualidadPropietario,
    required this.adelantoAportacion,
    required this.adelantoMontoAdministracion,
    required this.adelantoMontoIvaAdministracion,
    required this.adelantoMontoTotal,
    required this.integrantMonths,
    required this.proprietorMonths,
    required this.pagosTotales,
  });
}

class CotizacionFilaPago {
  final int numero; // 1..pagosTotales
  final String estatus; // "Integrante" o "Propietario"
  final double aportacion;
  final double gastosAdm;
  final double ivaAdm;
  final double seguroVida;
  final double mensualidad;

  CotizacionFilaPago({
    required this.numero,
    required this.estatus,
    required this.aportacion,
    required this.gastosAdm,
    required this.ivaAdm,
    required this.seguroVida,
    required this.mensualidad,
  });
}

class Cotizador {
  /// Crea parámetros desde un ProductoDb + precio + elecciones del usuario.
  CotizacionParams paramsDesdeProducto({
    required ProductoDb producto,
    required double precioVehiculo,
    required int mesEntrega,
    required int adelanto,
  }) {
    final p = CotizacionParams(
      precio: precioVehiculo,
      plazoMeses: producto.plazoMeses,
      mesEntrega: mesEntrega,
      adelanto: adelanto,
      factorIntegrante: producto.factorIntegrante,
      factorPropietario: producto.factorPropietario,
      cuotaInscripcionPct: producto.cuotaInscripcionPct,
      cuotaAdministracionPct: producto.cuotaAdministracionPct,
      ivaCuotaAdministracionPct: producto.ivaCuotaAdministracionPct,
      cuotaSeguroVidaPct: producto.cuotaSeguroVidaPct,
    );
    // Respeta límites del producto
    return p.clampWithProducto(producto);
  }

  /// Calcula el resumen (equivalente a tu `cotizar_resumen` en Python).
  CotizacionResumen calcularResumen(CotizacionParams p) {
    final precio = p.precio;

    // --- Aportaciones y gastos base (mensuales) ---
    final aportacionIntegrante = precio * p.factorIntegrante;
    final aportacionPropietario = precio * p.factorPropietario;
    final montoInscripcion = precio * p.cuotaInscripcionPct;
    final montoAdministracion = precio * p.cuotaAdministracionPct;
    final montoIvaAdministracion =
        montoAdministracion * p.ivaCuotaAdministracionPct;
    final montoSeguroVida = precio * p.cuotaSeguroVidaPct;

    final mensualidadIntegrante =
        aportacionIntegrante +
        montoAdministracion +
        montoIvaAdministracion +
        montoSeguroVida;
    final mensualidadPropietario =
        aportacionPropietario +
        montoAdministracion +
        montoIvaAdministracion +
        montoSeguroVida;

    // --- Adelanto (se paga en el mes de adjudicación) ---
    final adelantoAportacion = aportacionIntegrante * p.adelanto;
    final adelantoMontoAdministracion = montoAdministracion * p.adelanto;
    final adelantoMontoIvaAdministracion =
        adelantoMontoAdministracion * p.ivaCuotaAdministracionPct;
    final adelantoMontoTotal =
        adelantoAportacion +
        adelantoMontoAdministracion +
        adelantoMontoIvaAdministracion;

    // --- Conteos estilo bot ---
    final integrantMonths = (p.mesEntrega - 1).clamp(0, p.plazoMeses);
    final proprietorMonths = (p.plazoMeses - p.mesEntrega - p.adelanto + 1)
        .clamp(0, p.plazoMeses);
    final pagosTotales = (p.plazoMeses - p.adelanto).clamp(0, p.plazoMeses);

    return CotizacionResumen(
      aportacionIntegrante: aportacionIntegrante,
      aportacionPropietario: aportacionPropietario,
      montoInscripcion: montoInscripcion,
      montoAdministracion: montoAdministracion,
      montoIvaAdministracion: montoIvaAdministracion,
      montoSeguroVida: montoSeguroVida,
      mensualidadIntegrante: mensualidadIntegrante,
      mensualidadPropietario: mensualidadPropietario,
      adelantoAportacion: adelantoAportacion,
      adelantoMontoAdministracion: adelantoMontoAdministracion,
      adelantoMontoIvaAdministracion: adelantoMontoIvaAdministracion,
      adelantoMontoTotal: adelantoMontoTotal,
      integrantMonths: integrantMonths,
      proprietorMonths: proprietorMonths,
      pagosTotales: pagosTotales,
    );
  }

  /// Genera la tabla de pagos (útil para PDF).
  /// Reproduce la lógica de tu Python:
  /// - Mes < mesEntrega: Integrante
  /// - Mes == mesEntrega: Propietario + se suman adelantos a ese mes
  /// - Mes > mesEntrega: Propietario
  List<CotizacionFilaPago> generarTablaPagos(CotizacionParams p) {
    final r = calcularResumen(p);
    final filas = <CotizacionFilaPago>[];

    for (int mes = 1; mes <= r.pagosTotales; mes++) {
      late String estatus;
      late double aportacion;
      late double adm;
      late double iva;

      if (mes < p.mesEntrega) {
        estatus = 'Integrante';
        aportacion = r.aportacionIntegrante;
        adm = r.montoAdministracion;
        iva = r.montoIvaAdministracion;
      } else if (mes == p.mesEntrega) {
        estatus = 'Propietario';
        aportacion = r.aportacionPropietario + r.adelantoAportacion;
        adm = r.montoAdministracion + r.adelantoMontoAdministracion;
        iva = r.montoIvaAdministracion + r.adelantoMontoIvaAdministracion;
      } else {
        estatus = 'Propietario';
        aportacion = r.aportacionPropietario;
        adm = r.montoAdministracion;
        iva = r.montoIvaAdministracion;
      }

      final mensualidad = aportacion + adm + iva + r.montoSeguroVida;

      filas.add(
        CotizacionFilaPago(
          numero: mes,
          estatus: estatus,
          aportacion: aportacion,
          gastosAdm: adm,
          ivaAdm: iva,
          seguroVida: r.montoSeguroVida,
          mensualidad: mensualidad,
        ),
      );
    }

    return filas;
  }
}

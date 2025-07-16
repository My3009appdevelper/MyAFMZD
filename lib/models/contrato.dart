class Contrato {
  final String nombreTitular;
  final String numeroContrato;
  final String estatus;
  final double montoTotal;
  final double montoPagado;
  final String fechaProximoPago;

  Contrato({
    required this.nombreTitular,
    required this.numeroContrato,
    required this.estatus,
    required this.montoTotal,
    required this.montoPagado,
    required this.fechaProximoPago,
  });
}

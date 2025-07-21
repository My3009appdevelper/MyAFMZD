class ReportePdf {
  final String nombre;
  final DateTime fecha;
  final String rutaRemota;
  String? rutaLocal;
  final String tipo;

  bool get descargado => rutaLocal != null;

  ReportePdf({
    required this.nombre,
    required this.fecha,
    required this.rutaRemota,
    this.rutaLocal,
    required this.tipo,
  });
}

class ReportePdf {
  final String nombre;
  final DateTime fecha;
  final String rutaRemota;
  String? rutaLocal;

  bool get descargado => rutaLocal != null;

  ReportePdf({
    required this.nombre,
    required this.fecha,
    required this.rutaRemota,
    this.rutaLocal,
  });

  factory ReportePdf.fromJson(Map<String, dynamic> json) {
    return ReportePdf(
      nombre: json['nombre'],
      fecha: DateTime.parse(json['fecha']),
      rutaRemota: json['ruta_remota'],
    );
  }
}

class ReportePdf {
  final String nombre;
  final DateTime fecha;
  final String rutaRemota;
  final String tipo;
  String? rutaLocal;

  bool get descargado => rutaLocal != null;
  bool get esAMDA => tipo.toLowerCase().contains('amda');

  ReportePdf({
    required this.nombre,
    required this.fecha,
    required this.rutaRemota,
    this.rutaLocal,
    required this.tipo,
  });

  factory ReportePdf.fromMap(Map<String, dynamic> map) {
    return ReportePdf(
      nombre: map['nombre'] ?? 'Sin nombre',
      fecha: DateTime.parse(map['fecha']),
      rutaRemota: map['ruta_remota'],
      rutaLocal: map['ruta_local'],
      tipo: map['tipo'] ?? 'interno',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'fecha': fecha.toIso8601String(),
      'ruta_remota': rutaRemota,
      'ruta_local': rutaLocal,
      'tipo': tipo,
    };
  }

  @override
  bool operator ==(Object other) {
    return other is ReportePdf &&
        nombre == other.nombre &&
        fecha == other.fecha &&
        rutaRemota == other.rutaRemota &&
        rutaLocal == other.rutaLocal &&
        tipo == other.tipo;
  }

  @override
  int get hashCode => Object.hash(nombre, fecha, rutaRemota, rutaLocal, tipo);
}

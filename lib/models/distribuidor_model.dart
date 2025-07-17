class Distribuidor {
  final String nombre;
  final String grupo;
  final String direccion;
  final bool activo;
  final double latitud;
  final double longitud;

  Distribuidor({
    required this.nombre,
    required this.grupo,
    required this.direccion,
    required this.activo,
    required this.latitud,
    required this.longitud,
  });

  factory Distribuidor.fromJson(Map<String, dynamic> json) {
    return Distribuidor(
      nombre: json['nombre'],
      grupo: json['grupo'],
      direccion: json['direccion'],
      activo: json['activo'],
      latitud: json['latitud'].toDouble(),
      longitud: json['longitud'].toDouble(),
    );
  }
}

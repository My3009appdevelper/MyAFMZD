class Distribuidor {
  final String id; // ← ID del documento en Firestore
  final String nombre;
  final String grupo;
  final String direccion;
  final bool activo;
  final double latitud;
  final double longitud;

  Distribuidor({
    required this.id,
    required this.nombre,
    required this.grupo,
    required this.direccion,
    required this.activo,
    required this.latitud,
    required this.longitud,
  });

  factory Distribuidor.fromMap(Map<String, dynamic> map, {required String id}) {
    return Distribuidor(
      id: id,
      nombre: map['nombre'] ?? 'Sin nombre',
      direccion: map['direccion'] ?? '',
      latitud: (map['latitud'] ?? 0).toDouble(),
      longitud: (map['longitud'] ?? 0).toDouble(),
      grupo: map['grupo'] ?? 'General',
      activo: map['activo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'grupo': grupo,
      'direccion': direccion,
      'activo': activo,
      'latitud': latitud,
      'longitud': longitud,
    };
  }

  // Para comparar objetos fácilmente
  @override
  bool operator ==(Object other) {
    return other is Distribuidor &&
        id == other.id &&
        nombre == other.nombre &&
        grupo == other.grupo &&
        direccion == other.direccion &&
        activo == other.activo &&
        latitud == other.latitud &&
        longitud == other.longitud;
  }

  @override
  int get hashCode =>
      Object.hash(id, nombre, grupo, direccion, activo, latitud, longitud);
}

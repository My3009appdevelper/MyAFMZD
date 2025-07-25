class UsuarioModel {
  final String uid;
  final String nombre;
  final String correo;
  final String rol;
  final String uuidDistribuidora;
  final Map<String, bool> permisos;

  UsuarioModel({
    required this.uid,
    required this.nombre,
    required this.correo,
    required this.rol,
    required this.uuidDistribuidora,
    required this.permisos,
  });

  factory UsuarioModel.fromMap(String uid, Map<String, dynamic> data) {
    return UsuarioModel(
      uid: uid,
      nombre: data['nombre'] ?? '',
      correo: data['correo'] ?? '',
      rol: data['rol'] ?? 'usuario',
      uuidDistribuidora: data['uuidDistribuidora'] ?? '',
      permisos: Map<String, bool>.from(data['permisos'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'correo': correo,
      'rol': rol,
      'uuidDistribuidora': uuidDistribuidora,
      'permisos': permisos,
    };
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

class UsuarioModel {
  final String uid;
  final String nombre;
  final String correo;
  final String rol;
  final String uuidDistribuidora;
  final Map<String, bool> permisos;
  final DateTime? updatedAt;

  UsuarioModel({
    required this.uid,
    required this.nombre,
    required this.correo,
    required this.rol,
    required this.uuidDistribuidora,
    required this.permisos,
    this.updatedAt,
  });

  factory UsuarioModel.fromMap(String uid, Map<String, dynamic> data) {
    return UsuarioModel(
      uid: uid,
      nombre: data['nombre'] ?? '',
      correo: data['correo'] ?? '',
      rol: data['rol'] ?? 'usuario',
      uuidDistribuidora: data['uuidDistribuidora'] ?? '',
      permisos: Map<String, bool>.from(data['permisos'] ?? {}),
      updatedAt: data['updatedAt'] is Timestamp
          ? (data['updatedAt'] as Timestamp).toDate()
          : (data['updatedAt'] is String
                ? DateTime.tryParse(data['updatedAt'])
                : null),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'correo': correo,
      'rol': rol,
      'uuidDistribuidora': uuidDistribuidora,
      'permisos': permisos,
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}

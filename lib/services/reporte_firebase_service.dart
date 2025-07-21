import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:myafmzd/models/reporte_pdf_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReporteFirebaseService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  static const _keyDescargados = 'reportes_descargados';

  /// Descarga y parsea el archivo reportes_index.json desde Firebase Storage.
  Future<List<ReportePdf>> listarReportesDesdeFirestore() async {
    print('🌐 Obteniendo reportes desde Firestore...');

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('reportes')
          .orderBy('fecha', descending: true)
          .get();
      print('✅ Documentos encontrados: ${snapshot.docs.length}');

      final descargados = await _cargarDescargados();

      return snapshot.docs.map((doc) {
        final data = doc.data();

        final rutaRemota = data['ruta_remota'] as String;

        return ReportePdf(
          nombre: data['nombre'] ?? 'Sin título',
          fecha: (data['fecha'] as Timestamp).toDate(),
          rutaRemota: rutaRemota,
          rutaLocal: descargados[rutaRemota]?['path_local'],
          tipo: data['tipo'] ?? 'Otros',
        );
      }).toList();
    } catch (e) {
      print('❌ Error al cargar reportes desde Firestore: $e');
      return [];
    }
  }

  /// Descarga un archivo PDF de forma temporal desde Firebase Storage.
  Future<File?> descargarTemporal(String rutaRemota) async {
    try {
      final ref = _storage.ref(rutaRemota);
      final bytes = await ref.getData();

      if (bytes == null) return null;

      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${rutaRemota.split('/').last}');
      await tempFile.writeAsBytes(bytes, flush: true);

      return tempFile;
    } catch (e) {
      print('❌ Error al descargar archivo temporal: $e');
      return null;
    }
  }

  /// Descarga un archivo PDF y lo guarda en el directorio de documentos.
  Future<File?> descargarYGuardar(
    String rutaRemota, {
    required String tipo,
  }) async {
    try {
      final ref = _storage.ref(rutaRemota);
      final bytes = await ref.getData();

      if (bytes == null) return null;

      final dir = await getApplicationDocumentsDirectory();
      final fechaCarpeta = rutaRemota.split('/').length >= 2
          ? rutaRemota.split('/')[1]
          : 'unknown';
      final nombreArchivo = rutaRemota.split('/').last;

      // Esto genera un nombre como: "2024-06_AFMZD_en_el_Sector...pdf"
      final nombreUnico = '${fechaCarpeta}_$nombreArchivo';

      final localFile = File('${dir.path}/$nombreUnico');

      await localFile.writeAsBytes(bytes, flush: true);

      // 🔐 Guardar en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyDescargados);
      final Map<String, dynamic> decoded = raw == null
          ? {}
          : jsonDecode(raw) as Map<String, dynamic>;

      decoded[rutaRemota] = {'path_local': localFile.path, 'tipo': tipo};

      await prefs.setString(_keyDescargados, jsonEncode(decoded));

      return localFile;
    } catch (e) {
      print('❌ Error al descargar y guardar: $e');
      return null;
    }
  }

  Future<Map<String, Map<String, String>>> _cargarDescargados() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyDescargados);
    if (raw == null) return {};

    try {
      final Map<String, dynamic> decoded = jsonDecode(raw);
      return decoded.map((ruta, data) {
        final mapa = data as Map<String, dynamic>;
        return MapEntry(ruta, {
          'path_local': mapa['path_local'] ?? '',
          'tipo': mapa['tipo'] ?? 'Otros',
        });
      });
    } catch (e) {
      print('❌ Error al leer rutas descargadas: $e');
      return {};
    }
  }

  Future<List<ReportePdf>> cargarSoloDescargados() async {
    final descargados = await _cargarDescargados();

    return descargados.entries.map((entry) {
      final rutaRemota = entry.key;
      final rutaLocal = entry.value['path_local']!;
      final tipo = entry.value['tipo'] ?? 'Otros';

      final nombre = rutaRemota
          .split('/')
          .last
          .replaceAll('.pdf', '')
          .replaceAll('_', ' ');

      final fecha = _extraerFechaDesdeRuta(rutaRemota);

      return ReportePdf(
        nombre: nombre,
        fecha: fecha,
        rutaRemota: rutaRemota,
        rutaLocal: rutaLocal,
        tipo: tipo,
      );
    }).toList();
  }

  DateTime _extraerFechaDesdeRuta(String ruta) {
    final partes = ruta.split('/');
    if (partes.length >= 2) {
      final mes = partes[1];
      final parts = mes.split('-');
      return DateTime(int.parse(parts[0]), int.parse(parts[1]), 1);
    }
    return DateTime.now();
  }

  List<String> listarFechasUnicas(List<ReportePdf> reportes) {
    final meses = reportes
        .map(
          (r) =>
              '${r.fecha.year.toString().padLeft(4, '0')}-${r.fecha.month.toString().padLeft(2, '0')}',
        )
        .toSet()
        .toList();

    meses.sort();
    return meses;
  }

  Future<void> eliminarDescarga(String rutaRemota) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyDescargados);
      if (raw == null) return;

      final Map<String, dynamic> decoded = jsonDecode(raw);

      final data = decoded[rutaRemota];
      if (data is Map && data.containsKey('path_local')) {
        final path = data['path_local'];

        if (path != null && path is String) {
          final file = File(path);
          if (await file.exists()) {
            await file.delete();
            print('🗑️ Archivo eliminado: $path');
          }
        }
      }

      // Remueve del mapa y guarda el nuevo JSON
      decoded.remove(rutaRemota);
      await prefs.setString(_keyDescargados, jsonEncode(decoded));
    } catch (e) {
      print('❌ Error al eliminar descarga: $e');
    }
  }
}

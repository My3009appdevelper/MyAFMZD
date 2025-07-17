import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:myafmzd/models/reporte_pdf_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReporteFirebaseService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  static const _keyDescargados = 'reportes_descargados';

  /// Descarga y parsea el archivo reportes_index.json desde Firebase Storage.
  Future<List<ReportePdf>> listarReportesDesdeFirebase() async {
    try {
      // 1. Referencia al archivo en el bucket
      final ref = _storage.ref('reportes/reportes_index.json');

      // 2. Obtener directorio temporal para guardar temporalmente el JSON
      final dir = await getTemporaryDirectory();
      final tempFile = File('${dir.path}/reportes_index.json');

      // 3. Descargar el JSON a archivo temporal
      await ref.writeToFile(tempFile);

      // 4. Leer y parsear
      final contenido = await tempFile.readAsString();
      final List<dynamic> jsonList = json.decode(contenido);

      // 5. Crear lista de objetos ReportePdf
      final descargados = await _cargarDescargados();

      return jsonList.map((e) {
        final rutaRemota = e['ruta_remota'];
        final rutaLocal = descargados[rutaRemota];

        return ReportePdf(
          nombre: e['nombre'],
          fecha: DateTime.parse(e['fecha']),
          rutaRemota: rutaRemota,
          rutaLocal: rutaLocal,
        );
      }).toList();
    } catch (e) {
      print('❌ Error al cargar reportes desde Firebase: $e');
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
  Future<File?> descargarYGuardar(String rutaRemota) async {
    try {
      final ref = _storage.ref(rutaRemota);
      final bytes = await ref.getData();

      if (bytes == null) return null;

      final dir = await getApplicationDocumentsDirectory();
      final nombreArchivo = rutaRemota.split('/').last;
      final localFile = File('${dir.path}/$nombreArchivo');
      await localFile.writeAsBytes(bytes, flush: true);

      // 🔐 Guardar en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_keyDescargados);
      final Map<String, dynamic> decoded = raw == null
          ? {}
          : jsonDecode(raw) as Map<String, dynamic>;

      decoded[rutaRemota] = localFile.path;
      await prefs.setString(_keyDescargados, jsonEncode(decoded));

      return localFile;
    } catch (e) {
      print('❌ Error al descargar y guardar: $e');
      return null;
    }
  }

  Future<Map<String, String>> _cargarDescargados() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyDescargados);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (e) {
      print('❌ Error al leer rutas descargadas: $e');
      return {};
    }
  }

  Future<List<ReportePdf>> cargarSoloDescargados() async {
    final descargados = await _cargarDescargados();

    return descargados.entries.map((entry) {
      final nombre = entry.key
          .split('/')
          .last
          .replaceAll('.pdf', '')
          .replaceAll('_', ' ');
      final fecha = _extraerFechaDesdeRuta(entry.key);
      return ReportePdf(
        nombre: nombre,
        fecha: fecha,
        rutaRemota: entry.key,
        rutaLocal: entry.value,
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
}

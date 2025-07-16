import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

void main() async {
  final String basePath = p.join(Directory.current.path, 'assets', 'reportes');
  final Directory baseDir = Directory(basePath);

  if (!await baseDir.exists()) {
    print('❌ La carpeta $basePath no existe.');
    return;
  }

  final List<Map<String, dynamic>> reportes = [];

  final List<FileSystemEntity> carpetas = baseDir.listSync();
  for (var carpeta in carpetas) {
    if (carpeta is Directory) {
      final String folderName = p.basename(carpeta.path);

      // Validar que tenga formato tipo '2025-01'
      if (!RegExp(r'^\d{4}-\d{2}$').hasMatch(folderName)) continue;

      final DateTime fechaBase = DateTime.parse('$folderName-01');

      final List<FileSystemEntity> archivos = carpeta.listSync();

      for (var archivo in archivos.whereType<File>()) {
        final nombreArchivoRaw = p.basename(archivo.path).trim();
        if (nombreArchivoRaw.isEmpty) continue;

        final String nombreArchivo = nombreArchivoRaw.replaceAll(
          RegExp(r'\.pdf$', caseSensitive: false),
          '',
        );

        final String nombreFormateado =
            '${capitalize(folderName)} - ${formatearNombre(nombreArchivo)}';

        reportes.add({
          'nombre': nombreFormateado,
          'ruta': 'assets/reportes/$folderName/$nombreArchivoRaw',
          'fecha': fechaBase.toIso8601String().split('T').first,
        });
      }
    }
  }

  final File output = File('$basePath/reportes_index.json');
  await output.writeAsString(
    const JsonEncoder.withIndent('  ').convert(reportes),
  );
}

String capitalize(String mes) {
  final partes = mes.split('-');
  return '${partes[0]}-${partes[1]}';
}

String formatearNombre(String raw) {
  return raw
      .replaceAll('_', ' ')
      .replaceAll('-', ' ')
      .split(' ')
      .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
      .join(' ')
      .trim();
}

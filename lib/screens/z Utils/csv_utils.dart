// lib/utils/csv_utils.dart
import 'dart:convert';
import 'package:csv/csv.dart';

/// Quita BOM UTF-8 si existe y decodifica a String.
String decodeCsvBytes(List<int> bytes) {
  const bom = [0xEF, 0xBB, 0xBF];
  if (bytes.length >= 3 &&
      bytes[0] == bom[0] &&
      bytes[1] == bom[1] &&
      bytes[2] == bom[2]) {
    bytes = bytes.sublist(3);
  }
  return utf8.decode(bytes);
}

/// true/false, 1/0, yes/no, si/no
bool parseBoolFlexible(String? raw, {bool defaultValue = false}) {
  if (raw == null) return defaultValue;
  final v = raw.trim().toLowerCase();
  if (v.isEmpty) return defaultValue;
  return v == 'true' || v == '1' || v == 'yes' || v == 'y' || v == 'si';
}

/// Parsea fechas comunes y devuelve UTC (solo fecha → medianoche UTC).
/// Acepta: ISO (yyyy-MM-dd[THH:mm:ss[.SSS]Z]),
/// dd/MM/yyyy, MM/dd/yyyy (heurística).
DateTime? parseDateFlexible(String? raw) {
  if (raw == null) return null;
  final s = raw.trim();
  if (s.isEmpty) return null;

  // ISO
  try {
    final d = DateTime.parse(s);
    return d.isUtc ? d : d.toUtc();
  } catch (_) {}

  // dd/MM/yyyy o MM/dd/yyyy o yyyy-MM-dd
  final parts = s.split(RegExp(r'[/\-\.]'));
  if (parts.length == 3) {
    final p0 = int.tryParse(parts[0]);
    final p1 = int.tryParse(parts[1]);
    final p2 = int.tryParse(parts[2]);
    if (p0 != null && p1 != null && p2 != null) {
      late final int y, m, d;
      if (parts[0].length == 4) {
        y = p0;
        m = p1;
        d = p2; // yyyy-MM-dd
      } else if (p0 > 12) {
        d = p0;
        m = p1;
        y = p2; // dd/MM/yyyy
      } else if (p1 > 12) {
        m = p0;
        d = p1;
        y = p2; // MM/dd/yyyy
      } else {
        d = p0;
        m = p1;
        y = p2; // por defecto dd/MM/yyyy
      }
      return DateTime.utc(y, m, d);
    }
  }

  return null;
}

/// Convierte a CSV y agrega BOM al inicio (mejor soporte en Excel).
String toCsvStringWithBom(List<List<dynamic>> rows) {
  final csv = const ListToCsvConverter(eol: '\n').convert(rows);
  return '\uFEFF$csv';
}

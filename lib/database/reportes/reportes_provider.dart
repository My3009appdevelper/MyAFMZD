// ignore_for_file: avoid_print

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/database_provider.dart';
import 'package:myafmzd/database/reportes/reportes_dao.dart';
import 'package:myafmzd/database/reportes/reportes_service.dart';
import 'package:myafmzd/database/reportes/reportes_sync.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:uuid/uuid.dart';

// -----------------------------------------------------------------------------
// Provider global (igual que Productos: pasamos ref y db)
// -----------------------------------------------------------------------------
final reporteProvider =
    StateNotifierProvider<ReporteNotifier, List<ReportesDb>>((ref) {
      final db = ref.watch(appDatabaseProvider);
      return ReporteNotifier(ref, db);
    });

class ReporteNotifier extends StateNotifier<List<ReportesDb>> {
  ReporteNotifier(this._ref, AppDatabase db)
    : _dao = ReportesDao(db),
      _service = ReportesService(db),
      _sync = ReportesSync(db),
      super([]);

  final Ref _ref;
  final ReportesDao _dao;
  final ReportesService _service;
  final ReportesSync _sync;

  bool _hayInternet = true;
  bool get hayInternet => _hayInternet;

  String? _mesSeleccionado;
  String? get mesSeleccionado => _mesSeleccionado;
  List<String> get mesesDisponibles => _listarMesesDisponibles();

  List<ReportesDb> get filtrados =>
      filtrarPorMesYTipo(mes: _mesSeleccionado ?? '');

  List<String> get tiposDisponibles {
    final tipos = state.map((r) => r.tipo.trim()).toSet().toList();
    tipos.sort();
    return tipos;
  }

  // 🧠 Cache en memoria para miniaturas
  final Map<String, Uint8List> _miniaturaCache = {};

  // -----------------------------------------------------------------------------
  // CARGA OFFLINE-FIRST (paridad con Productos: local → pull → push → refresh)
  // -----------------------------------------------------------------------------
  Future<void> cargarOfflineFirst() async {
    try {
      _hayInternet = _ref.read(connectivityProvider);

      // 1) Pintar base local primero
      final local = await _dao.obtenerTodosDrift();
      state = local;
      print('[🧾 MENSAJES REPORTES PROVIDER] Local cargado → ${local.length}');

      // Mes inicial (con local)
      _ensureMesInicial();

      // 2) Sin internet → listo
      if (!_hayInternet) {
        print(
          '[🧾 MENSAJES REPORTES PROVIDER] Sin internet → usando solo local',
        );
        return;
      }

      // 3) Guardar snapshot previo para invalidar miniaturas si cambió la rutaRemota
      final anteriores = {for (final r in state) r.uid: r.rutaRemota};

      // 4) Sync completo (igual que Productos)
      await _sync.pullReportesOnline();
      await _sync.pushReportesOffline();

      // 5) Recargar actualizados
      final actualizados = await _dao.obtenerTodosDrift();

      // 6) Invalidar miniaturas SOLO si cambió rutaRemota
      for (final r in actualizados) {
        final beforeRuta = anteriores[r.uid];
        if (beforeRuta != null && beforeRuta != r.rutaRemota) {
          await invalidarMiniatura(r.uid);
          await obtenerMiniatura(r);
          print(
            '[🧾 MENSAJES REPORTES PROVIDER] Miniatura invalidada por cambio remoto: ${r.nombre}',
          );
        }
      }

      state = actualizados;

      // 7) Verificar/ajustar mes tras sync
      _ensureMesInicial();
    } catch (e) {
      print(
        '[🧾 MENSAJES REPORTES PROVIDER] ❌ Error en cargarOfflineFirst: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Miniaturas (sin cambios funcionales, solo limpieza menor)
  // ---------------------------------------------------------------------------
  Future<Uint8List?> obtenerMiniatura(ReportesDb reporte) async {
    // 1) RAM
    if (_miniaturaCache.containsKey(reporte.uid)) {
      print('[🧾 MENSAJES REPORTES PROVIDER] ✅ Miniatura RAM: ${reporte.uid}');
      return _miniaturaCache[reporte.uid];
    }

    // 2) Disco (persistente si hay rutaLocal, temporal si no)
    final fileCache = await _miniaturaFile(
      reporte.uid,
      persistente: reporte.rutaLocal.isNotEmpty,
    );
    if (await fileCache.exists()) {
      final bytes = await fileCache.readAsBytes();
      _miniaturaCache[reporte.uid] = bytes;
      print(
        '[🧾 MENSAJES REPORTES PROVIDER] ✅ Miniatura disco: ${fileCache.path}',
      );
      return bytes;
    }

    File? file;

    // 3) PDF local
    if (reporte.rutaLocal.isNotEmpty &&
        await File(reporte.rutaLocal).exists()) {
      file = File(reporte.rutaLocal);
      print('[🧾 MENSAJES REPORTES PROVIDER] Generando miniatura desde local');
    }
    // 4) PDF online temporal (solo con internet)
    else if (_hayInternet) {
      file = await descargarTemporal(reporte);
    }

    if (file == null) {
      print('[🧾 MENSAJES REPORTES PROVIDER] ❌ No hay archivo para miniatura');
      return null;
    }

    final doc = await PdfDocument.openFile(file.path);
    final page = await doc.getPage(1);
    final image = await page.render(width: 110, height: 80);
    await page.close();

    if (image == null) {
      print('[🧾 MENSAJES REPORTES PROVIDER] ⚠️ Render nulo de miniatura');
      return null;
    }

    _miniaturaCache[reporte.uid] = image.bytes;

    // 5) Guardar en disco
    final outFile = await _miniaturaFile(
      reporte.uid,
      persistente: reporte.rutaLocal.isNotEmpty,
    );
    await outFile.writeAsBytes(image.bytes);
    print(
      '[🧾 MENSAJES REPORTES PROVIDER] 💾 Miniatura guardada: ${outFile.path}',
    );

    return image.bytes;
  }

  Future<void> invalidarMiniatura(String uid) async {
    print('[🧾 MENSAJES REPORTES PROVIDER] Invalidando miniatura: $uid');
    _miniaturaCache.remove(uid);

    final filePersistente = await _miniaturaFile(uid, persistente: true);
    final fileTemporal = await _miniaturaFile(uid, persistente: false);

    for (final file in [filePersistente, fileTemporal]) {
      if (await file.exists()) {
        await file.delete();
        print('[🧾 MENSAJES REPORTES PROVIDER] 🗑️ Eliminada: ${file.path}');
      }
    }
  }

  Future<File> _miniaturaFile(String uid, {required bool persistente}) async {
    final dir = persistente
        ? await getApplicationDocumentsDirectory()
        : await getTemporaryDirectory();
    return File('${dir.path}/miniatura_$uid.png');
  }

  Future<File?> descargarTemporal(ReportesDb reporte) async {
    print(
      '[🧾 MENSAJES REPORTES PROVIDER] Descarga temporal: ${reporte.nombre}',
    );
    final dir = await getTemporaryDirectory();
    final tempPath = '${dir.path}/${reporte.uid}.pdf';
    final tempFile = File(tempPath);

    if (await tempFile.exists()) {
      print('[🧾 MENSAJES REPORTES PROVIDER] Temporal ya existe: $tempPath');
      return tempFile;
    }

    final file = await _service.descargarPDFOnline(reporte.rutaRemota);
    if (file == null) return null;

    await file.copy(tempFile.path);
    print(
      '[🧾 MENSAJES REPORTES PROVIDER] Temporal guardado: ${tempFile.path}',
    );
    return tempFile;
  }

  // ---------------------------------------------------------------------------
  // Filtros (sin cambios)
  // ---------------------------------------------------------------------------
  List<ReportesDb> filtrarPorMesYTipo({required String mes, String? tipo}) {
    return state.where((r) {
      final m =
          '${r.fecha.year.toString().padLeft(4, '0')}-'
          '${r.fecha.month.toString().padLeft(2, '0')}';
      final fechaOk = m == mes;
      final tipoOk = tipo == null || r.tipo == tipo;
      final descargadoOk =
          _hayInternet ||
          (r.rutaLocal.isNotEmpty && File(r.rutaLocal).existsSync());
      return fechaOk && tipoOk && descargadoOk;
    }).toList()..sort((a, b) {
      final cmpNombre = a.nombre.compareTo(b.nombre);
      return cmpNombre != 0 ? cmpNombre : b.fecha.compareTo(a.fecha);
    });
  }

  List<String> _listarMesesDisponibles() {
    final meses = state
        .map(
          (r) =>
              '${r.fecha.year.toString().padLeft(4, '0')}-${r.fecha.month.toString().padLeft(2, '0')}',
        )
        .toSet()
        .toList();
    meses.sort((a, b) => b.compareTo(a));
    return meses;
  }

  void seleccionarMes(String mes) {
    _mesSeleccionado = mes;
  }

  void _ensureMesInicial() {
    final meses = _listarMesesDisponibles();
    if (_mesSeleccionado == null || !meses.contains(_mesSeleccionado)) {
      _mesSeleccionado = meses.isNotEmpty ? meses.first : null;
      if (_mesSeleccionado == null) {
        print('[🧾 MENSAJES REPORTES PROVIDER] ⚠️ Sin meses disponibles');
      } else {
        print(
          '[🧾 MENSAJES REPORTES PROVIDER] Mes seleccionado: $_mesSeleccionado',
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Descarga / Eliminación de PDFs (ajustado a Companions)
  // ---------------------------------------------------------------------------
  Future<ReportesDb?> descargarPDF(ReportesDb reporte) async {
    final file = await _service.descargarPDFOnline(reporte.rutaRemota);
    if (file == null) {
      print(
        '[🧾 MENSAJES REPORTES PROVIDER] ❌ No se pudo descargar ${reporte.rutaRemota}',
      );
      return null;
    }

    // Actualización parcial (rutaLocal + updatedAt); no tocamos isSynced
    await invalidarMiniatura(reporte.uid);
    await _dao.upsertReporteDrift(
      ReportesCompanion(uid: Value(reporte.uid), rutaLocal: Value(file.path)),
    );

    final actualizados = await _dao.obtenerTodosDrift();
    state = actualizados;

    final actualizado = actualizados.firstWhere(
      (r) => r.uid == reporte.uid,
      orElse: () => reporte,
    );
    print('[🧾 MENSAJES REPORTES PROVIDER] ✅ PDF descargado en: ${file.path}');
    return actualizado;
  }

  bool todosDescargados(List<ReportesDb> lista) {
    return lista.every(
      (r) => r.rutaLocal.isNotEmpty && File(r.rutaLocal).existsSync(),
    );
  }

  Future<int> descargarTodos(List<ReportesDb> lista) async {
    int count = 0;
    for (final r in lista) {
      if (r.rutaLocal.isNotEmpty && File(r.rutaLocal).existsSync()) continue;
      final ok = await descargarPDF(r);
      if (ok != null) count++;
    }
    return count;
  }

  Future<void> eliminarPDF(ReportesDb reporte) async {
    print(
      '[🧾 MENSAJES REPORTES PROVIDER] Borrando PDF: ${reporte.rutaRemota}',
    );
    if (reporte.rutaLocal.isNotEmpty) {
      final file = File(reporte.rutaLocal);
      if (await file.exists()) {
        await file.delete();
        print(
          '[🧾 MENSAJES REPORTES PROVIDER] Borrado local: ${reporte.rutaRemota}',
        );
      }
    }

    await _dao.upsertReporteDrift(
      ReportesCompanion(uid: Value(reporte.uid), rutaLocal: const Value('')),
    );

    final actualizados = await _dao.obtenerTodosDrift();
    state = actualizados;
  }

  Future<int> eliminarTodos(List<ReportesDb> lista) async {
    int count = 0;
    for (final r in lista) {
      if (r.rutaLocal.isNotEmpty) {
        await eliminarPDF(r);
        count++;
      }
    }
    return count;
  }

  Map<String, List<ReportesDb>> agruparPorTipo(List<ReportesDb> lista) {
    final grupos = <String, List<ReportesDb>>{};
    for (final r in lista) {
      grupos.putIfAbsent(r.tipo.toUpperCase(), () => []).add(r);
    }
    return grupos;
  }

  // ---------------------------------------------------------------------------
  // Crear / Editar (paridad con Productos; companions + flags de sync)
  // ---------------------------------------------------------------------------
  Future<ReportesDb> crearReporteLocal({
    required String nombre,
    required String tipo,
    required DateTime fecha,
    required String rutaRemota,
  }) async {
    final uid = const Uuid().v4();
    final now = DateTime.now().toUtc();

    await _dao.upsertReporteDrift(
      ReportesCompanion.insert(
        uid: uid,
        nombre: Value(nombre),
        tipo: Value(tipo),
        fecha: Value(fecha.toUtc()),
        rutaRemota: Value(rutaRemota),
        rutaLocal: const Value(''),
        deleted: const Value(false),
        isSynced: const Value(false),
        updatedAt: Value(now),
      ),
    );

    final actualizados = await _dao.obtenerTodosDrift();
    state = actualizados;

    _ensureMesInicial();
    return actualizados.firstWhere((r) => r.uid == uid);
  }

  Future<ReportesDb> editarReporte({required ReportesDb actualizado}) async {
    final now = DateTime.now().toUtc();

    await _dao.upsertReporteDrift(
      ReportesCompanion(
        uid: Value(actualizado.uid),
        nombre: Value(actualizado.nombre),
        tipo: Value(actualizado.tipo),
        fecha: Value(actualizado.fecha.toUtc()),
        rutaRemota: Value(actualizado.rutaRemota),
        rutaLocal: Value(actualizado.rutaLocal),
        isSynced: const Value(false),
        updatedAt: Value(now),
        deleted: Value(actualizado.deleted),
      ),
    );

    final actualizados = await _dao.obtenerTodosDrift();
    state = actualizados;

    _ensureMesInicial();
    return actualizados.firstWhere((r) => r.uid == actualizado.uid);
  }

  // ---------------------------------------------------------------------------
  // Subir nuevo PDF (local → invalidación miniatura → sync si hay internet)
  // ---------------------------------------------------------------------------
  Future<void> subirNuevoPDF({
    required ReportesDb reporte,
    required File archivo,
    required String nuevoPath,
  }) async {
    try {
      // 1) Copiar local
      final dir = await getApplicationDocumentsDirectory();
      final safeName = nuevoPath.replaceAll('/', '_');
      final destino = File('${dir.path}/$safeName');
      await archivo.copy(destino.path);

      // 2) Actualizar local (no sync aún)
      await _dao.upsertReporteDrift(
        ReportesCompanion(
          uid: Value(reporte.uid),
          rutaRemota: Value(nuevoPath),
          rutaLocal: Value(destino.path),
          updatedAt: Value(DateTime.now().toUtc()),
          isSynced: const Value(false),
        ),
      );

      // refrescar estado
      state = await _dao.obtenerTodosDrift();

      // 3) Miniatura
      await invalidarMiniatura(reporte.uid);
      final actualizado = state.firstWhere(
        (r) => r.uid == reporte.uid,
        orElse: () => reporte,
      );
      await obtenerMiniatura(actualizado);

      // 4) Intentar sync si hay internet
      if (_hayInternet) {
        await cargarOfflineFirst();
      }

      print(
        '[🧾 MENSAJES REPORTES PROVIDER] PDF guardado localmente: ${destino.path}',
      );
    } catch (e) {
      print('[🧾 MENSAJES REPORTES PROVIDER] Error preparando PDF: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // Utilidades varias
  // ---------------------------------------------------------------------------
  ReportesDb? obtenerPorUid(String uid) {
    try {
      return state.firstWhere((r) => r.uid == uid);
    } catch (_) {
      return null;
    }
  }
}

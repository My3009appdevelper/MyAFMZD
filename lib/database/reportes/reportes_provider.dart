import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/reportes/reportes_dao.dart';
import 'package:myafmzd/database/reportes/reportes_service.dart';
import 'package:myafmzd/database/reportes/reportes_sync.dart';
import 'package:myafmzd/main.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:uuid/uuid.dart';

final reporteProvider =
    StateNotifierProvider<ReporteNotifier, List<ReportesDb>>((ref) {
      final db = ref.watch(appDatabaseProvider);
      return ReporteNotifier(db);
    });

class ReporteNotifier extends StateNotifier<List<ReportesDb>> {
  ReporteNotifier(AppDatabase db)
    : _dao = ReportesDao(db),
      _service = ReportesService(db),
      _sync = ReportesSync(db),
      super([]);

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

  // ---------------------------------------------------------------------------
  // 📌 Cargar lista desde Drift (local + sync con Supabase)
  // ---------------------------------------------------------------------------
  Future<void> cargar({required bool hayInternet}) async {
    _hayInternet = hayInternet;

    // Pintar base local primero
    final local = await _dao.obtenerTodosDrift();
    state = local;
    print('[📴 REPORTES PROVIDER] Local cargado -> ${local.length} reportes');

    // 🔥 Seleccionar mes inicial apenas cargamos local
    final meses = _listarMesesDisponibles();
    if (_mesSeleccionado == null || !meses.contains(_mesSeleccionado)) {
      if (meses.isNotEmpty) {
        _mesSeleccionado = meses.first;
        print(
          '[📅 REPORTES PROVIDER] Mes inicial seleccionado: $_mesSeleccionado',
        );
      } else {
        _mesSeleccionado = null;
        print('[📅 REPORTES PROVIDER] ⚠️ No hay meses disponibles');
      }
    }

    // 2️⃣ Si no hay internet → detenerse aquí
    if (!hayInternet) {
      print('[📴 REPORTES PROVIDER] Sin internet → usando solo local');
      return;
    }

    // Comparar timestamps
    final localTimestamp = await _dao.obtenerUltimaActualizacionDrift();
    final remoto = await _service.comprobarActualizacionesOnline();

    print('[⏱️ REPORTES PROVIDER] Remoto:$remoto | Local:$localTimestamp');

    if (remoto == null) {
      print('[📴 REPORTES PROVIDER] ⚠️ Supabase vacío → usar solo local');
      return;
    }

    if (localTimestamp != null) {
      final diff = remoto.difference(localTimestamp).inSeconds.abs();
      if (diff <= 1) {
        print('[📴 REPORTES PROVIDER] ✅ Sin cambios → mantener local');
        return;
      }
    }
    // Guardar estado anterior para comparar
    final anteriores = Map.fromEntries(state.map((r) => MapEntry(r.uid, r)));

    // Pull
    await _sync.pullReportesOnline(ultimaSync: localTimestamp);

    // Push de pendientes
    await _sync.pushReportesOffline();

    // Recargar actualizados
    final actualizados = await _dao.obtenerTodosDrift();
    // 🔥 Invalidar miniaturas SOLO si el PDF cambió
    for (final r in actualizados) {
      final anterior = anteriores[r.uid];

      if (anterior != null && anterior.rutaRemota != r.rutaRemota) {
        await invalidarMiniatura(r.uid);
        await obtenerMiniatura(r);
        print(
          '[🧹 REPORTES PROVIDER] Miniatura invalidada por cambio remoto: ${r.nombre}',
        );
      }
    }
    state = actualizados;

    // Revalidar mes después de sync
    final nuevosMeses = _listarMesesDisponibles();
    if (_mesSeleccionado == null || !nuevosMeses.contains(_mesSeleccionado)) {
      if (nuevosMeses.isNotEmpty) {
        _mesSeleccionado = nuevosMeses.first;
        print(
          '[📅 REPORTES PROVIDER] Mes actualizado tras sync: $_mesSeleccionado',
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 📌 Obtener/generar miniatura PDF
  // ---------------------------------------------------------------------------
  Future<Uint8List?> obtenerMiniatura(ReportesDb reporte) async {
    print('[📂 REPORTES PROVIDER] Solicitud de miniatura: ${reporte.nombre}');

    // 1️⃣ Cache en memoria
    if (_miniaturaCache.containsKey(reporte.uid)) {
      print('[📂 REPORTES PROVIDER] ✅ Usando miniatura en RAM: ${reporte.uid}');
      return _miniaturaCache[reporte.uid];
    }

    // 2️⃣ Cache persistente en disco
    final fileCache = await _miniaturaFile(
      reporte.uid,
      persistente: reporte.rutaLocal.isNotEmpty,
    );
    if (await fileCache.exists()) {
      final bytes = await fileCache.readAsBytes();
      _miniaturaCache[reporte.uid] = bytes;
      print(
        '[📂 REPORTES PROVIDER] ✅ Miniatura cargada desde disco: ${fileCache.path}',
      );
      return bytes;
    }

    File? file;

    // 3️⃣ PDF local descargado
    if (reporte.rutaLocal.isNotEmpty &&
        await File(reporte.rutaLocal).exists()) {
      file = File(reporte.rutaLocal);
      print('[🖼️ REPORTES PROVIDER] 📂 Generando miniatura desde PDF local');
    }
    // 4️⃣ PDF online temporal
    else if (_hayInternet) {
      file = await descargarTemporal(reporte);
    }

    if (file == null) {
      print('[🖼️ REPORTES PROVIDER] ❌ No hay archivo para miniatura');
      return null;
    }

    final doc = await PdfDocument.openFile(file.path);
    final page = await doc.getPage(1);
    final image = await page.render(width: 110, height: 80);
    await page.close();

    if (image == null) {
      print('[📂 REPORTES PROVIDER] ⚠️ Render nulo de miniatura');
      return null;
    }

    _miniaturaCache[reporte.uid] = image.bytes;

    // 5️⃣ Guardar en disco (persistente si es PDF descargado, temporal si no)
    final outFile = await _miniaturaFile(
      reporte.uid,
      persistente: reporte.rutaLocal.isNotEmpty,
    );
    await outFile.writeAsBytes(image.bytes);
    print('[🖼️ REPORTES PROVIDER] 💾 Miniatura guardada en: ${outFile.path}');

    return image.bytes;
  }

  /// Borra miniatura de memoria y disco
  Future<void> invalidarMiniatura(String uid) async {
    print('[🧹 REPORTES PROVIDER] Invalidando miniatura: $uid');
    _miniaturaCache.remove(uid);

    final filePersistente = await _miniaturaFile(uid, persistente: true);
    final fileTemporal = await _miniaturaFile(uid, persistente: false);

    for (final file in [filePersistente, fileTemporal]) {
      if (await file.exists()) {
        await file.delete();
        print('[🧹 REPORTES PROVIDER] 🗑️ Eliminada: ${file.path}');
      }
    }
  }

  /// Decide carpeta según si el PDF está descargado o no
  Future<File> _miniaturaFile(String uid, {required bool persistente}) async {
    final dir = persistente
        ? await getApplicationDocumentsDirectory()
        : await getTemporaryDirectory();
    return File('${dir.path}/miniatura_$uid.png');
  }

  // 📌 Descargar PDF temporal para miniaturas
  Future<File?> descargarTemporal(ReportesDb reporte) async {
    print(
      '[📴 REPORTES PROVIDER] Empezar a descargar Temporalmente: ${reporte.nombre}',
    );
    final dir = await getTemporaryDirectory();
    final tempPath = '${dir.path}/${reporte.uid}.pdf';
    final tempFile = File(tempPath);

    if (await tempFile.exists()) {
      print(
        '[📴 REPORTES PROVIDER] Usando PDF temporal ya existente: $tempPath',
      );
      return tempFile;
    }

    final file = await _service.descargarPDFOnline(reporte.rutaRemota);
    if (file == null) return null;

    await file.copy(tempFile.path);
    print(
      '[📴 REPORTES PROVIDER] Miniatura descargada temporal: ${tempFile.path}',
    );
    return tempFile;
  }

  // ---------------------------------------------------------------------------
  // 📌 Filtros
  // ---------------------------------------------------------------------------
  List<ReportesDb> filtrarPorMesYTipo({required String mes, String? tipo}) {
    return state.where((r) {
      final fechaOk =
          '${r.fecha.year.toString().padLeft(4, '0')}-${r.fecha.month.toString().padLeft(2, '0')}' ==
          mes;
      final tipoOk = tipo == null || r.tipo == tipo;
      final descargadoOk =
          _hayInternet ||
          (r.rutaLocal.isNotEmpty && File(r.rutaLocal).existsSync());
      return fechaOk && tipoOk && descargadoOk;
    }).toList()..sort((a, b) {
      final cmpFecha = b.fecha.compareTo(a.fecha);
      return cmpFecha != 0 ? cmpFecha : a.nombre.compareTo(b.nombre);
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

  // 📌 Descargar PDF y actualizar ruta local
  Future<ReportesDb?> descargarPDF(ReportesDb reporte) async {
    final file = await _service.descargarPDFOnline(reporte.rutaRemota);
    if (file == null) {
      print(
        '[REPORTES PROVIDER]❌ No se pudo descargar PDF: ${reporte.rutaRemota}',
      );
      return null;
    }

    final actualizado = reporte.copyWith(rutaLocal: file.path);
    print('[REPORTES PROVIDER] ✅ PDF descargado en: ${file.path}');

    await invalidarMiniatura(reporte.uid);
    await _dao.upsertReporteDrift(actualizado);

    state = [
      for (final r in state)
        if (r.uid == reporte.uid) actualizado else r,
    ];

    return actualizado;
  }

  ReportesDb? obtenerPorUid(String uid) {
    try {
      return state.firstWhere((r) => r.uid == uid);
    } catch (_) {
      return null;
    }
  }

  // ✅ Verifica si todos los reportes están descargados
  bool todosDescargados(List<ReportesDb> lista) {
    return lista.every(
      (r) => r.rutaLocal.isNotEmpty && File(r.rutaLocal).existsSync(),
    );
  }

  // ✅ Descarga todos los reportes filtrados
  Future<int> descargarTodos(List<ReportesDb> lista) async {
    int count = 0;
    for (final r in lista) {
      if (r.rutaLocal.isNotEmpty && File(r.rutaLocal).existsSync()) continue;
      await descargarPDF(r);
      count++;
    }
    return count;
  }

  // 📌 Eliminar PDF local
  Future<void> eliminarPDF(ReportesDb reporte) async {
    print('[🚯 REPORTES PROVIDER] Se borrará PDF: ${reporte.rutaRemota}');
    if (reporte.rutaLocal.isNotEmpty) {
      final file = File(reporte.rutaLocal);
      if (await file.exists()) {
        await file.delete();
        print('[🚯 REPORTES PROVIDER] Borrado: ${reporte.rutaRemota}');
      }
    }

    final actualizado = reporte.copyWith(rutaLocal: '');
    await _dao.upsertReporteDrift(actualizado);
    state = [
      for (final r in state)
        if (r.uid == reporte.uid) actualizado else r,
    ];
  }

  // ✅ Elimina todos los reportes filtrados
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

  // ✅ Agrupa por tipo
  Map<String, List<ReportesDb>> agruparPorTipo(List<ReportesDb> lista) {
    final grupos = <String, List<ReportesDb>>{};
    for (final r in lista) {
      grupos.putIfAbsent(r.tipo.toUpperCase(), () => []).add(r);
    }
    return grupos;
  }

  void seleccionarMes(String mes) {
    _mesSeleccionado = mes;
  }

  Future<ReportesDb> crearReporteLocal({
    required String nombre,
    required String tipo,
    required DateTime fecha,
    required String rutaRemota,
  }) async {
    final nuevo = ReportesDb(
      uid: Uuid().v4(),
      nombre: nombre,
      tipo: tipo,
      fecha: fecha,
      rutaRemota: rutaRemota,
      rutaLocal: '',
      deleted: false,
      isSynced: false,
      updatedAt: DateTime.now().toUtc(),
    );

    await _dao.upsertReporteDrift(nuevo);
    print('[🆕 REPORTES PROVIDER] Reporte creado localmente: ${nuevo.uid}');

    // Recargar desde DB para mantener consistencia
    final actualizados = await _dao.obtenerTodosDrift();
    state = actualizados;

    // Actualizar mes seleccionado si aplica
    final meses = _listarMesesDisponibles();
    if (_mesSeleccionado == null || !meses.contains(_mesSeleccionado)) {
      if (meses.isNotEmpty) _mesSeleccionado = meses.first;
    }
    return nuevo;
  }

  Future<ReportesDb> editarReporte({required ReportesDb actualizado}) async {
    final actualizadoConMeta = actualizado.copyWith(
      updatedAt: DateTime.now().toUtc(),
      isSynced: false,
    );

    await _dao.upsertReporteDrift(actualizadoConMeta);
    print(
      '[✏️ REPORTES PROVIDER] Reporte actualizado local: ${actualizado.uid}',
    );

    // Refrescar la lista
    final actualizados = await _dao.obtenerTodosDrift();
    state = actualizados;

    // Verificar mes seleccionado
    final meses = _listarMesesDisponibles();
    if (_mesSeleccionado == null || !meses.contains(_mesSeleccionado)) {
      if (meses.isNotEmpty) _mesSeleccionado = meses.first;
    }

    return actualizadoConMeta;
  }

  Future<void> subirNuevoPDF({
    required ReportesDb reporte,
    required File archivo,
    required String nuevoPath,
  }) async {
    try {
      // 1️⃣ Copiar archivo localmente primero
      final dir = await getApplicationDocumentsDirectory();
      final safeName = nuevoPath.replaceAll('/', '_');
      final destino = File('${dir.path}/$safeName');
      await archivo.copy(destino.path);

      // 2️⃣ Actualizar registro local sin subir aún
      final actualizado = reporte.copyWith(
        rutaRemota: nuevoPath,
        rutaLocal: destino.path,
        updatedAt: DateTime.now().toUtc(),
        isSynced: false,
      );

      await _dao.upsertReporteDrift(actualizado);

      state = await _dao.obtenerTodosDrift();

      // Validar miniatura si cambió algo importante
      await invalidarMiniatura(actualizado.uid);
      await obtenerMiniatura(actualizado);
      // 3️⃣ Intentar sync solo si hay conexión
      if (_hayInternet) {
        await cargar(hayInternet: true);
      }

      print(
        '[📥 REPORTES PROVIDER] PDF guardado localmente en: ${destino.path}',
      );
    } catch (e) {
      print('[❌ REPORTES PROVIDER] Error preparando PDF: $e');
      rethrow;
    }
  }
}

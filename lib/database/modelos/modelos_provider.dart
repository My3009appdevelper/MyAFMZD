// ignore_for_file: avoid_print

import 'dart:io';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/database_provider.dart';
import 'package:myafmzd/database/modelos/modelos_dao.dart';
import 'package:myafmzd/database/modelos/modelos_service.dart';
import 'package:myafmzd/database/modelos/modelos_sync.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

// -----------------------------------------------------------------------------
// Provider global
// -----------------------------------------------------------------------------
final modelosProvider = StateNotifierProvider<ModelosNotifier, List<ModeloDb>>((
  ref,
) {
  final db = ref.watch(appDatabaseProvider);
  return ModelosNotifier(ref, db);
});

class ModelosNotifier extends StateNotifier<List<ModeloDb>> {
  ModelosNotifier(this._ref, AppDatabase db)
    : _dao = ModelosDao(db),
      _servicio = ModelosService(db),
      _sync = ModelosSync(db),
      super([]);

  final Ref _ref;
  final ModelosDao _dao;
  final ModelosService _servicio;
  final ModelosSync _sync;

  bool _hayInternet = true;
  bool get hayInternet => _hayInternet;

  // ====== Defaults =========================
  static const List<String> _defaultMarcas = ['Mazda'];
  static const List<String> _defaultTipos = [
    'Sedán',
    'Hatchback',
    'SUV',
    'Pickup',
    'Roadster',
  ];
  static const List<String> _defaultTransmisiones = ['Automática', 'Manual'];
  static const List<String> _defaultDescripciones = [
    '2WD',
    'Sport',
    'Sport TM',
    'Sport TA',
    'Sport 2WD',
    'Grand Touring',
    'Grand Touring TM',
    'Grand Touring TA',
    'Grand Touring 2WD',
    'Signature',
    'Signature TM',
    'Signature TA',
    'Signature AWD',
    'Signature 2WD',
    'Signature 4X4',
    'Carbon Edition',
  ];
  // Muy comunes de Mazda, para primer uso sin datos:
  static const List<String> _defaultModelosMazda = [
    'Mazda 2',
    'Mazda 3',
    'CX-3',
    'CX-30',
    'CX-5',
    'CX-50',
    'CX-70',
    'CX-90',
    'MX-5',
    'BT-50',
  ];

  List<String> _mergeUniqueStr(List<String> a, List<String> b) {
    final set = <String>{};
    set.addAll(a.where((e) => e.trim().isNotEmpty));
    set.addAll(b.where((e) => e.trim().isNotEmpty));
    final out = set.toList()
      ..sort((x, y) => x.toLowerCase().compareTo(y.toLowerCase()));
    return out;
  }

  List<int> _mergeUniqueInt(List<int> a, List<int> b) {
    final set = <int>{}
      ..addAll(a)
      ..addAll(b);
    final out = set.toList()..sort();
    return out;
  }

  // ====== Marcas ===============================================================
  List<String> get marcasDisponibles {
    final enDb = state
        .map((m) => m.marca.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    return _mergeUniqueStr(enDb, _defaultMarcas);
  }

  // ====== Modelos (opcionalmente filtrados por marca) ==========================
  List<String> modelosDisponibles({String? marca}) {
    final enDb = state
        .where(
          (m) => marca == null || m.marca.toLowerCase() == marca.toLowerCase(),
        )
        .map((m) => m.modelo.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();

    final defaults = (marca == null || marca.toLowerCase() == 'mazda')
        ? _defaultModelosMazda
        : const <String>[];

    return _mergeUniqueStr(enDb, defaults);
  }

  // ====== Años (DB + rango razonable alrededor del año actual) =================
  List<int> get aniosDisponiblesForm {
    final enDb = state.map((m) => m.anio).toSet().toList();
    final now = DateTime.now().year;
    final rango = List<int>.generate((now + 1) - 2016 + 1, (i) => 2016 + i);
    return _mergeUniqueInt(enDb, rango);
  }

  // ====== Tipos / Transmisiones / Descripciones ================================
  List<String> get tiposDisponiblesForm {
    final enDb = state
        .map((m) => m.tipo.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    return _mergeUniqueStr(enDb, _defaultTipos);
  }

  List<String> get transmisionesDisponiblesForm {
    final enDb = state
        .map((m) => m.transmision.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    return _mergeUniqueStr(enDb, _defaultTransmisiones);
  }

  List<String> get descripcionesDisponiblesForm {
    final enDb = state
        .map((m) => m.descripcion.trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList();
    return _mergeUniqueStr(enDb, _defaultDescripciones);
  }

  // ---------------------------------------------------------------------------
  // ✅ Cargar modelos (offline-first)
  // ---------------------------------------------------------------------------
  Future<void> cargarOfflineFirst() async {
    try {
      _hayInternet = _ref.read(connectivityProvider);

      // 1) Pintar siempre local primero
      final local = await _dao.obtenerTodosDrift();
      state = local;
      print(
        '[🚗 MENSAJES MODELOS PROVIDER] Local cargado -> ${local.length} modelos',
      );

      // 2) Sin internet → detener
      if (!_hayInternet) {
        print(
          '[🚗 MENSAJES MODELOS PROVIDER] Sin internet → usando solo local',
        );
        return;
      }

      // 3) (Opcional) comparar timestamps
      final localTimestamp = await _dao.obtenerUltimaActualizacionDrift();
      final remotoTimestamp = await _servicio.comprobarActualizacionesOnline();
      print(
        '[🚗 MENSAJES MODELOS PROVIDER] Remoto:$remotoTimestamp | Local:$localTimestamp',
      );

      // 4) Pull (heads → diff → bulk)
      await _sync.pullModelosOnline();

      // 5) Push de cambios offline
      await _sync.pushModelosOffline();

      // 6) Recargar desde Drift
      final actualizados = await _dao.obtenerTodosDrift();
      state = actualizados;
    } catch (e) {
      print('[🚗 MENSAJES MODELOS PROVIDER] ❌ Error al cargar modelos: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Crear / Editar
  // ---------------------------------------------------------------------------
  Future<ModeloDb> crearModelo({
    required String claveCatalogo,
    String marca = 'Mazda',
    required String modelo,
    required int anio,
    required String tipo,
    required String transmision,
    String descripcion = '',
    bool activo = true,
    double precioBase = 0.0,
    String fichaRutaRemota = '',
  }) async {
    final uid = const Uuid().v4();
    final now = DateTime.now().toUtc();

    await _dao.upsertModeloDrift(
      ModelosCompanion.insert(
        uid: uid,
        anio: anio,
        claveCatalogo: Value(claveCatalogo),
        marca: Value(marca),
        modelo: Value(modelo),
        tipo: Value(tipo),
        transmision: Value(transmision),
        descripcion: Value(descripcion),
        activo: Value(activo),
        precioBase: Value(precioBase),
        fichaRutaRemota: Value(fichaRutaRemota),
        fichaRutaLocal: const Value(''),
        createdAt: Value(now),
        updatedAt: Value(now),
        deleted: const Value(false),
        isSynced: const Value(false),
      ),
    );

    final actualizados = await _dao.obtenerTodosDrift();
    state = actualizados;
    return actualizados.firstWhere((m) => m.uid == uid);
  }

  // ---------------------------------------------------------------------------
  // ✏️ Editar modelo (LOCAL → isSynced=false; el push lo sube)
  // ---------------------------------------------------------------------------
  Future<ModeloDb> editarModelo({required ModeloDb actualizado}) async {
    try {
      final comp = ModelosCompanion(
        uid: Value(actualizado.uid),
        claveCatalogo: Value(actualizado.claveCatalogo),
        marca: Value(actualizado.marca),
        modelo: Value(actualizado.modelo),
        anio: Value(actualizado.anio),
        tipo: Value(actualizado.tipo),
        transmision: Value(actualizado.transmision),
        descripcion: Value(actualizado.descripcion),
        activo: Value(actualizado.activo),
        precioBase: Value(actualizado.precioBase),
        fichaRutaRemota: Value(actualizado.fichaRutaRemota),
        fichaRutaLocal: const Value.absent(),
        createdAt: const Value.absent(),
        updatedAt: Value(DateTime.now().toUtc()),
        deleted: Value(actualizado.deleted),
        isSynced: Value(false),
      );

      await _dao.upsertModeloDrift(comp);

      final actualizados = await _dao.obtenerTodosDrift();
      state = actualizados;
      print(
        '[🚗 MENSAJES MODELOS PROVIDER] Modelo ${actualizado.uid} editado localmente',
      );

      return actualizados.firstWhere((m) => m.uid == actualizado.uid);
    } catch (e) {
      print('[🚗 MENSAJES MODELOS PROVIDER] ❌ Error al editar modelo: $e');
      rethrow;
    }
  }

  Future<void> eliminarModeloLocal(String uid) async {
    await _dao.upsertModeloDrift(
      ModelosCompanion(
        uid: Value(uid),
        deleted: const Value(true),
        updatedAt: Value(DateTime.now().toUtc()),
        isSynced: const Value(false),
      ),
    );
    state = await _dao.obtenerTodosDrift();
  }

  // ---------------------------------------------------------------------------
  // 📥/📤 Ficha técnica (PDF) local + sync diferido
  // ---------------------------------------------------------------------------
  Future<ModeloDb?> descargarFicha(ModeloDb modelo) async {
    final file = await _servicio.descargarFichaOnline(modelo.fichaRutaRemota);
    if (file == null) {
      print(
        '[🚗 MENSAJES MODELOS PROVIDER] ❌ No se pudo descargar ${modelo.fichaRutaRemota}',
      );
      return null;
    }

    // Actualización parcial; no tocamos isSynced
    await _dao.actualizarParcialPorUid(
      modelo.uid,
      ModelosCompanion(fichaRutaLocal: Value(file.path)),
    );

    final actualizados = await _dao.obtenerTodosDrift();
    state = actualizados;

    final actualizado = actualizados.firstWhere(
      (m) => m.uid == modelo.uid,
      orElse: () => modelo,
    );
    print('[🚗 MENSAJES MODELOS PROVIDER] ✅ Ficha descargada en: ${file.path}');
    return actualizado;
  }

  Future<void> eliminarFichaLocal(ModeloDb modelo) async {
    print(
      '[🚗 MENSAJES MODELOS PROVIDER] Borrando ficha local: ${modelo.fichaRutaLocal}',
    );
    if (modelo.fichaRutaLocal.isNotEmpty) {
      final file = File(modelo.fichaRutaLocal);
      try {
        if (await file.exists()) await file.delete();
      } catch (e) {
        print(
          '[🚗 MENSAJES MODELOS PROVIDER] ⚠️ Error borrando ficha local: $e',
        );
      }
    }
    await _dao.actualizarParcialPorUid(
      modelo.uid,
      const ModelosCompanion(fichaRutaLocal: Value('')),
    );
    state = await _dao.obtenerTodosDrift();
  }

  /// Copia un PDF local a la app y marca para sync (no sube de inmediato).
  Future<void> subirNuevaFicha({
    required ModeloDb modelo,
    required File archivo,
    required String nuevoPath,
  }) async {
    try {
      // 🔍 0) Checar si ya existe en Supabase ANTES de copiar local
      final yaExisteRemoto = await _servicio.existsFicha(nuevoPath);
      if (yaExisteRemoto) {
        print(
          '[🚗 MENSAJES MODELOS PROVIDER] ⏭️ Remoto ya existe, NO copio local: $nuevoPath',
        );

        // Solo si cambió el path remoto, sincroniza metadata
        if (modelo.fichaRutaRemota != nuevoPath) {
          await _dao.actualizarParcialPorUid(
            modelo.uid,
            ModelosCompanion(
              fichaRutaRemota: Value(nuevoPath),
              fichaRutaLocal: const Value(''),
              updatedAt: Value(DateTime.now().toUtc()),
              isSynced: const Value(false), // empuja solo metadata
            ),
          );
          state = await _dao.obtenerTodosDrift();
        }
        return;
      }

      // 1) Copiar a almacenamiento de la app (SOLO si no existe en remoto)
      final dir = await getApplicationSupportDirectory();
      final fichasDir = Directory(p.join(dir.path, 'fichas'));
      if (!await fichasDir.exists()) {
        await fichasDir.create(recursive: true);
      }
      final safeName = nuevoPath.replaceAll('/', '_');
      final destino = File(p.join(fichasDir.path, safeName));
      await archivo.copy(destino.path);

      // 2) Actualizar local (marcamos para sync)
      await _dao.actualizarParcialPorUid(
        modelo.uid,
        ModelosCompanion(
          fichaRutaRemota: Value(nuevoPath),
          fichaRutaLocal: Value(destino.path),
          updatedAt: Value(DateTime.now().toUtc()),
          isSynced: const Value(false),
        ),
      );

      state = await _dao.obtenerTodosDrift();

      // 3) Intentar sync si hay internet
      if (_hayInternet) {
        await cargarOfflineFirst();
      }

      print(
        '[🚗 MENSAJES MODELOS PROVIDER] Ficha guardada localmente: ${destino.path}',
      );
    } catch (e) {
      print('[🚗 MENSAJES MODELOS PROVIDER] ❌ Error preparando ficha: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 🧪 Duplicados
  // ---------------------------------------------------------------------------
  bool existeDuplicado({
    required String uidActual,
    required String claveCatalogo,
    required int anio,
    bool incluirEliminados = false,
  }) {
    final cat = claveCatalogo.trim().toLowerCase();
    if (cat.isEmpty)
      return false; // si el formulario ya lo exige, esto casi nunca ocurrirá

    return state.any((m) {
      if (m.uid == uidActual) return false; // ignorar yo mismo
      if (!incluirEliminados && m.deleted) return false; // ignorar soft-deleted

      final sameYear = m.anio == anio;
      final sameCat = m.claveCatalogo.trim().toLowerCase() == cat;

      return sameYear && sameCat; // ← ÚNICO por (anio, clave)
    });
  }

  // ---------------------------------------------------------------------------
  // 🔍 Utilidades de consulta/filtrado
  // ---------------------------------------------------------------------------
  ModeloDb? obtenerPorId(String id) {
    try {
      return state.firstWhere((m) => m.uid == id);
    } catch (_) {
      return null;
    }
  }

  List<int> get aniosUnicos {
    final list = state.map((m) => m.anio).toSet().toList()..sort();
    return list;
  }

  List<String> get tiposUnicos {
    final list = state.map((m) => m.tipo).toSet().toList()..sort();
    list.insert(0, 'Todos');
    return list;
  }

  List<String> get transmisionesUnicas {
    final list = state.map((m) => m.transmision).toSet().toList()..sort();
    list.insert(0, 'Todas');
    return list;
  }

  /// Filtrar por múltiples criterios comunes en catálogo.
  List<ModeloDb> filtrar({
    String? tipo, // 'Todos' => ignora
    String? transmision, // 'Todas' => ignora
    bool incluirInactivos = true,
    int? anio,
    double? precioMin,
    double? precioMax,
  }) {
    return state.where((m) {
      final tipoOk = tipo == null || tipo == 'Todos' || m.tipo == tipo;
      final transOk =
          transmision == null ||
          transmision == 'Todas' ||
          m.transmision == transmision;
      final activoOk = incluirInactivos || m.activo;
      final anioOk = anio == null || m.anio == anio;
      final pMinOk = precioMin == null || m.precioBase >= precioMin;
      final pMaxOk = precioMax == null || m.precioBase <= precioMax;
      return tipoOk && transOk && activoOk && anioOk && pMinOk && pMaxOk;
    }).toList()..sort((a, b) {
      // Activos primero, luego por modelo y año desc
      if (a.activo != b.activo) return a.activo ? -1 : 1;
      final cmp = a.modelo.compareTo(b.modelo);
      return cmp != 0 ? cmp : b.anio.compareTo(a.anio);
    });
  }
}

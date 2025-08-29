// ignore_for_file: avoid_print

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/connectivity/connectivity_provider.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/database_provider.dart';
import 'package:myafmzd/database/productos/productos_dao.dart';
import 'package:myafmzd/database/productos/productos_service.dart';
import 'package:myafmzd/database/productos/productos_sync.dart';
import 'package:uuid/uuid.dart';

// -----------------------------------------------------------------------------
// Provider global
// -----------------------------------------------------------------------------
final productosProvider =
    StateNotifierProvider<ProductosNotifier, List<ProductoDb>>((ref) {
      final db = ref.watch(appDatabaseProvider);
      return ProductosNotifier(ref, db);
    });

class ProductosNotifier extends StateNotifier<List<ProductoDb>> {
  ProductosNotifier(this._ref, AppDatabase db)
    : _dao = ProductosDao(db),
      _servicio = ProductosService(db),
      _sync = ProductosSync(db),
      super([]);

  final Ref _ref;
  final ProductosDao _dao;
  final ProductosService _servicio;
  final ProductosSync _sync;

  bool _hayInternet = true;
  bool get hayInternet => _hayInternet;

  // ---------------------------------------------------------------------------
  // ✅ Cargar productos (offline-first)
  // ---------------------------------------------------------------------------
  Future<void> cargarOfflineFirst() async {
    try {
      _hayInternet = _ref.read(connectivityProvider);

      // 1) Pintar siempre local primero
      final local = await _dao.obtenerTodosDrift();
      state = local;
      print(
        '[🧮 MENSAJES PRODUCTOS PROVIDER] Local cargado -> ${local.length} productos',
      );

      // 2) Sin internet → detener
      if (!_hayInternet) {
        print('[🧮 MENSAJES PRODUCTOS PROVIDER] Sin internet → solo local');
        return;
      }

      // 3) (Opcional) comparar timestamps para logging/telemetría
      final localTimestamp = await _dao.obtenerUltimaActualizacionDrift();
      final remotoTimestamp = await _servicio.comprobarActualizacionesOnline();
      print(
        '[🧮 MENSAJES PRODUCTOS PROVIDER] Remoto:$remotoTimestamp | Local:$localTimestamp',
      );

      // 4) Pull (heads → diff → bulk)
      await _sync.pullProductosOnline();

      // 5) Push de cambios offline
      await _sync.pushProductosOffline();

      // 6) Recargar desde Drift
      final actualizados = await _dao.obtenerTodosDrift();
      state = actualizados;
    } catch (e) {
      print('[🧮 MENSAJES PRODUCTOS PROVIDER] ❌ Error al cargar: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // ➕ Crear producto (LOCAL → isSynced=false; el push lo sube)
  // ---------------------------------------------------------------------------
  Future<ProductoDb> crearProductoLocal({
    String nombre = 'Autofinanciamiento Puro',
    bool activo = true,

    // Parámetros de cálculo
    int plazoMeses = 60,
    double factorIntegrante = 0.01667,
    double factorPropietario = 0.0206,
    double cuotaInscripcionPct = 0.005,
    double cuotaAdministracionPct = 0.002,
    double ivaCuotaAdministracionPct = 0.16,
    double cuotaSeguroVidaPct = 0.00065,

    // Reglas operativas
    int adelantoMinMens = 0,
    int adelantoMaxMens = 59,
    int mesEntregaMin = 1,
    int mesEntregaMax = 60,

    // Presentación / vigencia
    int prioridad = 0,
    String notas = '',
    DateTime? vigenteDesde,
    DateTime? vigenteHasta,
  }) async {
    final uid = const Uuid().v4();
    final now = DateTime.now().toUtc();

    final comp = ProductosCompanion.insert(
      uid: uid,
      nombre: Value(nombre),
      activo: Value(activo),
      plazoMeses: Value(plazoMeses),
      factorIntegrante: Value(factorIntegrante),
      factorPropietario: Value(factorPropietario),
      cuotaInscripcionPct: Value(cuotaInscripcionPct),
      cuotaAdministracionPct: Value(cuotaAdministracionPct),
      ivaCuotaAdministracionPct: Value(ivaCuotaAdministracionPct),
      cuotaSeguroVidaPct: Value(cuotaSeguroVidaPct),
      adelantoMinMens: Value(adelantoMinMens),
      adelantoMaxMens: Value(adelantoMaxMens),
      mesEntregaMin: Value(mesEntregaMin),
      mesEntregaMax: Value(mesEntregaMax),
      prioridad: Value(prioridad),
      notas: Value(notas),
      vigenteDesde: vigenteDesde == null
          ? const Value.absent()
          : Value(vigenteDesde),
      vigenteHasta: vigenteHasta == null
          ? const Value.absent()
          : Value(vigenteHasta),
      createdAt: Value(now),
      updatedAt: Value(now),
      deleted: const Value(false),
      isSynced: const Value(false),
    );

    await _dao.upsertProductoDrift(comp);
    final actualizados = await _dao.obtenerTodosDrift();
    state = actualizados;

    return actualizados.firstWhere((p) => p.uid == uid);
  }

  // ---------------------------------------------------------------------------
  // ✏️ Editar producto (LOCAL → isSynced=false; el push lo sube)
  // ---------------------------------------------------------------------------
  Future<ProductoDb> editarProducto({required ProductoDb actualizado}) async {
    try {
      final comp = ProductosCompanion(
        uid: Value(actualizado.uid),
        nombre: Value(actualizado.nombre),
        activo: Value(actualizado.activo),
        plazoMeses: Value(actualizado.plazoMeses),
        factorIntegrante: Value(actualizado.factorIntegrante),
        factorPropietario: Value(actualizado.factorPropietario),
        cuotaInscripcionPct: Value(actualizado.cuotaInscripcionPct),
        cuotaAdministracionPct: Value(actualizado.cuotaAdministracionPct),
        ivaCuotaAdministracionPct: Value(actualizado.ivaCuotaAdministracionPct),
        cuotaSeguroVidaPct: Value(actualizado.cuotaSeguroVidaPct),
        adelantoMinMens: Value(actualizado.adelantoMinMens),
        adelantoMaxMens: Value(actualizado.adelantoMaxMens),
        mesEntregaMin: Value(actualizado.mesEntregaMin),
        mesEntregaMax: Value(actualizado.mesEntregaMax),
        prioridad: Value(actualizado.prioridad),
        notas: Value(actualizado.notas),
        vigenteDesde: actualizado.vigenteDesde == null
            ? const Value.absent()
            : Value(actualizado.vigenteDesde!),
        vigenteHasta: actualizado.vigenteHasta == null
            ? const Value.absent()
            : Value(actualizado.vigenteHasta!),
        updatedAt: Value(DateTime.now().toUtc()),
        deleted: Value(actualizado.deleted),
        isSynced: const Value(false),
      );

      await _dao.upsertProductoDrift(comp);
      final actualizados = await _dao.obtenerTodosDrift();
      state = actualizados;

      print(
        '[🧮 MENSAJES PRODUCTOS PROVIDER] Producto ${actualizado.uid} editado localmente',
      );
      return actualizados.firstWhere((p) => p.uid == actualizado.uid);
    } catch (e) {
      print('[🧮 MENSAJES PRODUCTOS PROVIDER] ❌ Error al editar: $e');
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // 🗑️ Soft delete local (marca isSynced=false) → push lo sube
  // ---------------------------------------------------------------------------
  Future<void> eliminarProductoLocal(String uid) async {
    await _dao.upsertProductoDrift(
      ProductosCompanion(
        uid: Value(uid),
        deleted: const Value(true),
        updatedAt: Value(DateTime.now().toUtc()),
        isSynced: const Value(false),
      ),
    );
    state = await _dao.obtenerTodosDrift();
  }

  // Activar/desactivar (toggle)
  Future<void> setActivo(String uid, bool activo) async {
    await _dao.upsertProductoDrift(
      ProductosCompanion(
        uid: Value(uid),
        activo: Value(activo),
        updatedAt: Value(DateTime.now().toUtc()),
        isSynced: const Value(false),
      ),
    );
    state = await _dao.obtenerTodosDrift();
  }

  // ---------------------------------------------------------------------------
  // 🔍 Consultas / filtros
  // ---------------------------------------------------------------------------
  ProductoDb? obtenerPorUid(String uid) {
    try {
      return state.firstWhere((p) => p.uid == uid);
    } catch (_) {
      return null;
    }
  }

  /// ¿Está vigente en [fecha] (o ahora si null) y no eliminado?
  bool _estaVigente(ProductoDb p, {DateTime? fecha}) {
    final f = (fecha ?? DateTime.now().toUtc());
    final desdeOk = p.vigenteDesde == null || !f.isBefore(p.vigenteDesde!);
    final hastaOk = p.vigenteHasta == null || !f.isAfter(p.vigenteHasta!);
    return !p.deleted && desdeOk && hastaOk;
  }

  /// Lista de productos filtrada por vigencia y estado, ordenada por prioridad asc y updatedAt desc.
  List<ProductoDb> filtrar({
    bool soloVigentes = true,
    bool incluirInactivos = false,
    DateTime? enFecha,
  }) {
    final lista =
        state.where((p) {
          final vigenteOk = !soloVigentes || _estaVigente(p, fecha: enFecha);
          final activoOk = incluirInactivos || p.activo;
          return vigenteOk && activoOk;
        }).toList()..sort((a, b) {
          final pr = a.prioridad.compareTo(b.prioridad);
          if (pr != 0) return pr;
          return b.updatedAt.compareTo(a.updatedAt);
        });
    return lista;
  }

  /// El producto “preferido” vigente/activo (menor prioridad, más reciente).
  ProductoDb? productoVigentePreferido({DateTime? enFecha}) {
    final lista = filtrar(
      soloVigentes: true,
      incluirInactivos: false,
      enFecha: enFecha,
    );
    return lista.isNotEmpty ? lista.first : null;
  }

  /// Comprobación simple de límites operativos (mesEntrega/adelanto)
  bool validarParametros(
    ProductoDb p, {
    required int mesEntrega,
    required int adelanto,
  }) {
    final mesOk =
        mesEntrega >= p.mesEntregaMin && mesEntrega <= p.mesEntregaMax;
    final adelantoOk =
        adelanto >= p.adelantoMinMens && adelanto <= p.adelantoMaxMens;
    // Nota: si quieres reforzar la regla de que (mesEntrega - adelanto) >= 1, añádela aquí.
    return mesOk && adelantoOk;
  }

  /// Duplicados por nombre (ignora uidActual)
  bool existeDuplicado({required String uidActual, required String nombre}) {
    final nom = nombre.trim().toLowerCase();
    return state.any(
      (p) => p.uid != uidActual && p.nombre.trim().toLowerCase() == nom,
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myafmzd/database/app_database.dart';
import 'package:myafmzd/database/modelos/modelo_imagenes_provider.dart';
import 'package:myafmzd/database/productos/productos_provider.dart';
import 'package:myafmzd/screens/modelos/cotizador.dart';
import 'package:myafmzd/widgets/visor_pdf.dart';
import 'package:path_provider/path_provider.dart'; // Cotizador + provider
import 'package:pdf/pdf.dart' as pdf;
import 'package:pdf/widgets.dart' as pdfw;

class CotizadorScreen extends ConsumerStatefulWidget {
  final ModeloDb modelo;
  const CotizadorScreen({super.key, required this.modelo});

  @override
  ConsumerState<CotizadorScreen> createState() => _CotizadorScreenState();
}

class _CotizadorScreenState extends ConsumerState<CotizadorScreen> {
  ProductoDb? _productoSel;

  int _mesEntrega = 1; // se ajusta en init según producto
  int _adelanto = 0; // se ajusta en init según producto

  @override
  void initState() {
    super.initState();
    final productos = ref.read(productosProvider);
    _productoSel = _pickDefault(productos);
    _resetInputsFor(_productoSel);
  }

  // ------------ Helpers de dominio / rango permitido ------------
  int _minMes(ProductoDb p) => (p.mesEntregaMin <= 0) ? 1 : p.mesEntregaMin;
  int _maxMes(ProductoDb p) {
    final top = (p.mesEntregaMax <= 0) ? (p.plazoMeses - 1) : p.mesEntregaMax;
    return top.clamp(1, p.plazoMeses - 1);
  }

  int _maxAdelantoFor(ProductoDb p, int mesEntrega) {
    final capByMes = (p.plazoMeses - mesEntrega).clamp(0, p.plazoMeses);
    final aMax = p.adelantoMaxMens.clamp(0, p.plazoMeses);
    return aMax.clamp(0, capByMes); // máximo final
  }

  void _resetInputsFor(ProductoDb? p) {
    if (p == null) {
      _mesEntrega = 1;
      _adelanto = 0;
      return;
    }
    final minM = _minMes(p);
    final maxM = _maxMes(p);
    _mesEntrega = minM.clamp(1, maxM);
    final maxA = _maxAdelantoFor(p, _mesEntrega);
    _adelanto = p.adelantoMinMens.clamp(0, maxA);
  }

  // ------------ Helpers UI ------------
  ProductoDb? _pickDefault(List<ProductoDb> list) {
    if (list.isEmpty) return null;
    final activos = list.where((p) => p.activo).toList()
      ..sort((a, b) {
        final pr = a.prioridad.compareTo(b.prioridad);
        if (pr != 0) return pr;
        return a.nombre.compareTo(b.nombre);
      });
    if (activos.isNotEmpty) return activos.first;

    final ordenados = [...list]
      ..sort((a, b) {
        final pr = a.prioridad.compareTo(b.prioridad);
        if (pr != 0) return pr;
        return a.nombre.compareTo(b.nombre);
      });
    return ordenados.first;
  }

  String _fmtMon(num v) {
    final s = v.round().toString();
    final rev = s.split('').reversed.toList();
    final chunks = <String>[];
    for (var i = 0; i < rev.length; i += 3) {
      chunks.add(rev.sublist(i, (i + 3).clamp(0, rev.length)).join());
    }
    return chunks
        .map((c) => c.split('').reversed.join())
        .toList()
        .reversed
        .join(',');
  }

  String _fmtPct(double p, {int dec = 2}) =>
      '${(p * 100).toStringAsFixed(dec)}%';

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final productos = ref.watch(productosProvider);
    if (_productoSel != null &&
        !productos.any((p) => p.uid == _productoSel!.uid)) {
      _productoSel = _pickDefault(productos);
      _resetInputsFor(_productoSel);
    }

    final ordenados = [...productos]
      ..sort((a, b) {
        final act = (b.activo ? 1 : 0) - (a.activo ? 1 : 0);
        if (act != 0) return -act;
        final pr = a.prioridad.compareTo(b.prioridad);
        if (pr != 0) return pr;
        return a.nombre.compareTo(b.nombre);
      });

    final cotizador = ref.read(cotizadorProvider);

    final params = (_productoSel == null)
        ? null
        : cotizador.paramsDesdeProducto(
            producto: _productoSel!,
            precioVehiculo: widget.modelo.precioBase,
            mesEntrega: _mesEntrega,
            adelanto: _adelanto,
          );

    final resumen = (params == null) ? null : cotizador.calcularResumen(params);

    // Rango dinámico (si hay producto)
    final minMes = _productoSel != null ? _minMes(_productoSel!) : 1;
    final maxMes = _productoSel != null ? _maxMes(_productoSel!) : 1;
    final maxAdelanto = _productoSel != null
        ? _maxAdelantoFor(_productoSel!, _mesEntrega)
        : 0;

    // Asegura clamps por si cambió el rango
    final mesEntrega = _productoSel == null
        ? 1
        : _mesEntrega.clamp(minMes, maxMes);
    final adelanto = _productoSel == null ? 0 : _adelanto.clamp(0, maxAdelanto);

    if (_mesEntrega != mesEntrega || _adelanto != adelanto) {
      // Ajuste silencioso si el rango cambió por selección de producto o slider
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _mesEntrega = mesEntrega;
          _adelanto = adelanto;
        });
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Cotizar: ${widget.modelo.modelo}'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // ================= Modelo =================
          Text('Modelo seleccionado', style: tt.titleMedium),
          const SizedBox(height: 8),
          _card(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.modelo.modelo} ${widget.modelo.descripcion}',
                  style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  '${widget.modelo.tipo} · ${widget.modelo.transmision}',
                  style: tt.bodyMedium?.copyWith(color: cs.secondary),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Precio lista: ',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '\$${_fmtMon(widget.modelo.precioBase)}',
                      style: tt.titleMedium?.copyWith(color: cs.primary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ================ Selector de producto ===============
          Text('Elige un producto', style: tt.titleMedium),
          const SizedBox(height: 8),
          if (ordenados.isEmpty) ...[
            _card(
              context,
              child: Text(
                'No hay productos dados de alta.\nCrea uno en la sección de Productos.',
                style: tt.bodyMedium,
              ),
            ),
          ] else ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p in ordenados)
                  ChoiceChip(
                    label: Text(
                      p.nombre.isEmpty ? 'Producto' : p.nombre,
                      overflow: TextOverflow.ellipsis,
                    ),
                    selected: _productoSel?.uid == p.uid,
                    onSelected: (_) {
                      setState(() {
                        _productoSel = p;
                        _resetInputsFor(p); // recalcular rangos y defaults
                      });
                    },
                  ),
              ],
            ),
            const SizedBox(height: 12),

            if (_productoSel != null) ...[
              Text('Detalles del producto', style: tt.titleMedium),
              const SizedBox(height: 8),
              _card(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _kv('Plazo (meses)', '${_productoSel!.plazoMeses}', tt),
                    const Divider(height: 16),
                    _kv(
                      'Factor integrante',
                      _fmtPct(_productoSel!.factorIntegrante),
                      tt,
                    ),
                    _kv(
                      'Factor propietario',
                      _fmtPct(_productoSel!.factorPropietario),
                      tt,
                    ),
                    _kv(
                      'Cuota inscripción',
                      _fmtPct(_productoSel!.cuotaInscripcionPct),
                      tt,
                    ),
                    _kv(
                      'Cuota administración',
                      _fmtPct(_productoSel!.cuotaAdministracionPct),
                      tt,
                    ),
                    _kv(
                      'IVA cuota administración',
                      _fmtPct(_productoSel!.ivaCuotaAdministracionPct),
                      tt,
                    ),
                    _kv(
                      'Seguro de vida',
                      _fmtPct(_productoSel!.cuotaSeguroVidaPct, dec: 3),
                      tt,
                    ),
                  ],
                ),
              ),

              // =============== RESULTADOS: cuotas y mensualidades ===============
              if (resumen != null) ...[
                const SizedBox(height: 12),
                Text('Resultados (con precio de lista)', style: tt.titleMedium),
                const SizedBox(height: 8),
                _card(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Cuotas base (mensuales)', style: tt.titleSmall),
                      const SizedBox(height: 6),
                      _kv(
                        'Aportación integrante',
                        '\$${_fmtMon(resumen.aportacionIntegrante)}',
                        tt,
                      ),
                      _kv(
                        'Aportación propietario',
                        '\$${_fmtMon(resumen.aportacionPropietario)}',
                        tt,
                      ),
                      const Divider(height: 16),
                      _kv(
                        'Cuota de inscripción (única)',
                        '\$${_fmtMon(resumen.montoInscripcion)}',
                        tt,
                      ),
                      _kv(
                        'Gastos de administración',
                        '\$${_fmtMon(resumen.montoAdministracion)}',
                        tt,
                      ),
                      _kv(
                        'IVA administración',
                        '\$${_fmtMon(resumen.montoIvaAdministracion)}',
                        tt,
                      ),
                      _kv(
                        'Seguro de vida',
                        '\$${_fmtMon(resumen.montoSeguroVida)}',
                        tt,
                      ),
                      const Divider(height: 16),
                      Text('Mensualidades', style: tt.titleSmall),
                      const SizedBox(height: 6),
                      _kv(
                        'Integrante',
                        '\$${_fmtMon(resumen.mensualidadIntegrante)}',
                        tt,
                      ),
                      _kv(
                        'Propietario',
                        '\$${_fmtMon(resumen.mensualidadPropietario)}',
                        tt,
                      ),
                    ],
                  ),
                ),
              ],

              // ==================== SELECTORES (chips + slider) ====================
              const SizedBox(height: 16),
              Text('Selecciona mes de adjudicación', style: tt.titleMedium),
              const SizedBox(height: 8),
              _card(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _mesEntrega.toDouble(),
                            min: minMes.toDouble(),
                            max: maxMes.toDouble(),
                            divisions: (maxMes - minMes) > 0
                                ? (maxMes - minMes)
                                : null,
                            label: '$_mesEntrega',
                            onChanged: (v) {
                              setState(() {
                                _mesEntrega = v.round().clamp(minMes, maxMes);
                                final newMaxA = _maxAdelantoFor(
                                  _productoSel!,
                                  _mesEntrega,
                                );
                                _adelanto = _adelanto.clamp(0, newMaxA);
                              });
                            },
                          ),
                        ),
                        SizedBox(
                          width: 76,
                          child: Text(
                            '$_mesEntrega/$maxMes',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Rango permitido: $minMes a $maxMes',
                      style: tt.labelSmall?.copyWith(color: cs.secondary),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),
              Text(
                'Selecciona mensualidades adelantadas',
                style: tt.titleMedium,
              ),
              const SizedBox(height: 8),
              _card(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: _adelanto.toDouble(),
                            min: 0,
                            max: maxAdelanto.toDouble(),
                            divisions: maxAdelanto > 0 ? maxAdelanto : 1,
                            label: '$_adelanto',
                            onChanged: (v) => setState(
                              () => _adelanto = v.round().clamp(0, maxAdelanto),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 76,
                          child: Text(
                            '$_adelanto/$maxAdelanto',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      'Máximo posible: $maxAdelanto',
                      style: tt.labelSmall?.copyWith(color: cs.secondary),
                    ),
                  ],
                ),
              ),

              // --- RESUMEN DINÁMICO + PDF ---
              if (params != null && resumen != null) ...[
                const SizedBox(height: 16),
                Text('Resumen dinámico', style: tt.titleMedium),
                const SizedBox(height: 8),
                _card(
                  context,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _kv('Mes de adjudicación', '${params.mesEntrega}', tt),
                      _kv(
                        'Mensualidades adelantadas',
                        '${params.adelanto}',
                        tt,
                      ),
                      const Divider(height: 16),
                      _kv(
                        'Mensualidad (Integrante)',
                        '\$${_fmtMon(resumen.mensualidadIntegrante)}',
                        tt,
                      ),
                      _kv(
                        'Mensualidad (Propietario)',
                        '\$${_fmtMon(resumen.mensualidadPropietario)}',
                        tt,
                      ),
                      const Divider(height: 16),
                      _kv(
                        'Adelanto: Aportación',
                        '\$${_fmtMon(resumen.adelantoAportacion)}',
                        tt,
                      ),
                      _kv(
                        'Adelanto: Adm.',
                        '\$${_fmtMon(resumen.adelantoMontoAdministracion)}',
                        tt,
                      ),
                      _kv(
                        'Adelanto: IVA Adm.',
                        '\$${_fmtMon(resumen.adelantoMontoIvaAdministracion)}',
                        tt,
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Pagos totales: ${resumen.pagosTotales}  •  '
                          'Integrante: ${resumen.integrantMonths}  •  '
                          'Propietario: ${resumen.proprietorMonths}',
                          style: tt.labelSmall?.copyWith(color: cs.secondary),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('Generar PDF'),
                    onPressed: () async {
                      // intenta obtener la imagen de portada (o alguna descargada) del modelo
                      final cover = ref
                          .read(modeloImagenesProvider.notifier)
                          .coverOrFallback(
                            widget.modelo.uid,
                            soloDescargadas: true,
                          );

                      String? portadaPath;
                      if (cover != null &&
                          cover.rutaLocal.isNotEmpty &&
                          File(cover.rutaLocal).existsSync()) {
                        portadaPath = cover.rutaLocal;
                      }

                      final path = await _generarPdf(
                        params,
                        portadaPath: portadaPath,
                      );
                      if (!mounted) return;

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => VisorPDF(
                            assetPath: path,
                            titulo: 'Cotización ${widget.modelo.modelo}',
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ],
          ],
        ],
      ),
    );
  }

  // ---------- helpers de UI ----------
  Widget _card(BuildContext context, {required Widget child}) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: child,
    );
  }

  Widget _kv(String k, String v, TextTheme tt) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              k,
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(v, style: tt.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _generarPdf(
    CotizacionParams params, {
    String? portadaPath, // <- ruta local opcional a la imagen de portada
  }) async {
    final cot = ref.read(cotizadorProvider);
    final r = cot.calcularResumen(params);
    final filas = cot.generarTablaPagos(params);

    // Si no me pasaron portadaPath, intento resolverla con el provider
    if (portadaPath == null) {
      final cover = ref
          .read(modeloImagenesProvider.notifier)
          .coverOrFallback(widget.modelo.uid, soloDescargadas: true);
      if (cover != null &&
          cover.rutaLocal.isNotEmpty &&
          File(cover.rutaLocal).existsSync()) {
        portadaPath = cover.rutaLocal;
      }
    }

    // ---------- Utilidades ----------
    String _fechaLargaEs(DateTime d) {
      const meses = [
        'enero',
        'febrero',
        'marzo',
        'abril',
        'mayo',
        'junio',
        'julio',
        'agosto',
        'septiembre',
        'octubre',
        'noviembre',
        'diciembre',
      ];
      return '${d.day} de ${meses[d.month - 1]} de ${d.year}';
    }

    String _mon(num v) => _fmtMon(v); // reutiliza tu formateador de la clase

    pdfw.Widget _h1Center(String s) => pdfw.Align(
      alignment: pdfw.Alignment.center,
      child: pdfw.Text(
        s,
        style: pdfw.TextStyle(fontSize: 24, fontWeight: pdfw.FontWeight.bold),
      ),
    );

    pdfw.Widget _h2Center(String s) => pdfw.Align(
      alignment: pdfw.Alignment.center,
      child: pdfw.Text(
        s,
        style: pdfw.TextStyle(fontSize: 16, fontWeight: pdfw.FontWeight.bold),
      ),
    );

    pdfw.Widget _h3Center(String s) => pdfw.Align(
      alignment: pdfw.Alignment.center,
      child: pdfw.Text(
        s,
        style: pdfw.TextStyle(fontSize: 12, fontWeight: pdfw.FontWeight.bold),
      ),
    );

    // Etiqueta + valor en una sola línea, alineado a la derecha
    pdfw.Widget _rightLine(String k, String v) => pdfw.Align(
      alignment: pdfw.Alignment.centerLeft,
      child: pdfw.RichText(
        text: pdfw.TextSpan(
          children: [
            pdfw.TextSpan(
              text: '$k: ',
              style: pdfw.TextStyle(fontWeight: pdfw.FontWeight.bold),
            ),
            pdfw.TextSpan(text: v),
          ],
        ),
      ),
    );

    // Etiqueta + valor en una sola línea, alineado a la derecha
    pdfw.Widget _leftLine(String k, String v) => pdfw.Align(
      alignment: pdfw.Alignment.centerLeft,
      child: pdfw.RichText(
        text: pdfw.TextSpan(
          children: [
            pdfw.TextSpan(
              text: '$k: ',
              style: pdfw.TextStyle(fontWeight: pdfw.FontWeight.bold),
            ),
            pdfw.TextSpan(text: v),
          ],
        ),
      ),
    );

    // ---------- Carga de portada (opcional) ----------
    pdfw.MemoryImage? portadaImg;
    if (portadaPath != null) {
      final f = File(portadaPath);
      if (await f.exists()) {
        final bytes = await f.readAsBytes();
        portadaImg = pdfw.MemoryImage(bytes);
      }
    }

    // ---------- Documento ----------
    final doc = pdfw.Document();

    doc.addPage(
      pdfw.MultiPage(
        pageFormat: pdf.PdfPageFormat.a4,
        build: (ctx) => [
          // 1) Portada (si hay)
          if (portadaImg != null) ...[
            pdfw.Container(
              height: 140,
              width: double.infinity,
              decoration: pdfw.BoxDecoration(
                borderRadius: pdfw.BorderRadius.circular(6),
              ),
              child: pdfw.ClipRRect(
                horizontalRadius: 6,
                verticalRadius: 6,
                child: pdfw.Image(portadaImg, fit: pdfw.BoxFit.cover),
              ),
            ),
            pdfw.SizedBox(height: 12),
          ],

          // Título + Fecha (ES)
          _h1Center('Cotización de Autofinanciamiento'),
          pdfw.SizedBox(height: 6),
          _h3Center('Fecha de realización: ${_fechaLargaEs(DateTime.now())}'),
          pdfw.SizedBox(height: 14),

          // 3 & 4) Bloque doble columna:
          //   - Izquierda: Cuotas base + Mensualidades (alineado a la IZQ)
          //   - Derecha: Características del modelo (alineado a la DER con label+valor juntos)
          pdfw.Row(
            crossAxisAlignment: pdfw.CrossAxisAlignment.start,
            children: [
              // IZQUIERDA
              pdfw.Expanded(
                flex: 1,
                child: pdfw.Column(
                  crossAxisAlignment: pdfw.CrossAxisAlignment.start,
                  children: [
                    pdfw.Text(
                      'Cuotas base (mensuales)',
                      style: pdfw.TextStyle(
                        fontSize: 14,
                        fontWeight: pdfw.FontWeight.bold,
                      ),
                    ),
                    pdfw.SizedBox(height: 6),
                    _leftLine(
                      'Aportación integrante',
                      ' \$${_mon(r.aportacionIntegrante)}',
                    ),
                    _leftLine(
                      'Aportación propietario',
                      '\$${_mon(r.aportacionPropietario)}',
                    ),
                    _leftLine(
                      'Cuota inscripción (única)',
                      ' \$${_mon(r.montoInscripcion)}',
                    ),
                    _leftLine(
                      'Gastos administración',
                      ' \$${_mon(r.montoAdministracion)}',
                    ),
                    _leftLine(
                      'IVA Gtos Adm',
                      ' \$${_mon(r.montoIvaAdministracion)}',
                    ),
                    _leftLine(
                      'Seguro de vida',
                      ' \$${_mon(r.montoSeguroVida)}',
                    ),

                    pdfw.SizedBox(height: 10),
                    pdfw.Text(
                      'Mensualidades',
                      style: pdfw.TextStyle(
                        fontSize: 14,
                        fontWeight: pdfw.FontWeight.bold,
                      ),
                    ),
                    pdfw.SizedBox(height: 6),
                    _leftLine(
                      'Integrante',
                      ' \$${_mon(r.mensualidadIntegrante)}',
                    ),
                    _leftLine(
                      'Propietario',
                      ' \$${_mon(r.mensualidadPropietario)}',
                    ),
                  ],
                ),
              ),

              pdfw.SizedBox(width: 18),

              // DERECHA
              pdfw.Expanded(
                flex: 1,
                child: pdfw.Column(
                  crossAxisAlignment: pdfw.CrossAxisAlignment.end,
                  children: [
                    pdfw.Text(
                      'Características del modelo',
                      style: pdfw.TextStyle(
                        fontSize: 14,
                        fontWeight: pdfw.FontWeight.bold,
                      ),
                    ),
                    pdfw.SizedBox(height: 6),
                    _rightLine(
                      'Modelo',
                      '${widget.modelo.modelo} ${widget.modelo.descripcion}',
                    ),
                    _rightLine('Precio', '\$${_mon(widget.modelo.precioBase)}'),
                    _rightLine('Producto', _productoSel?.nombre ?? ''),
                    _rightLine('Mes adjudicación', '${params.mesEntrega}'),
                    _rightLine('Adelanto', '${params.adelanto} mensualidades'),
                  ],
                ),
              ),
            ],
          ),

          pdfw.SizedBox(height: 16),

          // 5) Título centrado + aviso justo debajo
          _h2Center('Tabla de pagos'),
          pdfw.SizedBox(height: 6),
          _h3Center(
            'Este ejercicio es una simulación de pagos y no constituye una oferta formal. '
            'No incluye seguro automotriz.',
          ),
          pdfw.SizedBox(height: 8),

          // 6) Tabla centrada con headers actualizados
          pdfw.TableHelper.fromTextArray(
            context: ctx,
            headers: const [
              'No',
              'Estatus',
              'Aportación',
              'Gtos. Admin',
              'IVA Gtos Admin',
              'Seg. Vida',
              'Mensualidad',
            ],
            data: filas
                .map(
                  (f) => [
                    f.numero,
                    f.estatus,
                    _mon(f.aportacion),
                    _mon(f.gastosAdm),
                    _mon(f.ivaAdm),
                    _mon(f.seguroVida),
                    _mon(f.mensualidad),
                  ],
                )
                .toList(),
            headerStyle: pdfw.TextStyle(
              color: pdf.PdfColors.white,
              fontSize: 9,
              fontWeight: pdfw.FontWeight.bold,
            ),
            cellStyle: const pdfw.TextStyle(fontSize: 9),
            headerDecoration: const pdfw.BoxDecoration(
              color: pdf.PdfColors.black,
            ),

            // ¡Todo centrado!
            headerAlignment: pdfw.Alignment.center,
            cellAlignment: pdfw.Alignment.center,

            headerHeight: 22,
            cellHeight: 18,
            headerPadding: const pdfw.EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 2,
            ),
            cellPadding: const pdfw.EdgeInsets.symmetric(
              horizontal: 6,
              vertical: 2,
            ),
          ),
        ],
      ),
    );

    // Guardar en carpeta temporal
    final dir = await getTemporaryDirectory();
    final safeModel = widget.modelo.modelo.replaceAll(
      RegExp(r'[^A-Za-z0-9_\-]'),
      '_',
    );
    final filename =
        'cotizacion_${safeModel}_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final file = File('${dir.path}/$filename');

    await file.writeAsBytes(await doc.save(), flush: true);
    return file.path;
  }
}

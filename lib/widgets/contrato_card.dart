import 'package:flutter/material.dart';
import '../models/contrato.dart';

class ContratoCard extends StatelessWidget {
  final Contrato contrato;

  const ContratoCard({super.key, required this.contrato});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Contrato: ${contrato.numeroContrato}", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text("Titular: ${contrato.nombreTitular}"),
            Text("Estatus: ${contrato.estatus}"),
            const SizedBox(height: 8),
            Text("Pagado: \$${contrato.montoPagado} de \$${contrato.montoTotal}"),
            Text("Próximo pago: ${contrato.fechaProximoPago}"),
          ],
        ),
      ),
    );
  }
}

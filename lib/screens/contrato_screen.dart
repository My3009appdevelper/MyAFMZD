import 'package:flutter/material.dart';
import '../models/contrato.dart';
import '../services/contrato_service.dart';
import '../widgets/contrato_card.dart';

class ContratoScreen extends StatefulWidget {
  const ContratoScreen({super.key});

  @override
  State<ContratoScreen> createState() => _ContratoScreenState();
}

class _ContratoScreenState extends State<ContratoScreen> {
  final ContratoService contratoService = ContratoService();
  late Future<Contrato> contratoFuture;

  @override
  void initState() {
    super.initState();
    contratoFuture = contratoService.obtenerContrato();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Contrato>(
      future: contratoFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Center(child: Text("Error al cargar el contrato"));
        } else if (!snapshot.hasData) {
          return const Center(child: Text("No se encontró información"));
        } else {
          return ContratoCard(contrato: snapshot.data!);
        }
      },
    );
  }
}

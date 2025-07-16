import '../models/contrato.dart';
import '../mock/contrato_mock.dart';

class ContratoService {
  Future<Contrato> obtenerContrato() async {
    await Future.delayed(const Duration(seconds: 1)); // Simula carga
    return contratoEjemplo;
  }
}

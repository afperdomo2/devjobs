import 'package:flutter_test/flutter_test.dart';
import 'package:devjobs/theme.dart';

void main() {
  group('statusColor', () {
    test('mapea estados frecuentes a sus tokens', () {
      expect(statusColor('Enviada'), StatusColors.enviada);
      expect(statusColor('Rechazada'), StatusColors.rechazada);
      expect(statusColor('sin respuesta'), StatusColors.sinRespuesta);
      expect(statusColor('aceptada'), StatusColors.aceptada);
      expect(statusColor('retirada'), StatusColors.retirada);
    });

    test('insensible a mayúsculas y espacios', () {
      expect(statusColor('  ENVIADA  '), StatusColors.enviada);
      expect(statusColor('RechAzada'), StatusColors.rechazada);
      expect(statusColor('Aceptada'), StatusColors.aceptada);
    });

    test('distingue entrevista agendada vs realizada', () {
      expect(statusColor('entrevista agendada'), StatusColors.entrevista);
      expect(statusColor('Entrevista realizada'), StatusColors.entrevistaRealizada);
      expect(statusColor('Entrevista'), StatusColors.entrevista);
    });

    test('reconocimiento por contiene (revisión, prueba, oferta)', () {
      expect(statusColor('En revisión'), StatusColors.revision);
      expect(statusColor('en revision'), StatusColors.revision);
      expect(statusColor('Prueba técnica'), StatusColors.pruebaTecnica);
      expect(statusColor('prueba tecnica'), StatusColors.pruebaTecnica);
      expect(statusColor('Oferta laboral'), StatusColors.oferta);
    });

    test('cadena vacía o desconocida retorna otro', () {
      expect(statusColor(''), StatusColors.otro);
      expect(statusColor('   '), StatusColors.otro);
      expect(statusColor('estado inexistente'), StatusColors.otro);
    });
  });
}
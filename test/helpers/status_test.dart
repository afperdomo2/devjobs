import 'package:devjobs/helpers/status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeStatus', () {
    test('ignora mayúsculas, tildes y espacios', () {
      expect(normalizeStatus('  En Revisión '), equals('en revision'));
      expect(normalizeStatus('EN REVISION'), equals('en revision'));
    });
  });

  group('isTerminalStatus', () {
    test('reconoce los estados finales', () {
      expect(isTerminalStatus('Aceptada'), isTrue);
      expect(isTerminalStatus('rechazada'), isTrue);
      expect(isTerminalStatus(' Retirada '), isTrue);
    });

    test('un estado activo no es terminal', () {
      expect(isTerminalStatus('Enviada'), isFalse);
      expect(isTerminalStatus('Entrevista agendada'), isFalse);
      expect(isTerminalStatus(''), isFalse);
    });
  });

  group('hasResponse', () {
    test('estados que implican respuesta', () {
      expect(hasResponse('En revisión'), isTrue);
      expect(hasResponse('Prueba técnica'), isTrue);
      expect(hasResponse('Entrevista agendada'), isTrue);
      expect(hasResponse('Entrevista realizada'), isTrue);
      expect(hasResponse('Oferta recibida'), isTrue);
      expect(hasResponse('Rechazada'), isTrue);
      expect(hasResponse('Aceptada'), isTrue);
    });

    test('estados sin respuesta o vacíos', () {
      expect(hasResponse('Enviada'), isFalse);
      expect(hasResponse('Sin respuesta'), isFalse);
      expect(hasResponse('Retirada'), isFalse);
      expect(hasResponse(''), isFalse);
      expect(hasResponse('   '), isFalse);
    });

    test('ignora mayúsculas, tildes y espacios', () {
      expect(hasResponse('  EN REVISIÓN  '), isTrue);
      expect(hasResponse('SIN RESPUESTA'), isFalse);
      expect(hasResponse(' Retirada '), isFalse);
    });
  });
}

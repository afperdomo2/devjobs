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

}

import 'package:devjobs/helpers/salary_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseSalary', () {
    test('valor único en pesos', () {
      final parsed = parseSalary('6000000');

      expect(parsed, isNotNull);
      expect(parsed!.currency, equals(SalaryCurrency.cop));
      expect(parsed.min, equals(6000000));
      expect(parsed.max, equals(6000000));
      expect(parsed.isRange, isFalse);
    });

    test('rango en pesos con separadores de miles', () {
      final parsed = parseSalary('4.500.000 - 6.000.000');

      expect(parsed, isNotNull);
      expect(parsed!.currency, equals(SalaryCurrency.cop));
      expect(parsed.min, equals(4500000));
      expect(parsed.max, equals(6000000));
      expect(parsed.isRange, isTrue);
    });

    test('valor único en dólares', () {
      final parsed = parseSalary('1.300 USD');

      expect(parsed, isNotNull);
      expect(parsed!.currency, equals(SalaryCurrency.usd));
      expect(parsed.min, equals(1300));
      expect(parsed.max, equals(1300));
    });

    test('rango en dólares', () {
      final parsed = parseSalary('600 - 850 USD');

      expect(parsed, isNotNull);
      expect(parsed!.currency, equals(SalaryCurrency.usd));
      expect(parsed.min, equals(600));
      expect(parsed.max, equals(850));
    });

    test('reconoce dólares con distintas marcas', () {
      expect(parseSalary('1000 USD')?.currency, SalaryCurrency.usd);
      expect(parseSalary('1.300 dólares')?.currency, SalaryCurrency.usd);
      expect(parseSalary(r'US$ 1.300')?.currency, SalaryCurrency.usd);
      expect(parseSalary(r'1.300 U$S')?.currency, SalaryCurrency.usd);
    });

    test('reconoce pesos y usa COP por defecto', () {
      expect(parseSalary('4.500.000 COP')?.currency, SalaryCurrency.cop);
      expect(parseSalary('600 - 850')?.currency, SalaryCurrency.cop);
    });

    test('ordena los extremos del rango', () {
      final parsed = parseSalary('6.000.000 - 4.500.000');

      expect(parsed!.min, equals(4500000));
      expect(parsed.max, equals(6000000));
    });

    test('acepta decimales y redondea', () {
      final parsed = parseSalary('1.300,50 USD');

      expect(parsed!.min, equals(1301));
      expect(parsed.max, equals(1301));
    });

    test('calcula el punto medio', () {
      final parsed = parseSalary('600 - 850 USD');

      expect(parsed!.midpoint, equals(725));
    });

    test('excluye valores subjetivos', () {
      expect(parseSalary('Yo puse 5.000.000'), isNull);
      expect(parseSalary('puse 5.000.000'), isNull);
      expect(parseSalary('propuse 5.000.000'), isNull);
      expect(parseSalary('sugerí 5.000.000'), isNull);
    });

    test('ignora textos sin números y valores cero', () {
      expect(parseSalary('A convenir'), isNull);
      expect(parseSalary(''), isNull);
      expect(parseSalary('   '), isNull);
      expect(parseSalary('0'), isNull);
      expect(parseSalary('0 - 0'), isNull);
    });
  });
}

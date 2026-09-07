import 'package:devjobs/helpers/salary_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('formatSalario', () {
    test('formatea número puro', () {
      expect(formatSalario('6500000'), equals('6.500.000'));
      expect(formatSalario('100000'), equals('100.000'));
    });

    test('vacío retorna vacío', () {
      expect(formatSalario(''), equals(''));
      expect(formatSalario('   '), equals('   '));
    });

    test('texto no numérico retorna original', () {
      expect(formatSalario('abc'), equals('abc'));
      expect(formatSalario('6.500.000'), equals('6.500.000'));
    });
  });

  group('extractSalario', () {
    test('extrae un monto formateado', () {
      expect(extractSalario('yo puse 6.500.000'), equals('6.500.000'));
    });

    test('extrae monto con signo dólar', () {
      expect(extractSalario(r'$3.500.000'), equals('3.500.000'));
    });

    test('extrae monto sin separadores', () {
      expect(extractSalario('6500000'), equals('6.500.000'));
    });

    test('rango → compacto con K', () {
      expect(
        extractSalario(r'Dice $100.000 - $150.000 por mes'),
        equals(r'$100K – $150K'),
      );
    });

    test('rango con valores en millones → M', () {
      expect(
        extractSalario(r'$1.500.000 - $6.500.000'),
        equals(r'$1,5M – $6,5M'),
      );
    });

    test('sin montos → retorna texto original (o truncado si largo)', () {
      expect(extractSalario('Sin salario fijo'), equals('Sin salario fijo'));
      expect(extractSalario('a convenir'), equals('a convenir'));
    });

    test('sin montos y muy largo → truncado a 18', () {
      final raw =
          'a convenir muy largo texto sin numeros para probar truncate largo';
      final result = extractSalario(raw);
      expect(result.length, lessThanOrEqualTo(19));
      expect(result.endsWith('…'), isTrue);
    });

    test('vacío retorna vacío', () {
      expect(extractSalario(''), equals(''));
      expect(extractSalario('   '), equals(''));
    });
  });
}

import 'package:devjobs/helpers/text_shortener.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('truncate', () {
    test('no recorta si cabe', () {
      expect(truncate('abc', 5), equals('abc'));
      expect(truncate('abc', 3), equals('abc'));
    });

    test('recorta con elipsis', () {
      expect(truncate('abcdef', 3), equals('abc…'));
    });

    test('hace trim antes', () {
      expect(truncate('  abc  ', 10), equals('abc'));
    });

    test('trimRight antes de añadir elipsis', () {
      expect(truncate('abc   def', 5), equals('abc…'));
    });
  });

  group('shortContract', () {
    test('mapea exactos frecuentes', () {
      expect(shortContract('Tiempo completo'), equals('T. completo'));
      expect(shortContract('Tiempo parcial'), equals('T. parcial'));
      expect(shortContract('Prestación de servicios'),
          equals('Prestación'));
      expect(shortContract('Contrato a término fijo'), equals('T. fijo'));
      expect(shortContract('Indefinido'), equals('Indefinido'));
      expect(shortContract('Freelance'), equals('Freelance'));
      expect(shortContract('Prácticas'), equals('Prácticas'));
      expect(shortContract('Obra o labor'), equals('Obra/labor'));
      expect(shortContract('medio tiempo'), equals('T. parcial'));
    });

    test('insensible a mayúsculas y espacios', () {
      expect(shortContract('  TIEMPO COMPLETO  '), equals('T. completo'));
      expect(shortContract('término fijo'), equals('T. fijo'));
    });

    test('desconocido largo → truncado a 14', () {
      final raw =
          'Una cosa muy larga de tipo de contrato extremadamente larga';
      final result = shortContract(raw);
      expect(result.endsWith('…'), isTrue);
      expect(result.length, lessThanOrEqualTo(15));
    });

    test('vacío retorna vacío', () {
      expect(shortContract(''), equals(''));
      expect(shortContract('   '), equals(''));
    });
  });
}

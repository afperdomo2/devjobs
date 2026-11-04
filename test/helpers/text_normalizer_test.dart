import 'package:devjobs/helpers/text_normalizer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeText', () {
    test('pasa a minúsculas y quita espacios sobrantes', () {
      expect(normalizeText('  En Revisión  '), equals('en revision'));
    });

    test('quita tildes y normaliza ñ/ç', () {
      expect(normalizeText('Programación'), equals('programacion'));
      expect(normalizeText('Diseño'), equals('diseno'));
      expect(normalizeText('François'), equals('francois'));
    });

    test('deja intacto el texto sin acentos', () {
      expect(normalizeText('Remoto'), equals('remoto'));
    });

    test('vacío retorna vacío', () {
      expect(normalizeText(''), equals(''));
      expect(normalizeText('   '), equals(''));
    });
  });
}

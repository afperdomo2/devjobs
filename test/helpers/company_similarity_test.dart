import 'package:devjobs/helpers/company_similarity.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('companyMatchKey', () {
    test('ignora mayúsculas, tildes, puntuación y espacios', () {
      expect(companyMatchKey('  XpertGroup S.A.S. '), 'xpertgroup s a s');
      expect(companyMatchKey('xpertgroup'), 'xpertgroup');
      expect(companyMatchKey('Stéfanini'), 'stefanini');
    });

    test('vacío con nombres sin contenido', () {
      expect(companyMatchKey(''), '');
      expect(companyMatchKey('  !!! '), '');
    });
  });

  group('companySimilarity', () {
    test('misma clave devuelve 1', () {
      expect(companySimilarity('Acme', ' ACME '), 1);
    });

    test('error de tipeo cercano puntúa alto', () {
      expect(companySimilarity('xpergroup', 'xpertgroup'),
          greaterThanOrEqualTo(0.85));
    });

    test('nombres distintos puntúan bajo', () {
      expect(companySimilarity('Acme', 'Globex'), lessThan(0.5));
      expect(companySimilarity('Acme', ''), 0);
    });
  });

  group('similarCompanyNames', () {
    test('sugiere el nombre base por sufijos', () {
      final matches = similarCompanyNames(
        'xpertgroup sas',
        ['xpertgroup', 'Globex'],
      );
      expect(matches, ['xpertgroup']);
    });

    test('sugiere por palabra raíz compartida (stefanini)', () {
      final matches = similarCompanyNames(
        'stefanini latam',
        ['stefanini group', 'Acme'],
      );
      expect(matches, ['stefanini group']);
    });

    test('sugiere por palabra inicial contenida en el otro nombre', () {
      final matches = similarCompanyNames(
        'empresa confidencial',
        ['confidencial'],
      );
      expect(matches, ['confidencial']);
    });

    test('sugiere por error de tipeo', () {
      final matches = similarCompanyNames(
        'xpergroup',
        ['xpertgroup', 'Globex'],
      );
      expect(matches, ['xpertgroup']);
    });

    test('no sugiere coincidencias exactas', () {
      expect(
        similarCompanyNames('xpertgroup', ['xpertgroup', 'XpertGroup']),
        isEmpty,
      );
    });

    test('no sugiere nombres sin relación ni entradas cortas', () {
      expect(similarCompanyNames('Acme', ['Globex', 'Initech']), isEmpty);
      expect(similarCompanyNames('ab', ['abcd']), isEmpty);
    });

    test('respeta maxResults y ordena por similitud', () {
      final matches = similarCompanyNames(
        'stefanini',
        ['stefanini group', 'stefanini latam', 'stefanini tech', 'Acme'],
        maxResults: 2,
      );
      expect(matches, hasLength(2));
      expect(matches, everyElement(startsWith('stefanini')));
    });

    test('sin duplicados cuando varios candidatos son la misma clave', () {
      final matches = similarCompanyNames(
        'xpertgroup sas',
        ['XpertGroup', 'xpertgroup'],
      );
      expect(matches, hasLength(1));
    });
  });

  group('isConfidentialCompany', () {
    test('detecta el bucket y sus variantes', () {
      expect(isConfidentialCompany('Empresa confidencial'), isTrue);
      expect(isConfidentialCompany('confidencial'), isTrue);
      expect(isConfidentialCompany(' CONFIDENCIAL SAS '), isTrue);
    });

    test('una empresa normal no cuenta', () {
      expect(isConfidentialCompany('Acme'), isFalse);
      expect(isConfidentialCompany(''), isFalse);
    });
  });
}

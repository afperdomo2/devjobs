import 'package:devjobs/helpers/search.dart';
import 'package:devjobs/models/job_application.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const base = JobApplication(
    rowIndex: 1,
    empresa: 'Acme',
    vacante: 'Flutter Developer',
    tipoContrato: 'Tiempo completo',
    modalidad: 'Remoto',
    ciudad: 'Bogotá',
    salarioOfrecido: '5.000.000',
    estado: 'Entrevista agendada',
    link: 'https://www.linkedin.com/jobs/123',
    descripcion: 'App móvil con Flutter',
    contacto: 'Ana Pérez',
    comentarios: '- 5/11/2026: Envié hoja de vida',
  );

  group('searchTokens', () {
    test('normaliza mayúsculas, tildes y espacios repetidos', () {
      expect(searchTokens('  BOGOTÁ   Remoto '), ['bogota', 'remoto']);
    });

    test('consulta vacía o solo espacios no produce tokens', () {
      expect(searchTokens(''), isEmpty);
      expect(searchTokens('   '), isEmpty);
    });
  });

  group('matchesSearch', () {
    test('encuentra por los campos visibles de siempre', () {
      for (final query in [
        'acme',
        'flutter developer',
        'tiempo completo',
        'remoto',
        'bogota',
        '5.000.000',
        'app movil',
        'ana perez',
      ]) {
        expect(matchesSearch(base, query), isTrue, reason: query);
      }
    });

    test('encuentra por estado, comentarios, enlace y plataforma', () {
      for (final query in [
        'entrevista agendada',
        'hoja de vida',
        'linkedin.com',
        'linkedin',
      ]) {
        expect(matchesSearch(base, query), isTrue, reason: query);
      }
    });

    test('ignora tildes en la consulta y en el texto', () {
      expect(matchesSearch(base, 'Bogota'), isTrue);
      expect(matchesSearch(base, 'perez'), isTrue);
      expect(matchesSearch(base, 'movil'), isTrue);
    });

    test('varias palabras se combinan entre campos distintos', () {
      expect(matchesSearch(base, 'acme remoto'), isTrue);
      expect(matchesSearch(base, 'acme entrevista'), isTrue);
    });

    test('varias palabras exigen que todas aparezcan', () {
      expect(matchesSearch(base, 'acme presencial'), isFalse);
    });

    test('consulta vacía coincide con todo', () {
      expect(matchesSearch(base, ''), isTrue);
      expect(matchesSearch(base, '   '), isTrue);
    });

    test('texto ausente no coincide', () {
      expect(matchesSearch(base, 'globant'), isFalse);
    });
  });

  group('searchApplications', () {
    test('consulta vacía devuelve todos en el mismo orden', () {
      final apps = [base, base.copyWith(rowIndex: 2, empresa: 'Globant')];
      final results = searchApplications(apps, '');
      expect(results, apps);
    });

    test('filtra y conserva el orden original', () {
      final apps = [
        base,
        base.copyWith(rowIndex: 2, empresa: 'Globant', modalidad: 'Remoto'),
        base.copyWith(rowIndex: 3, empresa: 'Acme', modalidad: 'Presencial'),
      ];

      final results = searchApplications(apps, 'acme remoto');

      expect(results.map((a) => a.rowIndex), [1]);
    });

    test('lista vacía devuelve lista vacía', () {
      expect(searchApplications([], 'acme'), isEmpty);
    });

    test('no modifica la lista original', () {
      final apps = [base, base.copyWith(rowIndex: 2, empresa: 'Globant')];
      final copy = List<JobApplication>.of(apps);

      searchApplications(apps, 'acme');

      expect(apps, copy);
    });
  });
}

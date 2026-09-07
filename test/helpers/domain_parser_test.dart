import 'package:devjobs/helpers/domain_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('extractPlatform', () {
    test('link vacío retorna vacío', () {
      expect(extractPlatform(''), equals(''));
      expect(extractPlatform('   '), equals(''));
    });

    test('dominio directo con www', () {
      expect(
        extractPlatform('https://www.linkedin.com/jobs/view/123'),
        equals('Linkedin'),
      );
    });

    test('subdominio país (co.computrabajo.com)', () {
      expect(
        extractPlatform('https://co.computrabajo.com/empleo/123'),
        equals('Computrabajo'),
      );
    });

    test('TLD compuesto .com.co', () {
      expect(
        extractPlatform('https://www.computrabajo.com.co/empleo/123'),
        equals('Computrabajo'),
      );
    });

    test('subdominio regional + subdominio (es.indeed.com)', () {
      expect(
        extractPlatform('https://es.indeed.com/viewjob?jk=abc'),
        equals('Indeed'),
      );
    });

    test('sin esquema (www.glassdoor.com)', () {
      expect(
        extractPlatform('www.glassdoor.com/job/123'),
        equals('Glassdoor'),
      );
    });

    test('dominio directo sin subdominio ni www', () {
      expect(
        extractPlatform('https://linkedin.com/jobs'),
        equals('Linkedin'),
      );
    });

    test('link sin esquema sin www', () {
      expect(
        extractPlatform('computrabajo.com/ofertas'),
        equals('Computrabajo'),
      );
    });

    test('múltiples subdominios con TLD compuesto', () {
      expect(
        extractPlatform('https://sub.dominio.ejemplo.com.co/ruta'),
        equals('Ejemplo'),
      );
    });

    test('host de una sola etiqueta', () {
      expect(extractPlatform('https://localhost/test'), equals('Localhost'));
    });

    test('jobs.google.com (subdominio jobs)', () {
      expect(
        extractPlatform('https://jobs.google.com/search'),
        equals('Google'),
      );
    });

    test('elempleo con TLD simple', () {
      expect(
        extractPlatform('https://www.elempleo.com/co/ofertas/123'),
        equals('Elempleo'),
      );
    });
  });
}

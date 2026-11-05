import 'package:devjobs/helpers/job_url.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizeJobUrl', () {
    test('convierte una búsqueda de LinkedIn en la vacante', () {
      expect(
        normalizeJobUrl(
          'https://www.linkedin.com/jobs/search-results/?currentJobId=4487544255&eBP=abc',
        ),
        equals('https://www.linkedin.com/jobs/view/4487544255'),
      );
    });

    test('quita tracking, www y barra final', () {
      expect(
        normalizeJobUrl(
          'https://www.linkedin.com/jobs/view/123/?trk=public_jobs',
        ),
        equals('https://linkedin.com/jobs/view/123'),
      );
    });

    test('conserva parámetros funcionales y quita utm', () {
      final normalized = normalizeJobUrl(
        'https://co.computrabajo.com/oferta/abc?fgoa=true&utm_source=x&id=7',
      );
      expect(normalized, contains('id=7'));
      expect(normalized, isNot(contains('utm_')));
      expect(normalized, isNot(contains('fgoa')));
    });

    test('agrega https a un dominio sin esquema', () {
      expect(
        normalizeJobUrl('linkedin.com/jobs/view/123/'),
        equals('https://linkedin.com/jobs/view/123'),
      );
    });

    test('devuelve el texto original si no es una URL válida', () {
      expect(normalizeJobUrl('no es una url'), equals('no es una url'));
    });
  });

  group('jobUrlHint', () {
    test('detecta una publicación de LinkedIn', () {
      final hint = jobUrlHint(
        'https://www.linkedin.com/posts/seguimos-creciendo-123',
      );
      expect(hint, contains('publicación'));
    });

    test('detecta una búsqueda de LinkedIn sin vacante', () {
      final hint = jobUrlHint(
        'https://www.linkedin.com/jobs/search/?keywords=flutter',
      );
      expect(hint, contains('búsqueda'));
    });

    test('detecta la página de postulación de GetOnBrd', () {
      final hint = jobUrlHint(
        'https://www.getonbrd.com/applications?job_application_preview=true',
      );
      expect(hint, contains('GetOnBrd'));
    });

    test('detecta el formulario de BairesDev', () {
      final hint = jobUrlHint(
        'https://applicants.bairesdev.com/job/111/284527/apply?lang=es',
      );
      expect(hint, contains('BairesDev'));
    });

    test('no marca una vacante normal', () {
      expect(jobUrlHint('https://example.com/jobs/123'), isNull);
    });
  });
}

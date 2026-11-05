import 'package:devjobs/models/job_application.dart';
import 'package:devjobs/models/job_import.dart';
import 'package:devjobs/services/job_import_service.dart';
import 'package:devjobs/services/openai_compatible_extractor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FakeExtractor implements JobExtractor {
  int calls = 0;
  AiJobData? response;
  Object? error;

  @override
  Future<AiJobData> extract(String text) async {
    calls++;
    if (error != null) throw error!;
    return response ?? const AiJobData();
  }
}

const _jsonLdHtml = '''
<html><head><title>Backend - Acme</title>
<script type="application/ld+json">
{"@type":"JobPosting","title":"Backend Developer","hiringOrganization":{"name":"Acme"},"jobLocation":{"address":{"addressLocality":["Bogotá"]}},"employmentType":"FULL_TIME","baseSalary":{"currency":"COP","value":{"minValue":6000000,"maxValue":8000000}},"description":"<p>Buscamos un backend con experiencia en APIs, bases de datos y nube. Trabajo remoto.</p>"}
</script></head><body><main>Buscamos un backend con experiencia en APIs, bases de datos y nube. Trabajo remoto.</main></body></html>
''';

final _listingHtml =
    '<html><head><title>Trabajo de dev | Bolsa de Empleo</title></head>'
    '<body><h1>455 Ofertas de trabajo</h1>'
    '<p>${'Oferta de trabajo en Bogotá. ' * 40}</p></body></html>';

void main() {
  JobImportService service(http.Client client, {_FakeExtractor? extractor}) {
    return JobImportService(
      client: client,
      extractor: extractor ?? _FakeExtractor(),
      now: () => DateTime(2026, 11, 5),
    );
  }

  test('JSON-LD + IA: el JSON-LD gana y la IA completa', () async {
    final extractor = _FakeExtractor()
      ..response = const AiJobData(
        modalidad: 'Remoto',
        resumen: 'Resumen de la IA para Acme.',
        responsabilidades: ['Diseñar APIs REST.'],
        requisitos: ['Experiencia: 3 años.'],
        datosClave: ['Inglés B2'],
      );
    final client = MockClient((request) async {
      expect(request.url.toString(), equals('https://acme.com/jobs/1'));
      return http.Response(
        _jsonLdHtml,
        200,
        headers: {'content-type': 'text/html; charset=utf-8'},
      );
    });

    final result = await service(
      client,
      extractor: extractor,
    ).fromLink('https://acme.com/jobs/1', existing: const []);

    expect(result.status, JobImportStatus.success);
    expect(result.fields['empresa'], equals('Acme'));
    expect(result.fields['vacante'], equals('Backend Developer'));
    expect(result.fields['tipoContrato'], equals('Tiempo completo'));
    expect(result.fields['modalidad'], equals('Remoto'));
    expect(result.fields['ciudad'], equals('Bogotá'));
    expect(
      result.fields['salarioOfrecido'],
      equals('COP 6.000.000 – 8.000.000'),
    );
    expect(result.fields['descripcion'], contains('## Resumen'));
    expect(
      result.fields['descripcion'],
      contains('Resumen de la IA para Acme.'),
    );
    expect(result.fields['comentarios'], contains('Inglés B2'));
    expect(result.source, equals('JSON-LD + IA'));
    expect(extractor.calls, equals(1));
  });

  test('un listado no llama a la IA y pide el texto', () async {
    final extractor = _FakeExtractor();
    final client = MockClient(
      (_) async => http.Response(
        _listingHtml,
        200,
        headers: {'content-type': 'text/html; charset=utf-8'},
      ),
    );

    final result = await service(
      client,
      extractor: extractor,
    ).fromLink('https://co.computrabajo.com/oferta/1', existing: const []);

    expect(result.status, JobImportStatus.needsText);
    expect(result.message, contains('búsqueda'));
    expect(result.fields['link'], isNotNull);
    expect(extractor.calls, equals(0));
  });

  test('una SPA sin texto no llama a la IA', () async {
    final extractor = _FakeExtractor();
    final client = MockClient(
      (_) async =>
          http.Response('<html><body>Mercado Libre Careers</body></html>', 200),
    );

    final result = await service(client, extractor: extractor).fromLink(
      'https://careers-meli.mercadolibre.com/es/positions?id=1',
      existing: const [],
    );

    expect(result.status, JobImportStatus.needsText);
    expect(result.message, contains('JavaScript'));
    expect(extractor.calls, equals(0));
  });

  test('HTTP 403 no llama a la IA', () async {
    final extractor = _FakeExtractor();
    final client = MockClient((_) async => http.Response('Forbidden', 403));

    final result = await service(
      client,
      extractor: extractor,
    ).fromLink('https://co.indeed.com/viewjob?jk=1', existing: const []);

    expect(result.status, JobImportStatus.needsText);
    expect(result.message, contains('bloqueó'));
    expect(extractor.calls, equals(0));
  });

  test('texto pegado llama a la IA y llena el formulario', () async {
    final extractor = _FakeExtractor()
      ..response = const AiJobData(
        empresa: 'Acme',
        vacante: 'Dev',
        resumen: 'Buscamos un desarrollador con experiencia.',
        responsabilidades: ['Construir APIs.'],
        datosClave: ['Inglés B2'],
      );

    final result = await service(
      MockClient((_) async => http.Response('', 500)),
      extractor: extractor,
    ).fromText('Descripción de la vacante. ' * 10, existing: const []);

    expect(result.fields['empresa'], equals('Acme'));
    expect(result.fields['vacante'], equals('Dev'));
    expect(result.fields['descripcion'], contains('## Resumen'));
    expect(result.fields['descripcion'], contains('Construir APIs.'));
    expect(result.fields['comentarios'], contains('Inglés B2'));
    expect(result.fields.containsKey('link'), isFalse);
    expect(extractor.calls, equals(1));
  });

  test('si la IA falla pero hay JSON-LD, devuelve datos parciales', () async {
    final extractor = _FakeExtractor()
      ..error = const JobImportException(JobImportErrorKind.network, 'sin red');
    final client = MockClient(
      (_) async => http.Response(
        _jsonLdHtml,
        200,
        headers: {'content-type': 'text/html; charset=utf-8'},
      ),
    );

    final result = await service(
      client,
      extractor: extractor,
    ).fromLink('https://acme.com/jobs/1', existing: const []);

    expect(result.status, JobImportStatus.partial);
    expect(result.fields['empresa'], equals('Acme'));
    expect(result.fields['descripcion'], contains('## Descripción'));
    expect(result.warnings.join(' '), contains('sin red'));
    expect(result.source, equals('JSON-LD'));
  });

  test('normaliza una búsqueda de LinkedIn antes de hacer fetch', () async {
    final extractor = _FakeExtractor()
      ..response = const AiJobData(modalidad: 'Remoto');
    final client = MockClient((request) async {
      expect(
        request.url.toString(),
        equals('https://www.linkedin.com/jobs/view/4487544255'),
      );
      return http.Response(
        _jsonLdHtml,
        200,
        headers: {'content-type': 'text/html; charset=utf-8'},
      );
    });

    final result = await service(client, extractor: extractor).fromLink(
      'https://www.linkedin.com/jobs/search-results/?currentJobId=4487544255',
      existing: const [],
    );

    expect(result.fields['vacante'], equals('Backend Developer'));
  });

  test('detecta un duplicado por enlace', () async {
    final client = MockClient(
      (_) async => http.Response(
        _jsonLdHtml,
        200,
        headers: {'content-type': 'text/html; charset=utf-8'},
      ),
    );
    const existing = JobApplication(
      rowIndex: 7,
      empresa: 'Acme',
      vacante: 'Backend Developer',
      link: 'https://acme.com/jobs/1?utm_source=x',
    );

    final result = await service(
      client,
    ).fromLink('https://acme.com/jobs/1', existing: const [existing]);

    expect(result.duplicate?.rowIndex, equals(7));
  });

  test('un enlace inválido no hace fetch ni IA', () async {
    final extractor = _FakeExtractor();
    final client = MockClient((_) async {
      throw StateError('no debería hacer fetch');
    });

    final result = await service(
      client,
      extractor: extractor,
    ).fromLink('no es una url', existing: const []);

    expect(result.status, JobImportStatus.needsText);
    expect(result.message, contains('no es válido'));
    expect(extractor.calls, equals(0));
  });

  test('un enlace de publicación de LinkedIn no hace fetch', () async {
    final extractor = _FakeExtractor();
    final client = MockClient((_) async {
      throw StateError('no debería hacer fetch');
    });

    final result = await service(
      client,
      extractor: extractor,
    ).fromLink('https://www.linkedin.com/posts/foo', existing: const []);

    expect(result.status, JobImportStatus.needsText);
    expect(result.message, contains('publicación'));
    expect(extractor.calls, equals(0));
  });
}

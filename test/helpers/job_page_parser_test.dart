import 'package:devjobs/helpers/job_page_parser.dart';
import 'package:devjobs/models/job_import.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('htmlToText', () {
    test('limpia scripts, estilos y etiquetas', () {
      const html = '''
        <html><body>
          <script>alert("x")</script>
          <style>.x{color:red}</style>
          <h1>Desarrollador</h1>
          <p>Buscamos <b>talento</b>.</p>
        </body></html>
      ''';
      final text = htmlToText(html);
      expect(text, contains('Desarrollador'));
      expect(text, contains('Buscamos talento'));
      expect(text, isNot(contains('alert')));
      expect(text, isNot(contains('color:red')));
    });

    test('decodifica entidades HTML y numéricas', () {
      expect(
        htmlToText('&amp; &lt; &gt; &#39; &nbsp; &#xE1;'),
        contains("& < > ' á"),
      );
    });
  });

  group('findJobPosting', () {
    test('encuentra un JobPosting dentro de @graph', () {
      final description = 'Descripción larga de la vacante. ' * 5;
      final html =
          '''
        <script type="application/ld+json">
        {"@context":"https://schema.org","@graph":[
          {"@type":"WebSite","name":"X"},
          {"@type":"JobPosting","title":"Backend","description":"$description"}
        ]}
        </script>
      ''';
      final job = findJobPosting(html);
      expect(job, isNotNull);
      expect(job?['title'], equals('Backend'));
    });
  });

  group('parseJobPage', () {
    test('lee un JSON-LD con addressLocality en array', () {
      final html = '''
        <html><head><title>Dev - Acme</title>
        <script type="application/ld+json">
        {
          "@context": "https://schema.org",
          "@type": "JobPosting",
          "title": "Desarrollador TI",
          "hiringOrganization": {"@type": "Organization", "name": "Seguros Bolívar"},
          "jobLocation": {"@type": "Place", "address": {
            "@type": "PostalAddress",
            "addressLocality": ["Bogotá, D.C."],
            "addressRegion": ["Bogotá D.C."]
          }},
          "employmentType": "FULL_TIME",
          "baseSalary": {"@type": "MonetaryAmount", "currency": "COP"},
          "description": "<p>Buscamos un desarrollador con experiencia en Flutter y Dart para construir aplicaciones móviles.</p>"
        }
        </script></head>
        <body><main><h1>Desarrollador TI</h1><p>Buscamos un desarrollador con experiencia en Flutter y Dart para construir aplicaciones móviles.</p></main></body></html>
      ''';

      final page = parseJobPage(
        html: html,
        uri: Uri.parse('https://www.magneto365.com/co/empleos/dev-1'),
        status: 200,
      );

      expect(page.kind, JobPageKind.detail);
      expect(page.hasJobPosting, isTrue);
      expect(page.title, equals('Desarrollador TI'));
      expect(page.company, equals('Seguros Bolívar'));
      expect(page.city, contains('Bogotá, D.C.'));
      expect(page.employmentType, equals('FULL_TIME'));
      expect(page.salaryText, isNull);
      expect(page.description, contains('Buscamos un desarrollador'));
    });

    test('si la descripción estructurada es muy corta, no la usa', () {
      final longText =
          'Descripción real de la vacante con todos los detalles. ' * 5;
      final html =
          '''
        <script type="application/ld+json">
        {"@type":"JobPosting","title":"Dev","description":"..."}
        </script>
        <main><h1>Dev</h1><p>$longText</p></main>
      ''';

      final page = parseJobPage(
        html: html,
        uri: Uri.parse('https://www.elempleo.com/co/ofertas-trabajo/dev-1'),
        status: 200,
      );

      expect(page.description, isNull);
      expect(page.text, contains('Descripción real de la vacante'));
    });

    test('detecta una página de listado', () {
      final filler = 'Oferta de trabajo en Bogotá. ' * 40;
      final html =
          '''
        <html><head>
          <title>Trabajo de desarrollador en Bogotá | Bolsa de Empleo</title>
        </head><body>
          <h1>455 Ofertas de trabajo de desarrollador</h1>
          <p>$filler</p>
        </body></html>
      ''';

      final page = parseJobPage(
        html: html,
        uri: Uri.parse(
          'https://co.computrabajo.com/ofertas-de-trabajo/oferta-de-trabajo-de-dev-123',
        ),
        status: 200,
      );

      expect(page.kind, JobPageKind.listing);
      expect(page.warning, contains('búsqueda'));
    });

    test('detecta una SPA sin texto', () {
      final page = parseJobPage(
        html: '<html><body>Mercado Libre Careers</body></html>',
        uri: Uri.parse(
          'https://careers-meli.mercadolibre.com/es/positions?id=1',
        ),
        status: 200,
      );

      expect(page.kind, JobPageKind.spa);
    });

    test('marca HTTP 403 como bloqueado', () {
      final page = parseJobPage(
        html: '<html><body>Forbidden</body></html>',
        uri: Uri.parse('https://co.indeed.com/viewjob?jk=1'),
        status: 403,
      );

      expect(page.kind, JobPageKind.blocked);
    });
  });

  group('looksLikeListing', () {
    test('detecta muchos botones de postulación', () {
      expect(
        looksLikeListing(title: null, h1: null, text: 'Ver oferta ' * 7),
        isTrue,
      );
    });

    test('no marca una vacante normal', () {
      expect(
        looksLikeListing(
          title: 'Desarrollador Backend',
          h1: 'Desarrollador Backend',
          text: 'Buscamos un desarrollador. Postularme.',
        ),
        isFalse,
      );
    });
  });
}

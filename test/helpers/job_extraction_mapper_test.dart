import 'package:devjobs/helpers/job_extraction_mapper.dart';
import 'package:devjobs/models/job_application.dart';
import 'package:devjobs/models/job_import.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 5);

  ParsedJobPage page({
    String? title = 'Backend Developer',
    String? company = 'Acme',
    String? city = 'Bogotá',
    String? employmentType = 'FULL_TIME',
    String? salaryText = 'COP 6.000.000 a 8.000.000',
    String? description =
        'Buscamos un backend con experiencia en APIs, bases de datos y nube. ',
    bool hasJobPosting = true,
    JobPageKind kind = JobPageKind.detail,
  }) {
    return ParsedJobPage(
      kind: kind,
      text: 'Texto visible de la vacante. ' * 20,
      title: title,
      company: company,
      city: city,
      employmentType: employmentType,
      salaryText: salaryText,
      description: description,
      hasJobPosting: hasJobPosting,
    );
  }

  group('buildJobImportResult', () {
    test('mapea todos los campos y arma la nota con fecha', () {
      final result = buildJobImportResult(
        page: page(),
        ai: AiJobData(
          modalidad: 'remoto',
          contacto: 'Ana Pérez',
          resumen: 'Rol backend para Acme.',
          responsabilidades: ['Diseñar APIs REST.'],
          requisitos: ['Experiencia: 3 años.'],
          beneficios: ['Horario flexible.'],
          observaciones: ['Viaje ocasional.'],
          datosClave: [
            'Inglés B2',
            'Horario flexible',
            'Job ID: 123',
            'Salario de 6M',
          ],
        ),
        link: 'https://www.linkedin.com/jobs/view/1?trk=x',
        existing: const [],
        now: now,
      );

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
      expect(result.fields['descripcion'], contains('Rol backend para Acme.'));
      expect(result.fields['descripcion'], contains('## Responsabilidades'));
      expect(
        result.fields['descripcion'],
        contains('- **Experiencia:** 3 años.'),
      );
      expect(result.fields['contacto'], equals('Ana Pérez'));
      expect(result.fields['link'], equals('https://linkedin.com/jobs/view/1'));
      expect(
        result.fields['comentarios'],
        equals('- 5/11/2026: Datos clave: Inglés B2 · Horario flexible'),
      );
      expect(result.fields['comentarios'], isNot(contains('Job ID')));
      expect(result.fields['comentarios'], isNot(contains('Salario de 6M')));
      expect(result.source, equals('JSON-LD + IA'));
      expect(result.status, JobImportStatus.success);
      expect(result.warnings.join(' '), contains('contacto'));
    });

    test('salario "a convenir" va a comentarios, no al campo', () {
      final result = buildJobImportResult(
        page: page(
          salaryText: 'Salario a convenir',
          description: null,
          hasJobPosting: false,
        ),
        ai: const AiJobData(datosClave: ['Inglés B2']),
        link: '',
        existing: const [],
        now: now,
      );

      expect(result.fields.containsKey('salarioOfrecido'), isFalse);
      expect(result.fields['comentarios'], contains('Salario a convenir'));
      expect(result.warnings.join(' '), contains('monto concreto'));
    });

    test('moneda distinta de COP/USD se anota y no se toca el campo', () {
      final result = buildJobImportResult(
        page: page(salaryText: 'EUR 3.000', hasJobPosting: false),
        ai: null,
        link: '',
        existing: const [],
        now: now,
      );

      expect(result.fields.containsKey('salarioOfrecido'), isFalse);
      expect(result.fields['comentarios'], contains('EUR 3.000'));
      expect(result.warnings.join(' '), contains('moneda distinta'));
    });

    test('empresa confidencial queda vacía y avisa', () {
      final result = buildJobImportResult(
        page: page(company: 'CONFIDENTIAL'),
        ai: const AiJobData(empresa: 'Importante empresa del sector'),
        link: '',
        existing: const [],
        now: now,
      );

      expect(result.fields.containsKey('empresa'), isFalse);
      expect(result.warnings.join(' '), contains('confidencial'));
      expect(result.warnings.join(' '), contains('No se encontró la empresa'));
    });

    test('detecta duplicados por enlace canónico', () {
      const existing = JobApplication(
        rowIndex: 7,
        empresa: 'Acme',
        vacante: 'Backend Developer',
        link: 'https://www.linkedin.com/jobs/view/1?trk=x',
      );

      final result = buildJobImportResult(
        page: page(),
        ai: const AiJobData(),
        link: 'https://linkedin.com/jobs/view/1',
        existing: const [existing],
        now: now,
      );

      expect(result.duplicate?.rowIndex, equals(7));
    });

    test('para páginas sin JSON-LD prefiere el cargo de la IA', () {
      final result = buildJobImportResult(
        page: page(
          title: 'Dev en Acme — Colombia | Empleos de LinkedIn',
          hasJobPosting: false,
          description: null,
        ),
        ai: const AiJobData(vacante: 'Dev'),
        link: '',
        existing: const [],
        now: now,
      );

      expect(result.fields['vacante'], equals('Dev'));
    });

    test('para JSON-LD prefiere el cargo estructurado', () {
      final result = buildJobImportResult(
        page: page(title: 'Structured'),
        ai: const AiJobData(vacante: 'AI'),
        link: '',
        existing: const [],
        now: now,
      );

      expect(result.fields['vacante'], equals('Structured'));
    });
  });

  group('mapContractType', () {
    test('normaliza sinónimos', () {
      expect(mapContractType('Full time'), equals('Tiempo completo'));
      expect(mapContractType('Part-time'), equals('Tiempo Parcial'));
      expect(mapContractType('Obra o labor'), equals('Por proyecto'));
      expect(mapContractType('Término fijo'), equals('Temporal'));
      expect(mapContractType('Prestación de servicios'), equals('Freelance'));
      expect(mapContractType('Practicante'), equals('Otro'));
    });

    test('indefinido usa el contexto', () {
      expect(
        mapContractType('Indefinido', 'jornada tiempo completo'),
        equals('Tiempo completo'),
      );
      expect(mapContractType('Indefinido'), equals('Indefinido'));
    });

    test('vacío retorna null', () {
      expect(mapContractType(''), isNull);
      expect(mapContractType(null), isNull);
    });
  });

  group('mapModality', () {
    test('normaliza sinónimos', () {
      expect(mapModality('Remoto (teletrabajo)'), equals('Remoto'));
      expect(mapModality('Híbrido'), equals('Híbrido'));
      expect(mapModality('On-site'), equals('Presencial'));
      expect(mapModality('home office'), equals('Remoto'));
    });

    test('vacío retorna null', () {
      expect(mapModality(''), isNull);
    });
  });

  group('AiJobData.fromJson', () {
    test('acepta datosClave como objeto o como array', () {
      final fromObject = AiJobData.fromJson({
        'empresa': 'Acme',
        'datosClave': {
          'experiencia': '3 anos',
          'beneficios': ['Horario flexible'],
        },
      });
      expect(fromObject.empresa, equals('Acme'));
      expect(
        fromObject.datosClave,
        containsAll(['3 anos', 'Horario flexible']),
      );

      final fromList = AiJobData.fromJson({
        'datosClave': ['Inglés B2', 'Inglés B2', ''],
      });
      expect(fromList.datosClave, equals(['Inglés B2']));
    });
  });

  group('cleanJobTitle', () {
    test('quita sufijos de portales', () {
      expect(
        cleanJobTitle('Desarrollador | LinkedIn'),
        equals('Desarrollador'),
      );
      expect(
        cleanJobTitle('Desarrollador - Computrabajo'),
        equals('Desarrollador'),
      );
      expect(
        cleanJobTitle('Desarrollador | Bolsa de Empleo'),
        equals('Desarrollador'),
      );
    });
  });
}

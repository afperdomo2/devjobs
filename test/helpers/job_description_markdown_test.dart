import 'package:devjobs/helpers/job_description_markdown.dart';
import 'package:devjobs/models/job_import.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildJobDescriptionMarkdown', () {
    test('arma las secciones en orden y con etiquetas en negrita', () {
      const ai = AiJobData(
        resumen: 'Rol backend para Acme.',
        responsabilidades: [
          'Diseñar APIs REST.',
          'Participar en revisiones de código.',
        ],
        requisitos: ['Experiencia: 3 años.', 'Tecnologías: Dart y Flutter.'],
        beneficios: ['Horario: flexible.'],
        observaciones: ['Viaje ocasional.'],
      );

      final markdown = buildJobDescriptionMarkdown(ai)!;

      expect(markdown, contains('## Resumen\n\nRol backend para Acme.'));
      expect(
        markdown,
        contains('## Responsabilidades\n\n- Diseñar APIs REST.'),
      );
      expect(markdown, contains('## Requisitos'));
      expect(markdown, contains('- **Experiencia:** 3 años.'));
      expect(markdown, contains('- **Tecnologías:** Dart y Flutter.'));
      expect(markdown, contains('## Beneficios'));
      expect(markdown, contains('## Observaciones'));
      expect(
        markdown.indexOf('## Resumen'),
        lessThan(markdown.indexOf('## Responsabilidades')),
      );
    });

    test('omite secciones vacías', () {
      const ai = AiJobData(
        resumen: 'Solo resumen.',
        beneficios: ['Seguro médico.'],
      );

      final markdown = buildJobDescriptionMarkdown(ai);

      expect(markdown, contains('## Resumen'));
      expect(markdown, contains('## Beneficios'));
      expect(markdown, isNot(contains('## Requisitos')));
      expect(markdown, isNot(contains('## Observaciones')));
    });

    test('usa el fallback cuando la IA no trae secciones', () {
      final fallback = 'Buscamos un desarrollador. ' * 5;
      final markdown = buildJobDescriptionMarkdown(
        null,
        fallbackDescription: '• Diseñar APIs.\n• Colaborar.\n\n$fallback',
      );

      expect(markdown, contains('## Descripción'));
      expect(markdown, contains('- Diseñar APIs.'));
      expect(markdown, contains('- Colaborar.'));
    });

    test('devuelve null si no hay datos ni fallback útil', () {
      expect(buildJobDescriptionMarkdown(null), isNull);
      expect(
        buildJobDescriptionMarkdown(null, fallbackDescription: 'Corto'),
        isNull,
      );
    });

    test('respeta el tope de seguridad sin cortar a mitad de palabra', () {
      final longBullet = 'Requisito muy largo ' * 12;
      final ai = AiJobData(
        resumen: 'Resumen ' * 60,
        responsabilidades: List.filled(6, longBullet),
        requisitos: List.filled(6, longBullet),
        beneficios: List.filled(6, longBullet),
        observaciones: List.filled(6, longBullet),
      );

      final markdown = buildJobDescriptionMarkdown(ai);

      expect(markdown, isNotNull);
      expect(markdown!.length, lessThanOrEqualTo(kMaxDescriptionChars + 4));
      expect(markdown.endsWith('…'), isTrue);
    });

    test('no duplica el asterisco si la IA ya mandó negritas', () {
      const ai = AiJobData(requisitos: ['**Experiencia:** 3 años.']);

      final markdown = buildJobDescriptionMarkdown(ai);

      expect(markdown, contains('- **Experiencia:** 3 años.'));
      expect(markdown, isNot(contains('****')));
    });

    test('limita la cantidad de viñetas por sección', () {
      final ai = AiJobData(
        responsabilidades: List.generate(10, (i) => 'Responsabilidad $i.'),
      );

      final markdown = buildJobDescriptionMarkdown(ai)!;
      final bullets = RegExp(r'^- ', multiLine: true).allMatches(markdown);

      expect(bullets.length, equals(kMaxBulletsPerSection));
    });
  });

  group('looksLikeMarkdown', () {
    test('detecta títulos, listas y negritas', () {
      expect(looksLikeMarkdown('## Resumen'), isTrue);
      expect(looksLikeMarkdown('- item'), isTrue);
      expect(looksLikeMarkdown('**Importante**'), isTrue);
    });

    test('no marca texto plano', () {
      expect(looksLikeMarkdown('Buscamos un desarrollador.'), isFalse);
      expect(looksLikeMarkdown(''), isFalse);
    });
  });
}

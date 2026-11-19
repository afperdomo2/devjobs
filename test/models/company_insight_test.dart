import 'package:devjobs/models/company_insight.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CompanyRecommendation.parse', () {
    test('acepta la etiqueta visible', () {
      expect(CompanyRecommendation.parse('Priorizar'),
          CompanyRecommendation.priorizar);
      expect(CompanyRecommendation.parse('Baja prioridad'),
          CompanyRecommendation.bajaPrioridad);
    });

    test('acepta el id y variantes sin tildes', () {
      expect(CompanyRecommendation.parse('precaucion'),
          CompanyRecommendation.precaucion);
      expect(CompanyRecommendation.parse('PRECAUCIÓN'),
          CompanyRecommendation.precaucion);
    });

    test('desconocido o vacío cae en Seguimiento normal', () {
      expect(CompanyRecommendation.parse('lo que sea'),
          CompanyRecommendation.seguimientoNormal);
      expect(CompanyRecommendation.parse(''),
          CompanyRecommendation.seguimientoNormal);
    });
  });

  group('insightTagByValue', () {
    test('resuelve id y etiqueta visible sin tildes', () {
      expect(insightTagByValue('no-respuesta')?.id, 'no-respuesta');
      expect(insightTagByValue('No responde')?.id, 'no-respuesta');
      expect(insightTagByValue('PROCESO ÁGIL')?.id, 'proceso-agil');
    });

    test('fuera de vocabulario devuelve null', () {
      expect(insightTagByValue('inventada'), isNull);
      expect(insightTagByValue(''), isNull);
    });

    test('cada etiqueta tiene tono y etiqueta visible', () {
      for (final tag in kCompanyInsightTags) {
        expect(tag.label, isNotEmpty);
        expect(tag.id, isNotEmpty);
        expect(insightTagByValue(tag.label)?.id, tag.id);
      }
    });
  });

  group('CompanyInsight.fromJson', () {
    test('parsea fechas d/M/yyyy, listas y etiquetas', () {
      final insight = CompanyInsight.fromJson(<String, dynamic>{
        'empresa': ' Acme ',
        'fechaAnalisis': '12/11/2026',
        'datosAl': '10/11/2026',
        'totalPostulaciones': '5',
        'etiquetas': 'No responde, Da feedback, inventada',
        'recomendacion': 'Precaución',
        'resumen': 'Procesos lentos.',
        'fortalezas': '- Publica salarios\n- Proceso corto',
        'riesgos': '- Nunca da feedback',
        'perfilVacantes': 'Roles backend.',
        'procesoSeleccion': 'Dos etapas.',
        'contactos': '- Laura — reclutadora',
      });

      expect(insight.empresa, 'Acme');
      expect(insight.key, 'acme');
      expect(insight.fechaAnalisis, DateTime(2026, 11, 12));
      expect(insight.datosAl, DateTime(2026, 11, 10));
      expect(insight.totalPostulaciones, 5);
      // La etiqueta fuera de vocabulario se descarta.
      expect(insight.etiquetas, ['no-respuesta', 'con-feedback']);
      expect(insight.recomendacion, CompanyRecommendation.precaucion);
      expect(insight.resumen, 'Procesos lentos.');
      expect(insight.fortalezas, ['Publica salarios', 'Proceso corto']);
      expect(insight.riesgos, ['Nunca da feedback']);
      expect(insight.contactos, ['Laura — reclutadora']);
    });

    test('acepta fechas ISO y valores vacíos', () {
      final insight = CompanyInsight.fromJson(<String, dynamic>{
        'empresa': 'Acme',
        'fechaAnalisis': '2026-11-12',
        'totalPostulaciones': 0,
      });

      expect(insight.fechaAnalisis, DateTime(2026, 11, 12));
      expect(insight.datosAl, isNull);
      expect(insight.etiquetas, isEmpty);
      expect(insight.recomendacion, CompanyRecommendation.seguimientoNormal);
    });
  });

  group('CompanyInsight.tryFromJson', () {
    test('descarta registros que no son análisis (script viejo)', () {
      expect(
        CompanyInsight.tryFromJson(<String, dynamic>{
          '_rowIndex': 2,
          'empresa': 'Acme',
          'fechaPostulacion': '01/01/2026',
        }),
        isNull,
      );
    });

    test('descarta registros sin empresa', () {
      expect(
        CompanyInsight.tryFromJson(<String, dynamic>{'resumen': 'texto'}),
        isNull,
      );
    });

    test('acepta un análisis válido', () {
      final insight = CompanyInsight.tryFromJson(<String, dynamic>{
        'empresa': 'Acme',
        'resumen': 'texto',
      });
      expect(insight, isNotNull);
      expect(insight!.empresa, 'Acme');
    });
  });

  group('CompanyInsight.toJson', () {
    test('round-trip conserva etiquetas, listas y fechas', () {
      final original = CompanyInsight(
        empresa: 'Acme',
        fechaAnalisis: DateTime(2026, 11, 12),
        datosAl: DateTime(2026, 11, 10),
        totalPostulaciones: 3,
        etiquetas: ['no-respuesta', 'con-feedback'],
        recomendacion: CompanyRecommendation.priorizar,
        resumen: 'Buena.',
        fortalezas: ['Siempre responde'],
        riesgos: ['Proceso largo'],
        perfilVacantes: 'Backend.',
        procesoSeleccion: 'Dos etapas.',
        contactos: ['Laura — reclutadora'],
      );

      final json = original.toJson();
      // Fechas ISO para que Apps Script las convierta a Date.
      expect(json['fechaAnalisis'], '2026-11-12');
      expect(json['datosAl'], '2026-11-10');
      // Etiquetas con etiqueta visible para la hoja.
      expect(json['etiquetas'], 'No responde, Da feedback');
      expect(json['recomendacion'], 'Priorizar');
      expect(json['fortalezas'], '- Siempre responde');

      final back = CompanyInsight.fromJson(
        Map<String, dynamic>.from(json.map(
          (k, v) => MapEntry(k, v?.toString() ?? ''),
        )),
      );
      expect(back.empresa, 'Acme');
      expect(back.fechaAnalisis, DateTime(2026, 11, 12));
      expect(back.datosAl, DateTime(2026, 11, 10));
      expect(back.totalPostulaciones, 3);
      expect(back.etiquetas, ['no-respuesta', 'con-feedback']);
      expect(back.recomendacion, CompanyRecommendation.priorizar);
      expect(back.fortalezas, ['Siempre responde']);
      expect(back.riesgos, ['Proceso largo']);
      expect(back.contactos, ['Laura — reclutadora']);
    });

    test('las listas quedan como líneas "- item"', () {
      const insight = CompanyInsight(
        empresa: 'Acme',
        fortalezas: ['Una', 'Dos'],
      );
      expect(insight.toJson()['fortalezas'], '- Una\n- Dos');
    });
  });
}

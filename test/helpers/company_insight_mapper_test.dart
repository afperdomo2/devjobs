import 'package:devjobs/helpers/company_insight_mapper.dart';
import 'package:devjobs/models/company_insight.dart';
import 'package:devjobs/models/job_import.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CompanyInsight map(Map<String, dynamic> json) {
    return mapAiCompanyInsight(
      json,
      empresa: 'Acme',
      fechaAnalisis: DateTime(2026, 11, 19),
      datosAl: DateTime(2026, 11, 10),
      totalPostulaciones: 4,
    );
  }

  test('mapea un análisis completo', () {
    final insight = map(<String, dynamic>{
      'etiquetas': ['no-respuesta', 'proceso-agil'],
      'recomendacion': 'Baja prioridad',
      'resumen': 'No responde pero el proceso es corto.',
      'fortalezas': ['Proceso de una etapa'],
      'riesgos': ['Nunca responden'],
      'perfilVacantes': 'Roles de backend.',
      'procesoSeleccion': 'Una sola entrevista.',
      'contactos': ['Laura — reclutadora'],
    });

    expect(insight.empresa, 'Acme');
    expect(insight.fechaAnalisis, DateTime(2026, 11, 19));
    expect(insight.datosAl, DateTime(2026, 11, 10));
    expect(insight.totalPostulaciones, 4);
    expect(insight.etiquetas, ['no-respuesta', 'proceso-agil']);
    expect(insight.recomendacion, CompanyRecommendation.bajaPrioridad);
    expect(insight.resumen, 'No responde pero el proceso es corto.');
    expect(insight.fortalezas, ['Proceso de una etapa']);
    expect(insight.riesgos, ['Nunca responden']);
    expect(insight.contactos, ['Laura — reclutadora']);
  });

  test('acepta etiquetas por etiqueta visible y descarta las inventadas', () {
    final insight = map(<String, dynamic>{
      'etiquetas': 'No responde, Etiqueta inventada, Da feedback',
      'resumen': 'texto',
    });

    expect(insight.etiquetas, ['no-respuesta', 'con-feedback']);
  });

  test('recorta textos y listas a sus límites', () {
    final insight = map(<String, dynamic>{
      'resumen': 'x' * 1000,
      'fortalezas': ['a' * 400, 'b', 'c', 'd', 'e', 'f', 'g'],
      'contactos': ['1', '2', '3', '4'],
    });

    expect(insight.resumen.length, kInsightMaxText);
    expect(insight.fortalezas.length, kInsightMaxItems);
    expect(insight.fortalezas.first.length, kInsightMaxItemLength);
    expect(insight.contactos.length, kInsightMaxContactos);
  });

  test('acepta listas como objeto y recomendación desconocida', () {
    final insight = map(<String, dynamic>{
      'resumen': 'texto',
      'fortalezas': {'clave': 'Valor', 'otra': 'Otro'},
      'recomendacion': 'algo raro',
    });

    expect(insight.fortalezas, ['Valor', 'Otro']);
    expect(insight.recomendacion, CompanyRecommendation.seguimientoNormal);
  });

  test('lanza JobImportException si el análisis viene vacío', () {
    expect(
      () => map(<String, dynamic>{'etiquetas': [], 'resumen': ''}),
      throwsA(
        isA<JobImportException>().having(
          (e) => e.kind,
          'kind',
          JobImportErrorKind.invalidResponse,
        ),
      ),
    );
  });
}

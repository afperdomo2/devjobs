import 'package:devjobs/helpers/company_analysis.dart';
import 'package:devjobs/helpers/company_analysis_prompt.dart';
import 'package:devjobs/models/job_application.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

JobApplication app({
  int rowIndex = 1,
  String vacante = 'Dev Backend',
  String estado = 'Enviada',
  String fechaPostulacion = '01/11/2026',
  String fechaSeguimiento = '',
  String comentarios = '',
  String descripcion = '',
  String link = '',
  String salarioOfrecido = '',
}) {
  return JobApplication(
    rowIndex: rowIndex,
    empresa: 'Acme',
    vacante: vacante,
    estado: estado,
    fechaPostulacion: fechaPostulacion,
    fechaSeguimiento: fechaSeguimiento,
    comentarios: comentarios,
    descripcion: descripcion,
    link: link,
    salarioOfrecido: salarioOfrecido,
  );
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  test('incluye empresa, hechos calculados, notas y canal', () {
    final apps = [
      app(
        rowIndex: 1,
        estado: 'En revisión',
        fechaSeguimiento: '05/11/2026',
        comentarios: '- 5/11/2026: Me llamaron por teléfono',
        link: 'https://www.linkedin.com/jobs/1',
        salarioOfrecido: '3.000.000 COP',
      ),
      app(rowIndex: 2, fechaPostulacion: '02/11/2026'),
    ];
    final facts = companyAnalysisFacts(apps, now: DateTime(2026, 11, 19));
    final prompt = buildCompanyAnalysisPrompt(
      empresa: 'Acme',
      facts: facts,
      apps: apps,
    );

    expect(prompt, contains('Empresa: Acme'));
    expect(prompt, contains('Postulaciones: 2 (activas: 2, finalizadas: 0)'));
    expect(prompt, contains('Respondieron: 1/2 (50%)'));
    expect(prompt, contains('Entrevistas realizadas: 0'));
    expect(prompt, contains('COP: 3M–3M (promedio 3M, 1 dato)'));
    expect(prompt, contains('canal: Linkedin'));
    expect(prompt, contains('sin enlace (posible correo)'));
    expect(prompt, contains('Me llamaron por teléfono'));
    expect(prompt, contains('<empresa>'));
    expect(prompt, contains('</empresa>'));
  });

  test('ordena por última novedad y trunca descripciones largas', () {
    final longDescription = 'x' * 500;
    final apps = [
      app(
        rowIndex: 1,
        vacante: 'Vieja',
        fechaPostulacion: '01/10/2026',
        descripcion: longDescription,
      ),
      app(
        rowIndex: 2,
        vacante: 'Nueva',
        fechaPostulacion: '01/11/2026',
        fechaSeguimiento: '10/11/2026',
      ),
    ];
    final facts = companyAnalysisFacts(apps, now: DateTime(2026, 11, 19));
    final prompt = buildCompanyAnalysisPrompt(
      empresa: 'Acme',
      facts: facts,
      apps: apps,
    );

    // La más reciente aparece primero.
    expect(prompt.indexOf('Nueva'), lessThan(prompt.indexOf('Vieja')));
    // La descripción se recorta con elipsis y no arruina el prompt.
    expect(prompt, isNot(contains(longDescription)));
    expect(prompt, contains('${'x' * 240}…'));
  });

  test('con más de 25 postulaciones indica cuántas quedaron fuera', () {
    final apps = [
      for (var i = 1; i <= 26; i++)
        app(rowIndex: i, fechaPostulacion: '$i/11/2026'),
    ];
    final facts = companyAnalysisFacts(apps, now: DateTime(2026, 11, 19));
    final prompt = buildCompanyAnalysisPrompt(
      empresa: 'Acme',
      facts: facts,
      apps: apps,
    );

    expect(prompt, contains('…y 1 postulación más.'));
  });

  test('el prompt de sistema trae el vocabulario cerrado de etiquetas', () {
    for (final tag in const [
      'no-respuesta',
      'respuesta-lenta',
      'respuesta-rapida',
      'con-feedback',
      'sin-feedback',
      'proceso-agil',
      'proceso-largo',
      'vacantes-estancadas',
      'reclutamiento-serio',
      'salario-transparente',
      'pide-prueba',
      'publica-frecuente',
    ]) {
      expect(kCompanyAnalysisSystemPrompt, contains(tag));
    }
    expect(kCompanyAnalysisSystemPrompt, contains('Priorizar'));
    expect(kCompanyAnalysisSystemPrompt, contains('Precaución'));
    expect(kCompanyAnalysisSystemPrompt, contains('canal de postulación'));
  });
}

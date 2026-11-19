import 'package:devjobs/models/ai_config.dart';
import 'package:devjobs/models/company_insight.dart';
import 'package:devjobs/models/job_application.dart';
import 'package:devjobs/models/job_import.dart';
import 'package:devjobs/services/company_analyzer_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

AiConfig _config({List<String> models = const ['m1', 'm2']}) {
  return AiConfig(
    baseUrl: 'https://ejemplo.test/v1',
    apiKey: 'key',
    models: models,
  );
}

JobApplication _app({int rowIndex = 1}) {
  return JobApplication(
    rowIndex: rowIndex,
    empresa: 'Acme',
    vacante: 'Dev',
    estado: 'Enviada',
    fechaPostulacion: '01/11/2026',
    comentarios: '- 2/11/2026: Sin respuesta',
  );
}

const _okJson = <String, dynamic>{
  'etiquetas': ['no-respuesta'],
  'recomendacion': 'Baja prioridad',
  'resumen': 'No responde.',
  'fortalezas': [],
  'riesgos': ['Nunca responden'],
};

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  test('analiza con el primer modelo y registra datosAl/total', () async {
    String? usedModel;
    String? usedUser;
    final service = CompanyAnalyzerService(
      config: _config(),
      delayBetweenAttempts: Duration.zero,
      completeForModel: (model, system, user) async {
        usedModel = model;
        usedUser = user;
        return _okJson;
      },
    );

    final insight = await service.analyze(
      empresa: 'Acme',
      apps: [_app()],
      now: DateTime(2026, 11, 19),
    );

    expect(usedModel, 'm1');
    expect(usedUser, contains('Empresa: Acme'));
    expect(usedUser, contains('Sin respuesta'));
    expect(insight.empresa, 'Acme');
    expect(insight.fechaAnalisis, DateTime(2026, 11, 19));
    expect(insight.datosAl, DateTime(2026, 11, 2));
    expect(insight.totalPostulaciones, 1);
    expect(insight.etiquetas, ['no-respuesta']);
    expect(insight.recomendacion, CompanyRecommendation.bajaPrioridad);
  });

  test('cuota en el primer modelo activa el respaldo al segundo', () async {
    final attempted = <String>[];
    final service = CompanyAnalyzerService(
      config: _config(),
      delayBetweenAttempts: Duration.zero,
      completeForModel: (model, system, user) async {
        attempted.add(model);
        if (model == 'm1') {
          throw const JobImportException(JobImportErrorKind.quota, 'cuota');
        }
        return _okJson;
      },
    );

    final insight = await service.analyze(empresa: 'Acme', apps: [_app()]);

    expect(attempted, ['m1', 'm2']);
    expect(insight.resumen, 'No responde.');
  });

  test('error de red NO activa el respaldo', () async {
    final attempted = <String>[];
    final service = CompanyAnalyzerService(
      config: _config(),
      delayBetweenAttempts: Duration.zero,
      completeForModel: (model, system, user) async {
        attempted.add(model);
        throw const JobImportException(JobImportErrorKind.network, 'red');
      },
    );

    await expectLater(
      service.analyze(empresa: 'Acme', apps: [_app()]),
      throwsA(isA<JobImportException>()),
    );
    expect(attempted, ['m1']);
  });

  test('si todos fallan, el error lista los modelos intentados', () async {
    final service = CompanyAnalyzerService(
      config: _config(),
      delayBetweenAttempts: Duration.zero,
      completeForModel: (model, system, user) async {
        throw const JobImportException(JobImportErrorKind.quota, 'cuota');
      },
    );

    await expectLater(
      service.analyze(empresa: 'Acme', apps: [_app()]),
      throwsA(
        isA<JobImportException>()
            .having((e) => e.message, 'message', contains('m1, m2')),
      ),
    );
  });

  test('sin IA configurada lanza unauthorized', () async {
    final service = CompanyAnalyzerService(
      config: AiConfig.empty,
      completeForModel: (model, system, user) async => _okJson,
    );

    await expectLater(
      service.analyze(empresa: 'Acme', apps: [_app()]),
      throwsA(
        isA<JobImportException>().having(
          (e) => e.kind,
          'kind',
          JobImportErrorKind.unauthorized,
        ),
      ),
    );
  });

  test('sin postulaciones no llama a la IA', () async {
    var called = false;
    final service = CompanyAnalyzerService(
      config: _config(),
      completeForModel: (model, system, user) async {
        called = true;
        return _okJson;
      },
    );

    await expectLater(
      service.analyze(empresa: 'Acme', apps: const []),
      throwsA(isA<JobImportException>()),
    );
    expect(called, isFalse);
  });
}

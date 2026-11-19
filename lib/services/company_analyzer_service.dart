import 'dart:async';

import 'package:http/http.dart' as http;

import '../helpers/company_analysis.dart';
import '../helpers/company_analysis_prompt.dart';
import '../helpers/company_insight_mapper.dart';
import '../models/ai_config.dart';
import '../models/company_insight.dart';
import '../models/job_application.dart';
import '../models/job_import.dart';
import 'fallback_extractor.dart';
import 'openai_compatible_extractor.dart';

/// Genera el [CompanyInsight] de una empresa con IA.
///
/// Arma el prompt con los hechos deterministas ([companyAnalysisFacts]) y el
/// historial de postulaciones, y prueba los modelos de [AiConfig] en orden
/// con la misma política de respaldo de [FallbackExtractor]: cuota, clave no
/// habilitada, modelo no encontrado o servidor caído pasan al siguiente;
/// red o JSON inválido no.
class CompanyAnalyzerService {
  final AiConfig config;
  final http.Client? client;
  final Duration delayBetweenAttempts;

  /// Permite sustituir la llamada al modelo en tests.
  final Future<Map<String, dynamic>> Function(String model, String system,
      String user)? completeForModel;

  CompanyAnalyzerService({
    required this.config,
    this.client,
    this.delayBetweenAttempts = const Duration(milliseconds: 400),
    this.completeForModel,
  });

  /// Analiza las postulaciones [apps] de la empresa [empresa].
  ///
  /// [now] fija la fecha del análisis (tests determinísticos). Los datos
  /// incluidos quedan registrados en el resultado ([CompanyInsight.datosAl]
  /// y [CompanyInsight.totalPostulaciones]) para detectar el desfase.
  Future<CompanyInsight> analyze({
    required String empresa,
    required List<JobApplication> apps,
    DateTime? now,
  }) async {
    if (!config.isEnabled) {
      throw const JobImportException(
        JobImportErrorKind.unauthorized,
        'Falta configurar la IA para analizar empresas.',
      );
    }
    if (apps.isEmpty) {
      throw const JobImportException(
        JobImportErrorKind.unknown,
        'No hay postulaciones de esta empresa para analizar.',
      );
    }

    final facts = companyAnalysisFacts(apps, now: now);
    final prompt = buildCompanyAnalysisPrompt(
      empresa: empresa,
      facts: facts,
      apps: apps,
    );

    final data = await _completeWithFallback(
      kCompanyAnalysisSystemPrompt,
      prompt,
    );

    return mapAiCompanyInsight(
      data,
      empresa: empresa,
      fechaAnalisis: now ?? DateTime.now(),
      datosAl: facts.ultimaNovedad,
      totalPostulaciones: facts.total,
    );
  }

  Future<Map<String, dynamic>> _completeWithFallback(
    String system,
    String user,
  ) async {
    final models = config.models;
    if (models.isEmpty) {
      throw const JobImportException(
        JobImportErrorKind.unauthorized,
        'No hay modelos de IA configurados.',
      );
    }

    Object? lastError;
    final tried = <String>[];

    for (final model in models) {
      try {
        return await _complete(model, system, user);
      } on JobImportException catch (error) {
        lastError = error;
        tried.add(model);
        if (!aiShouldFallback(error.kind)) break;
        if (delayBetweenAttempts > Duration.zero) {
          await Future<void>.delayed(delayBetweenAttempts);
        }
      }
    }

    final names = tried.join(', ');
    if (lastError is JobImportException) {
      throw JobImportException(
        lastError.kind,
        'Ningún modelo respondió ($names). ${lastError.message}',
      );
    }
    throw JobImportException(
      JobImportErrorKind.unknown,
      'Ningún modelo respondió ($names).',
    );
  }

  Future<Map<String, dynamic>> _complete(
    String model,
    String system,
    String user,
  ) {
    final override = completeForModel;
    if (override != null) return override(model, system, user);
    return OpenAiCompatibleExtractor(
      baseUrl: config.baseUrl,
      apiKey: config.apiKey,
      model: model,
      client: client,
    ).completeJson(system: system, user: user);
  }
}

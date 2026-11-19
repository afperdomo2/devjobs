import 'dart:async';

import 'package:http/http.dart' as http;

import '../models/ai_config.dart';
import '../models/job_import.dart';
import 'openai_compatible_extractor.dart';

/// true si un error de un modelo justifica probar con el siguiente:
/// cuota, clave no habilitada, modelo no encontrado o servidor caído.
///
/// Los errores de red o de respuesta inválida no activan el respaldo: son
/// problemas de conexión o de calidad, no de disponibilidad. La comparten
/// [FallbackExtractor] y el análisis de empresas.
bool aiShouldFallback(JobImportErrorKind kind) => switch (kind) {
  JobImportErrorKind.quota ||
  JobImportErrorKind.unauthorized ||
  JobImportErrorKind.notFound ||
  JobImportErrorKind.server => true,
  _ => false,
};

/// Un extractor con el nombre del modelo que representa; el nombre se usa en
/// los mensajes de error cuando ningún modelo responde.
class ModelExtractor {
  final String model;
  final JobExtractor extractor;

  const ModelExtractor({required this.model, required this.extractor});
}

/// Extrae la vacante probando varios modelos en orden.
///
/// Si un modelo falla por cuota, clave no habilitada, modelo no encontrado o
/// servidor caído, se intenta con el siguiente. Los errores de red o de
/// respuesta inválida no activan el respaldo: son problemas de conexión o de
/// calidad, no de disponibilidad.
class FallbackExtractor implements JobExtractor {
  final List<ModelExtractor> models;
  final Duration delayBetweenAttempts;

  FallbackExtractor(
    this.models, {
    this.delayBetweenAttempts = const Duration(milliseconds: 400),
  });

  /// Crea un extractor por modelo de [config] contra el mismo proveedor.
  factory FallbackExtractor.fromConfig(
    AiConfig config, {
    http.Client? client,
  }) {
    return FallbackExtractor([
      for (final model in config.models)
        ModelExtractor(
          model: model,
          extractor: OpenAiCompatibleExtractor(
            baseUrl: config.baseUrl,
            apiKey: config.apiKey,
            model: model,
            client: client,
          ),
        ),
    ]);
  }

  @override
  Future<AiJobData> extract(String text) async {
    if (models.isEmpty) {
      throw const JobImportException(
        JobImportErrorKind.unauthorized,
        'No hay modelos de IA configurados.',
      );
    }

    Object? lastError;
    final tried = <String>[];

    for (final candidate in models) {
      try {
        return await candidate.extractor.extract(text);
      } on JobImportException catch (error) {
        lastError = error;
        tried.add(candidate.model);
        if (!aiShouldFallback(error.kind)) break;
        if (delayBetweenAttempts > Duration.zero) {
          await Future<void>.delayed(delayBetweenAttempts);
        }
      }
    }

    throw _allFailed(lastError, tried);
  }

  JobImportException _allFailed(Object? lastError, List<String> tried) {
    final models = tried.join(', ');
    if (lastError is JobImportException) {
      return JobImportException(
        lastError.kind,
        'Ningún modelo respondió ($models). ${lastError.message}',
      );
    }
    return JobImportException(
      JobImportErrorKind.unknown,
      'Ningún modelo respondió ($models).',
    );
  }
}

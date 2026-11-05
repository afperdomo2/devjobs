import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../helpers/job_extraction_mapper.dart';
import '../helpers/job_page_parser.dart';
import '../helpers/job_url.dart';
import '../helpers/offer_link.dart';
import '../helpers/text_shortener.dart';
import '../models/job_application.dart';
import '../models/job_import.dart';
import 'openai_compatible_extractor.dart';

/// Interfaz para poder inyectar un importador falso en tests.
abstract class JobImporter {
  Future<JobImportResult> fromLink(
    String url, {
    required List<JobApplication> existing,
  });

  Future<JobImportResult> fromText(
    String text, {
    required List<JobApplication> existing,
    String? link,
  });
}

const Map<String, String> _fetchHeaders = {
  'User-Agent':
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36',
  'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
  'Accept-Language': 'es-CO,es;q=0.9,en;q=0.8',
};

class JobImportService implements JobImporter {
  final http.Client _client;
  final JobExtractor _extractor;
  final DateTime Function() _now;
  final int maxInputChars;

  JobImportService({
    http.Client? client,
    JobExtractor? extractor,
    DateTime Function()? now,
    this.maxInputChars = 12000,
  }) : _client = client ?? http.Client(),
       _extractor =
           extractor ??
           OpenAiCompatibleExtractor(
             baseUrl: kAiBaseUrl,
             apiKey: kAiApiKey,
             model: kAiModel,
           ),
       _now = now ?? DateTime.now;

  @override
  Future<JobImportResult> fromLink(
    String rawUrl, {
    required List<JobApplication> existing,
  }) async {
    final link = normalizeJobUrl(rawUrl);
    final uri = parseOfferUri(link);
    if (uri == null) {
      return _needsText(
        link,
        'El enlace no es válido. Revisa la URL o pega la descripción.',
      );
    }

    final hint = jobUrlHint(link);
    if (hint != null) {
      return _needsText(link, hint, kind: JobPageKind.notAJob);
    }

    http.Response response;
    try {
      response = await _client
          .get(uri, headers: _fetchHeaders)
          .timeout(const Duration(seconds: 20));
    } on TimeoutException {
      return _needsText(
        link,
        'El sitio tardó demasiado en responder. Pega la descripción de la vacante.',
      );
    } catch (_) {
      return _needsText(
        link,
        'No se pudo abrir el enlace. Revisa tu conexión o pega la descripción.',
      );
    }

    if (response.statusCode != 200) {
      return _needsText(
        link,
        _statusMessage(response.statusCode),
        kind:
            response.statusCode == 401 ||
                response.statusCode == 403 ||
                response.statusCode == 429
            ? JobPageKind.blocked
            : JobPageKind.unknown,
      );
    }

    final contentType = (response.headers['content-type'] ?? '').toLowerCase();
    if (contentType.isNotEmpty &&
        !contentType.contains('html') &&
        !contentType.contains('xml') &&
        !contentType.contains('text/plain')) {
      return _needsText(
        link,
        'El enlace no parece una página web. Pega la descripción de la vacante.',
      );
    }

    final html = _decode(response);
    final page = parseJobPage(
      html: html,
      uri: uri,
      status: response.statusCode,
    );

    if (page.kind != JobPageKind.detail) {
      return _needsText(
        link,
        page.warning ??
            'No se pudo leer la vacante. Pega la descripción de la vacante.',
        kind: page.kind,
      );
    }

    return _extract(page: page, link: link, existing: existing);
  }

  @override
  Future<JobImportResult> fromText(
    String rawText, {
    required List<JobApplication> existing,
    String? link,
  }) async {
    final text = rawText.trim();
    if (text.length < 40) {
      return _needsText(
        link ?? '',
        'Pega una descripción un poco más larga (mínimo 40 caracteres).',
      );
    }

    final page = ParsedJobPage(kind: JobPageKind.detail, text: text);
    return _extract(page: page, link: link?.trim() ?? '', existing: existing);
  }

  Future<JobImportResult> _extract({
    required ParsedJobPage page,
    required String link,
    required List<JobApplication> existing,
  }) async {
    AiJobData? ai;
    String? aiError;

    try {
      ai = await _extractor.extract(_buildAiInput(page));
    } on JobImportException catch (error) {
      aiError = error.message;
    } catch (_) {
      aiError = 'No se pudo consultar la IA.';
    }

    final result = buildJobImportResult(
      page: page,
      ai: ai,
      link: link,
      existing: existing,
      now: _now(),
    );

    if (ai == null) {
      if (!result.hasData) {
        return _needsText(
          link,
          aiError ?? 'No se pudieron extraer datos. Pega la descripción.',
        );
      }
      return JobImportResult(
        status: JobImportStatus.partial,
        fields: result.fields,
        importedFields: result.importedFields,
        warnings: [
          ...result.warnings,
          aiError ?? 'No se pudieron generar las notas con IA.',
        ],
        duplicate: result.duplicate,
        source: 'JSON-LD',
        kind: result.kind,
      );
    }

    if (!result.hasData) {
      return _needsText(
        link,
        'No se encontraron datos en la página. Pega la descripción de la vacante.',
      );
    }

    return result;
  }

  String _buildAiInput(ParsedJobPage page) {
    final buffer = StringBuffer();
    if (page.title != null) buffer.writeln('Cargo detectado: ${page.title}');
    if (page.company != null) {
      buffer.writeln('Empresa detectada: ${page.company}');
    }
    if (page.city != null) buffer.writeln('Ciudad detectada: ${page.city}');
    if (page.employmentType != null) {
      buffer.writeln('Tipo de contrato detectado: ${page.employmentType}');
    }
    if (page.salaryText != null) {
      buffer.writeln('Salario detectado: ${page.salaryText}');
    }
    buffer.writeln('Texto de la página:');

    final body = (page.description != null && page.description!.length >= 200)
        ? page.description!
        : page.text;
    buffer.write(body);

    return truncate(buffer.toString(), maxInputChars);
  }

  String _decode(http.Response response) {
    final maxBytes = 3 * 1024 * 1024;
    final bytes = response.bodyBytes.length > maxBytes
        ? response.bodyBytes.sublist(0, maxBytes)
        : response.bodyBytes;

    final contentType = response.headers['content-type'] ?? '';
    final charset = RegExp(
      r'''charset=["']?([\w-]+)''',
      caseSensitive: false,
    ).firstMatch(contentType)?.group(1)?.toLowerCase();

    if (charset != null && charset != 'utf-8' && charset != 'utf8') {
      return latin1.decode(bytes, allowInvalid: true);
    }
    return utf8.decode(bytes, allowMalformed: true);
  }

  String _statusMessage(int status) {
    return switch (status) {
      401 || 403 =>
        'El sitio bloqueó la lectura automática (HTTP $status). Pega la descripción de la vacante.',
      404 => 'La vacante no está disponible (HTTP 404). Pega la descripción.',
      429 =>
        'El sitio limitó las solicitudes (HTTP 429). Intenta más tarde o pega la descripción.',
      _ =>
        'El sitio respondió con HTTP $status. Pega la descripción de la vacante.',
    };
  }

  JobImportResult _needsText(
    String link,
    String message, {
    JobPageKind kind = JobPageKind.unknown,
  }) {
    final normalized = link.trim().isEmpty ? '' : normalizeJobUrl(link);
    return JobImportResult(
      status: JobImportStatus.needsText,
      fields: {if (normalized.isNotEmpty) 'link': normalized},
      importedFields: {if (normalized.isNotEmpty) 'link'},
      warnings: const [],
      message: message,
      source: '',
      kind: kind,
    );
  }
}

import 'dart:convert';

import 'package:devjobs/models/ai_config.dart';
import 'package:devjobs/models/job_import.dart';
import 'package:devjobs/services/fallback_extractor.dart';
import 'package:devjobs/services/openai_compatible_extractor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

class _FakeExtractor implements JobExtractor {
  final String model;
  final AiJobData? response;
  final JobImportException? error;
  int calls = 0;

  _FakeExtractor({required this.model, this.response, this.error});

  @override
  Future<AiJobData> extract(String text) async {
    calls++;
    if (error != null) throw error!;
    return response ?? const AiJobData();
  }
}

JobImportException _fail(JobImportErrorKind kind, String message) =>
    JobImportException(kind, message);

FallbackExtractor _extractor(List<_FakeExtractor> extractors) {
  return FallbackExtractor(
    [
      for (final e in extractors)
        ModelExtractor(model: e.model, extractor: e),
    ],
    delayBetweenAttempts: Duration.zero,
  );
}

void main() {
  test('devuelve la respuesta del primer modelo', () async {
    final first = _FakeExtractor(
      model: 'a',
      response: const AiJobData(empresa: 'Acme'),
    );
    final second = _FakeExtractor(model: 'b');

    final data = await _extractor([first, second]).extract('texto');

    expect(data.empresa, equals('Acme'));
    expect(first.calls, equals(1));
    expect(second.calls, equals(0));
  });

  test('si el primero se queda sin cuota prueba el siguiente', () async {
    final first = _FakeExtractor(
      model: 'a',
      error: _fail(JobImportErrorKind.quota, 'Cuota agotada'),
    );
    final second = _FakeExtractor(
      model: 'b',
      response: const AiJobData(vacante: 'Dev'),
    );

    final data = await _extractor([first, second]).extract('texto');

    expect(data.vacante, equals('Dev'));
    expect(second.calls, equals(1));
  });

  test('si el primero no está habilitado prueba el siguiente', () async {
    final first = _FakeExtractor(
      model: 'a',
      error: _fail(JobImportErrorKind.unauthorized, 'No habilitado'),
    );
    final second = _FakeExtractor(model: 'b');

    await _extractor([first, second]).extract('texto');

    expect(second.calls, equals(1));
  });

  test('si el modelo no existe prueba el siguiente', () async {
    final first = _FakeExtractor(
      model: 'a',
      error: _fail(JobImportErrorKind.notFound, 'Modelo no disponible'),
    );
    final second = _FakeExtractor(model: 'b');

    await _extractor([first, second]).extract('texto');

    expect(second.calls, equals(1));
  });

  test('si el proveedor está caído prueba el siguiente', () async {
    final first = _FakeExtractor(
      model: 'a',
      error: _fail(JobImportErrorKind.server, '500'),
    );
    final second = _FakeExtractor(model: 'b');

    await _extractor([first, second]).extract('texto');

    expect(second.calls, equals(1));
  });

  test('un error de red no activa el respaldo', () async {
    final first = _FakeExtractor(
      model: 'a',
      error: _fail(JobImportErrorKind.network, 'Sin conexión'),
    );
    final second = _FakeExtractor(model: 'b');

    await expectLater(
      _extractor([first, second]).extract('texto'),
      throwsA(isA<JobImportException>()),
    );

    expect(second.calls, equals(0));
  });

  test('una respuesta inválida no activa el respaldo', () async {
    final first = _FakeExtractor(
      model: 'a',
      error: _fail(JobImportErrorKind.invalidResponse, 'JSON inválido'),
    );
    final second = _FakeExtractor(model: 'b');

    await expectLater(
      _extractor([first, second]).extract('texto'),
      throwsA(isA<JobImportException>()),
    );

    expect(second.calls, equals(0));
  });

  test('si todos fallan lanza un error con los modelos intentados', () async {
    final first = _FakeExtractor(
      model: 'deepseek-v4.1-flash',
      error: _fail(JobImportErrorKind.quota, 'Cuota agotada'),
    );
    final second = _FakeExtractor(
      model: 'glm-5.3-flash',
      error: _fail(JobImportErrorKind.quota, 'Cuota agotada'),
    );

    await expectLater(
      _extractor([first, second]).extract('texto'),
      throwsA(
        isA<JobImportException>()
            .having(
              (e) => e.kind,
              'kind',
              JobImportErrorKind.quota,
            )
            .having(
              (e) => e.message,
              'message',
              contains('deepseek-v4.1-flash, glm-5.3-flash'),
            ),
      ),
    );

    expect(first.calls, equals(1));
    expect(second.calls, equals(1));
  });

  test('con un solo modelo se comporta como antes', () async {
    final only = _FakeExtractor(
      model: 'a',
      response: const AiJobData(empresa: 'Acme'),
    );

    final data = await _extractor([only]).extract('texto');

    expect(data.empresa, equals('Acme'));
    expect(only.calls, equals(1));
  });

  test('sin modelos lanza un error de configuración', () async {
    await expectLater(
      _extractor(const []).extract('texto'),
      throwsA(
        isA<JobImportException>().having(
          (e) => e.kind,
          'kind',
          JobImportErrorKind.unauthorized,
        ),
      ),
    );
  });

  test('fromConfig crea un extractor por modelo y los prueba en orden', () async {
    final requested = <String>[];
    final client = MockClient((request) async {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      requested.add(body['model'] as String);
      return http.Response('{"error":"rate limit"}', 429);
    });

    const config = AiConfig(
      baseUrl: 'https://api.example.com/v1',
      apiKey: 'key',
      models: ['modelo-a', 'modelo-b'],
    );

    await expectLater(
      FallbackExtractor.fromConfig(
        config,
        client: client,
      ).extract('texto'),
      throwsA(isA<JobImportException>()),
    );

    expect(requested, equals(['modelo-a', 'modelo-b']));
  });
}

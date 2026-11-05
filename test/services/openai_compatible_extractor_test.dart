import 'dart:convert';

import 'package:devjobs/models/job_import.dart';
import 'package:devjobs/services/openai_compatible_extractor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _ok(String content) {
  return http.Response(
    jsonEncode({
      'choices': [
        {
          'message': {'content': content},
          'finish_reason': 'stop',
        },
      ],
    }),
    200,
  );
}

String? _header(http.BaseRequest request, String name) {
  for (final entry in request.headers.entries) {
    if (entry.key.toLowerCase() == name.toLowerCase()) return entry.value;
  }
  return null;
}

OpenAiCompatibleExtractor _extractor(
  http.Client client, {
  String baseUrl = 'https://opencode.ai/inference/go/openai/v1',
  String model = 'deepseek-v4.1-flash',
}) {
  return OpenAiCompatibleExtractor(
    baseUrl: baseUrl,
    apiKey: 'key',
    model: model,
    client: client,
    sessionId: 'ses_test',
  );
}

void main() {
  test('envía el request correcto y parsea el JSON', () async {
    late http.Request captured;
    final client = MockClient((request) async {
      captured = request;
      return _ok(
        jsonEncode({
          'empresa': 'Acme',
          'vacante': 'Dev',
          'resumen': 'Rol backend para Acme.',
          'responsabilidades': ['Diseñar APIs.'],
          'requisitos': ['Experiencia: 3 años.'],
          'beneficios': ['Horario flexible.'],
          'observaciones': ['Viaje ocasional.'],
          'datosClave': {
            'ingles': 'B2',
            'beneficios': ['Horario flexible'],
          },
        }),
      );
    });

    final data = await _extractor(client).extract('texto de la vacante');

    expect(
      captured.url.toString(),
      equals('https://opencode.ai/inference/go/openai/v1/chat/completions'),
    );
    expect(_header(captured, 'authorization'), equals('Bearer key'));
    expect(_header(captured, 'x-opencode-session'), equals('ses_test'));

    final body = jsonDecode(captured.body) as Map<String, dynamic>;
    expect(body['model'], equals('deepseek-v4.1-flash'));
    expect(body['reasoning_effort'], equals('none'));
    expect(body['response_format'], equals({'type': 'json_object'}));
    expect(body['messages'], isA<List>());

    expect(data.empresa, equals('Acme'));
    expect(data.vacante, equals('Dev'));
    expect(data.resumen, equals('Rol backend para Acme.'));
    expect(data.responsabilidades, equals(['Diseñar APIs.']));
    expect(data.requisitos, equals(['Experiencia: 3 años.']));
    expect(data.beneficios, equals(['Horario flexible.']));
    expect(data.observaciones, equals(['Viaje ocasional.']));
    expect(data.datosClave, containsAll(['B2', 'Horario flexible']));
  });

  test('limpia vallas de markdown', () async {
    final client = MockClient(
      (_) async => _ok('```json\n{"empresa":"Acme"}\n```'),
    );

    final data = await _extractor(client).extract('texto');

    expect(data.empresa, equals('Acme'));
  });

  test('usa reasoning_content si content viene vacío', () async {
    final client = MockClient(
      (_) async => http.Response(
        jsonEncode({
          'choices': [
            {
              'message': {
                'content': '',
                'reasoning_content': '{"empresa":"Acme"}',
              },
              'finish_reason': 'stop',
            },
          ],
        }),
        200,
      ),
    );

    final data = await _extractor(client).extract('texto');

    expect(data.empresa, equals('Acme'));
  });

  test('reintenta sin response_format si el proveedor lo rechaza', () async {
    var calls = 0;
    final client = MockClient((request) async {
      calls++;
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      if (calls == 1) {
        expect(body.containsKey('response_format'), isTrue);
        return http.Response('response_format is not supported', 400);
      }
      expect(body.containsKey('response_format'), isFalse);
      return _ok('{"empresa":"Acme"}');
    });

    final data = await _extractor(client).extract('texto');

    expect(calls, equals(2));
    expect(data.empresa, equals('Acme'));
  });

  test('traduce 401 a unauthorized', () async {
    final client = MockClient(
      (_) async => http.Response('{"error":"unauthorized"}', 401),
    );

    await expectLater(
      _extractor(client).extract('texto'),
      throwsA(
        isA<JobImportException>().having(
          (error) => error.kind,
          'kind',
          JobImportErrorKind.unauthorized,
        ),
      ),
    );
  });

  test('traduce 429 a quota', () async {
    final client = MockClient(
      (_) async => http.Response('{"error":"rate limit"}', 429),
    );

    await expectLater(
      _extractor(client).extract('texto'),
      throwsA(
        isA<JobImportException>().having(
          (error) => error.kind,
          'kind',
          JobImportErrorKind.quota,
        ),
      ),
    );
  });

  test('no envía session ni reasoning fuera de OpenCode/DeepSeek', () async {
    final client = MockClient((request) async {
      expect(_header(request, 'x-opencode-session'), isNull);
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body.containsKey('reasoning_effort'), isFalse);
      return _ok('{"empresa":"Acme"}');
    });

    final data = await _extractor(
      client,
      baseUrl: 'https://api.example.com/v1',
      model: 'gpt-6-luna',
    ).extract('texto');

    expect(data.empresa, equals('Acme'));
  });

  test('JSON inválido se reporta como invalidResponse', () async {
    final client = MockClient((_) async => _ok('esto no es json'));

    await expectLater(
      _extractor(client).extract('texto'),
      throwsA(
        isA<JobImportException>().having(
          (error) => error.kind,
          'kind',
          JobImportErrorKind.invalidResponse,
        ),
      ),
    );
  });
}

import 'dart:convert';

import 'package:devjobs/models/company_insight.dart';
import 'package:devjobs/services/sheets_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('CreateResult.fromJson', () {
    test('parsea rowIndex y shifted=false', () {
      final result = CreateResult.fromJson(<String, dynamic>{
        'rowIndex': 13,
        'shifted': false,
      });

      expect(result.rowIndex, 13);
      expect(result.shifted, isFalse);
    });

    test('parsea shifted=true', () {
      final result = CreateResult.fromJson(<String, dynamic>{
        'rowIndex': 2,
        'shifted': true,
      });

      expect(result.rowIndex, 2);
      expect(result.shifted, isTrue);
    });

    test('sin shifted asume true para scripts viejos', () {
      final result = CreateResult.fromJson(<String, dynamic>{'rowIndex': 14});

      expect(result.shifted, isTrue);
    });

    test('acepta shifted como string', () {
      final result = CreateResult.fromJson(<String, dynamic>{
        'rowIndex': 13,
        'shifted': 'false',
      });

      expect(result.shifted, isFalse);
    });

    test('lanza FormatException si falta rowIndex', () {
      expect(
        () => CreateResult.fromJson(<String, dynamic>{'shifted': false}),
        throwsA(isA<FormatException>()),
      );
    });
  });

  group('fetchCompanyInsights', () {
    test('parsea las filas de la pestaña EmpresaAnalisis', () async {
      final client = MockClient((request) async {
        expect(request.url.queryParameters['action'], 'companyInsights');
        return http.Response(
          jsonEncode([
            {
              'empresa': 'Acme',
              'fechaAnalisis': '19/11/2026',
              'datosAl': '10/11/2026',
              'totalPostulaciones': '3',
              'etiquetas': 'No responde',
              'recomendacion': 'Baja prioridad',
              'resumen': 'No responde.',
            },
          ]),
          200,
        );
      });
      final service = SheetsApiService(
        baseUrl: 'http://test',
        client: client,
      );

      final insights = await service.fetchCompanyInsights();

      expect(insights, hasLength(1));
      expect(insights.first.empresa, 'Acme');
      expect(insights.first.etiquetas, ['no-respuesta']);
    });

    test('descarta filas sin forma de análisis (script viejo)', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {
              '_rowIndex': 2,
              'empresa': 'Acme',
              'fechaPostulacion': '01/01/2026',
            },
          ]),
          200,
        );
      });
      final service = SheetsApiService(
        baseUrl: 'http://test',
        client: client,
      );

      expect(await service.fetchCompanyInsights(), isEmpty);
    });

    test('lanza Exception con HTTP distinto de 200', () async {
      final client = MockClient((request) async => http.Response('', 500));
      final service = SheetsApiService(
        baseUrl: 'http://test',
        client: client,
      );

      expect(
        service.fetchCompanyInsights(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('upsertCompanyInsight', () {
    test('envía la acción con los datos del análisis', () async {
      late http.Request captured;
      final client = MockClient((request) async {
        captured = request;
        return http.Response(jsonEncode({'_ok': true, 'rowIndex': 2}), 200);
      });
      final service = SheetsApiService(
        baseUrl: 'http://test',
        client: client,
      );

      const insight = CompanyInsight(
        empresa: 'Acme',
        totalPostulaciones: 3,
        resumen: 'No responde.',
      );
      await service.upsertCompanyInsight(insight);

      final body = jsonDecode(captured.body) as Map<String, dynamic>;
      expect(body['action'], 'upsertCompanyInsight');
      expect(body['data'], isA<Map>());
      expect((body['data'] as Map)['empresa'], 'Acme');
    });

    test('propaga el _error del script', () async {
      final client = MockClient((request) async {
        return http.Response(jsonEncode({'_error': 'sin permisos'}), 200);
      });
      final service = SheetsApiService(
        baseUrl: 'http://test',
        client: client,
      );

      expect(
        service.upsertCompanyInsight(const CompanyInsight(empresa: 'Acme')),
        throwsA(isA<Exception>()),
      );
    });
  });
}

import 'dart:async';

import 'package:devjobs/models/ai_config.dart';
import 'package:devjobs/models/company_insight.dart';
import 'package:devjobs/models/job_application.dart';
import 'package:devjobs/providers/app_state.dart';
import 'package:devjobs/screens/empresas_screen.dart';
import 'package:devjobs/services/company_analyzer_service.dart';
import 'package:devjobs/services/sheets_api_service.dart';
import 'package:devjobs/theme.dart';
import 'package:devjobs/widgets/company_card.dart';
import 'package:devjobs/widgets/filter_pill.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

class _FakeApi extends SheetsApiService {
  final List<JobApplication> data;
  final List<CompanyInsight> insights;
  int updateCalls = 0;
  final List<Map<String, String>> updates = [];

  _FakeApi(this.data, {this.insights = const []}) : super(baseUrl: 'http://test');

  @override
  Future<List<JobApplication>> fetchAll() async => data;

  @override
  Future<List<CompanyInsight>> fetchCompanyInsights() async => insights;

  @override
  Future<void> upsertCompanyInsight(CompanyInsight insight) async {}

  @override
  Future<void> updateRow(int rowIndex, Map<String, String> updates) async {
    updateCalls++;
    this.updates.add({'_row': '$rowIndex', ...updates});
  }
}

void main() {
  setUpAll(() async {
    // El prompt de análisis de empresa formatea fechas en español.
    await initializeDateFormatting('es');
  });

  String daysAgo(int days) {
    final date = DateTime.now().subtract(Duration(days: days));
    return '${date.day}/${date.month}/${date.year}';
  }

  final apps = [
    // Acme: 4 total, 2 activas, 3 con respuesta, 1 entrevista.
    JobApplication(
      rowIndex: 1,
      empresa: 'Acme',
      estado: 'Entrevista realizada',
      entrevistaRealizada: true,
      fechaPostulacion: daysAgo(1),
    ),
    JobApplication(
      rowIndex: 2,
      empresa: 'Acme',
      estado: 'En revisión',
      fechaPostulacion: daysAgo(2),
    ),
    JobApplication(
      rowIndex: 3,
      empresa: 'Acme',
      estado: 'Rechazada',
      fechaPostulacion: daysAgo(3),
    ),
    JobApplication(
      rowIndex: 4,
      empresa: 'Acme',
      estado: 'Retirada',
      fechaPostulacion: daysAgo(4),
    ),
    // Beta: 2 total, 2 activas, 2 con respuesta, 2 entrevistas.
    JobApplication(
      rowIndex: 5,
      empresa: 'Beta',
      estado: 'Entrevista realizada',
      entrevistaRealizada: true,
      fechaPostulacion: daysAgo(5),
    ),
    JobApplication(
      rowIndex: 6,
      empresa: 'Beta',
      estado: 'Entrevista agendada',
      entrevistaRealizada: true,
      fechaPostulacion: daysAgo(6),
    ),
    // Gamma: 3 total, 3 activas, 3 con respuesta, 0 entrevistas.
    for (var i = 0; i < 3; i++)
      JobApplication(
        rowIndex: 7 + i,
        empresa: 'Gamma',
        estado: 'En revisión',
        fechaPostulacion: daysAgo(10 + i),
      ),
  ];

  Future<_FakeApi> pumpScreen(
    WidgetTester tester, {
    List<CompanyInsight> insights = const [],
    CompanyAnalyzerService Function(AiConfig config)? analyzerBuilder,
  }) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _FakeApi(apps, insights: insights);
    final state = AppState(apiService: api, analyzerBuilder: analyzerBuilder);
    await state.fetchApplications(forceRefresh: true);
    await state.updateAiConfig(const AiConfig(
      baseUrl: 'https://ejemplo.test/v1',
      apiKey: 'key',
      models: ['m1'],
    ));

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: EmpresasScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return api;
  }

  List<String> order(WidgetTester tester) {
    return tester
        .widgetList<CompanyCard>(find.byType(CompanyCard))
        .map((card) => card.company.nombre)
        .toList();
  }

  testWidgets('ordena por los criterios elegidos', (tester) async {
    await pumpScreen(tester);

    expect(order(tester), equals(['Acme', 'Gamma', 'Beta']));

    await tester.tap(find.text('Más entrevistas'));
    await tester.pump();
    expect(order(tester), equals(['Beta', 'Acme', 'Gamma']));

    await tester.ensureVisible(find.text('Recientes'));
    await tester.pump();
    await tester.tap(find.text('Recientes'));
    await tester.pump();
    expect(order(tester), equals(['Acme', 'Beta', 'Gamma']));

    await tester.ensureVisible(find.text('Mejor respuesta'));
    await tester.pump();
    await tester.tap(find.text('Mejor respuesta'));
    await tester.pump();
    expect(order(tester), equals(['Gamma', 'Beta', 'Acme']));
    expect(tester.takeException(), isNull);
  });

  group('filtro por comportamiento', () {
    // Las etiquetas/recomendación también se pintan en las cards: los taps
    // se acotan a los FilterPill de la barra de filtros.
    Finder pill(String label) => find.ancestor(
          of: find.text(label),
          matching: find.byType(FilterPill),
        );

    final insights = [
      const CompanyInsight(
        empresa: 'Acme',
        recomendacion: CompanyRecommendation.priorizar,
        etiquetas: ['no-respuesta'],
      ),
      const CompanyInsight(
        empresa: 'Beta',
        recomendacion: CompanyRecommendation.seguimientoNormal,
        etiquetas: ['con-feedback'],
      ),
    ];

    testWidgets('Con análisis muestra solo las empresas con análisis',
        (tester) async {
      await pumpScreen(tester, insights: insights);

      expect(order(tester), hasLength(3));

      await tester.ensureVisible(pill('Con análisis'));
      await tester.tap(pill('Con análisis'));
      await tester.pump();

      expect(order(tester), equals(['Acme', 'Beta']));
      expect(find.text('2 de 3 empresas'), findsOneWidget);
    });

    testWidgets('filtra por recomendación y por etiqueta', (tester) async {
      await pumpScreen(tester, insights: insights);

      await tester.ensureVisible(pill('Priorizar'));
      await tester.tap(pill('Priorizar'));
      await tester.pump();
      expect(order(tester), equals(['Acme']));
      expect(find.text('1 de 3 empresas'), findsOneWidget);

      await tester.ensureVisible(pill('No responde'));
      await tester.tap(pill('No responde'));
      await tester.pump();
      expect(order(tester), equals(['Acme']));

      await tester.ensureVisible(pill('Da feedback'));
      await tester.tap(pill('Da feedback'));
      await tester.pump();
      expect(order(tester), equals(['Beta']));
    });

    testWidgets('sin resultados ofrece limpiar filtros', (tester) async {
      await pumpScreen(tester, insights: insights);

      await tester.ensureVisible(pill('Sin feedback'));
      await tester.tap(pill('Sin feedback'));
      await tester.pump();

      expect(
        find.text('Sin empresas con este comportamiento'),
        findsOneWidget,
      );

      await tester.tap(find.text('Limpiar filtros'));
      await tester.pump();
      expect(order(tester), hasLength(3));
    });
  });

  group('Analizar pendientes', () {
    Map<String, dynamic> okJson() => {
          'etiquetas': ['no-respuesta'],
          'recomendacion': 'Baja prioridad',
          'resumen': 'Ok.',
        };

    CompanyAnalyzerService Function(AiConfig) countingAnalyzer(
      void Function() onCall,
    ) {
      return (config) => CompanyAnalyzerService(
            config: config,
            completeForModel: (m, s, u) async {
              onCall();
              return okJson();
            },
          );
    }

    testWidgets('pide confirmación y Cancelar no dispara nada', (tester) async {
      var calls = 0;
      await pumpScreen(
        tester,
        analyzerBuilder: countingAnalyzer(() => calls++),
      );

      expect(find.text('Analizar (3)'), findsOneWidget);
      await tester.tap(find.byKey(const Key('analyze-pending')));
      await tester.pumpAndSettle();

      expect(find.text('¿Analizar 3 empresas con IA?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(calls, 0);
      expect(find.text('Analizar (3)'), findsOneWidget);
    });

    testWidgets('confirmado ejecuta el lote completo y el botón desaparece',
        (tester) async {
      var calls = 0;
      await pumpScreen(
        tester,
        analyzerBuilder: countingAnalyzer(() => calls++),
      );

      await tester.tap(find.byKey(const Key('analyze-pending')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Analizar'));
      await tester.pumpAndSettle();

      expect(calls, 3);
      expect(find.text('Analizar (3)'), findsNothing);
      expect(find.text('Análisis completados: 3 de 3'), findsOneWidget);
    });

    testWidgets('muestra el progreso con Detener mientras corre', (tester) async {
      final completer = Completer<Map<String, dynamic>>();
      var calls = 0;
      await pumpScreen(
        tester,
        analyzerBuilder: (config) => CompanyAnalyzerService(
          config: config,
          completeForModel: (m, s, u) {
            calls++;
            return calls == 1 ? completer.future : Future.value(okJson());
          },
        ),
      );

      await tester.tap(find.byKey(const Key('analyze-pending')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Analizar'));
      await tester.pump();

      expect(find.textContaining('Analizando'), findsOneWidget);
      expect(find.text('Detener'), findsOneWidget);

      completer.complete(okJson());
      await tester.pumpAndSettle();
      expect(find.text('Detener'), findsNothing);
      expect(find.text('Análisis completados: 3 de 3'), findsOneWidget);
    });

    testWidgets('se oculta cuando no quedan empresas por analizar',
        (tester) async {
      await pumpScreen(
        tester,
        insights: const [
          CompanyInsight(empresa: 'Acme', resumen: 'x'),
          CompanyInsight(empresa: 'Beta', resumen: 'x'),
          CompanyInsight(empresa: 'Gamma', resumen: 'x'),
        ],
      );

      expect(find.byKey(const Key('analyze-pending')), findsNothing);
    });
  });

  group('Combinar empresas', () {
    Finder tile(String name) => find.descendant(
          of: find.byType(CheckboxListTile),
          matching: find.text(name),
        );

    testWidgets('el botón abre la hoja y el merge renombra las filas absorbidas',
        (tester) async {
      final api = await pumpScreen(tester);

      await tester.tap(find.byKey(const Key('merge-companies')));
      await tester.pumpAndSettle();
      expect(find.text('Combinar empresas'), findsOneWidget);

      await tester.tap(tile('Acme'));
      await tester.pump();
      await tester.tap(tile('Beta'));
      await tester.pump();
      // Vista previa: Beta (2 filas) pasa a llamarse Acme.
      expect(find.text('· "Beta" (2 filas) → "Acme"'), findsOneWidget);

      await tester.tap(find.byKey(const Key('merge-confirm')));
      await tester.pumpAndSettle();

      // Solo se renombran las 2 filas de Beta.
      expect(api.updateCalls, 2);
      expect(
        api.updates.map((u) => u['_row']).toSet(),
        {'5', '6'},
      );
      expect(api.updates.every((u) => u['empresa'] == 'Acme'), isTrue);
      expect(
        find.text('Postulaciones combinadas en "Acme"'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('el botón no aparece con una sola empresa', (tester) async {
      tester.view.physicalSize = const Size(600, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final state = AppState(
        apiService: _FakeApi([apps.first]),
      );
      await state.fetchApplications(forceRefresh: true);
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: MaterialApp(
            theme: AppTheme.light,
            home: const Scaffold(body: EmpresasScreen()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('merge-companies')), findsNothing);
    });
  });
}

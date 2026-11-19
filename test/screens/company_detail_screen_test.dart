import 'package:devjobs/models/ai_config.dart';
import 'package:devjobs/models/company_insight.dart';
import 'package:devjobs/models/job_application.dart';
import 'package:devjobs/providers/app_state.dart';
import 'package:devjobs/screens/company_detail_screen.dart';
import 'package:devjobs/services/sheets_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

class _FakeApi extends SheetsApiService {
  final List<JobApplication> data;
  final List<CompanyInsight> insights;

  _FakeApi(this.data, {this.insights = const []}) : super(baseUrl: 'http://test');

  @override
  Future<List<JobApplication>> fetchAll() async => data;

  @override
  Future<List<CompanyInsight>> fetchCompanyInsights() async => insights;

  @override
  Future<void> upsertCompanyInsight(CompanyInsight insight) async {}
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  final apps = [
    JobApplication(
      rowIndex: 1,
      empresa: 'Acme',
      vacante: 'Dev',
      estado: 'Entrevista realizada',
      entrevistaRealizada: true,
      porGestionar: true,
      fechaPostulacion: '01/01/2026',
      fechaSeguimiento: '05/01/2026',
      ciudad: 'Bogotá',
      modalidad: 'Remoto',
      link: 'https://www.linkedin.com/jobs/1',
    ),
    JobApplication(
      rowIndex: 2,
      empresa: 'Acme',
      estado: 'En revisión',
      fechaPostulacion: '02/01/2026',
    ),
    JobApplication(
      rowIndex: 3,
      empresa: 'Acme',
      estado: 'Rechazada',
      fechaPostulacion: '03/01/2026',
      fechaSeguimiento: '10/01/2026',
    ),
  ];

  testWidgets('a 360 px las métricas muestran sus etiquetas sin desbordar',
      (tester) async {
    // Altura suficiente para el header + métricas, sin llegar a las cards de
    // vacantes (el font Ahem de los tests es más ancho que el real y provoca
    // falsos overflows en ApplicationCard).
    tester.view.physicalSize = const Size(360, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState(apiService: _FakeApi(apps));
    await state.fetchApplications(forceRefresh: true);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const MaterialApp(home: CompanyDetailScreen(nombre: 'Acme')),
      ),
    );
    await tester.pump();

    expect(find.text('Activas'), findsOneWidget);
    expect(find.text('Respondieron'), findsOneWidget);
    expect(find.text('Finalizadas'), findsOneWidget);
    expect(find.text('Entrevistas'), findsOneWidget);
    expect(find.text('Por gestionar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('con IA configurada ofrece el análisis aunque no exista aún',
      (tester) async {
    final state = AppState(apiService: _FakeApi(apps));
    await state.fetchApplications(forceRefresh: true);
    await state.updateAiConfig(const AiConfig(
      baseUrl: 'https://ejemplo.test/v1',
      apiKey: 'key',
      models: ['m1'],
    ));

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const MaterialApp(home: CompanyDetailScreen(nombre: 'Acme')),
      ),
    );
    await tester.pump();

    // El ListView construye bajo demanda: hay que acercarse a la tarjeta.
    await tester.scrollUntilVisible(
      find.text('Análisis IA'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.text('Análisis IA'), findsOneWidget);
    expect(find.text('Analizar con IA'), findsOneWidget);
    // Acme tiene 3 postulaciones (>= 2): sin advertencia de pocos datos.
    expect(find.textContaining('puede ser limitado'), findsNothing);
  });

  testWidgets('con menos de 2 postulaciones avisa pero permite analizar',
      (tester) async {
    final una = [
      JobApplication(
        rowIndex: 1,
        empresa: 'SoloUna',
        estado: 'Enviada',
        fechaPostulacion: '01/01/2026',
      ),
    ];
    final state = AppState(apiService: _FakeApi(una));
    await state.fetchApplications(forceRefresh: true);
    await state.updateAiConfig(const AiConfig(
      baseUrl: 'https://ejemplo.test/v1',
      apiKey: 'key',
      models: ['m1'],
    ));

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const MaterialApp(home: CompanyDetailScreen(nombre: 'SoloUna')),
      ),
    );
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Análisis IA'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.textContaining('el análisis puede ser limitado'), findsOneWidget);
    // La advertencia no bloquea: el botón sigue disponible.
    expect(find.text('Analizar con IA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('muestra el análisis guardado con sus etiquetas', (tester) async {
    final state = AppState(
      apiService: _FakeApi(
        apps,
        insights: [
          CompanyInsight(
            empresa: 'Acme',
            totalPostulaciones: 3,
            datosAl: DateTime(2026, 1, 10),
            etiquetas: const ['no-respuesta'],
            recomendacion: CompanyRecommendation.bajaPrioridad,
            resumen: 'No responde.',
          ),
        ],
      ),
    );
    await state.fetchApplications(forceRefresh: true);
    await state.loadCompanyInsights();

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const MaterialApp(home: CompanyDetailScreen(nombre: 'Acme')),
      ),
    );
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('Análisis IA'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();

    expect(find.text('No responde'), findsOneWidget);
    expect(find.text('No responde.'), findsOneWidget);
    expect(find.text('Baja prioridad'), findsOneWidget);
    expect(find.text('Analizar con IA'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin IA y sin análisis no se muestra la tarjeta', (tester) async {
    final state = AppState(apiService: _FakeApi(apps));
    await state.fetchApplications(forceRefresh: true);
    expect(state.aiEnabled, isFalse);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const MaterialApp(home: CompanyDetailScreen(nombre: 'Acme')),
      ),
    );
    await tester.pump();

    expect(find.text('Análisis IA'), findsNothing);
  });

  testWidgets('la empresa confidencial no ofrece el análisis IA',
      (tester) async {
    final confidencial = [
      JobApplication(
        rowIndex: 1,
        empresa: 'Empresa confidencial',
        estado: 'Enviada',
        fechaPostulacion: '01/01/2026',
      ),
    ];
    final state = AppState(apiService: _FakeApi(confidencial));
    await state.fetchApplications(forceRefresh: true);
    await state.updateAiConfig(const AiConfig(
      baseUrl: 'https://ejemplo.test/v1',
      apiKey: 'key',
      models: ['m1'],
    ));

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: const MaterialApp(
          home: CompanyDetailScreen(nombre: 'Empresa confidencial'),
        ),
      ),
    );
    await tester.pump();

    // Aunque la IA esté configurada, la tarjeta no se ofrece.
    await tester.scrollUntilVisible(
      find.textContaining('Vacantes'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    expect(find.text('Análisis IA'), findsNothing);
    expect(find.text('Analizar con IA'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

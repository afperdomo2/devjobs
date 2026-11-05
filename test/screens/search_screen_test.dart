import 'package:devjobs/models/job_application.dart';
import 'package:devjobs/providers/app_state.dart';
import 'package:devjobs/screens/search_screen.dart';
import 'package:devjobs/services/sheets_api_service.dart';
import 'package:devjobs/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

class _FakeApi extends SheetsApiService {
  final List<JobApplication> data;

  _FakeApi(this.data) : super(baseUrl: 'http://test');

  @override
  Future<List<JobApplication>> fetchAll() async => data;
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  final apps = [
    const JobApplication(
      rowIndex: 1,
      empresa: 'Acme',
      vacante: 'Flutter Developer',
      ciudad: 'Bogotá',
      modalidad: 'Remoto',
      estado: 'Entrevista agendada',
      link: 'https://www.linkedin.com/jobs/1',
      comentarios: '- 5/11/2026: Envié hoja de vida',
      fechaPostulacion: '01/11/2026',
    ),
    const JobApplication(
      rowIndex: 2,
      empresa: 'Globant',
      vacante: 'Backend Engineer',
      ciudad: 'Medellín',
      modalidad: 'Presencial',
      estado: 'Rechazada',
      comentarios: '- Sin respuesta',
      fechaPostulacion: '02/11/2026',
    ),
    const JobApplication(
      rowIndex: 3,
      empresa: 'Acme',
      vacante: 'Diseñador',
      ciudad: 'Bogotá',
      modalidad: 'Híbrido',
      estado: 'Enviada',
      comentarios: '- Puse salario',
      fechaPostulacion: '03/11/2026',
    ),
  ];

  Future<void> pumpSearch(WidgetTester tester) async {
    tester.view.physicalSize = const Size(480, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState(apiService: _FakeApi(apps));
    await state.fetchApplications(forceRefresh: true);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const SearchScreen(),
        ),
      ),
    );
    // Sin pumpAndSettle: el cursor del TextField autofocus nunca se detiene.
    await tester.pump();
  }

  Future<void> type(WidgetTester tester, String query) async {
    await tester.enterText(find.byType(TextField), query);
    await tester.pump();
  }

  testWidgets('empieza con la ayuda inicial y sin contador', (tester) async {
    await pumpSearch(tester);

    expect(find.text('Escribe para buscar'), findsOneWidget);
    expect(find.textContaining('resultados'), findsNothing);
    expect(find.text('Flutter Developer'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cuenta resultados y encuentra sin tildes', (tester) async {
    await pumpSearch(tester);

    await type(tester, 'Bogota');

    expect(find.text('2 resultados'), findsOneWidget);
    expect(find.text('Flutter Developer'), findsOneWidget);
    expect(find.text('Diseñador'), findsOneWidget);
    expect(find.text('Backend Engineer'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('varias palabras se combinan entre campos', (tester) async {
    await pumpSearch(tester);

    await type(tester, 'acme remoto');

    expect(find.text('1 resultado'), findsOneWidget);
    expect(find.text('Flutter Developer'), findsOneWidget);
    expect(find.text('Diseñador'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('encuentra por estado, comentarios y plataforma', (
    tester,
  ) async {
    await pumpSearch(tester);

    await type(tester, 'rechazada');
    expect(find.text('1 resultado'), findsOneWidget);
    expect(find.text('Backend Engineer'), findsOneWidget);

    await type(tester, 'hoja de vida');
    expect(find.text('1 resultado'), findsOneWidget);
    expect(find.text('Flutter Developer'), findsOneWidget);

    await type(tester, 'linkedin');
    expect(find.text('1 resultado'), findsOneWidget);
    expect(find.text('Flutter Developer'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin coincidencias muestra 0 resultados y permite limpiar', (
    tester,
  ) async {
    await pumpSearch(tester);

    await type(tester, 'zzz');

    expect(find.text('0 resultados'), findsOneWidget);
    expect(find.text('Sin resultados para "zzz"'), findsOneWidget);
    expect(find.text('Limpiar búsqueda'), findsOneWidget);

    await tester.tap(find.text('Limpiar búsqueda'));
    await tester.pump();

    expect(find.text('Escribe para buscar'), findsOneWidget);
    expect(find.text('0 resultados'), findsNothing);
    expect(tester.widget<TextField>(find.byType(TextField)).controller?.text, '');
    expect(tester.takeException(), isNull);
  });
}

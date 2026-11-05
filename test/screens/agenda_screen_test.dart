import 'package:devjobs/models/job_application.dart';
import 'package:devjobs/providers/app_state.dart';
import 'package:devjobs/screens/agenda_screen.dart';
import 'package:devjobs/services/sheets_api_service.dart';
import 'package:devjobs/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeApi extends SheetsApiService {
  List<JobApplication> data;

  _FakeApi(this.data) : super(baseUrl: 'http://test');

  @override
  Future<List<JobApplication>> fetchAll() async => data;
}

void main() {
  Future<AppState> pumpAgenda(
    WidgetTester tester,
    List<JobApplication> apps,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
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
          home: const Scaffold(body: AgendaScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return state;
  }

  testWidgets('muestra las secciones accionables y su conteo', (tester) async {
    await pumpAgenda(tester, [
      const JobApplication(
        rowIndex: 1,
        empresa: 'Pendiente',
        vacante: 'Backend',
        estado: 'En revisión',
        porGestionar: true,
      ),
      const JobApplication(
        rowIndex: 2,
        empresa: 'Entrevista',
        vacante: 'Mobile',
        estado: 'Entrevista agendada',
      ),
      const JobApplication(
        rowIndex: 3,
        empresa: 'Oferta',
        vacante: 'QA',
        estado: 'Oferta recibida',
      ),
      const JobApplication(
        rowIndex: 4,
        empresa: 'Normal',
        vacante: 'Data',
        estado: 'En revisión',
      ),
    ]);

    expect(find.text('3 pendientes'), findsOneWidget);
    expect(find.text('Por gestionar'), findsOneWidget);
    expect(find.text('Entrevistas agendadas'), findsOneWidget);
    expect(find.text('Ofertas recibidas'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.text('Entrevista'), findsOneWidget);
    expect(find.text('Oferta'), findsOneWidget);
    expect(find.text('Normal'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('pasa de vacío a datos sin adjuntar dos scroll views', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _FakeApi([]);
    final state = AppState(apiService: api);
    await state.fetchApplications(forceRefresh: true);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: AgendaScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Todo al día'), findsOneWidget);

    api.data = [
      const JobApplication(
        rowIndex: 1,
        empresa: 'Pendiente',
        estado: 'En revisión',
        porGestionar: true,
      ),
    ];
    await state.fetchApplications(forceRefresh: true);
    await tester.pumpAndSettle();

    expect(find.text('Por gestionar'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin pendientes muestra Todo al día', (tester) async {
    await pumpAgenda(tester, [
      const JobApplication(
        rowIndex: 1,
        empresa: 'Normal',
        vacante: 'Data',
        estado: 'En revisión',
      ),
    ]);

    expect(find.text('Todo al día'), findsOneWidget);
    expect(find.text('No hay pendientes por atender'), findsOneWidget);
    expect(find.text('Por gestionar'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

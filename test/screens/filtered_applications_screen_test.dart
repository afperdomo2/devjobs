import 'package:devjobs/models/job_application.dart';
import 'package:devjobs/providers/app_state.dart';
import 'package:devjobs/screens/filtered_applications_screen.dart';
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

  String daysAgo(int days) {
    final date = DateTime.now().subtract(Duration(days: days));
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<AppState> buildState(List<JobApplication> apps) async {
    final state = AppState(apiService: _FakeApi(apps));
    await state.fetchApplications(forceRefresh: true);
    return state;
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    AppState state, {
    required List<JobApplication> Function(List<JobApplication>) selector,
    String emptyMessage = 'Sin resultados',
  }) async {
    // 480 para evitar el falso overflow del font Ahem de los tests; el
    // layout real se valida en los tests de las cards.
    tester.view.physicalSize = const Size(480, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          theme: AppTheme.light,
          home: FilteredApplicationsScreen(
            title: 'Resultados',
            selector: selector,
            emptyMessage: emptyMessage,
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('un selector muestra solo las postulaciones incluidas', (
    tester,
  ) async {
    final apps = [
      JobApplication(
        rowIndex: 1,
        empresa: 'Antigua',
        vacante: 'Backend',
        estado: 'En revisión',
        fechaPostulacion: daysAgo(20),
      ),
      JobApplication(
        rowIndex: 2,
        empresa: 'Reciente',
        vacante: 'Mobile',
        estado: 'En revisión',
        fechaPostulacion: daysAgo(2),
      ),
      JobApplication(
        rowIndex: 3,
        empresa: 'Cerrada',
        vacante: 'QA',
        estado: 'Rechazada',
        fechaPostulacion: daysAgo(20),
      ),
    ];
    final state = await buildState(apps);

    await pumpScreen(
      tester,
      state,
      selector: (apps) =>
          apps.where((app) => app.empresa == 'Antigua').toList(),
    );

    expect(find.text('Antigua'), findsOneWidget);
    expect(find.text('Reciente'), findsNothing);
    expect(find.text('Cerrada'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('si el selector no devuelve nada muestra el mensaje vacío', (
    tester,
  ) async {
    final state = await buildState([
      JobApplication(
        rowIndex: 1,
        empresa: 'Reciente',
        vacante: 'Mobile',
        estado: 'En revisión',
        fechaPostulacion: daysAgo(1),
      ),
    ]);

    await pumpScreen(
      tester,
      state,
      selector: (apps) => const <JobApplication>[],
      emptyMessage: 'Sin pendientes',
    );

    expect(find.text('Sin pendientes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

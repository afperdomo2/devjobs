import 'package:devjobs/models/job_application.dart';
import 'package:devjobs/providers/app_state.dart';
import 'package:devjobs/screens/main_screen.dart';
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
      estado: 'Entrevista agendada',
      ciudad: 'Bogotá',
      modalidad: 'Remoto',
      fechaPostulacion: '01/11/2026',
      porGestionar: true,
    ),
    const JobApplication(
      rowIndex: 2,
      empresa: 'Globant',
      vacante: 'Backend Engineer',
      estado: 'Rechazada',
      fechaPostulacion: '02/10/2026',
      fechaSeguimiento: '05/10/2026',
    ),
  ];

  Future<AppState> buildState() async {
    final state = AppState(apiService: _FakeApi(apps));
    await state.fetchApplications(forceRefresh: true);
    return state;
  }

  testWidgets('a 360 px no desborda en tema claro ni oscuro', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = await buildState();

    for (final theme in [AppTheme.light, AppTheme.dark]) {
      await tester.pumpWidget(
        ChangeNotifierProvider.value(
          value: state,
          child: MaterialApp(theme: theme, home: const MainScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Inicio'), findsOneWidget);
      expect(find.text('Postulaciones'), findsOneWidget);
      expect(find.text('Empresas'), findsOneWidget);
      expect(find.text('Agenda'), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}

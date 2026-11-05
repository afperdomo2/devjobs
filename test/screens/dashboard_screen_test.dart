import 'package:devjobs/models/job_application.dart';
import 'package:devjobs/providers/app_state.dart';
import 'package:devjobs/screens/dashboard_screen.dart';
import 'package:devjobs/services/sheets_api_service.dart';
import 'package:devjobs/theme.dart';
import 'package:devjobs/widgets/pending_applications_card.dart';
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

  Future<void> pumpDashboard(
    WidgetTester tester,
    List<JobApplication> apps,
  ) async {
    // Ancho amplio para evitar el falso overflow del font Ahem de los tests.
    tester.view.physicalSize = const Size(600, 2000);
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
          home: const Scaffold(body: DashboardScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('Inicio muestra Por gestionar y Con entrevista', (tester) async {
    await pumpDashboard(tester, [
      JobApplication(
        rowIndex: 1,
        empresa: 'Pendiente',
        vacante: 'Backend',
        estado: 'En revisión',
        fechaPostulacion: daysAgo(20),
        porGestionar: true,
        entrevistaRealizada: true,
      ),
      JobApplication(
        rowIndex: 2,
        empresa: 'Entrevistada',
        vacante: 'Mobile',
        estado: 'Entrevista realizada',
        fechaPostulacion: daysAgo(10),
        entrevistaRealizada: true,
      ),
      JobApplication(
        rowIndex: 3,
        empresa: 'Normal',
        vacante: 'QA',
        estado: 'En revisión',
        fechaPostulacion: daysAgo(2),
      ),
    ]);

    // La grilla ya no tiene "Por gestionar": ahora muestra "Con entrevista".
    expect(find.text('Con entrevista'), findsOneWidget);
    // La card de lista usa el switch O y aparece con su título.
    expect(find.text('Por gestionar'), findsOneWidget);
    expect(find.text('Pendientes de acción'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(PendingApplicationsCard),
        matching: find.text('Pendiente'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(PendingApplicationsCard),
        matching: find.text('Entrevistada'),
      ),
      findsNothing,
    );
    // Los tres estados de prueba implican respuesta: 100 %.
    expect(find.text('Con respuesta'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    // Actividad reciente muestra el movimiento más nuevo.
    expect(find.text('Actividad reciente'), findsOneWidget);
    expect(find.text('Normal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin pendientes no muestra la tarjeta Por gestionar', (
    tester,
  ) async {
    await pumpDashboard(tester, [
      JobApplication(
        rowIndex: 1,
        empresa: 'Entrevistada',
        vacante: 'Mobile',
        estado: 'Entrevista realizada',
        fechaPostulacion: daysAgo(10),
        entrevistaRealizada: true,
      ),
    ]);

    expect(find.text('Con entrevista'), findsOneWidget);
    expect(find.text('Por gestionar'), findsNothing);
    expect(find.text('Pendientes de acción'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

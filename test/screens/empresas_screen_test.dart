import 'package:devjobs/models/job_application.dart';
import 'package:devjobs/providers/app_state.dart';
import 'package:devjobs/screens/empresas_screen.dart';
import 'package:devjobs/services/sheets_api_service.dart';
import 'package:devjobs/theme.dart';
import 'package:devjobs/widgets/company_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeApi extends SheetsApiService {
  final List<JobApplication> data;

  _FakeApi(this.data) : super(baseUrl: 'http://test');

  @override
  Future<List<JobApplication>> fetchAll() async => data;
}

void main() {
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

  Future<void> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(600, 900);
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
          home: const Scaffold(body: EmpresasScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();
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
}

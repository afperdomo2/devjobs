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
  int updateCalls = 0;
  final List<Map<String, String>> updates = [];

  _FakeApi(this.data) : super(baseUrl: 'http://test');

  @override
  Future<List<JobApplication>> fetchAll() async => data;

  @override
  Future<void> updateRow(int rowIndex, Map<String, String> updates) async {
    updateCalls++;
    this.updates.add({'_row': '$rowIndex', ...updates});
  }
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

  Future<_FakeApi> pumpScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _FakeApi(apps);
    final state = AppState(apiService: api);
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

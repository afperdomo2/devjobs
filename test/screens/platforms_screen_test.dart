import 'package:devjobs/models/job_application.dart';
import 'package:devjobs/providers/app_state.dart';
import 'package:devjobs/screens/platforms_screen.dart';
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

  Future<void> pumpScreen(
    WidgetTester tester,
    List<JobApplication> apps,
  ) async {
    tester.view.physicalSize = const Size(600, 1600);
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
          home: const PlatformsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final apps = [
    JobApplication(
      rowIndex: 1,
      empresa: 'Vieja',
      link: 'https://www.linkedin.com/jobs/view/1',
      fechaPostulacion: daysAgo(8),
    ),
    JobApplication(
      rowIndex: 2,
      empresa: 'Nueva',
      link: 'https://www.computrabajo.com.co/ofertas/2',
      fechaPostulacion: daysAgo(1),
    ),
  ];

  testWidgets('lista plataformas con su última aplicación', (tester) async {
    await pumpScreen(tester, apps);

    expect(find.text('Plataformas'), findsOneWidget);
    expect(find.text('2 plataformas'), findsOneWidget);
    expect(find.text('2 postulaciones'), findsOneWidget);
    expect(find.text('Linkedin'), findsOneWidget);
    expect(find.text('Computrabajo'), findsOneWidget);
    expect(find.text('hace 8 días'), findsOneWidget);
    expect(find.text('hace 1 día'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ordenar por "Más antiguas" pone primero la más antigua', (
    tester,
  ) async {
    await pumpScreen(tester, apps);

    // Por defecto, el orden es por volumen; con empate, alfabético:
    // Computrabajo antes que Linkedin.
    final linkedinBefore = tester.getTopLeft(find.text('Linkedin')).dy;
    final computrabajoBefore = tester.getTopLeft(find.text('Computrabajo')).dy;
    expect(computrabajoBefore, lessThan(linkedinBefore));

    await tester.tap(find.text('Más antiguas'));
    await tester.pumpAndSettle();

    final linkedinAfter = tester.getTopLeft(find.text('Linkedin')).dy;
    final computrabajoAfter = tester.getTopLeft(find.text('Computrabajo')).dy;
    expect(linkedinAfter, lessThan(computrabajoAfter));
    expect(tester.takeException(), isNull);
  });

  testWidgets('tocar una plataforma abre sus postulaciones', (tester) async {
    await pumpScreen(tester, apps);

    await tester.tap(find.text('Linkedin'));
    await tester.pumpAndSettle();

    expect(find.text('Plataforma · Linkedin'), findsOneWidget);
    expect(find.text('Vieja'), findsOneWidget);
    expect(find.text('Nueva'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin enlaces muestra el estado vacío', (tester) async {
    await pumpScreen(tester, const []);

    expect(find.text('Sin plataformas registradas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

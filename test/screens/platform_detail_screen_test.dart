import 'package:devjobs/models/job_application.dart';
import 'package:devjobs/providers/app_state.dart';
import 'package:devjobs/screens/application_detail_screen.dart';
import 'package:devjobs/screens/company_detail_screen.dart';
import 'package:devjobs/screens/platform_detail_screen.dart';
import 'package:devjobs/services/sheets_api_service.dart';
import 'package:devjobs/widgets/meta_chip.dart';
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

  // Dos postulaciones en "Linkedin" y una en "Computrabajo": la pantalla solo
  // debe mostrar las de la plataforma indicada.
  final apps = [
    JobApplication(
      rowIndex: 1,
      empresa: 'Acme',
      vacante: 'Dev Jr',
      estado: 'Entrevista realizada',
      entrevistaRealizada: true,
      porGestionar: true,
      salarioOfrecido: '6000000',
      ciudad: 'Bogotá',
      modalidad: 'Remoto',
      fechaPostulacion: '01/01/2026',
      fechaSeguimiento: '05/01/2026',
      link: 'https://www.linkedin.com/jobs/view/1',
    ),
    JobApplication(
      rowIndex: 2,
      empresa: 'Beta',
      vacante: 'QA',
      estado: 'Enviada',
      fechaPostulacion: '02/01/2026',
      link: 'https://co.linkedin.com/jobs/view/2',
    ),
    JobApplication(
      rowIndex: 3,
      empresa: 'Otra',
      vacante: 'Dev Sr',
      estado: 'Enviada',
      fechaPostulacion: '03/01/2026',
      link: 'https://www.computrabajo.com.co/ofertas/3',
    ),
  ];

  Future<void> pumpScreen(
    WidgetTester tester, {
    String nombre = 'Linkedin',
  }) async {
    tester.view.physicalSize = const Size(480, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState(apiService: _FakeApi(apps));
    await state.fetchApplications(forceRefresh: true);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(home: PlatformDetailScreen(nombre: nombre)),
      ),
    );
    await tester.pump();
  }

  testWidgets('muestra métricas, distribución, salario y vacantes', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Métricas'), findsOneWidget);
    expect(find.text('Activas'), findsOneWidget);
    expect(find.text('Respondieron'), findsOneWidget);
    expect(find.text('Finalizadas'), findsOneWidget);
    expect(find.text('Entrevistas'), findsOneWidget);
    // Dos: la etiqueta de la métrica y el GestionTag de la vacante marcada.
    expect(find.text('Por gestionar'), findsNWidgets(2));

    expect(find.text('Distribución'), findsOneWidget);
    expect(find.text('Empresas'), findsOneWidget);
    expect(find.text('Ciudades'), findsOneWidget);
    expect(find.text('Modalidades'), findsOneWidget);

    expect(find.text('Salario ofrecido'), findsOneWidget);
    expect(find.text('Vacantes (2)'), findsOneWidget);
    expect(find.text('Dev Jr'), findsOneWidget);
    expect(find.text('QA'), findsOneWidget);
    // La postulación de otra plataforma no aparece.
    expect(find.text('Dev Sr'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tocar una empresa de la distribución abre su detalle', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.widgetWithText(MetaChip, 'Acme'));
    await tester.pumpAndSettle();

    expect(find.byType(CompanyDetailScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tocar una vacante abre el detalle de la postulación', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text('QA'));
    await tester.pumpAndSettle();

    expect(find.byType(ApplicationDetailScreen), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('plataforma sin datos muestra un aviso', (tester) async {
    await pumpScreen(tester, nombre: 'Inexistente');

    expect(find.text('Sin datos para mostrar'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

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

  _FakeApi(this.data) : super(baseUrl: 'http://test');

  @override
  Future<List<JobApplication>> fetchAll() async => data;
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
}

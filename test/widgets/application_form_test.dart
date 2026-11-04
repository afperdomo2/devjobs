import 'dart:io';

import 'package:devjobs/helpers/date_formatter.dart';
import 'package:devjobs/models/job_application.dart';
import 'package:devjobs/providers/app_state.dart';
import 'package:devjobs/screens/application_form_screen.dart';
import 'package:devjobs/services/sheets_api_service.dart';
import 'package:devjobs/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

class _FormApi extends SheetsApiService {
  _FormApi() : super(baseUrl: 'http://test');

  bool failFetch = false;
  int createCalls = 0;
  int updateCalls = 0;
  JobApplication? lastCreated;
  int? lastUpdatedRow;
  Map<String, String>? lastUpdates;

  @override
  Future<List<JobApplication>> fetchAll() async {
    if (failFetch) throw SocketException('offline');
    return const <JobApplication>[];
  }

  @override
  Future<CreateResult> create(JobApplication application) async {
    createCalls++;
    lastCreated = application;
    return const CreateResult(rowIndex: 42, shifted: false);
  }

  @override
  Future<void> updateRow(int rowIndex, Map<String, String> updates) async {
    updateCalls++;
    lastUpdatedRow = rowIndex;
    lastUpdates = updates;
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  Future<(AppState, _FormApi)> pumpForm(
    WidgetTester tester, {
    JobApplication? initial,
  }) async {
    tester.view.physicalSize = const Size(360, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final api = _FormApi();
    final state = AppState(apiService: api);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          locale: const Locale('es'),
          supportedLocales: const [Locale('es')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: AppTheme.light,
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => initial == null
                          ? const ApplicationFormScreen.create()
                          : ApplicationFormScreen.edit(application: initial),
                    ),
                  ),
                  child: const Text('abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return (state, api);
  }

  testWidgets('crear: muestra las secciones y los valores por defecto', (
    tester,
  ) async {
    await pumpForm(tester);

    expect(find.text('Nueva postulación'), findsOneWidget);
    expect(find.text('Vacante'), findsWidgets);
    expect(find.text('Proceso'), findsOneWidget);
    expect(find.text('Notas'), findsOneWidget);
    expect(find.text('Enviada'), findsWidgets);

    final today = DateTime.now();
    expect(
      find.text(formatDateValue(DateTime(today.year, today.month, today.day))),
      findsOneWidget,
    );
  });

  testWidgets('crear: valida empresa y vacante antes de guardar', (
    tester,
  ) async {
    final (_, api) = await pumpForm(tester);

    await tester.tap(find.byKey(const Key('form-save')));
    await tester.pump();

    expect(find.text('Ingresa la empresa'), findsOneWidget);
    expect(find.text('Ingresa la vacante'), findsOneWidget);
    expect(api.createCalls, 0);
  });

  testWidgets('crear: envía la postulación con la fecha en ISO', (
    tester,
  ) async {
    final (_, api) = await pumpForm(tester);
    final today = DateTime.now();

    await tester.enterText(find.byKey(const Key('form-empresa')), 'Acme');
    await tester.enterText(find.byKey(const Key('form-vacante')), 'Dev');
    await tester.tap(find.byKey(const Key('form-save')));
    await tester.pumpAndSettle();

    expect(api.createCalls, 1);
    expect(api.lastCreated?.empresa, 'Acme');
    expect(api.lastCreated?.vacante, 'Dev');
    expect(api.lastCreated?.estado, 'Enviada');
    expect(
      api.lastCreated?.fechaPostulacion,
      formatApiDate(DateTime(today.year, today.month, today.day)),
    );
    expect(find.text('abrir'), findsOneWidget);
  });

  testWidgets('editar: precarga los valores y actualiza las fechas', (
    tester,
  ) async {
    const initial = JobApplication(
      rowIndex: 7,
      empresa: 'Acme',
      vacante: 'Dev',
      tipoContrato: 'Freelance',
      modalidad: 'Remoto',
      ciudad: 'Bogotá',
      estado: 'Enviada',
      fechaPostulacion: '01/01/2026',
      fechaSeguimiento: '05/01/2026',
    );
    final (_, api) = await pumpForm(tester, initial: initial);

    expect(find.text('Editar postulación'), findsOneWidget);
    expect(find.text('Acme'), findsOneWidget);
    expect(find.text('1 de enero, 2026'), findsOneWidget);
    expect(find.text('5 de enero, 2026'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('form-empresa')), 'Acme 2');
    await tester.tap(find.byKey(const Key('form-save')));
    await tester.pumpAndSettle();

    expect(api.updateCalls, 1);
    expect(api.lastUpdatedRow, 7);
    expect(api.lastUpdates?['empresa'], 'Acme 2');
    expect(api.lastUpdates?['fechaPostulacion'], '2026-01-01');
    expect(api.lastUpdates?['fechaSeguimiento'], '2026-01-05');
  });

  testWidgets('offline: deshabilita el botón de guardar', (tester) async {
    final (state, api) = await pumpForm(tester);

    api.failFetch = true;
    await state.fetchApplications(forceRefresh: true);
    await tester.pump();

    final button = tester.widget<FilledButton>(
      find.byKey(const Key('form-save')),
    );
    expect(button.onPressed, isNull);
    expect(find.textContaining('Sin conexión'), findsWidgets);
  });

  testWidgets('abre el selector de fecha en español', (tester) async {
    await pumpForm(tester);

    await tester.tap(find.byKey(const Key('form-fecha-postulacion')));
    await tester.pumpAndSettle();

    expect(find.byType(DatePickerDialog), findsOneWidget);
    expect(find.text('Cancelar'), findsOneWidget);

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();
  });

  testWidgets('elige una fecha del calendario y la envía en ISO', (
    tester,
  ) async {
    final (_, api) = await pumpForm(tester);
    final today = DateTime.now();
    final expected = DateTime(today.year, today.month, 15);

    await tester.tap(find.byKey(const Key('form-fecha-postulacion')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('15'));
    await tester.pump();
    await tester.tap(find.text('ACEPTAR'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('form-empresa')), 'Acme');
    await tester.enterText(find.byKey(const Key('form-vacante')), 'Dev');
    await tester.tap(find.byKey(const Key('form-save')));
    await tester.pumpAndSettle();

    expect(api.lastCreated?.fechaPostulacion, formatApiDate(expected));
  });

  testWidgets('editar: limpiar la última novedad envía vacío', (tester) async {
    const initial = JobApplication(
      rowIndex: 8,
      empresa: 'Acme',
      vacante: 'Dev',
      estado: 'Enviada',
      fechaPostulacion: '01/01/2026',
      fechaSeguimiento: '05/01/2026',
    );
    final (_, api) = await pumpForm(tester, initial: initial);

    await tester.tap(find.byIcon(Icons.clear));
    await tester.pump();
    await tester.tap(find.byKey(const Key('form-save')));
    await tester.pumpAndSettle();

    expect(api.lastUpdates?['fechaSeguimiento'], '');
  });
}

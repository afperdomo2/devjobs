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
  _FormApi({this.data = const <JobApplication>[]})
      : super(baseUrl: 'http://test');

  final List<JobApplication> data;

  @override
  Future<List<JobApplication>> fetchAll() async => data;
}

Future<void> pumpForm(
  WidgetTester tester, {
  JobApplication? initial,
  List<JobApplication> data = const <JobApplication>[],
}) async {
  tester.view.physicalSize = const Size(360, 1600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final state = AppState(apiService: _FormApi(data: data));
  await state.fetchApplications(forceRefresh: true);

  await tester.pumpWidget(
    ChangeNotifierProvider.value(
      value: state,
      child: MaterialApp(
        locale: const Locale('es'),
        supportedLocales: const [Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        theme: AppTheme.light,
        home: initial == null
            ? const ApplicationFormScreen.create()
            : ApplicationFormScreen.edit(application: initial),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  group('enlace Empresa confidencial', () {
    testWidgets('solo se ve con el campo Empresa vacío', (tester) async {
      await pumpForm(tester);

      expect(
        find.byKey(const Key('form-empresa-confidencial')),
        findsOneWidget,
      );

      await tester.enterText(find.byKey(const Key('form-empresa')), 'Acme');
      await tester.pump();
      expect(
        find.byKey(const Key('form-empresa-confidencial')),
        findsNothing,
      );

      await tester.enterText(find.byKey(const Key('form-empresa')), '');
      await tester.pump();
      expect(
        find.byKey(const Key('form-empresa-confidencial')),
        findsOneWidget,
      );
    });

    testWidgets('rellena el campo con "Empresa confidencial"', (tester) async {
      await pumpForm(tester);

      await tester.tap(find.byKey(const Key('form-empresa-confidencial')));
      await tester.pump();

      // El campo lleva el nombre y el enlace ya no aparece.
      expect(find.text('Empresa confidencial'), findsOneWidget);
      expect(
        find.byKey(const Key('form-empresa-confidencial')),
        findsNothing,
      );
    });
  });

  group('sugerencias de empresas similares', () {
    final existing = [
      const JobApplication(
        rowIndex: 5,
        empresa: 'xpertgroup',
        vacante: 'Dev',
      ),
    ];

    testWidgets('avisa cuando el nombre se parece a uno registrado',
        (tester) async {
      await pumpForm(tester, data: existing);

      await tester.enterText(
        find.byKey(const Key('form-empresa')),
        'xpertgroup sas',
      );
      await tester.pump();

      expect(
        find.byKey(const Key('form-empresa-suggestions')),
        findsOneWidget,
      );
      expect(find.textContaining('Usar "xpertgroup"'), findsOneWidget);
    });

    testWidgets('el chip adopta el nombre registrado y el aviso desaparece',
        (tester) async {
      await pumpForm(tester, data: existing);

      await tester.enterText(
        find.byKey(const Key('form-empresa')),
        'xpertgroup sas',
      );
      await tester.pump();
      await tester.tap(find.textContaining('Usar "xpertgroup"'));
      await tester.pump();

      expect(find.text('xpertgroup'), findsOneWidget); // el campo
      expect(
        find.byKey(const Key('form-empresa-suggestions')),
        findsNothing,
      );
    });

    testWidgets('una coincidencia exacta no muestra sugerencias',
        (tester) async {
      await pumpForm(tester, data: existing);

      await tester.enterText(find.byKey(const Key('form-empresa')), 'xpertgroup');
      await tester.pump();

      expect(
        find.byKey(const Key('form-empresa-suggestions')),
        findsNothing,
      );
    });

    testWidgets('nombres sin relación no muestran sugerencias', (tester) async {
      await pumpForm(tester, data: existing);

      await tester.enterText(find.byKey(const Key('form-empresa')), 'Globex');
      await tester.pump();

      expect(
        find.byKey(const Key('form-empresa-suggestions')),
        findsNothing,
      );
    });

    testWidgets('en edición no sugiere la empresa de la propia fila',
        (tester) async {
      final initial = const JobApplication(
        rowIndex: 8,
        empresa: 'xpertgroup sas',
        vacante: 'Dev',
      );
      await pumpForm(
        tester,
        initial: initial,
        data: [
          initial,
          const JobApplication(
            rowIndex: 5,
            empresa: 'xpertgroup',
            vacante: 'QA',
          ),
        ],
      );

      await tester.enterText(find.byKey(const Key('form-empresa')), 'xpertgrou');
      await tester.pump();

      expect(find.textContaining('Usar "xpertgroup"'), findsOneWidget);
      expect(find.textContaining('xpertgroup sas'), findsNothing);
    });
  });
}

import 'package:devjobs/models/job_application.dart';
import 'package:devjobs/models/job_import.dart';
import 'package:devjobs/providers/app_state.dart';
import 'package:devjobs/screens/application_form_screen.dart';
import 'package:devjobs/services/job_import_service.dart';
import 'package:devjobs/services/sheets_api_service.dart';
import 'package:devjobs/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

class _FormApi extends SheetsApiService {
  _FormApi() : super(baseUrl: 'http://test');

  @override
  Future<List<JobApplication>> fetchAll() async {
    return const <JobApplication>[];
  }

  @override
  Future<CreateResult> create(JobApplication application) async {
    return const CreateResult(rowIndex: 42, shifted: false);
  }

  @override
  Future<void> updateRow(int rowIndex, Map<String, String> updates) async {}
}

class _FakeImporter implements JobImporter {
  final JobImportResult result;
  int calls = 0;

  _FakeImporter(this.result);

  @override
  Future<JobImportResult> fromLink(
    String url, {
    required List<JobApplication> existing,
  }) async {
    calls++;
    return result;
  }

  @override
  Future<JobImportResult> fromText(
    String text, {
    required List<JobApplication> existing,
    String? link,
  }) async {
    calls++;
    return result;
  }
}

void main() {
  setUpAll(() async {
    dotenv.loadFromString(envString: 'AI_API_KEY=test');
    await initializeDateFormatting('es');
  });

  Future<void> pumpForm(
    WidgetTester tester, {
    required JobImporter importer,
  }) async {
    tester.view.physicalSize = const Size(360, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState(apiService: _FormApi());

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          locale: const Locale('es'),
          supportedLocales: const [Locale('es')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          theme: AppTheme.light,
          home: ApplicationFormScreen.create(importService: importer),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('importa datos y los puede vaciar', (tester) async {
    const result = JobImportResult(
      status: JobImportStatus.success,
      fields: {
        'empresa': 'Acme',
        'vacante': 'Dev',
        'tipoContrato': 'Indefinido',
        'modalidad': 'Remoto',
        'descripcion':
            '## Resumen\n\nBuscamos un dev.\n\n## Requisitos\n\n- **Experiencia:** 3 años.',
        'comentarios': '- 5/11/2026: Datos clave: Inglés B2',
        'link': 'https://acme.com/jobs/1',
      },
      importedFields: {
        'empresa',
        'vacante',
        'tipoContrato',
        'modalidad',
        'descripcion',
        'comentarios',
        'link',
      },
      warnings: [],
      source: 'IA',
    );
    final importer = _FakeImporter(result);

    await pumpForm(tester, importer: importer);

    expect(find.byKey(const Key('import-entry')), findsOneWidget);

    await tester.tap(find.byKey(const Key('import-entry')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('import-link')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('import-text')),
      'Descripción de la vacante con todos los detalles. ' * 3,
    );
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('import-analyze')))
          .onPressed,
      isNotNull,
    );
    await tester.tap(find.byKey(const Key('import-analyze')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('import-use')), findsOneWidget);

    await tester.tap(find.byKey(const Key('import-use')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('import-summary')), findsOneWidget);
    expect(find.text('Acme'), findsOneWidget);
    expect(find.text('Dev'), findsOneWidget);
    expect(importer.calls, equals(1));

    await tester.ensureVisible(
      find.byKey(const Key('form-descripcion-preview')),
    );
    await tester.tap(find.byKey(const Key('form-descripcion-preview')));
    await tester.pumpAndSettle();
    expect(find.text('Resumen'), findsOneWidget);
    expect(find.byIcon(Icons.summarize_outlined), findsOneWidget);

    await tester.tap(find.byKey(const Key('form-descripcion-preview')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('form-descripcion')), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('import-clear')));
    await tester.tap(find.byKey(const Key('import-clear')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('import-summary')), findsNothing);
    expect(find.byKey(const Key('import-entry')), findsOneWidget);
    expect(find.text('Acme'), findsNothing);
  });
}

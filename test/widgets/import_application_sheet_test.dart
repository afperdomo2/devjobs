import 'package:devjobs/models/ai_config.dart';
import 'package:devjobs/models/job_application.dart';
import 'package:devjobs/models/job_import.dart';
import 'package:devjobs/providers/app_state.dart';
import 'package:devjobs/services/job_import_service.dart';
import 'package:devjobs/services/sheets_api_service.dart';
import 'package:devjobs/theme.dart';
import 'package:devjobs/widgets/import_application_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeApi extends SheetsApiService {
  _FakeApi() : super(baseUrl: 'http://test');
}

class _FakeImporter implements JobImporter {
  final JobImportResult result;

  _FakeImporter(this.result);

  @override
  Future<JobImportResult> fromLink(
    String url, {
    required List<JobApplication> existing,
  }) async {
    return result;
  }

  @override
  Future<JobImportResult> fromText(
    String text, {
    required List<JobApplication> existing,
    String? link,
  }) async {
    return result;
  }
}

const _aiFailedResult = JobImportResult(
  status: JobImportStatus.needsText,
  fields: {'link': 'https://acme.com/jobs/1'},
  importedFields: {'link'},
  warnings: [],
  message: 'Ningún modelo respondió (modelo-a, modelo-b). Cuota agotada.',
  source: '',
  kind: JobPageKind.unknown,
  aiError: 'Ningún modelo respondió (modelo-a, modelo-b). Cuota agotada.',
);

void main() {
  Future<AppState> pumpSheet(
    WidgetTester tester, {
    AiConfig? config,
    JobImporter? importer,
  }) async {
    tester.view.physicalSize = const Size(420, 880);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState(apiService: _FakeApi());
    if (config != null) await state.updateAiConfig(config);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: ImportApplicationSheet(service: importer),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return state;
  }

  testWidgets('sin configurar ofrece configurar la IA', (tester) async {
    await pumpSheet(tester);

    expect(find.byKey(const Key('import-configure')), findsOneWidget);
    expect(find.byKey(const Key('import-analyze')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('muestra el modelo principal y los respaldos', (tester) async {
    await pumpSheet(
      tester,
      config: const AiConfig(
        baseUrl: 'https://api.example.com/v1',
        apiKey: 'key',
        models: ['modelo-a', 'modelo-b'],
      ),
    );

    expect(find.text('Modelo principal: modelo-a'), findsOneWidget);
    expect(find.text('Respaldo: modelo-b'), findsOneWidget);
    expect(find.byKey(const Key('import-analyze')), findsOneWidget);
  });

  testWidgets('si la IA no responde ofrece configurarla', (tester) async {
    await pumpSheet(
      tester,
      config: const AiConfig(
        baseUrl: 'https://api.example.com/v1',
        apiKey: 'key',
        models: ['modelo-a'],
      ),
      importer: _FakeImporter(_aiFailedResult),
    );

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

    expect(find.textContaining('Ningún modelo respondió'), findsOneWidget);
    expect(find.byKey(const Key('import-configure-ai')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

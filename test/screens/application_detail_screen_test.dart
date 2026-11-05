import 'dart:io';

import 'package:devjobs/models/job_application.dart';
import 'package:devjobs/providers/app_state.dart';
import 'package:devjobs/screens/application_detail_screen.dart';
import 'package:devjobs/services/sheets_api_service.dart';
import 'package:devjobs/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

class _FakeApi extends SheetsApiService {
  final List<JobApplication> data;
  bool failFetch = false;
  int updateCalls = 0;
  int? lastRow;
  Map<String, String>? lastUpdates;

  _FakeApi(this.data) : super(baseUrl: 'http://test');

  @override
  Future<List<JobApplication>> fetchAll() async {
    if (failFetch) throw SocketException('offline');
    return data;
  }

  @override
  Future<void> updateRow(int rowIndex, Map<String, String> updates) async {
    updateCalls++;
    lastRow = rowIndex;
    lastUpdates = updates;
  }
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  const application = JobApplication(
    rowIndex: 7,
    empresa: 'Acme',
    vacante: 'Dev',
    estado: 'En revisión',
    fechaPostulacion: '01/11/2026',
    comentarios: '- Nota previa',
  );

  Future<(AppState, _FakeApi)> pumpDetail(
    WidgetTester tester, {
    bool offline = false,
    JobApplication? app,
    Size size = const Size(360, 900),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final target = app ?? application;
    final api = _FakeApi([target])..failFetch = offline;
    final state = AppState(apiService: api);
    await state.fetchApplications(forceRefresh: true);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          theme: AppTheme.light,
          home: ApplicationDetailScreen(application: target),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (state, api);
  }

  testWidgets('agrega una nota con fecha y la muestra en comentarios', (
    tester,
  ) async {
    final (_, api) = await pumpDetail(tester);

    await tester.tap(find.byIcon(Icons.note_add_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Agregar nota'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField),
      'Llamada con reclutador',
    );
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(api.updateCalls, equals(1));
    expect(api.lastRow, equals(7));
    final comments = api.lastUpdates?['comentarios'] ?? '';
    expect(comments, contains('- Nota previa'));
    expect(comments, contains('Llamada con reclutador'));
    expect(comments, contains('- '));
    expect(find.textContaining('Llamada con reclutador'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin conexión deshabilita el botón de nota', (tester) async {
    await pumpDetail(tester, offline: true);

    final button = tester.widget<IconButton>(
      find.widgetWithIcon(IconButton, Icons.note_add_outlined),
    );

    expect(button.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el enlace aparece antes de comentarios y descripción', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      size: const Size(480, 2000),
      app: const JobApplication(
        rowIndex: 7,
        empresa: 'Acme',
        vacante: 'Dev',
        estado: 'En revisión',
        link: 'https://www.linkedin.com/jobs/1',
        comentarios: '- Nota previa',
        descripcion: 'Descripción larga de la vacante.',
      ),
    );

    final linkY = tester.getTopLeft(find.text('Enlace externo')).dy;
    final commentsY = tester.getTopLeft(find.text('Comentarios')).dy;
    final descriptionY = tester.getTopLeft(find.text('Descripción')).dy;

    expect(linkY, lessThan(commentsY));
    expect(linkY, lessThan(descriptionY));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Abrir y Copiar están disponibles y copian el enlace', (
    tester,
  ) async {
    final clipboardCalls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') clipboardCalls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );

    const link = 'https://www.linkedin.com/jobs/1';
    await pumpDetail(
      tester,
      app: const JobApplication(
        rowIndex: 7,
        empresa: 'Acme',
        vacante: 'Dev',
        estado: 'En revisión',
        link: link,
      ),
    );

    expect(find.text('Enlace externo'), findsOneWidget);
    expect(find.text('Abrir'), findsOneWidget);
    expect(find.text('Copiar'), findsOneWidget);
    expect(find.text('linkedin.com'), findsWidgets);

    final openButton = tester.widget<FilledButton>(
      find.byWidgetPredicate((w) => w is FilledButton),
    );
    expect(openButton.onPressed, isNotNull);

    await tester.tap(find.text('Copiar'));
    await tester.pump();

    expect(clipboardCalls, hasLength(1));
    expect(
      (clipboardCalls.single.arguments as Map)['text'],
      link,
    );
    expect(find.text('Enlace copiado al portapapeles'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un enlace inválido avisa y deshabilita Abrir', (tester) async {
    await pumpDetail(
      tester,
      app: const JobApplication(
        rowIndex: 7,
        empresa: 'Acme',
        vacante: 'Dev',
        estado: 'En revisión',
        link: 'no-es-un-link',
      ),
    );

    expect(find.text('El enlace no parece válido.'), findsOneWidget);

    final openButton = tester.widget<FilledButton>(
      find.byWidgetPredicate((w) => w is FilledButton),
    );
    expect(openButton.onPressed, isNull);

    final copyButton = tester.widget<OutlinedButton>(
      find.byWidgetPredicate((w) => w is OutlinedButton),
    );
    expect(copyButton.onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });
}

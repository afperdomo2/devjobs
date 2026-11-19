import 'dart:io';

import 'package:devjobs/helpers/date_formatter.dart';
import 'package:devjobs/models/company_insight.dart';
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
  final List<CompanyInsight> insights;
  bool failFetch = false;
  int updateCalls = 0;
  int? lastRow;
  Map<String, String>? lastUpdates;

  _FakeApi(this.data, {this.insights = const []})
      : super(baseUrl: 'http://test');

  @override
  Future<List<JobApplication>> fetchAll() async {
    if (failFetch) throw SocketException('offline');
    return data;
  }

  @override
  Future<List<CompanyInsight>> fetchCompanyInsights() async => insights;

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
    List<CompanyInsight> insights = const [],
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final target = app ?? application;
    final api = _FakeApi([target], insights: insights)..failFetch = offline;
    final state = AppState(apiService: api);
    await state.fetchApplications(forceRefresh: true);
    await state.loadCompanyInsights();

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

  testWidgets('renderiza la descripción Markdown con secciones', (
    tester,
  ) async {
    const app = JobApplication(
      rowIndex: 8,
      empresa: 'Acme',
      vacante: 'Dev',
      estado: 'Enviada',
      descripcion:
          '## Resumen\n\nRol backend.\n\n## Requisitos\n\n- **Experiencia:** 3 años.',
    );

    await pumpDetail(tester, app: app, size: const Size(360, 1200));

    expect(find.text('Resumen'), findsOneWidget);
    expect(find.text('Requisitos'), findsOneWidget);
    expect(find.byIcon(Icons.summarize_outlined), findsOneWidget);
    expect(find.byIcon(Icons.rule), findsOneWidget);
    expect(find.textContaining('Rol backend.'), findsOneWidget);
  });

  testWidgets('agrega una nota con fecha y la muestra en comentarios', (
    tester,
  ) async {
    final (_, api) = await pumpDetail(tester);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Agregar nota'));
    await tester.pumpAndSettle();
    expect(find.text('Agregar nota'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Llamada con reclutador');
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

  testWidgets('cambia el estado a uno de cierre con fecha y nota', (
    tester,
  ) async {
    final (_, api) = await pumpDetail(tester);

    await tester.tap(find.text('Cambiar estado'));
    await tester.pumpAndSettle();
    expect(find.text('Estado'), findsOneWidget);
    expect(find.text('Cerrar proceso'), findsOneWidget);

    await tester.tap(find.text('Rechazada'));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('status-dialog-nota')),
      'Rechacé por el salario',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final today = DateTime.now();
    expect(api.updateCalls, equals(1));
    expect(api.lastRow, equals(7));
    final updates = api.lastUpdates!;
    expect(updates['estado'], equals('Rechazada'));
    expect(updates['fechaSeguimiento'], equals(formatApiDate(today)));
    expect(updates['porGestionar'], equals('false'));
    expect(updates.containsKey('entrevistaRealizada'), isFalse);
    expect(
      updates['comentarios'],
      contains('${today.day}/${today.month}/${today.year}'),
    );
    expect(updates['comentarios'], contains('Rechacé por el salario'));
    expect(find.text('Proceso finalizado como Rechazada'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un estado intermedio mueve la novedad y conserva el flag', (
    tester,
  ) async {
    final (_, api) = await pumpDetail(
      tester,
      app: const JobApplication(
        rowIndex: 7,
        empresa: 'Acme',
        vacante: 'Dev',
        estado: 'En revisión',
        fechaPostulacion: '01/11/2026',
        fechaSeguimiento: '05/11/2026',
        porGestionar: true,
      ),
    );

    await tester.tap(find.text('Cambiar estado'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Entrevista agendada'));
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final updates = api.lastUpdates!;
    expect(updates['estado'], equals('Entrevista agendada'));
    expect(updates['fechaSeguimiento'], equals(formatApiDate(DateTime.now())));
    expect(updates.containsKey('porGestionar'), isFalse);
    expect(find.text('Estado actualizado a Entrevista agendada'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el switch de entrevista se guarda desde el diálogo', (
    tester,
  ) async {
    final (_, api) = await pumpDetail(
      tester,
      app: const JobApplication(
        rowIndex: 7,
        empresa: 'Acme',
        vacante: 'Dev',
        estado: 'En revisión',
        fechaPostulacion: '01/11/2026',
      ),
    );

    await tester.tap(find.text('Cambiar estado'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('status-dialog-entrevista')),
    );
    await tester.tap(find.byKey(const Key('status-dialog-entrevista')));
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(api.lastUpdates?['entrevistaRealizada'], equals('true'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cambiar estado sigue disponible si el proceso ya terminó', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      app: const JobApplication(
        rowIndex: 7,
        empresa: 'Acme',
        vacante: 'Dev',
        estado: 'Aceptada',
        fechaPostulacion: '01/11/2026',
        fechaSeguimiento: '05/11/2026',
      ),
    );

    expect(find.text('Cambiar estado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin conexión deshabilita Cambiar estado', (tester) async {
    await pumpDetail(tester, offline: true);

    final button = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Cambiar estado'),
    );

    expect(button.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin conexión el menú de acciones queda deshabilitado', (
    tester,
  ) async {
    await pumpDetail(tester, offline: true);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    final edit = tester.widget<PopupMenuItem<dynamic>>(
      find
          .ancestor(
            of: find.text('Editar postulación'),
            matching: find.byWidgetPredicate((w) => w is PopupMenuItem),
          )
          .first,
    );
    final note = tester.widget<PopupMenuItem<dynamic>>(
      find
          .ancestor(
            of: find.text('Agregar nota'),
            matching: find.byWidgetPredicate((w) => w is PopupMenuItem),
          )
          .first,
    );

    expect(edit.enabled, isFalse);
    expect(note.enabled, isFalse);

    // Un ítem deshabilitado no abre el diálogo de nota.
    await tester.tap(find.text('Agregar nota'));
    await tester.pumpAndSettle();
    expect(find.byType(AlertDialog), findsNothing);
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
      find.widgetWithText(FilledButton, 'Abrir'),
    );
    expect(openButton.onPressed, isNotNull);

    await tester.tap(find.text('Copiar'));
    await tester.pump();

    expect(clipboardCalls, hasLength(1));
    expect((clipboardCalls.single.arguments as Map)['text'], link);
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
      find.widgetWithText(FilledButton, 'Abrir'),
    );
    expect(openButton.onPressed, isNull);

    final copyButton = tester.widget<OutlinedButton>(
      find.widgetWithText(OutlinedButton, 'Copiar'),
    );
    expect(copyButton.onPressed, isNotNull);
    expect(tester.takeException(), isNull);
  });

  group('Análisis de la empresa con IA', () {
    const insight = CompanyInsight(
      empresa: 'Acme',
      recomendacion: CompanyRecommendation.seguimientoNormal,
      etiquetas: ['no-respuesta'],
      resumen: 'Resumen corto del análisis de la empresa.',
      fortalezas: ['Siempre responde'],
      riesgos: ['Nunca da feedback'],
    );

    testWidgets('muestra el bloque colapsado con Ver más y se expande inline',
        (tester) async {
      await pumpDetail(tester, insights: const [insight]);

      // El ListView es perezoso: hay que acercarse al bloque.
      await tester.scrollUntilVisible(
        find.text('Análisis de la empresa con IA'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pump();

      expect(find.text('Análisis de la empresa con IA'), findsOneWidget);
      expect(find.text('Ver más'), findsOneWidget);
      expect(find.text('Señales positivas'), findsNothing);

      await tester.tap(find.text('Ver más'));
      await tester.pumpAndSettle();

      expect(find.text('Señales positivas'), findsOneWidget);
      expect(find.text('Siempre responde'), findsOneWidget);
      expect(find.text('Ver menos'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sin análisis no se muestra el bloque', (tester) async {
      await pumpDetail(tester);

      // Se recorre toda la lista para que el bloque (de existir) se construya.
      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await tester.pumpAndSettle();

      expect(find.text('Análisis de la empresa con IA'), findsNothing);
      expect(find.text('Ver más'), findsNothing);
    });

    testWidgets('la empresa confidencial no muestra el bloque', (tester) async {
      await pumpDetail(
        tester,
        app: const JobApplication(
          rowIndex: 7,
          empresa: 'Empresa confidencial',
          vacante: 'Dev',
          estado: 'En revisión',
        ),
        insights: const [
          CompanyInsight(empresa: 'Empresa confidencial', resumen: 'x'),
        ],
      );

      await tester.drag(find.byType(ListView), const Offset(0, -3000));
      await tester.pumpAndSettle();

      expect(find.text('Análisis de la empresa con IA'), findsNothing);
    });
  });
}

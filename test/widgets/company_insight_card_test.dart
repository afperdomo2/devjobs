import 'package:devjobs/models/company_insight.dart';
import 'package:devjobs/widgets/company_insight_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

CompanyInsight insight({
  DateTime? fechaAnalisis,
  List<String> etiquetas = const ['no-respuesta', 'con-feedback'],
  CompanyRecommendation recomendacion = CompanyRecommendation.precaucion,
  String resumen = 'Procesos largos y sin feedback.',
  List<String> fortalezas = const ['Siempre responde'],
  List<String> riesgos = const ['Nunca dan feedback'],
  String perfilVacantes = 'Roles backend.',
  String procesoSeleccion = 'Dos etapas.',
  List<String> contactos = const ['Laura — reclutadora'],
}) {
  return CompanyInsight(
    empresa: 'Acme',
    fechaAnalisis: fechaAnalisis ?? DateTime(2026, 11, 12),
    datosAl: DateTime(2026, 11, 10),
    totalPostulaciones: 3,
    etiquetas: etiquetas,
    recomendacion: recomendacion,
    resumen: resumen,
    fortalezas: fortalezas,
    riesgos: riesgos,
    perfilVacantes: perfilVacantes,
    procesoSeleccion: procesoSeleccion,
    contactos: contactos,
  );
}

Future<void> pumpCard(
  WidgetTester tester, {
  CompanyInsight? insight,
  bool aiEnabled = true,
  bool stale = false,
  bool loading = false,
  bool offline = false,
  String? error,
  VoidCallback? onAnalyze,
  String title = 'Análisis IA',
  bool collapsible = false,
  bool showCard = true,
  bool lowData = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: CompanyInsightCard(
            insight: insight,
            aiEnabled: aiEnabled,
            stale: stale,
            loading: loading,
            offline: offline,
            error: error,
            onAnalyze: onAnalyze,
            title: title,
            collapsible: collapsible,
            showCard: showCard,
            lowData: lowData,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  testWidgets('sin análisis y sin IA no se renderiza nada', (tester) async {
    await pumpCard(tester, aiEnabled: false);
    expect(find.text('Análisis IA'), findsNothing);
  });

  testWidgets('sin análisis ofrece "Analizar con IA" y dispara el callback',
      (tester) async {
    var taps = 0;
    await pumpCard(tester, onAnalyze: () => taps++);

    expect(find.text('Análisis IA'), findsOneWidget);
    expect(find.text('Analizar con IA'), findsOneWidget);

    await tester.tap(find.text('Analizar con IA'));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('offline desactiva el botón y avisa', (tester) async {
    await pumpCard(tester, offline: true, onAnalyze: () {});

    expect(find.text('Conecta a internet para analizar.'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Analizar con IA'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('cargando muestra progreso y oculta el botón', (tester) async {
    await pumpCard(tester, loading: true, onAnalyze: () {});

    expect(find.text('Analizando vacantes y notas…'), findsOneWidget);
    expect(find.text('Analizar con IA'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('muestra el error y permite reintentar', (tester) async {
    await pumpCard(
      tester,
      error: 'La IA no está disponible en este momento.',
      onAnalyze: () {},
    );

    expect(
      find.text('La IA no está disponible en este momento.'),
      findsOneWidget,
    );
    expect(find.text('Analizar con IA'), findsOneWidget);
  });

  testWidgets('con análisis muestra etiquetas, señales y recomendación',
      (tester) async {
    await pumpCard(tester, insight: insight(), onAnalyze: () {});

    expect(find.text('No responde'), findsOneWidget);
    expect(find.text('Da feedback'), findsOneWidget);
    expect(find.text('Procesos largos y sin feedback.'), findsOneWidget);
    expect(find.text('Señales positivas'), findsOneWidget);
    expect(find.text('Siempre responde'), findsOneWidget);
    expect(find.text('A tener en cuenta'), findsOneWidget);
    expect(find.text('Nunca dan feedback'), findsOneWidget);
    expect(find.text('Recomendación'), findsOneWidget);
    expect(find.text('Precaución'), findsOneWidget);
    expect(find.text('Analizado el 12 nov 2026'), findsOneWidget);
    expect(find.text('Reanalizar'), findsOneWidget);
  });

  testWidgets('las secciones expandibles revelan su contenido',
      (tester) async {
    await pumpCard(tester, insight: insight(), onAnalyze: () {});

    expect(find.text('Roles backend.'), findsNothing);
    await tester.tap(find.text('Perfil de vacantes'));
    await tester.pumpAndSettle();
    expect(find.text('Roles backend.'), findsOneWidget);

    await tester.ensureVisible(find.text('Contactos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Contactos'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Laura — reclutadora'), findsOneWidget);
  });

  testWidgets('avisa cuando el análisis está desactualizado', (tester) async {
    await pumpCard(tester, insight: insight(), stale: true, onAnalyze: () {});

    expect(
      find.text('Datos desactualizados: hay novedades desde el análisis.'),
      findsOneWidget,
    );
  });

  testWidgets('Reanalizar dispara el callback y se desactiva offline',
      (tester) async {
    var taps = 0;
    await pumpCard(tester, insight: insight(), onAnalyze: () => taps++);

    await tester.tap(find.text('Reanalizar'));
    await tester.pump();
    expect(taps, 1);

    await pumpCard(
      tester,
      insight: insight(),
      offline: true,
      onAnalyze: () => taps++,
    );
    final button = tester.widget<OutlinedButton>(
      find.ancestor(
        of: find.text('Reanalizar'),
        matching: find.byType(OutlinedButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('sin etiquetas y sin secciones no rompe el layout',
      (tester) async {
    await pumpCard(
      tester,
      insight: insight(
        etiquetas: const [],
        fortalezas: const [],
        riesgos: const [],
        perfilVacantes: '',
        procesoSeleccion: '',
        contactos: const [],
      ),
      onAnalyze: () {},
    );

    expect(find.text('Procesos largos y sin feedback.'), findsOneWidget);
    expect(find.text('Perfil de vacantes'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('con pocos datos avisa pero permite analizar igual', (
    tester,
  ) async {
    await pumpCard(tester, aiEnabled: true, lowData: true, onAnalyze: () {});

    expect(
      find.text(
        'Con menos de 2 postulaciones el análisis puede ser limitado. '
        'Puedes generarlo igualmente.',
      ),
      findsOneWidget,
    );
    // El botón sigue activo: es solo una advertencia.
    expect(find.text('Analizar con IA'), findsOneWidget);
    final button = tester.widget<FilledButton>(
      find.ancestor(
        of: find.text('Analizar con IA'),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNotNull);
  });

  group('modo colapsable (detalle de la vacante)', () {
    testWidgets('colapsado muestra el preview y Ver más; expande y colapsa', (
      tester,
    ) async {
      await pumpCard(
        tester,
        insight: insight(),
        collapsible: true,
        showCard: false,
        title: 'Análisis de la empresa con IA',
        onAnalyze: () {},
      );

      // Preview: chips compactos + resumen truncado, sin señales.
      expect(find.text('Ver más'), findsOneWidget);
      expect(find.text('Señales positivas'), findsNothing);
      expect(find.text('Recomendación'), findsNothing);
      final preview = tester.widget<Text>(
        find.text('Procesos largos y sin feedback.'),
      );
      expect(preview.maxLines, 3);

      await tester.tap(find.text('Ver más'));
      await tester.pump();

      // Expandido: el análisis completo (igual que en el detalle de empresa).
      expect(find.text('Ver menos'), findsOneWidget);
      expect(find.text('Ver más'), findsNothing);
      expect(find.text('Señales positivas'), findsOneWidget);
      expect(find.text('Siempre responde'), findsOneWidget);
      expect(find.text('Recomendación'), findsOneWidget);
      final full = tester.widget<Text>(
        find.text('Procesos largos y sin feedback.'),
      );
      expect(full.maxLines, isNull);

      await tester.tap(find.text('Ver menos'));
      await tester.pump();
      expect(find.text('Señales positivas'), findsNothing);
      expect(find.text('Ver más'), findsOneWidget);
    });

    testWidgets('el modo completo no muestra Ver más', (tester) async {
      await pumpCard(tester, insight: insight(), onAnalyze: () {});

      expect(find.text('Ver más'), findsNothing);
      expect(find.text('Ver menos'), findsNothing);
      expect(find.text('Señales positivas'), findsOneWidget);
    });

    testWidgets('el título es personalizable', (tester) async {
      await pumpCard(
        tester,
        insight: insight(),
        title: 'Análisis de la empresa con IA',
      );

      expect(find.text('Análisis de la empresa con IA'), findsOneWidget);
    });
  });
}

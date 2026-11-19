import 'package:devjobs/helpers/company_stats.dart';
import 'package:devjobs/models/company_insight.dart';
import 'package:devjobs/widgets/company_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  CompanyStats company({
    int entrevistas = 0,
    int porGestionar = 0,
    DateTime? ultimaPostulacion,
  }) =>
      CompanyStats(
        nombre: 'Acme',
        total: 8,
        activas: 3,
        finalizadas: 2,
        conNovedad: 2,
        entrevistas: entrevistas,
        porGestionar: porGestionar,
        ultimaPostulacion: ultimaPostulacion,
      );

  Future<void> pumpCard(
    WidgetTester tester,
    CompanyStats stats, {
    VoidCallback? onTap,
    CompanyInsight? insight,
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: CompanyCard(
              company: stats,
              onTap: onTap ?? () {},
              insight: insight,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('muestra los chips base sin entrevistas ni pendientes',
      (tester) async {
    await pumpCard(
      tester,
      company(
        ultimaPostulacion: DateTime.now().subtract(const Duration(days: 15)),
      ),
    );

    expect(find.text('Acme'), findsOneWidget);
    expect(
      find.textContaining('8 postulaciones · 3 activas · hace'),
      findsOneWidget,
    );
    expect(find.textContaining('3 activas'), findsOneWidget);
    expect(find.text('2/8 respondieron'), findsOneWidget);
    expect(find.textContaining('entrevista'), findsNothing);
    expect(find.textContaining('por gestionar'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('muestra entrevistas y pendientes cuando hay', (tester) async {
    await pumpCard(tester, company(entrevistas: 2, porGestionar: 1));

    expect(find.text('2 entrevistas'), findsOneWidget);
    expect(find.text('1 por gestionar'), findsOneWidget);
    expect(find.textContaining('8 postulaciones'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el nombre no compite con la recomendación en la misma fila', (
    tester,
  ) async {
    // La recomendación vive en su propia fila; el header solo lleva
    // identidad, así que el nombre nunca se trunca por un chip.
    await pumpCard(
      tester,
      company(),
      insight: const CompanyInsight(
        empresa: 'Acme',
        recomendacion: CompanyRecommendation.seguimientoNormal,
      ),
    );

    final name = tester.widget<Text>(
      find.descendant(
        of: find.byType(CompanyCard),
        matching: find.text('Acme'),
      ),
    );
    expect(name.overflow, TextOverflow.ellipsis);
    expect(find.text('Seguimiento normal'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tocar la card dispara el callback', (tester) async {
    var tapped = 0;
    await pumpCard(tester, company(), onTap: () => tapped++);

    await tester.tap(find.byType(CompanyCard));

    expect(tapped, 1);
  });

  group('con análisis IA', () {
    const insight = CompanyInsight(
      empresa: 'Acme',
      recomendacion: CompanyRecommendation.priorizar,
      etiquetas: ['con-feedback', 'no-respuesta', 'proceso-agil'],
    );

    testWidgets('muestra la recomendación y hasta dos etiquetas', (
      tester,
    ) async {
      await pumpCard(tester, company(), insight: insight);

      expect(find.text('Priorizar'), findsOneWidget);
      // Máx. 2 etiquetas, negativas primero.
      expect(find.text('No responde'), findsOneWidget);
      expect(find.text('Da feedback'), findsOneWidget);
      expect(find.text('Proceso ágil'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sin análisis no se muestra nada de IA', (tester) async {
      await pumpCard(tester, company());

      expect(find.text('Priorizar'), findsNothing);
      expect(find.text('No responde'), findsNothing);
    });

    testWidgets('un análisis sin etiquetas muestra solo la recomendación', (
      tester,
    ) async {
      await pumpCard(
        tester,
        company(),
        insight: const CompanyInsight(
          empresa: 'Acme',
          recomendacion: CompanyRecommendation.bajaPrioridad,
        ),
      );

      expect(find.text('Baja prioridad'), findsOneWidget);
    });
  });
}

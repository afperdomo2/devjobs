import 'package:devjobs/helpers/company_stats.dart';
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
            child: CompanyCard(company: stats, onTap: onTap ?? () {}),
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
    expect(find.textContaining('8 postulaciones · hace'), findsOneWidget);
    expect(find.text('3 activas'), findsOneWidget);
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

  testWidgets('tocar la card dispara el callback', (tester) async {
    var tapped = 0;
    await pumpCard(tester, company(), onTap: () => tapped++);

    await tester.tap(find.byType(CompanyCard));

    expect(tapped, 1);
  });
}

import 'package:devjobs/helpers/salary_insights.dart';
import 'package:devjobs/helpers/salary_parser.dart';
import 'package:devjobs/theme.dart';
import 'package:devjobs/widgets/salary_insights_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SalaryGroup group({
    SalaryCurrency currency = SalaryCurrency.cop,
    int count = 3,
    int min = 4500000,
    int max = 6000000,
    int average = 5900000,
  }) {
    return SalaryGroup(
      currency: currency,
      count: count,
      min: min,
      max: max,
      average: average,
    );
  }

  Future<void> pumpCard(
    WidgetTester tester,
    List<SalaryGroup> groups,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: SalaryInsightsCard(groups: groups),
          ),
        ),
      ),
    );
  }

  testWidgets('con una moneda no muestra encabezado de tabla', (tester) async {
    await pumpCard(tester, [group()]);

    expect(find.text('Salario ofrecido'), findsOneWidget);
    expect(find.text('COP (3)'), findsOneWidget);
    expect(find.text('5,9M'), findsOneWidget);
    expect(find.text('promedio'), findsOneWidget);
    expect(find.text('Rango 4,5M – 6M'), findsOneWidget);
    expect(find.text('Moneda'), findsNothing);
    expect(find.textContaining('Basado en'), findsNothing);
    expect(find.textContaining('Solo valores'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('con dos monedas muestra la tabla de 3 columnas', (
    tester,
  ) async {
    await pumpCard(tester, [
      group(),
      group(
        currency: SalaryCurrency.usd,
        count: 2,
        min: 600,
        max: 850,
        average: 725,
      ),
    ]);

    expect(find.text('Salario ofrecido'), findsOneWidget);
    expect(find.text('Moneda'), findsOneWidget);
    expect(find.text('Promedio'), findsOneWidget);
    expect(find.text('Rango'), findsOneWidget);
    expect(find.text('COP (3)'), findsOneWidget);
    expect(find.text('USD (2)'), findsOneWidget);
    expect(find.text('5,9M'), findsOneWidget);
    expect(find.text('4,5M – 6M'), findsOneWidget);
    expect(find.text('725'), findsOneWidget);
    expect(find.text('600 – 850'), findsOneWidget);
    expect(find.textContaining('Basado en'), findsNothing);
    expect(find.textContaining('Solo valores'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin grupos no pinta la tarjeta', (tester) async {
    await pumpCard(tester, const []);

    expect(find.byType(Card), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('valores largos no desbordan a 360 px', (tester) async {
    await pumpCard(tester, [
      group(
        currency: SalaryCurrency.usd,
        count: 12,
        min: 1234567890,
        max: 9876543210,
        average: 5555555555,
      ),
    ]);

    expect(find.text('Salario ofrecido'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

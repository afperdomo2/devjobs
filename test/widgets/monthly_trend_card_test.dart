import 'package:devjobs/helpers/trends.dart';
import 'package:devjobs/theme.dart';
import 'package:devjobs/widgets/monthly_trend_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  List<MonthlyCount> counts(List<int> values) {
    return [
      for (var i = 0; i < values.length; i++)
        MonthlyCount(month: DateTime(2026, 6 + i, 1), count: values[i]),
    ];
  }

  Future<void> pumpCard(
    WidgetTester tester,
    List<MonthlyCount> data,
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
            child: MonthlyTrendCard(counts: data),
          ),
        ),
      ),
    );
  }

  testWidgets('pinta seis meses y el total', (tester) async {
    await pumpCard(tester, counts([0, 2, 0, 5, 1, 3]));

    expect(find.text('Ritmo mensual'), findsOneWidget);
    expect(
      find.text('Últimos 6 meses · 11 postulaciones'),
      findsOneWidget,
    );
    expect(find.text('jun'), findsOneWidget);
    expect(find.text('nov'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    // Junio y agosto están en cero.
    expect(find.text('0'), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets('con todo en cero muestra el mensaje y no desborda', (
    tester,
  ) async {
    await pumpCard(tester, counts([0, 0, 0, 0, 0, 0]));

    expect(find.text('Ritmo mensual'), findsOneWidget);
    expect(find.text('Sin postulaciones en 6 meses'), findsOneWidget);
    expect(find.text('0'), findsNWidgets(6));
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin datos no pinta la tarjeta', (tester) async {
    await pumpCard(tester, const []);

    expect(find.byType(Card), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

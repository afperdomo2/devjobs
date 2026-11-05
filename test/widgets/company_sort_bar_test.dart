import 'package:devjobs/helpers/company_stats.dart';
import 'package:devjobs/theme.dart';
import 'package:devjobs/widgets/company_sort_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpBar(
    WidgetTester tester, {
    CompanySortMode selected = CompanySortMode.total,
    ValueChanged<CompanySortMode>? onSelected,
  }) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: CompanySortBar(
            selected: selected,
            onSelected: onSelected ?? (_) {},
          ),
        ),
      ),
    );
  }

  testWidgets('muestra las cinco opciones', (tester) async {
    await pumpBar(tester);

    expect(find.text('Más postulaciones'), findsOneWidget);
    expect(find.text('Más activas'), findsOneWidget);
    expect(find.text('Más entrevistas'), findsOneWidget);
    expect(find.text('Mejor respuesta'), findsOneWidget);
    expect(find.text('Recientes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tocar una opción devuelve el criterio correcto', (tester) async {
    CompanySortMode? selected;
    await pumpBar(tester, onSelected: (mode) => selected = mode);

    await tester.ensureVisible(find.text('Más entrevistas'));
    await tester.tap(find.text('Más entrevistas'));

    expect(selected, equals(CompanySortMode.entrevistas));
  });
}

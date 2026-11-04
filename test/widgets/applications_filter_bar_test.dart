import 'package:devjobs/providers/app_state.dart';
import 'package:devjobs/widgets/applications_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const counts = {
    AppState.filterAll: 10,
    AppState.filterActivas: 4,
    AppState.filterEnviadas: 3,
    AppState.filterFinalizadas: 3,
  };

  Future<void> pumpBar(
    WidgetTester tester, {
    required String selected,
    required ValueChanged<String> onSelected,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ApplicationsFilterBar(
            selected: selected,
            counts: counts,
            onSelected: onSelected,
          ),
        ),
      ),
    );
  }

  testWidgets('pinta las cuatro pills con sus contadores', (tester) async {
    await pumpBar(tester, selected: AppState.filterAll, onSelected: (_) {});

    expect(find.text('Todas'), findsOneWidget);
    expect(find.text('Activas'), findsOneWidget);
    expect(find.text('Enviadas'), findsOneWidget);
    expect(find.text('Finalizadas'), findsOneWidget);
    expect(find.text('10'), findsOneWidget);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('3'), findsNWidgets(2));
  });

  testWidgets('tocar una pill informa su filtro', (tester) async {
    String? selected;
    await pumpBar(
      tester,
      selected: AppState.filterAll,
      onSelected: (mode) => selected = mode,
    );

    await tester.tap(find.text('Enviadas'));
    await tester.pump();

    expect(selected, AppState.filterEnviadas);
  });
}

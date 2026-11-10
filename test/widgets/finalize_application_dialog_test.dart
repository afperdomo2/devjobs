import 'package:devjobs/widgets/finalize_application_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  /// Abre el diálogo y devuelve una función para leer el resultado.
  Future<FinalizeApplicationResult? Function()> pumpDialog(
    WidgetTester tester, {
    DateTime? today,
  }) async {
    FinalizeApplicationResult? result;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('es'),
        supportedLocales: const [Locale('es')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showFinalizeApplicationDialog(
                    context,
                    empresa: 'Acme',
                    vacante: 'Dev',
                    today: today,
                  );
                },
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    return () => result;
  }

  testWidgets('muestra los estados finales, la fecha de hoy y espera estado', (
    tester,
  ) async {
    await pumpDialog(tester, today: DateTime(2026, 11, 10));

    expect(find.text('Aceptada'), findsOneWidget);
    expect(find.text('Rechazada'), findsOneWidget);
    expect(find.text('Retirada'), findsOneWidget);
    expect(find.text('10 de noviembre, 2026'), findsOneWidget);
    expect(find.text('Acme · Dev'), findsOneWidget);

    final confirm = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Finalizar'),
    );
    expect(confirm.onPressed, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('devuelve el estado, la fecha y la nota recortada', (
    tester,
  ) async {
    final read = await pumpDialog(tester, today: DateTime(2026, 11, 10));

    await tester.tap(find.text('Rechazada'));
    await tester.pump();
    await tester.enterText(
      find.byKey(const Key('finalize-nota')),
      '  Rechacé por el salario  ',
    );
    await tester.tap(find.text('Finalizar'));
    await tester.pumpAndSettle();

    final result = read();
    expect(result, isNotNull);
    expect(result!.estado, equals('Rechazada'));
    expect(result.fecha, equals(DateTime(2026, 11, 10)));
    expect(result.nota, equals('Rechacé por el salario'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('permite elegir otra fecha de finalización', (tester) async {
    final read = await pumpDialog(tester, today: DateTime(2026, 11, 10));

    await tester.tap(find.byKey(const Key('finalize-fecha')));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);

    await tester.tap(find.text('5'));
    await tester.tap(find.text('ACEPTAR'));
    await tester.pumpAndSettle();
    expect(find.text('5 de noviembre, 2026'), findsOneWidget);

    await tester.tap(find.text('Aceptada'));
    await tester.pump();
    await tester.tap(find.text('Finalizar'));
    await tester.pumpAndSettle();

    final result = read();
    expect(result, isNotNull);
    expect(result!.fecha, equals(DateTime(2026, 11, 5)));
    expect(tester.takeException(), isNull);
  });

  testWidgets('cancelar no devuelve resultado', (tester) async {
    final read = await pumpDialog(tester, today: DateTime(2026, 11, 10));

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(read(), isNull);
    expect(tester.takeException(), isNull);
  });
}

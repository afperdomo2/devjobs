import 'package:devjobs/widgets/change_status_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  /// Abre el diálogo y devuelve una función para leer el resultado.
  Future<ChangeStatusResult? Function()> pumpDialog(
    WidgetTester tester, {
    DateTime? today,
    String estadoActual = 'En revisión',
    String? fechaActual,
    bool entrevista = false,
  }) async {
    ChangeStatusResult? result;

    tester.view.physicalSize = const Size(500, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
                  result = await showChangeStatusDialog(
                    context,
                    empresa: 'Acme',
                    vacante: 'Dev',
                    estadoActual: estadoActual,
                    entrevistaRealizada: entrevista,
                    fechaActual: fechaActual == null
                        ? null
                        : DateTime.parse(fechaActual),
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

  testWidgets('agrupa los estados en curso y los de cierre', (tester) async {
    await pumpDialog(tester, today: DateTime(2026, 11, 10));

    expect(find.text('Cambiar estado'), findsOneWidget);
    expect(find.text('Acme · Dev'), findsOneWidget);
    expect(find.text('Estado'), findsOneWidget);
    expect(find.text('Cerrar proceso'), findsOneWidget);
    expect(find.text('Entrevista agendada'), findsOneWidget);
    expect(find.text('Prueba técnica'), findsOneWidget);
    expect(find.text('Aceptada'), findsOneWidget);
    expect(find.text('Rechazada'), findsOneWidget);
    expect(find.text('Retirada'), findsOneWidget);
    expect(find.text('10 de noviembre, 2026'), findsOneWidget);
    expect(find.text('Ya hice la entrevista'), findsOneWidget);
  });

  testWidgets('sin cambios el botón Guardar está deshabilitado', (tester) async {
    await pumpDialog(
      tester,
      today: DateTime(2026, 11, 10),
      fechaActual: '2026-11-10',
    );

    final confirm = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Guardar'),
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
      find.byKey(const Key('status-dialog-nota')),
      '  Rechacé por el salario  ',
    );
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final result = read();
    expect(result, isNotNull);
    expect(result!.estado, equals('Rechazada'));
    expect(result.fecha, equals(DateTime(2026, 11, 10)));
    expect(result.nota, equals('Rechacé por el salario'));
    expect(result.entrevistaRealizada, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('permite elegir otra fecha para la novedad', (tester) async {
    final read = await pumpDialog(tester, today: DateTime(2026, 11, 10));

    await tester.tap(find.byKey(const Key('status-dialog-fecha')));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);

    await tester.tap(find.text('5'));
    await tester.tap(find.text('ACEPTAR'));
    await tester.pumpAndSettle();
    expect(find.text('5 de noviembre, 2026'), findsOneWidget);

    await tester.tap(find.text('Aceptada'));
    await tester.pump();
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final result = read();
    expect(result, isNotNull);
    expect(result!.fecha, equals(DateTime(2026, 11, 5)));
    expect(result.estado, equals('Aceptada'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('el switch de entrevista permite guardar solo ese cambio', (
    tester,
  ) async {
    final read = await pumpDialog(
      tester,
      today: DateTime(2026, 11, 10),
      fechaActual: '2026-11-10',
    );

    await tester.ensureVisible(find.byKey(const Key('status-dialog-entrevista')));
    await tester.tap(find.byKey(const Key('status-dialog-entrevista')));
    await tester.pump();

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final result = read();
    expect(result, isNotNull);
    expect(result!.entrevistaRealizada, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un estado fuera de la lista se ofrece como opción', (
    tester,
  ) async {
    await pumpDialog(
      tester,
      today: DateTime(2026, 11, 10),
      estadoActual: 'En negociación',
      fechaActual: '2026-11-10',
    );

    expect(find.text('En negociación'), findsOneWidget);

    final chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'En negociación'),
    );
    expect(chip.selected, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un proceso ya cerrado muestra su estado seleccionado', (
    tester,
  ) async {
    await pumpDialog(
      tester,
      today: DateTime(2026, 11, 10),
      estadoActual: 'Aceptada',
      fechaActual: '2026-11-05',
    );

    final chip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, 'Aceptada'),
    );
    expect(chip.selected, isTrue);
    // El estado de cierre no se duplica en el grupo de estados en curso.
    expect(find.text('Aceptada'), findsOneWidget);
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

import 'package:devjobs/helpers/company_stats.dart';
import 'package:devjobs/widgets/merge_companies_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

CompanyStats company(String nombre, int total) {
  return CompanyStats(
    nombre: nombre,
    total: total,
    activas: total,
    finalizadas: 0,
    conNovedad: 0,
    entrevistas: 0,
    porGestionar: 0,
  );
}

/// El título del CheckboxListTile (el dropdown del nombre final puede
/// mostrar el mismo texto y confundir los finders).
Finder tile(String name) => find.descendant(
      of: find.byType(CheckboxListTile),
      matching: find.text(name),
    );

Future<void> pumpSheet(
  WidgetTester tester, {
  Future<void> Function(String, List<String>)? onMerge,
}) async {
  late BuildContext sheetContext;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            sheetContext = context;
            return const SizedBox.shrink();
          },
        ),
      ),
    ),
  );
  // Sin await: la hoja se cierra en el propio test.
  showMergeCompaniesSheet(
    sheetContext,
    companies: [
      company('xpertgroup', 3),
      company('xpertgroup sas', 2),
      company('Globex', 4),
    ],
    onMerge: onMerge ?? (finalName, names) async {},
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('lista las empresas con sus conteos', (tester) async {
    await pumpSheet(tester);

    expect(find.text('Combinar empresas'), findsOneWidget);
    expect(tile('xpertgroup'), findsOneWidget);
    expect(tile('xpertgroup sas'), findsOneWidget);
    expect(find.text('3 postulaciones'), findsOneWidget);
    expect(find.text('2 postulaciones'), findsOneWidget);
    expect(find.text('4 postulaciones'), findsOneWidget);
  });

  testWidgets('sin dos seleccionadas el botón queda deshabilitado',
      (tester) async {
    await pumpSheet(tester);

    final button =
        tester.widget<FilledButton>(find.byKey(const Key('merge-confirm')));
    expect(button.onPressed, isNull);

    await tester.tap(tile('xpertgroup'));
    await tester.pump();
    // Con una sola sigue deshabilitado.
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('merge-confirm')))
          .onPressed,
      isNull,
    );
  });

  testWidgets(
      'seleccionar dos habilita, pide nombre final y muestra la vista previa',
      (tester) async {
    await pumpSheet(tester);

    await tester.tap(tile('xpertgroup'));
    await tester.pump();
    await tester.tap(tile('xpertgroup sas'));
    await tester.pump();

    expect(find.text('Nombre final'), findsOneWidget);
    expect(
      find.text('· "xpertgroup sas" (2 filas) → "xpertgroup"'),
      findsOneWidget,
    );
    expect(find.text('Combinar 2 postulaciones'), findsOneWidget);
  });

  testWidgets('confirmar llama onMerge con el nombre final y la selección',
      (tester) async {
    String? mergedTo;
    List<String>? mergedNames;
    await pumpSheet(
      tester,
      onMerge: (finalName, names) async {
        mergedTo = finalName;
        mergedNames = names;
      },
    );

    await tester.tap(tile('xpertgroup'));
    await tester.pump();
    await tester.tap(tile('xpertgroup sas'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('merge-confirm')));
    await tester.pumpAndSettle();

    expect(mergedTo, 'xpertgroup');
    expect(mergedNames, containsAll(['xpertgroup', 'xpertgroup sas']));
    // La hoja se cierra al confirmar.
    expect(find.text('Combinar empresas'), findsNothing);
  });

  testWidgets('un error de onMerge se muestra y la hoja sigue abierta',
      (tester) async {
    await pumpSheet(
      tester,
      onMerge: (finalName, names) async =>
          throw Exception('Sin conexión a internet.'),
    );

    await tester.tap(tile('xpertgroup'));
    await tester.pump();
    await tester.tap(tile('xpertgroup sas'));
    await tester.pump();
    await tester.tap(find.byKey(const Key('merge-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('Sin conexión a internet.'), findsOneWidget);
    expect(find.text('Combinar empresas'), findsOneWidget);
  });

  testWidgets('desmarcar la empresa final elige otra automáticamente',
      (tester) async {
    await pumpSheet(tester);

    await tester.tap(tile('xpertgroup'));
    await tester.pump();
    await tester.tap(tile('xpertgroup sas'));
    await tester.pump();
    await tester.tap(tile('Globex'));
    await tester.pump();
    // "xpertgroup" fue la primera seleccionada: quedó como nombre final.
    expect(
      find.text('· "xpertgroup sas" (2 filas) → "xpertgroup"'),
      findsOneWidget,
    );
    expect(
      find.text('· "Globex" (4 filas) → "xpertgroup"'),
      findsOneWidget,
    );

    await tester.tap(tile('xpertgroup'));
    await tester.pump();
    // Al salir de la selección, el nombre final pasa al siguiente.
    expect(
      find.text('· "Globex" (4 filas) → "xpertgroup sas"'),
      findsOneWidget,
    );
  });

  testWidgets('la lista está en orden alfabético', (tester) async {
    await pumpSheet(tester);

    final titles = tester
        .widgetList<CheckboxListTile>(find.byType(CheckboxListTile))
        .map((t) => (t.title as Text).data)
        .toList();
    expect(titles, ['Globex', 'xpertgroup', 'xpertgroup sas']);
  });

  testWidgets('el buscador filtra sin perder la selección', (tester) async {
    await pumpSheet(tester);

    await tester.enterText(find.byKey(const Key('merge-search')), 'xpert');
    await tester.pump();
    expect(tile('Globex'), findsNothing);
    expect(tile('xpertgroup'), findsOneWidget);

    await tester.tap(tile('xpertgroup'));
    await tester.pump();
    await tester.enterText(find.byKey(const Key('merge-search')), 'sas');
    await tester.pump();
    await tester.tap(tile('xpertgroup sas'));
    await tester.pump();

    // Al limpiar la búsqueda, ambas siguen seleccionadas y la vista previa
    // muestra la absorbida.
    await tester.enterText(find.byKey(const Key('merge-search')), '');
    await tester.pump();
    expect(find.byType(CheckboxListTile), findsNWidgets(3));
    expect(
      find.text('· "xpertgroup sas" (2 filas) → "xpertgroup"'),
      findsOneWidget,
    );
  });

  testWidgets('sin resultados ofrece limpiar búsqueda', (tester) async {
    await pumpSheet(tester);

    await tester.enterText(find.byKey(const Key('merge-search')), 'zzz');
    await tester.pump();

    expect(find.text('Sin resultados para "zzz"'), findsOneWidget);
    await tester.tap(find.text('Limpiar búsqueda'));
    await tester.pump();
    expect(find.byType(CheckboxListTile), findsNWidgets(3));
  });
}

import 'package:devjobs/models/job_application.dart';
import 'package:devjobs/theme.dart';
import 'package:devjobs/widgets/application_card.dart';
import 'package:devjobs/widgets/meta_chip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  Future<void> pumpCard(
    WidgetTester tester,
    JobApplication application, {
    Size size = const Size(360, 800),
    double textScale = 1,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ApplicationCard(application: application, onTap: () {}),
              ],
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('la ciudad con varias sedes no desborda la card',
      (tester) async {
    const ciudad = 'Bogotá, D.C. - Cali - Medellín - Bucaramanga - Neiva';
    await pumpCard(
      tester,
      const JobApplication(
        rowIndex: 1,
        empresa: 'Acme',
        vacante: 'Backend Developer',
        modalidad: 'Presencial',
        ciudad: ciudad,
      ),
    );

    // Sin el Flexible del chip, este texto se medía a su ancho intrínseco
    // (~420 px) y desbordaba la card en 360 px.
    expect(tester.takeException(), isNull);

    final locationText = find.text('Presencial · $ciudad');
    expect(locationText, findsOneWidget);

    final text = tester.widget<Text>(locationText);
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);

    final chipWidth = tester.getSize(find.byType(MetaChip).first).width;
    final textWidth = tester.getSize(locationText).width;
    expect(textWidth, lessThanOrEqualTo(chipWidth));
    expect(chipWidth, lessThan(360 - 16 * 2));
  });

  testWidgets('sigue sin desbordar con el texto ampliado', (tester) async {
    await pumpCard(
      tester,
      const JobApplication(
        rowIndex: 2,
        empresa: 'Acme',
        vacante: 'Backend Developer',
        modalidad: 'Híbrido',
        ciudad: 'Bogotá, D.C. - Cali - Medellín - Bucaramanga - Neiva',
      ),
      size: const Size(320, 800),
      textScale: 1.6,
    );

    expect(tester.takeException(), isNull);
  });

  testWidgets('un chip corto no se estira al ancho de la card', (tester) async {
    await pumpCard(
      tester,
      const JobApplication(
        rowIndex: 3,
        empresa: 'Acme',
        vacante: 'Backend Developer',
        modalidad: 'Remoto',
      ),
    );

    expect(tester.takeException(), isNull);

    final chip = find.widgetWithText(MetaChip, 'Remoto');
    expect(chip, findsOneWidget);
    expect(tester.getSize(chip).width, lessThan(160));
  });

  testWidgets('tocar la card dispara el callback', (tester) async {
    var taps = 0;
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ApplicationCard(
                application: const JobApplication(
                  rowIndex: 4,
                  empresa: 'Acme',
                  vacante: 'Backend Developer',
                ),
                onTap: () => taps++,
              ),
            ],
          ),
        ),
      ),
    );

    await tester.tap(find.byType(ApplicationCard));
    expect(taps, 1);
  });
}

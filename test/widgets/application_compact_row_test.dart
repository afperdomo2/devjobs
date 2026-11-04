import 'package:devjobs/models/job_application.dart';
import 'package:devjobs/theme.dart';
import 'package:devjobs/widgets/application_compact_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpRow(
    WidgetTester tester, {
    required JobApplication application,
    VoidCallback? onTap,
  }) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: ApplicationCompactRow(
            application: application,
            onTap: onTap ?? () {},
            trailingLabel: 'hace 10 días',
            trailingColor: AppColors.warningDark,
          ),
        ),
      ),
    );
  }

  testWidgets('muestra empresa, vacante y texto de la derecha', (tester) async {
    await pumpRow(
      tester,
      application: const JobApplication(
        rowIndex: 1,
        empresa: 'Acme',
        vacante: 'Backend',
      ),
    );

    expect(find.text('Acme'), findsOneWidget);
    expect(find.text('Backend'), findsOneWidget);
    expect(find.text('hace 10 días'), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no muestra vacante vacía', (tester) async {
    await pumpRow(
      tester,
      application: const JobApplication(rowIndex: 1, empresa: 'Acme'),
    );

    expect(find.text('Acme'), findsOneWidget);
    expect(find.text('hace 10 días'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tocar la fila dispara el callback', (tester) async {
    var taps = 0;
    await pumpRow(
      tester,
      application: const JobApplication(rowIndex: 1, empresa: 'Acme'),
      onTap: () => taps++,
    );

    await tester.tap(find.byType(ApplicationCompactRow));

    expect(taps, 1);
  });
}

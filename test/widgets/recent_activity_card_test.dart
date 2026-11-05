import 'package:devjobs/helpers/activity.dart';
import 'package:devjobs/models/job_application.dart';
import 'package:devjobs/theme.dart';
import 'package:devjobs/widgets/recent_activity_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Movement movement({
    int rowIndex = 1,
    String empresa = 'Acme',
    String vacante = 'Backend',
    String estado = 'En revisión',
    int daysAgo = 3,
  }) {
    return Movement(
      application: JobApplication(
        rowIndex: rowIndex,
        empresa: empresa,
        vacante: vacante,
        estado: estado,
      ),
      date: DateTime(2026, 11, 1),
      daysAgo: daysAgo,
    );
  }

  Future<void> pumpCard(
    WidgetTester tester, {
    required List<Movement> movements,
    int last7 = 2,
    int last30 = 5,
    ValueChanged<JobApplication>? onOpen,
  }) async {
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
            child: RecentActivityCard(
              movements: movements,
              last7: last7,
              last30: last30,
              onOpen: onOpen ?? (_) {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('muestra los conteos y los movimientos', (tester) async {
    await pumpCard(
      tester,
      movements: [
        movement(empresa: 'Acme', vacante: 'Backend', daysAgo: 3),
        movement(
          rowIndex: 2,
          empresa: 'Globotech',
          vacante: 'Mobile',
          estado: 'Entrevista realizada',
          daysAgo: 1,
        ),
      ],
    );

    expect(find.text('Actividad reciente'), findsOneWidget);
    expect(find.text('Últimos 7 días'), findsOneWidget);
    expect(find.text('Últimos 30 días'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('Acme'), findsOneWidget);
    expect(find.text('Globotech'), findsOneWidget);
    expect(find.text('hace 3 días'), findsOneWidget);
    expect(find.text('hace 1 día'), findsOneWidget);
    expect(find.textContaining('Entrevista realizada'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin movimientos muestra el mensaje vacío', (tester) async {
    await pumpCard(tester, movements: const []);

    expect(find.text('Actividad reciente'), findsOneWidget);
    expect(find.text('Sin movimientos recientes'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tocar un movimiento abre la postulación correcta', (
    tester,
  ) async {
    JobApplication? opened;
    await pumpCard(
      tester,
      movements: [
        movement(empresa: 'Acme', rowIndex: 1),
        movement(empresa: 'Globotech', rowIndex: 2),
      ],
      onOpen: (app) => opened = app,
    );

    await tester.tap(find.text('Globotech'));

    expect(opened?.rowIndex, equals(2));
  });
}

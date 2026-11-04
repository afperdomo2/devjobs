import 'package:devjobs/helpers/date_formatter.dart';
import 'package:devjobs/models/job_application.dart';
import 'package:devjobs/theme.dart';
import 'package:devjobs/widgets/pending_applications_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String daysAgo(int days) =>
      formatApiDate(DateTime.now().subtract(Duration(days: days)));

  JobApplication app({
    int rowIndex = 1,
    String empresa = 'Acme',
    String vacante = 'Backend',
    int days = 10,
    bool porGestionar = true,
  }) {
    return JobApplication(
      rowIndex: rowIndex,
      empresa: empresa,
      vacante: vacante,
      estado: 'En revisión',
      fechaPostulacion: daysAgo(days),
      porGestionar: porGestionar,
    );
  }

  Future<void> pumpCard(
    WidgetTester tester, {
    required List<JobApplication> applications,
    VoidCallback? onSeeAll,
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
            child: PendingApplicationsCard(
              applications: applications,
              onSeeAll: onSeeAll ?? () {},
              onOpen: onOpen ?? (_) {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('sin pendientes no pinta la tarjeta', (tester) async {
    await pumpCard(tester, applications: const []);

    expect(find.byType(Card), findsNothing);
    expect(find.text('Por gestionar'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('muestra hasta tres filas sin enlace si no sobran', (tester) async {
    await pumpCard(
      tester,
      applications: [
        app(rowIndex: 1, empresa: 'Acme', vacante: 'Backend'),
        app(rowIndex: 2, empresa: 'Globotech', vacante: 'Mobile'),
      ],
    );

    expect(find.text('Por gestionar'), findsOneWidget);
    expect(find.text('Pendientes de acción'), findsOneWidget);
    expect(find.text('Acme'), findsOneWidget);
    expect(find.text('Globotech'), findsOneWidget);
    expect(find.textContaining('hace'), findsWidgets);
    expect(find.textContaining('Ver todas'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('con más de tres muestra Ver todas con el total', (tester) async {
    final applications = [
      for (var i = 1; i <= 5; i++)
        app(rowIndex: i, empresa: 'Empresa $i', vacante: 'Vacante $i'),
    ];

    await pumpCard(tester, applications: applications);

    expect(find.text('Empresa 1'), findsOneWidget);
    expect(find.text('Empresa 3'), findsOneWidget);
    expect(find.text('Empresa 4'), findsNothing);
    expect(find.text('Empresa 5'), findsNothing);
    expect(find.text('5'), findsOneWidget);
    expect(find.text('Ver todas (5)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tocar una fila abre la postulación correcta', (tester) async {
    JobApplication? opened;
    final applications = [
      app(rowIndex: 1, empresa: 'Acme'),
      app(rowIndex: 2, empresa: 'Globotech'),
    ];

    await pumpCard(
      tester,
      applications: applications,
      onOpen: (app) => opened = app,
    );

    await tester.tap(find.text('Globotech'));

    expect(opened?.rowIndex, equals(2));
  });

  testWidgets('tocar Ver todas dispara el callback', (tester) async {
    var seeAll = 0;
    final applications = [
      for (var i = 1; i <= 5; i++)
        app(rowIndex: i, empresa: 'Empresa $i', vacante: 'Vacante $i'),
    ];

    await pumpCard(
      tester,
      applications: applications,
      onSeeAll: () => seeAll++,
    );

    await tester.tap(find.text('Ver todas (5)'));

    expect(seeAll, 1);
  });
}

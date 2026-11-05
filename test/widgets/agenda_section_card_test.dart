import 'package:devjobs/helpers/agenda.dart';
import 'package:devjobs/models/job_application.dart';
import 'package:devjobs/theme.dart';
import 'package:devjobs/widgets/agenda_section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  AgendaSection section({
    AgendaSectionKind kind = AgendaSectionKind.porGestionar,
    int count = 2,
  }) {
    return AgendaSection(
      kind: kind,
      applications: [
        for (var i = 1; i <= count; i++)
          JobApplication(
            rowIndex: i,
            empresa: 'Empresa $i',
            vacante: 'Vacante $i',
            estado: 'En revisión',
          ),
      ],
    );
  }

  Future<void> pumpCard(
    WidgetTester tester, {
    required AgendaSection data,
    ValueChanged<JobApplication>? onOpen,
    VoidCallback? onSeeAll,
  }) async {
    tester.view.physicalSize = const Size(360, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: AgendaSectionCard(
              section: data,
              onOpen: onOpen ?? (_) {},
              onSeeAll: onSeeAll ?? () {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('muestra hasta cinco filas y Ver todas con el total', (
    tester,
  ) async {
    await pumpCard(tester, data: section(count: 6));

    expect(find.text('Por gestionar'), findsOneWidget);
    expect(find.text('Empresa 1'), findsOneWidget);
    expect(find.text('Empresa 5'), findsOneWidget);
    expect(find.text('Empresa 6'), findsNothing);
    expect(find.text('Ver todas (6)'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no muestra Ver todas si caben todas', (tester) async {
    await pumpCard(tester, data: section(count: 2));

    expect(find.text('Empresa 1'), findsOneWidget);
    expect(find.text('Empresa 2'), findsOneWidget);
    expect(find.textContaining('Ver todas'), findsNothing);
  });

  testWidgets('una sección vacía no pinta nada', (tester) async {
    await pumpCard(tester, data: section(count: 0));

    expect(find.byType(Card), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tocar una fila y Ver todas dispara sus callbacks', (
    tester,
  ) async {
    JobApplication? opened;
    var seeAll = 0;

    await pumpCard(
      tester,
      data: section(count: 6),
      onOpen: (app) => opened = app,
      onSeeAll: () => seeAll++,
    );

    await tester.tap(find.text('Empresa 2'));
    expect(opened?.rowIndex, equals(2));

    await tester.tap(find.text('Ver todas (6)'));
    expect(seeAll, equals(1));
  });

  testWidgets('los títulos de las otras secciones son correctos', (
    tester,
  ) async {
    await pumpCard(
      tester,
      data: section(
        kind: AgendaSectionKind.entrevistaAgendada,
        count: 1,
      ),
    );
    expect(find.text('Entrevistas agendadas'), findsOneWidget);

    await pumpCard(
      tester,
      data: section(kind: AgendaSectionKind.ofertaRecibida, count: 1),
    );
    expect(find.text('Ofertas recibidas'), findsOneWidget);
  });
}

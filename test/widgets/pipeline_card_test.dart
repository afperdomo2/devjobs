import 'package:devjobs/helpers/pipeline.dart';
import 'package:devjobs/theme.dart';
import 'package:devjobs/widgets/pipeline_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  PipelineStage stage(String label) =>
      pipelineStages.firstWhere((stage) => stage.label == label);

  Future<void> pumpCard(
    WidgetTester tester, {
    required List<(PipelineStage, int)> segments,
    ValueChanged<PipelineStage>? onStageTap,
  }) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: PipelineCard(
              segments: segments,
              onStageTap: onStageTap ?? (_) {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('pinta las etapas y el texto de ayuda', (tester) async {
    await pumpCard(
      tester,
      segments: [
        (stage('En revisión'), 2),
        (stage('Entrevista'), 1),
      ],
    );

    expect(find.text('Pipeline de postulaciones'), findsOneWidget);
    expect(
      find.text('Toca una etapa para ver las postulaciones'),
      findsOneWidget,
    );
    expect(find.text('En revisión 2'), findsOneWidget);
    expect(find.text('Entrevista 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tocar una etapa devuelve la etapa correcta', (tester) async {
    PipelineStage? tapped;
    await pumpCard(
      tester,
      segments: [
        (stage('En revisión'), 2),
        (stage('Entrevista'), 1),
      ],
      onStageTap: (value) => tapped = value,
    );

    await tester.tap(find.text('Entrevista 1'));

    expect(tapped?.label, equals('Entrevista'));
  });

  testWidgets('sin segmentos no se rompe', (tester) async {
    await pumpCard(tester, segments: const []);

    expect(find.text('Pipeline de postulaciones'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

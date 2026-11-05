import 'package:devjobs/theme.dart';
import 'package:devjobs/widgets/platforms_review_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpButton(
    WidgetTester tester, {
    VoidCallback? onPressed,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: PlatformsReviewButton(onPressed: onPressed ?? () {}),
        ),
      ),
    );
  }

  testWidgets('es un acceso neutro de ancho completo', (tester) async {
    await pumpButton(tester);

    expect(find.text('Revisar plataformas'), findsOneWidget);
    expect(find.byIcon(Icons.language), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_outlined), findsNothing);
    expect(
      tester.getSize(find.byType(OutlinedButton)).width,
      tester.view.physicalSize.width / tester.view.devicePixelRatio,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('al tocar dispara la acción', (tester) async {
    var pressed = false;
    await pumpButton(tester, onPressed: () => pressed = true);

    await tester.tap(find.byType(OutlinedButton));
    expect(pressed, isTrue);
    expect(tester.takeException(), isNull);
  });
}

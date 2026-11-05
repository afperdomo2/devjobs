import 'package:devjobs/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final entry in {
    'claro': AppTheme.light,
    'oscuro': AppTheme.dark,
  }.entries) {
    test('${entry.key}: filled y outlined comparten radio y alto', () {
      final filledShape = entry.value.filledButtonTheme.style!.shape!.resolve(
        <WidgetState>{},
      );
      final outlinedShape = entry.value.outlinedButtonTheme.style!.shape!
          .resolve(<WidgetState>{});

      expect(filledShape, isA<RoundedRectangleBorder>());
      expect(outlinedShape, isA<RoundedRectangleBorder>());

      final filledRadius =
          (filledShape as RoundedRectangleBorder).borderRadius
              as BorderRadius;
      final outlinedRadius =
          (outlinedShape as RoundedRectangleBorder).borderRadius
              as BorderRadius;

      expect(outlinedRadius, filledRadius);
      expect(outlinedRadius.topLeft.x, AppRadius.control);

      expect(
        entry.value.outlinedButtonTheme.style!.minimumSize!.resolve(
          <WidgetState>{},
        ),
        const Size(0, 48),
      );
    });
  }
}

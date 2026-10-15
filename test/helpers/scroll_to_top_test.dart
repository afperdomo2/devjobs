import 'package:devjobs/helpers/scroll_to_top.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldShowScrollToTop', () {
    test('no muestra el botón sin desplazamiento', () {
      expect(
        shouldShowScrollToTop(offset: 0, viewportHeight: 880),
        isFalse,
      );
      expect(
        shouldShowScrollToTop(offset: -40, viewportHeight: 880),
        isFalse,
      );
    });

    test('muestra el botón tras media pantalla (viewport grande)', () {
      // 880 * 0.5 = 440, por encima del piso de 350.
      expect(
        shouldShowScrollToTop(offset: 439, viewportHeight: 880),
        isFalse,
      );
      expect(
        shouldShowScrollToTop(offset: 440, viewportHeight: 880),
        isTrue,
      );
    });

    test('aplica el piso en viewports pequeños', () {
      // 400 * 0.5 = 200, así que rige el piso de 350.
      expect(
        shouldShowScrollToTop(offset: 340, viewportHeight: 400),
        isFalse,
      );
      expect(
        shouldShowScrollToTop(offset: 350, viewportHeight: 400),
        isTrue,
      );
    });

    test('viewport degenerado usa el piso', () {
      expect(
        shouldShowScrollToTop(offset: 0, viewportHeight: 0),
        isFalse,
      );
      expect(
        shouldShowScrollToTop(offset: 349, viewportHeight: 0),
        isFalse,
      );
      expect(
        shouldShowScrollToTop(offset: 350, viewportHeight: 0),
        isTrue,
      );
    });

    test('respeta fraction y minOffset personalizados', () {
      expect(
        shouldShowScrollToTop(
          offset: 99,
          viewportHeight: 1000,
          fraction: 0.1,
          minOffset: 50,
        ),
        isFalse,
      );
      expect(
        shouldShowScrollToTop(
          offset: 120,
          viewportHeight: 1000,
          fraction: 0.1,
          minOffset: 50,
        ),
        isTrue,
      );
    });
  });
}

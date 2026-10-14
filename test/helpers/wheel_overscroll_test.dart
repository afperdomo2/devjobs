import 'package:flutter_test/flutter_test.dart';
import 'package:devjobs/helpers/wheel_overscroll.dart';

void main() {
  group('WheelOverscrollTracker', () {
    test('acumula hacia arriba en el tope y dispara al superar el umbral', () {
      final t = WheelOverscrollTracker(threshold: 100);
      expect(t.addScroll(-40, atTop: true), isFalse);
      expect(t.addScroll(-40, atTop: true), isFalse);
      expect(t.addScroll(-40, atTop: true), isTrue); // 120 acumulado
    });

    test('no acumula si la lista no está en el tope', () {
      final t = WheelOverscrollTracker(threshold: 100);
      expect(t.addScroll(-60, atTop: false), isFalse);
      expect(t.addScroll(-60, atTop: false), isFalse);
      expect(t.addScroll(-60, atTop: true), isFalse); // contador seguía en 0
    });

    test('se reinicia al hacer scroll hacia abajo', () {
      final t = WheelOverscrollTracker(threshold: 100);
      t.addScroll(-80, atTop: true);
      t.addScroll(50, atTop: true); // baja → reset
      expect(t.addScroll(-80, atTop: true), isFalse); // 80 < 100
      expect(t.addScroll(-30, atTop: true), isTrue); // 110 acumulado
    });

    test('se reinicia tras disparar (no dispara dos veces seguidas)', () {
      final t = WheelOverscrollTracker(threshold: 50);
      expect(t.addScroll(-100, atTop: true), isTrue);
      expect(t.addScroll(-10, atTop: true), isFalse);
    });

    test('delta positivo (hacia abajo) nunca dispara', () {
      final t = WheelOverscrollTracker(threshold: 10);
      expect(t.addScroll(100, atTop: true), isFalse);
    });

    test('reset() limpia el acumulado', () {
      final t = WheelOverscrollTracker(threshold: 100);
      t.addScroll(-90, atTop: true);
      t.reset();
      expect(t.addScroll(-90, atTop: true), isFalse);
      expect(t.addScroll(-20, atTop: true), isTrue);
    });
  });
}

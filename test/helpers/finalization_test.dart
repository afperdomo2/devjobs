import 'package:devjobs/helpers/finalization.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fecha = DateTime(2026, 11, 10);

  group('finalizationUpdates', () {
    test('cierra el proceso con estado, fecha y nota', () {
      final updates = finalizationUpdates(
        estado: 'Aceptada',
        fecha: fecha,
        comentariosActuales: '- Nota previa',
        nota: 'Acepté la oferta',
      );

      expect(updates['estado'], equals('Aceptada'));
      expect(updates['fechaSeguimiento'], equals('2026-11-10'));
      expect(updates['porGestionar'], equals('false'));
      expect(
        updates['comentarios'],
        equals('- Nota previa\n- 10/11/2026: Acepté la oferta'),
      );
    });

    test('sin nota no reescribe comentarios', () {
      final updates = finalizationUpdates(
        estado: 'Rechazada',
        fecha: fecha,
        comentariosActuales: '- Nota previa',
      );

      expect(updates.containsKey('comentarios'), isFalse);
      expect(updates['estado'], equals('Rechazada'));
    });

    test('una nota en blanco tampoco reescribe comentarios', () {
      final updates = finalizationUpdates(
        estado: 'Retirada',
        fecha: fecha,
        comentariosActuales: '- Nota previa',
        nota: '   ',
      );

      expect(updates.containsKey('comentarios'), isFalse);
    });

    test('la nota usa la fecha elegida, no la de hoy', () {
      final updates = finalizationUpdates(
        estado: 'Aceptada',
        fecha: DateTime(2026, 1, 5),
        comentariosActuales: '',
        nota: 'Cerré el proceso',
      );

      expect(updates['fechaSeguimiento'], equals('2026-01-05'));
      expect(updates['comentarios'], equals('- 5/1/2026: Cerré el proceso'));
    });

    test('los saltos de línea de la nota quedan en una sola entrada', () {
      final updates = finalizationUpdates(
        estado: 'Rechazada',
        fecha: fecha,
        comentariosActuales: '',
        nota: 'Rechacé\npor el salario',
      );

      expect(
        updates['comentarios'],
        equals('- 10/11/2026: Rechacé por el salario'),
      );
    });
  });
}

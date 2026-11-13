import 'package:devjobs/helpers/change_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final fecha = DateTime(2026, 11, 10);

  group('changeStatusUpdates', () {
    test('estado terminal cierra, mueve la novedad y limpia por gestionar', () {
      final updates = changeStatusUpdates(
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

    test('un estado intermedio conserva "Por gestionar"', () {
      final updates = changeStatusUpdates(
        estado: 'Entrevista agendada',
        fecha: fecha,
        comentariosActuales: '',
      );

      expect(updates['estado'], equals('Entrevista agendada'));
      expect(updates['fechaSeguimiento'], equals('2026-11-10'));
      expect(updates.containsKey('porGestionar'), isFalse);
    });

    test('sin nota no reescribe comentarios', () {
      final updates = changeStatusUpdates(
        estado: 'Rechazada',
        fecha: fecha,
        comentariosActuales: '- Nota previa',
      );

      expect(updates.containsKey('comentarios'), isFalse);
      expect(updates['estado'], equals('Rechazada'));
    });

    test('una nota en blanco tampoco reescribe comentarios', () {
      final updates = changeStatusUpdates(
        estado: 'Retirada',
        fecha: fecha,
        comentariosActuales: '- Nota previa',
        nota: '   ',
      );

      expect(updates.containsKey('comentarios'), isFalse);
    });

    test('la nota usa la fecha elegida, no la de hoy', () {
      final updates = changeStatusUpdates(
        estado: 'Aceptada',
        fecha: DateTime(2026, 1, 5),
        comentariosActuales: '',
        nota: 'Cerré el proceso',
      );

      expect(updates['fechaSeguimiento'], equals('2026-01-05'));
      expect(updates['comentarios'], equals('- 5/1/2026: Cerré el proceso'));
    });

    test('los saltos de línea de la nota quedan en una sola entrada', () {
      final updates = changeStatusUpdates(
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

    test('la entrevista solo se envía cuando se indica', () {
      final sinCambio = changeStatusUpdates(
        estado: 'Prueba técnica',
        fecha: fecha,
        comentariosActuales: '',
      );
      expect(sinCambio.containsKey('entrevistaRealizada'), isFalse);

      final marcada = changeStatusUpdates(
        estado: 'Prueba técnica',
        fecha: fecha,
        comentariosActuales: '',
        entrevistaRealizada: true,
      );
      expect(marcada['entrevistaRealizada'], equals('true'));

      final desmarcada = changeStatusUpdates(
        estado: 'Prueba técnica',
        fecha: fecha,
        comentariosActuales: '',
        entrevistaRealizada: false,
      );
      expect(desmarcada['entrevistaRealizada'], equals('false'));
    });

    test('un estado desconocido con tilde no se confunde con cierre', () {
      final updates = changeStatusUpdates(
        estado: 'En negociación',
        fecha: fecha,
        comentariosActuales: '',
      );

      expect(updates['estado'], equals('En negociación'));
      expect(updates.containsKey('porGestionar'), isFalse);
    });
  });
}

import 'package:devjobs/helpers/comments.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseComments', () {
    test('vacío retorna lista vacía', () {
      expect(parseComments(''), isEmpty);
      expect(parseComments('   '), isEmpty);
    });

    test('separa líneas, quita viñetas y descarta vacías', () {
      expect(
        parseComments('- Nota 1\n\n  - Nota 2  \nNota 3'),
        equals(['Nota 1', 'Nota 2', 'Nota 3']),
      );
    });
  });

  group('appendComment', () {
    final date = DateTime(2026, 11, 4);

    test('agrega fecha a un comentario vacío', () {
      expect(
        appendComment('', 'Llamada con reclutador', date: date),
        equals('- 4/11/2026: Llamada con reclutador'),
      );
    });

    test('conserva los comentarios existentes', () {
      expect(
        appendComment('- Nota previa', 'Nueva nota', date: date),
        equals('- Nota previa\n- 4/11/2026: Nueva nota'),
      );
    });

    test('texto vacío no modifica el comentario', () {
      expect(
        appendComment('- Nota previa  ', '   ', date: date),
        equals('- Nota previa'),
      );
    });

    test('normaliza saltos de línea internos', () {
      expect(
        appendComment('', 'Línea 1\nLínea 2', date: date),
        equals('- 4/11/2026: Línea 1 Línea 2'),
      );
    });

    test('usa día y mes sin ceros a la izquierda', () {
      expect(
        appendComment('', 'Nota', date: DateTime(2026, 1, 5)),
        equals('- 5/1/2026: Nota'),
      );
    });
  });
}

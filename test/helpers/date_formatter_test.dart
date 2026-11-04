import 'package:devjobs/helpers/date_formatter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  group('parseDate', () {
    test('parsa d/M/yyyy', () {
      final d = parseDate('02/06/2026');
      expect(d, isNotNull);
      expect(d!.year, equals(2026));
      expect(d.month, equals(6));
      expect(d.day, equals(2));
    });

    test('parsa ISO embebido', () {
      final d = parseDate('2026-06-02');
      expect(d!.year, equals(2026));
      expect(d.month, equals(6));
      expect(d.day, equals(2));
    });

    test('retorna null si no parsea', () {
      expect(parseDate(''), isNull);
      expect(parseDate('texto raro'), isNull);
    });

    test('ignora espacios alrededor', () {
      final d = parseDate(' 02/06/2026 ');
      expect(d, isNotNull);
      expect(d!.day, equals(2));
    });

    test('rechaza fechas que DateTime normalizaría', () {
      expect(parseDate('31/02/2026'), isNull);
      expect(parseDate('2026-02-30'), isNull);
      expect(parseDate('2026-13-01'), isNull);
    });
  });

  group('formatApiDate', () {
    test('usa ceros a la izquierda', () {
      expect(formatApiDate(DateTime(2026, 1, 5)), equals('2026-01-05'));
    });

    test('ignora la hora', () {
      expect(
        formatApiDate(DateTime(2026, 11, 4, 23, 59)),
        equals('2026-11-04'),
      );
    });

    test('soporta año bisiesto', () {
      expect(formatApiDate(DateTime(2028, 2, 29)), equals('2028-02-29'));
    });

    test('round-trip con parseDate', () {
      final date = DateTime(2026, 12, 31);
      expect(parseDate(formatApiDate(date)), equals(date));
    });
  });

  group('formatDateValue', () {
    test('formatea un DateTime al formato largo español', () {
      expect(
        formatDateValue(DateTime(2026, 6, 2)),
        equals('2 de junio, 2026'),
      );
    });
  });

  group('formatDate', () {
    test('formatea d/M/yyyy al formato largo español', () {
      expect(formatDate('02/06/2026'), equals('2 de junio, 2026'));
    });

    test('retorna original si no parsea', () {
      expect(formatDate('texto raro'), equals('texto raro'));
      expect(formatDate(''), equals(''));
    });
  });

  group('formatDateShort', () {
    test('formatea a abreviado español', () {
      // 2026-06-02 es martes → "mar"
      expect(formatDateShort('02/06/2026'), equals('mar 2 jun 2026'));
    });

    test('retorna original si no parsea', () {
      expect(formatDateShort(''), equals(''));
      expect(formatDateShort('---'), equals('---'));
    });
  });

  group('formatDias', () {
    test('pluraliza correctamente', () {
      expect(formatDias(0), equals('0 días'));
      expect(formatDias(1), equals('1 día'));
      expect(formatDias(2), equals('2 días'));
      expect(formatDias(15), equals('15 días'));
    });
  });

  group('formatSinNovedad', () {
    test('0 días retorna hoy', () {
      expect(formatSinNovedad(0), equals('hoy'));
    });

    test('pluraliza correctamente', () {
      expect(formatSinNovedad(1), equals('hace 1 día'));
      expect(formatSinNovedad(2), equals('hace 2 días'));
      expect(formatSinNovedad(15), equals('hace 15 días'));
    });
  });

  group('formatDuracion', () {
    test('0 días retorna Mismo día', () {
      expect(formatDuracion(0), equals('Mismo día'));
    });

    test('pluraliza correctamente', () {
      expect(formatDuracion(1), equals('Duró 1 día'));
      expect(formatDuracion(2), equals('Duró 2 días'));
      expect(formatDuracion(13), equals('Duró 13 días'));
    });
  });
}

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
}

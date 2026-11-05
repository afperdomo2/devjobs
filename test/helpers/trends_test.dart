import 'package:devjobs/helpers/date_formatter.dart';
import 'package:devjobs/helpers/trends.dart';
import 'package:devjobs/models/job_application.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  JobApplication app({
    int rowIndex = 1,
    String fechaPostulacion = '',
  }) {
    return JobApplication(
      rowIndex: rowIndex,
      fechaPostulacion: fechaPostulacion,
    );
  }

  String date(int year, int month, int day) =>
      formatApiDate(DateTime(year, month, day));

  group('monthlyApplicationCounts', () {
    test('lista vacía devuelve los meses en cero', () {
      final result = monthlyApplicationCounts(
        [],
        now: DateTime(2026, 11, 15),
      );

      expect(result.length, equals(6));
      expect(result.every((item) => item.count == 0), isTrue);
      expect(result.first.month, equals(DateTime(2026, 6, 1)));
      expect(result.last.month, equals(DateTime(2026, 11, 1)));
    });

    test('cuenta por mes e ignora fechas fuera de la ventana', () {
      final applications = [
        app(rowIndex: 1, fechaPostulacion: date(2026, 11, 1)),
        app(rowIndex: 2, fechaPostulacion: date(2026, 11, 15)),
        app(rowIndex: 3, fechaPostulacion: date(2026, 10, 20)),
        app(rowIndex: 4, fechaPostulacion: date(2026, 6, 5)),
        app(rowIndex: 5, fechaPostulacion: date(2026, 5, 31)),
        app(rowIndex: 6, fechaPostulacion: 'texto raro'),
      ];

      final result = monthlyApplicationCounts(
        applications,
        now: DateTime(2026, 11, 15),
      );

      expect(
        result.map((item) => item.count).toList(),
        equals([1, 0, 0, 0, 1, 2]),
      );
      expect(
        result.map((item) => item.month.month).toList(),
        equals([6, 7, 8, 9, 10, 11]),
      );
    });

    test('cruza correctamente de diciembre a enero', () {
      final applications = [
        app(rowIndex: 1, fechaPostulacion: date(2025, 12, 20)),
        app(rowIndex: 2, fechaPostulacion: date(2026, 1, 5)),
        app(rowIndex: 3, fechaPostulacion: date(2026, 1, 20)),
      ];

      final result = monthlyApplicationCounts(
        applications,
        now: DateTime(2026, 1, 15),
      );

      expect(result.length, equals(6));
      expect(result.first.month, equals(DateTime(2025, 8, 1)));
      expect(result[4].month, equals(DateTime(2025, 12, 1)));
      expect(result[4].count, equals(1));
      expect(result.last.month, equals(DateTime(2026, 1, 1)));
      expect(result.last.count, equals(2));
    });

    test('meses <= 0 devuelve lista vacía', () {
      expect(monthlyApplicationCounts([], months: 0), isEmpty);
      expect(monthlyApplicationCounts([], months: -1), isEmpty);
    });

    test('months = 1 devuelve solo el mes actual', () {
      final result = monthlyApplicationCounts(
        [
          app(fechaPostulacion: date(2026, 11, 3)),
          app(fechaPostulacion: date(2026, 10, 3)),
        ],
        months: 1,
        now: DateTime(2026, 11, 15),
      );

      expect(result.length, equals(1));
      expect(result.first.month, equals(DateTime(2026, 11, 1)));
      expect(result.first.count, equals(1));
    });
  });
}

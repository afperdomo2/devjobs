import 'package:devjobs/helpers/activity.dart';
import 'package:devjobs/models/job_application.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 4);

  String date(int daysAgo) {
    final value = DateTime(now.year, now.month, now.day - daysAgo);
    return '${value.day}/${value.month}/${value.year}';
  }

  JobApplication app({
    int rowIndex = 1,
    String empresa = 'Acme',
    String vacante = 'Dev',
    String estado = 'En revisión',
    String? fechaPostulacion,
    String? fechaSeguimiento,
  }) {
    return JobApplication(
      rowIndex: rowIndex,
      empresa: empresa,
      vacante: vacante,
      estado: estado,
      fechaPostulacion: fechaPostulacion ?? date(10),
      fechaSeguimiento: fechaSeguimiento ?? '',
    );
  }

  group('countApplicationsSince', () {
    test('lista vacía retorna 0', () {
      expect(countApplicationsSince([], 7, now: now), equals(0));
    });

    test('cuenta dentro de la ventana e incluye el límite exacto', () {
      final applications = [
        app(rowIndex: 1, fechaPostulacion: date(2)),
        app(rowIndex: 2, fechaPostulacion: date(7)),
        app(rowIndex: 3, fechaPostulacion: date(8)),
        app(rowIndex: 4, fechaPostulacion: date(30)),
        app(rowIndex: 5, fechaPostulacion: date(31)),
      ];

      expect(countApplicationsSince(applications, 7, now: now), equals(2));
      expect(countApplicationsSince(applications, 30, now: now), equals(4));
    });

    test('ignora fechas vacías o inválidas', () {
      final applications = [
        app(rowIndex: 1, fechaPostulacion: ''),
        app(rowIndex: 2, fechaPostulacion: 'texto raro'),
        app(rowIndex: 3, fechaPostulacion: date(1)),
      ];

      expect(countApplicationsSince(applications, 7, now: now), equals(1));
    });
  });

  group('recentMovements', () {
    test('lista vacía retorna vacía', () {
      expect(recentMovements([], now: now), isEmpty);
    });

    test('usa fechaSeguimiento antes que la postulación', () {
      final application = app(
        fechaPostulacion: date(20),
        fechaSeguimiento: date(2),
      );

      final result = recentMovements([application], now: now);

      expect(result.length, equals(1));
      expect(result.first.date, equals(DateTime(2026, 11, 2)));
      expect(result.first.daysAgo, equals(2));
    });

    test('cae a la postulación si no hay seguimiento', () {
      final application = app(fechaPostulacion: date(5));

      final result = recentMovements([application], now: now);

      expect(result.first.date, equals(DateTime(2026, 10, 30)));
      expect(result.first.daysAgo, equals(5));
    });

    test('cae a la postulación si el seguimiento no parsea', () {
      final application = app(
        fechaPostulacion: date(5),
        fechaSeguimiento: 'texto raro',
      );

      final result = recentMovements([application], now: now);

      expect(result.first.date, equals(DateTime(2026, 10, 30)));
    });

    test('ordena del más reciente al más antiguo', () {
      final applications = [
        app(rowIndex: 1, empresa: 'Antigua', fechaPostulacion: date(20)),
        app(rowIndex: 2, empresa: 'Reciente', fechaPostulacion: date(1)),
        app(rowIndex: 3, empresa: 'Media', fechaPostulacion: date(10)),
      ];

      final result = recentMovements(applications, now: now);

      expect(
        result.map((movement) => movement.application.empresa).toList(),
        equals(['Reciente', 'Media', 'Antigua']),
      );
    });

    test('respeta el límite', () {
      final applications = [
        for (var i = 0; i < 6; i++)
          app(rowIndex: i, empresa: 'Empresa $i', fechaPostulacion: date(i)),
      ];

      expect(recentMovements(applications, now: now).length, 3);
      expect(recentMovements(applications, limit: 4, now: now).length, 4);
      expect(recentMovements(applications, limit: 0, now: now), isEmpty);
    });

    test('omite postulaciones sin fechas y no genera días negativos', () {
      final future = app(
        rowIndex: 1,
        fechaPostulacion: date(-2),
      );
      final withoutDates = const JobApplication(rowIndex: 2);
      final invalid = JobApplication(
        rowIndex: 3,
        fechaPostulacion: 'texto raro',
      );

      final result = recentMovements(
        [future, withoutDates, invalid],
        now: now,
      );

      expect(result.length, equals(1));
      expect(result.first.daysAgo, equals(0));
    });
  });
}

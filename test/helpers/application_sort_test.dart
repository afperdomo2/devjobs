import 'package:devjobs/helpers/application_sort.dart';
import 'package:devjobs/models/job_application.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  JobApplication app({
    int rowIndex = 1,
    String empresa = 'Acme',
    bool porGestionar = false,
    String fechaPostulacion = '',
    String fechaSeguimiento = '',
  }) {
    return JobApplication(
      rowIndex: rowIndex,
      empresa: empresa,
      porGestionar: porGestionar,
      fechaPostulacion: fechaPostulacion,
      fechaSeguimiento: fechaSeguimiento,
    );
  }

  group('sortApplications', () {
    test('lista vacía retorna vacía', () {
      expect(sortApplications([]), isEmpty);
    });

    test('las marcadas Por gestionar van primero', () {
      final applications = [
        app(rowIndex: 1, empresa: 'Normal', fechaPostulacion: '10/01/2026'),
        app(
          rowIndex: 2,
          empresa: 'Pendiente',
          porGestionar: true,
          fechaPostulacion: '01/01/2026',
        ),
      ];

      final sorted = sortApplications(applications);
      expect(sorted.first.empresa, equals('Pendiente'));
    });

    test('ordena por fecha de seguimiento descendente', () {
      final applications = [
        app(
          rowIndex: 1,
          empresa: 'Antigua',
          fechaSeguimiento: '01/01/2026',
        ),
        app(
          rowIndex: 2,
          empresa: 'Reciente',
          fechaSeguimiento: '10/01/2026',
        ),
        app(
          rowIndex: 3,
          empresa: 'Media',
          fechaSeguimiento: '05/01/2026',
        ),
      ];

      final sorted = sortApplications(applications);
      expect(
        sorted.map((application) => application.empresa).toList(),
        equals(['Reciente', 'Media', 'Antigua']),
      );
    });

    test('las que tienen seguimiento van antes que las que no', () {
      final applications = [
        app(
          rowIndex: 1,
          empresa: 'Sin seguimiento',
          fechaPostulacion: '20/01/2026',
        ),
        app(
          rowIndex: 2,
          empresa: 'Con seguimiento',
          fechaSeguimiento: '01/01/2026',
        ),
      ];

      final sorted = sortApplications(applications);
      expect(sorted.first.empresa, equals('Con seguimiento'));
    });

    test('sin seguimiento ordena por postulación descendente', () {
      final applications = [
        app(
          rowIndex: 1,
          empresa: 'Antigua',
          fechaPostulacion: '01/01/2026',
        ),
        app(
          rowIndex: 2,
          empresa: 'Reciente',
          fechaPostulacion: '10/01/2026',
        ),
      ];

      final sorted = sortApplications(applications);
      expect(
        sorted.map((application) => application.empresa).toList(),
        equals(['Reciente', 'Antigua']),
      );
    });

    test('no modifica la lista original', () {
      final applications = [
        app(rowIndex: 1, empresa: 'B', fechaPostulacion: '01/01/2026'),
        app(rowIndex: 2, empresa: 'A', fechaPostulacion: '10/01/2026'),
      ];

      sortApplications(applications);

      expect(applications.first.empresa, equals('B'));
    });
  });
}

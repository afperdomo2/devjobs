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

    test('el flag Por gestionar no altera el orden', () {
      final applications = [
        app(
          rowIndex: 1,
          empresa: 'Pendiente antigua',
          porGestionar: true,
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
        equals(['Reciente', 'Pendiente antigua']),
      );
    });

    test('ordena por última novedad descendente', () {
      final applications = [
        app(
          rowIndex: 1,
          empresa: 'Antigua',
          fechaPostulacion: '01/01/2026',
          fechaSeguimiento: '02/01/2026',
        ),
        app(
          rowIndex: 2,
          empresa: 'Reciente',
          fechaPostulacion: '10/01/2026',
        ),
        app(
          rowIndex: 3,
          empresa: 'Media',
          fechaPostulacion: '03/01/2026',
          fechaSeguimiento: '05/01/2026',
        ),
      ];

      final sorted = sortApplications(applications);
      expect(
        sorted.map((application) => application.empresa).toList(),
        equals(['Reciente', 'Media', 'Antigua']),
      );
    });

    test('un seguimiento viejo no supera a una postulación más reciente', () {
      final applications = [
        app(
          rowIndex: 1,
          empresa: 'Con seguimiento',
          fechaPostulacion: '01/01/2026',
          fechaSeguimiento: '01/02/2026',
        ),
        app(
          rowIndex: 2,
          empresa: 'Postulación nueva',
          fechaPostulacion: '01/10/2026',
        ),
      ];

      final sorted = sortApplications(applications);
      expect(sorted.first.empresa, equals('Postulación nueva'));
    });

    test('el seguimiento manda sobre la postulación si es más reciente', () {
      final applications = [
        app(
          rowIndex: 1,
          empresa: 'Nueva sin seguimiento',
          fechaPostulacion: '10/01/2026',
        ),
        app(
          rowIndex: 2,
          empresa: 'Seguimiento reciente',
          fechaPostulacion: '01/01/2026',
          fechaSeguimiento: '20/01/2026',
        ),
      ];

      final sorted = sortApplications(applications);
      expect(sorted.first.empresa, equals('Seguimiento reciente'));
    });

    test('desempata por rowIndex ascendente', () {
      final applications = [
        app(rowIndex: 5, empresa: 'Fila 5', fechaPostulacion: '10/01/2026'),
        app(rowIndex: 2, empresa: 'Fila 2', fechaPostulacion: '10/01/2026'),
        app(rowIndex: 3, empresa: 'Fila 3', fechaPostulacion: '10/01/2026'),
      ];

      final sorted = sortApplications(applications);
      expect(
        sorted.map((application) => application.empresa).toList(),
        equals(['Fila 2', 'Fila 3', 'Fila 5']),
      );
    });

    test('las postulaciones sin fecha válida quedan al final', () {
      final applications = [
        app(rowIndex: 1, empresa: 'Sin fecha'),
        app(
          rowIndex: 2,
          empresa: 'Con fecha',
          fechaPostulacion: '10/01/2026',
        ),
        app(
          rowIndex: 3,
          empresa: 'Fecha inválida',
          fechaPostulacion: '31/02/2026',
        ),
      ];

      final sorted = sortApplications(applications);
      expect(sorted.first.empresa, equals('Con fecha'));
      expect(
        sorted.map((application) => application.empresa).skip(1),
        equals(['Sin fecha', 'Fecha inválida']),
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

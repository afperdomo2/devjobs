import 'package:devjobs/helpers/platform_stats.dart';
import 'package:devjobs/models/job_application.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  JobApplication app({
    required int row,
    String link = '',
    String fechaPostulacion = '',
  }) {
    return JobApplication(
      rowIndex: row,
      link: link,
      fechaPostulacion: fechaPostulacion,
    );
  }

  group('platformsStats', () {
    test('agrupa por plataforma y toma la última aplicación', () {
      final stats = platformsStats([
        app(
          row: 1,
          link: 'https://www.linkedin.com/jobs/view/111',
          fechaPostulacion: '15/10/2026',
        ),
        app(
          row: 2,
          link: 'https://co.linkedin.com/jobs/view/222',
          fechaPostulacion: '20/10/2026',
        ),
        app(
          row: 3,
          link: 'https://www.computrabajo.com.co/ofertas/333',
          fechaPostulacion: '01/09/2026',
        ),
      ]);

      expect(stats.length, 2);
      // Orden por volumen (descendente).
      expect(stats.first.nombre, 'Linkedin');
      expect(stats.first.total, 2);
      expect(stats.first.ultimaPostulacion, DateTime(2026, 10, 20));
      expect(stats.last.nombre, 'Computrabajo');
      expect(stats.last.total, 1);
      expect(stats.last.ultimaPostulacion, DateTime(2026, 9, 1));
    });

    test('ignora postulaciones sin enlace', () {
      final stats = platformsStats([
        app(row: 1),
        app(row: 2, link: '   ', fechaPostulacion: '01/10/2026'),
        app(
          row: 3,
          link: 'https://www.linkedin.com/jobs/view/1',
          fechaPostulacion: '02/10/2026',
        ),
      ]);

      expect(stats.length, 1);
      expect(stats.single.nombre, 'Linkedin');
      expect(stats.single.total, 1);
    });

    test('plataforma sin fechas queda con ultimaPostulacion null', () {
      final stats = platformsStats([
        app(row: 1, link: 'https://www.linkedin.com/jobs/view/1'),
        app(
          row: 2,
          link: 'https://www.linkedin.com/jobs/view/2',
          fechaPostulacion: '',
        ),
      ]);

      expect(stats.length, 1);
      expect(stats.single.total, 2);
      expect(stats.single.ultimaPostulacion, isNull);
      expect(stats.single.diasDesdeUltima(DateTime(2026, 11, 5)), isNull);
    });

    test('lista vacía devuelve lista vacía', () {
      expect(platformsStats([]), isEmpty);
    });
  });

  group('sortPlatforms', () {
    final platforms = [
      const PlatformStats(
        nombre: 'Linkedin',
        total: 1,
        ultimaPostulacion: null,
      ),
      PlatformStats(
        nombre: 'Computrabajo',
        total: 2,
        ultimaPostulacion: DateTime(2026, 10, 10),
      ),
      PlatformStats(
        nombre: 'Elempleo',
        total: 1,
        ultimaPostulacion: DateTime(2026, 10, 20),
      ),
      PlatformStats(
        nombre: 'Indeed',
        total: 2,
        ultimaPostulacion: DateTime(2026, 10, 1),
      ),
    ];

    List<String> names(PlatformSortMode mode) =>
        sortPlatforms(platforms, mode).map((p) => p.nombre).toList();

    test('total: más postulaciones y desempate alfabético', () {
      // Computrabajo e Indeed tienen 2; desempatan alfabéticamente.
      // Linkedin queda entre los de 1 y Elempleo, y la fecha null va al final
      // dentro del desempate por total.
      expect(names(PlatformSortMode.total), [
        'Computrabajo',
        'Indeed',
        'Elempleo',
        'Linkedin',
      ]);
    });

    test('recent: última aplicación más reciente primero', () {
      expect(names(PlatformSortMode.recent), [
        'Elempleo',
        'Computrabajo',
        'Indeed',
        'Linkedin',
      ]);
    });

    test(
      'oldest: última aplicación más antigua primero y sin fecha al final',
      () {
        expect(names(PlatformSortMode.oldest), [
          'Indeed',
          'Computrabajo',
          'Elempleo',
          'Linkedin',
        ]);
      },
    );
  });
}

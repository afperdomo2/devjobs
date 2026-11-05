import 'package:devjobs/helpers/company_stats.dart';
import 'package:devjobs/models/job_application.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  String fmt(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  final now = DateTime.now();
  final hoy = DateTime(now.year, now.month, now.day);
  String daysAgo(int n) => fmt(DateTime(now.year, now.month, now.day - n));

  group('companiesStats', () {
    test('lista vacía retorna lista vacía', () {
      expect(companiesStats([]), isEmpty);
    });

    test('agrupa por empresa y cuenta total/activas/finalizadas', () {
      final apps = [
        JobApplication(
            rowIndex: 1,
            empresa: 'Acme',
            estado: 'Enviada',
            fechaPostulacion: daysAgo(5)),
        JobApplication(
            rowIndex: 2,
            empresa: 'Acme',
            estado: 'Rechazada',
            fechaPostulacion: daysAgo(10),
            fechaSeguimiento: daysAgo(4)),
        JobApplication(
            rowIndex: 3,
            empresa: ' Globotech ',
            estado: 'Aceptada',
            fechaPostulacion: daysAgo(8),
            fechaSeguimiento: daysAgo(6)),
        JobApplication(
            rowIndex: 4,
            empresa: 'Acme',
            estado: 'En revisión',
            fechaPostulacion: daysAgo(2)),
      ];
      final stats = companiesStats(apps);
      expect(stats.length, equals(2));

      final acme = stats.firstWhere((s) => s.nombre == 'Acme');
      expect(acme.total, equals(3));
      expect(acme.activas, equals(2));
      expect(acme.finalizadas, equals(1));

      // El nombre se trimmea.
      final globo = stats.firstWhere((s) => s.nombre == 'Globotech');
      expect(globo.total, equals(1));
      expect(globo.finalizadas, equals(1));
    });

    test('agrupa variantes de mayúsculas/espacios y usa el nombre más frecuente',
        () {
      final apps = [
        JobApplication(rowIndex: 1, empresa: 'Acme', estado: 'Enviada'),
        JobApplication(rowIndex: 2, empresa: 'ACME', estado: 'Enviada'),
        JobApplication(rowIndex: 3, empresa: ' acme ', estado: 'Enviada'),
        JobApplication(rowIndex: 4, empresa: 'Acme', estado: 'Rechazada'),
      ];
      final stats = companiesStats(apps);
      expect(stats.length, equals(1));
      expect(stats.first.total, equals(4));
      expect(stats.first.nombre, equals('Acme'));
    });

    test('empate de variantes elige el nombre que ordena primero', () {
      final apps = [
        JobApplication(rowIndex: 1, empresa: 'Zeta', estado: 'Enviada'),
        JobApplication(rowIndex: 2, empresa: 'zeta', estado: 'Enviada'),
      ];
      final stats = companiesStats(apps);
      expect(stats.length, equals(1));
      expect(stats.first.nombre, equals('Zeta'));
    });

    test('ordena por total desc; empate se resuelve alfabético', () {
      final apps = [
        JobApplication(rowIndex: 1, empresa: 'Zeta', estado: 'Enviada'),
        JobApplication(rowIndex: 2, empresa: 'Beta', estado: 'Enviada'),
        JobApplication(rowIndex: 3, empresa: 'Alpha', estado: 'Enviada'),
        JobApplication(rowIndex: 4, empresa: 'Beta', estado: 'Enviada'),
      ];
      final names = companiesStats(apps).map((s) => s.nombre).toList();
      expect(names, equals(['Beta', 'Alpha', 'Zeta']));
    });

    test('ignora empresas vacías o con solo espacios', () {
      final apps = [
        JobApplication(rowIndex: 1, empresa: '', estado: 'Enviada'),
        JobApplication(rowIndex: 2, empresa: '   ', estado: 'Enviada'),
        JobApplication(rowIndex: 3, empresa: 'Acme', estado: 'Enviada'),
      ];
      expect(companiesStats(apps).length, equals(1));
    });

    test('promedioDias: solo finalizadas con seguimiento aportan', () {
      final apps = [
        // Finalizada con duración 4 (postulación hace 8, novedad hace 4).
        JobApplication(
            rowIndex: 1,
            empresa: 'Acme',
            estado: 'Rechazada',
            fechaPostulacion: daysAgo(8),
            fechaSeguimiento: daysAgo(4)),
        // Finalizada sin seguimiento → excluida del promedio.
        JobApplication(
            rowIndex: 2,
            empresa: 'Acme',
            estado: 'Retirada',
            fechaPostulacion: daysAgo(6)),
        // Activa con seguimiento → excluida del promedio.
        JobApplication(
            rowIndex: 3,
            empresa: 'Acme',
            estado: 'En revisión',
            fechaPostulacion: daysAgo(9),
            fechaSeguimiento: daysAgo(1)),
      ];
      expect(companiesStats(apps).first.promedioDias, equals(4));
    });

    test('promedioDias null si no hay finalizadas con seguimiento', () {
      final apps = [
        JobApplication(
            rowIndex: 1,
            empresa: 'Acme',
            estado: 'Enviada',
            fechaPostulacion: daysAgo(3)),
      ];
      expect(companiesStats(apps).first.promedioDias, isNull);
    });

    test('conNovedad cuenta estados con respuesta, no la fecha de seguimiento',
        () {
      final apps = [
        JobApplication(
            rowIndex: 1,
            empresa: 'Acme',
            estado: 'En revisión',
            fechaPostulacion: daysAgo(5)),
        JobApplication(
            rowIndex: 2,
            empresa: 'Acme',
            estado: 'Rechazada',
            fechaPostulacion: daysAgo(5)),
        JobApplication(
            rowIndex: 3,
            empresa: 'Acme',
            estado: 'Aceptada',
            fechaPostulacion: daysAgo(5)),
        // Tiene seguimiento, pero el estado sigue sin respuesta.
        JobApplication(
            rowIndex: 4,
            empresa: 'Acme',
            estado: 'Enviada',
            fechaPostulacion: daysAgo(5),
            fechaSeguimiento: daysAgo(2)),
        // Tiene seguimiento, pero no hubo respuesta de la empresa.
        JobApplication(
            rowIndex: 5,
            empresa: 'Acme',
            estado: 'Sin respuesta',
            fechaPostulacion: daysAgo(5),
            fechaSeguimiento: daysAgo(2)),
        JobApplication(
            rowIndex: 6,
            empresa: 'Acme',
            estado: 'Retirada',
            fechaPostulacion: daysAgo(5)),
      ];
      expect(companiesStats(apps).first.conNovedad, equals(3));
    });

    test('entrevistas y porGestionar cuentan por empresa', () {
      final apps = [
        JobApplication(
            rowIndex: 1,
            empresa: 'Acme',
            estado: 'Entrevista realizada',
            entrevistaRealizada: true,
            porGestionar: true),
        JobApplication(
            rowIndex: 2,
            empresa: 'Acme',
            estado: 'Entrevista agendada',
            entrevistaRealizada: true),
        JobApplication(rowIndex: 3, empresa: 'Acme', estado: 'Enviada'),
        JobApplication(
            rowIndex: 4,
            empresa: 'Otra',
            estado: 'Enviada',
            porGestionar: true),
      ];
      final stats = companiesStats(apps);

      final acme = stats.firstWhere((s) => s.nombre == 'Acme');
      expect(acme.entrevistas, equals(2));
      expect(acme.porGestionar, equals(1));

      final otra = stats.firstWhere((s) => s.nombre == 'Otra');
      expect(otra.entrevistas, equals(0));
      expect(otra.porGestionar, equals(1));
    });

    test('sortCompanies ordena por los cinco criterios', () {
      CompanyStats company({
        required String nombre,
        int total = 1,
        int activas = 0,
        int entrevistas = 0,
        int conNovedad = 0,
        DateTime? ultima,
      }) {
        return CompanyStats(
          nombre: nombre,
          total: total,
          activas: activas,
          finalizadas: 0,
          conNovedad: conNovedad,
          entrevistas: entrevistas,
          porGestionar: 0,
          ultimaPostulacion: ultima,
        );
      }

      final companies = [
        company(
          nombre: 'A',
          total: 2,
          activas: 1,
          entrevistas: 2,
          conNovedad: 1,
          ultima: hoy.subtract(const Duration(days: 1)),
        ),
        company(
          nombre: 'B',
          total: 3,
          activas: 3,
          entrevistas: 0,
          conNovedad: 2,
          ultima: hoy.subtract(const Duration(days: 5)),
        ),
        company(
          nombre: 'C',
          total: 5,
          activas: 2,
          entrevistas: 1,
          conNovedad: 4,
        ),
      ];

      String names(CompanySortMode mode) => sortCompanies(companies, mode)
          .map((company) => company.nombre)
          .join(',');

      expect(names(CompanySortMode.total), equals('C,B,A'));
      expect(names(CompanySortMode.activas), equals('B,C,A'));
      expect(names(CompanySortMode.entrevistas), equals('A,C,B'));
      expect(names(CompanySortMode.responseRate), equals('C,B,A'));
      expect(names(CompanySortMode.recent), equals('A,B,C'));
    });

    test('sortCompanies no modifica la lista original', () {
      final a = CompanyStats(
        nombre: 'A',
        total: 1,
        activas: 0,
        finalizadas: 0,
        conNovedad: 0,
        entrevistas: 0,
        porGestionar: 0,
      );
      final b = CompanyStats(
        nombre: 'B',
        total: 2,
        activas: 0,
        finalizadas: 0,
        conNovedad: 0,
        entrevistas: 0,
        porGestionar: 0,
      );
      final companies = [a, b];

      sortCompanies(companies, CompanySortMode.total);

      expect(companies.first.nombre, equals('A'));
    });

    test('ultimaPostulacion toma la más reciente; null si no hay fechas', () {
      final apps = [
        JobApplication(
            rowIndex: 1,
            empresa: 'Acme',
            estado: 'Enviada',
            fechaPostulacion: daysAgo(9)),
        JobApplication(
            rowIndex: 2,
            empresa: 'Acme',
            estado: 'Enviada',
            fechaPostulacion: daysAgo(1)),
        JobApplication(rowIndex: 3, empresa: 'Otra', estado: 'Enviada'),
      ];
      final stats = companiesStats(apps);

      final acme = stats.firstWhere((s) => s.nombre == 'Acme');
      expect(acme.ultimaPostulacion, isNotNull);
      expect(acme.ultimaPostulacion!.day,
          equals(hoy.subtract(const Duration(days: 1)).day));

      expect(stats.firstWhere((s) => s.nombre == 'Otra').ultimaPostulacion,
          isNull);
    });
  });
}

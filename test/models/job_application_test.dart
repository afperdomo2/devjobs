import 'package:devjobs/models/job_application.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('es');
  });

  group('JobApplication.fromJson / toJson / copyWith', () {
    final json = {
      '_rowIndex': 5,
      'empresa': 'Acme',
      'vacante': 'Flutter Dev',
      'tipoContrato': 'Tiempo completo',
      'modalidad': 'Remoto',
      'ciudad': 'Bogotá',
      'salarioOfrecido': '6500000',
      'estado': 'En revisión',
      'link': 'https://www.linkedin.com/jobs/123',
      'descripcion': 'Desc',
      'fechaPostulacion': '02/06/2026',
      'fechaSeguimiento': '12/06/2026',
      'contacto': 'Ana',
      'comentarios': 'Nota',
      'entrevistaRealizada': 'true',
    };

    test('fromJson mapea campos correctamente', () {
      final app = JobApplication.fromJson(json);
      expect(app.rowIndex, equals(5));
      expect(app.empresa, equals('Acme'));
      expect(app.vacante, equals('Flutter Dev'));
      expect(app.tipoContrato, equals('Tiempo completo'));
      expect(app.modalidad, equals('Remoto'));
      expect(app.ciudad, equals('Bogotá'));
      expect(app.salarioOfrecido, equals('6500000'));
      expect(app.estado, equals('En revisión'));
      expect(app.link, equals('https://www.linkedin.com/jobs/123'));
      expect(app.descripcion, equals('Desc'));
      expect(app.fechaPostulacion, equals('02/06/2026'));
      expect(app.fechaSeguimiento, equals('12/06/2026'));
      expect(app.contacto, equals('Ana'));
      expect(app.comentarios, equals('Nota'));
      expect(app.entrevistaRealizada, isTrue);
    });

    test('entrevistaRealizada insensible a mayúsculas y faltante', () {
      expect(
          JobApplication.fromJson({'entrevistaRealizada': 'TRUE'}).entrevistaRealizada,
          isTrue);
      expect(
          JobApplication.fromJson({'entrevistaRealizada': 'false'}).entrevistaRealizada,
          isFalse);
      expect(
          JobApplication.fromJson({'entrevistaRealizada': 'FALSE'}).entrevistaRealizada,
          isFalse);
      expect(JobApplication.fromJson({}).entrevistaRealizada, isFalse);
    });

    test('toJson round-trip conserva campos relevantes', () {
      final app = JobApplication.fromJson(json);
      final out = app.toJson();
      expect(out['empresa'], equals('Acme'));
      expect(out['estado'], equals('En revisión'));
      expect(out['entrevistaRealizada'], equals(true));
      expect(out['_rowIndex'], equals(5));
    });

    test('copyWith sobrescribe solo campos indicados', () {
      const base = JobApplication(empresa: 'A', vacante: 'V', rowIndex: 1);
      final copy = base.copyWith(vacante: 'Nuevo', estado: 'Enviada');
      expect(copy.empresa, equals('A'));
      expect(copy.vacante, equals('Nuevo'));
      expect(copy.estado, equals('Enviada'));
      expect(copy.rowIndex, equals(1));
    });
  });

  group('JobApplication getters', () {
    test('diasProceso: diferencia entre postulacion y seguimiento', () {
      const app = JobApplication(
        rowIndex: 1,
        fechaPostulacion: '02/06/2026',
        fechaSeguimiento: '12/06/2026',
      );
      expect(app.diasProceso, equals(10));
    });

    test('diasProceso null si falta alguna fecha', () {
      const a = JobApplication(rowIndex: 1, fechaPostulacion: '02/06/2026');
      expect(a.diasProceso, isNull);
      const b = JobApplication(rowIndex: 1);
      expect(b.diasProceso, isNull);
    });

    test('plataforma extrae dominio friendly', () {
      const app = JobApplication(
        rowIndex: 1,
        link: 'https://co.computrabajo.com/empleo/123',
      );
      expect(app.plataforma, equals('Computrabajo'));
    });

    test('plataforma vacía si link vacío', () {
      const app = JobApplication(rowIndex: 1, link: '');
      expect(app.plataforma, equals(''));
    });
  });

  group('DashboardStats', () {
    test('fromJson mapea campos', () {
      final s = DashboardStats.fromJson({
        'total': 10,
        'activas': 6,
        'entrevistas': 2,
        'rechazadas': 3,
      });
      expect(s.total, equals(10));
      expect(s.activas, equals(6));
      expect(s.entrevistas, equals(2));
      expect(s.rechazadas, equals(3));
    });

    test('valores por defecto 0 si ausentes', () {
      const s = DashboardStats(total: 0, activas: 0, entrevistas: 0, rechazadas: 0);
      expect(s.total, equals(0));
    });
  });
}

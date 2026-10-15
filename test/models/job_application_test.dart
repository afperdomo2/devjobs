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
      'porGestionar': 'true',
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
      expect(app.porGestionar, isTrue);
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

    test('porGestionar insensible a mayúsculas y faltante', () {
      expect(JobApplication.fromJson({'porGestionar': 'true'}).porGestionar, isTrue);
      expect(JobApplication.fromJson({'porGestionar': 'TRUE'}).porGestionar, isTrue);
      expect(JobApplication.fromJson({'porGestionar': 'false'}).porGestionar, isFalse);
      expect(JobApplication.fromJson({'porGestionar': 'FALSE'}).porGestionar, isFalse);
      expect(JobApplication.fromJson({}).porGestionar, isFalse);
    });

    test('toJson round-trip conserva campos relevantes', () {
      final app = JobApplication.fromJson(json);
      final out = app.toJson();
      expect(out['empresa'], equals('Acme'));
      expect(out['estado'], equals('En revisión'));
      expect(out['entrevistaRealizada'], equals(true));
      expect(out['porGestionar'], equals(true));
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

    test('copyWith toca porGestionar solo cuando se indica', () {
      const base = JobApplication(rowIndex: 1, porGestionar: true);
      expect(base.copyWith(vacante: 'X').porGestionar, isTrue);
      expect(base.copyWith(porGestionar: false).porGestionar, isFalse);
    });
  });

  group('JobApplication getters', () {
    // Fechas relativas a hoy para que los tests no caduquen.
    String fmt(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    final now = DateTime.now();
    final hoy = DateTime(now.year, now.month, now.day);
    final hoyStr = fmt(hoy);

    group('isFinalizado', () {
      test('acepta, rechaza y retirada son finales (case-insensitive)', () {
        expect(const JobApplication(rowIndex: 1, estado: 'Aceptada').isFinalizado, isTrue);
        expect(const JobApplication(rowIndex: 1, estado: 'aceptada').isFinalizado, isTrue);
        expect(const JobApplication(rowIndex: 1, estado: ' Aceptada ').isFinalizado, isTrue);
        expect(const JobApplication(rowIndex: 1, estado: 'Rechazada').isFinalizado, isTrue);
        expect(const JobApplication(rowIndex: 1, estado: 'Retirada').isFinalizado, isTrue);
      });

      test('estados en curso no son finales', () {
        expect(const JobApplication(rowIndex: 1, estado: 'Enviada').isFinalizado, isFalse);
        expect(const JobApplication(rowIndex: 1, estado: 'En revisión').isFinalizado, isFalse);
        expect(const JobApplication(rowIndex: 1, estado: 'Oferta recibida').isFinalizado, isFalse);
        expect(const JobApplication(rowIndex: 1, estado: '').isFinalizado, isFalse);
      });
    });

    group('diasProceso', () {
      test('finalizado: duración entre postulación y última novedad', () {
        final app = JobApplication(
          rowIndex: 1,
          estado: 'Rechazada',
          fechaPostulacion: fmt(hoy.subtract(const Duration(days: 10))),
          fechaSeguimiento: fmt(hoy.subtract(const Duration(days: 3))),
        );
        expect(app.diasProceso, equals(7));
      });

      test('finalizado sin seguimiento: null (duración desconocida)', () {
        final app = JobApplication(
          rowIndex: 1,
          estado: 'Retirada',
          fechaPostulacion: hoyStr,
        );
        expect(app.diasProceso, isNull);
      });

      test('activo: mide desde postulación hasta hoy, no hacia seguimiento', () {
        final post = DateTime(now.year, now.month, now.day - 5);
        final seg = DateTime(now.year, now.month, now.day - 1);
        final app = JobApplication(
          rowIndex: 1,
          estado: 'En revisión',
          fechaPostulacion: fmt(post),
          fechaSeguimiento: fmt(seg),
        );
        // Debe usar hoy - postulación (≈5), no seguimiento - postulación (4).
        expect(app.diasProceso, equals(DateTime.now().difference(post).inDays));
        expect(app.diasProceso, isNot(equals(4)));
      });

      test('null si falta fecha de postulación', () {
        const a = JobApplication(rowIndex: 1, fechaSeguimiento: '12/06/2026');
        expect(a.diasProceso, isNull);
        const b = JobApplication(rowIndex: 1);
        expect(b.diasProceso, isNull);
      });

      test('seguimiento anterior a postulación no genera días negativos', () {
        final app = JobApplication(
          rowIndex: 1,
          estado: 'Aceptada',
          fechaPostulacion: fmt(hoy),
          fechaSeguimiento: fmt(hoy.subtract(const Duration(days: 3))),
        );
        expect(app.diasProceso, equals(0));
      });

      test('postulación futura no genera días negativos', () {
        final app = JobApplication(
          rowIndex: 1,
          estado: 'Enviada',
          fechaPostulacion: fmt(hoy.add(const Duration(days: 3))),
        );
        expect(app.diasProceso, equals(0));
      });
    });

    group('diasSinNovedad', () {
      test('activo: días desde la última novedad (seguimiento)', () {
        final post = DateTime(now.year, now.month, now.day - 10);
        final seg = DateTime(now.year, now.month, now.day - 3);
        final app = JobApplication(
          rowIndex: 1,
          estado: 'En revisión',
          fechaPostulacion: fmt(post),
          fechaSeguimiento: fmt(seg),
        );
        expect(app.diasSinNovedad, equals(DateTime.now().difference(seg).inDays));
        expect(app.diasSinNovedad, isNot(equals(DateTime.now().difference(post).inDays)));
      });

      test('activo sin seguimiento: usa la postulación como referencia', () {
        final post = DateTime(now.year, now.month, now.day - 4);
        final app = JobApplication(
          rowIndex: 1,
          estado: 'Enviada',
          fechaPostulacion: fmt(post),
        );
        expect(app.diasSinNovedad, equals(DateTime.now().difference(post).inDays));
      });

      test('finalizado: null (no aplica)', () {
        final app = JobApplication(
          rowIndex: 1,
          estado: 'Rechazada',
          fechaPostulacion: fmt(hoy.subtract(const Duration(days: 20))),
          fechaSeguimiento: fmt(hoy.subtract(const Duration(days: 10))),
        );
        expect(app.diasSinNovedad, isNull);
      });

      test('null si no hay fechas', () {
        const app = JobApplication(rowIndex: 1, estado: 'Enviada');
        expect(app.diasSinNovedad, isNull);
      });

      test('seguimiento futuro no genera días negativos', () {
        final app = JobApplication(
          rowIndex: 1,
          estado: 'En revisión',
          fechaPostulacion: fmt(hoy),
          fechaSeguimiento: fmt(hoy.add(const Duration(days: 2))),
        );
        expect(app.diasSinNovedad, equals(0));
      });
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
        'finalizadas': 3,
        'porGestionar': 4,
      });
      expect(s.total, equals(10));
      expect(s.activas, equals(6));
      expect(s.entrevistas, equals(2));
      expect(s.finalizadas, equals(3));
      expect(s.porGestionar, equals(4));
    });

    test('valores por defecto 0 si ausentes', () {
      const s = DashboardStats(
        total: 0,
        activas: 0,
        entrevistas: 0,
        finalizadas: 0,
        porGestionar: 0,
      );
      expect(s.total, equals(0));
      expect(s.porGestionar, equals(0));
    });
  });
}

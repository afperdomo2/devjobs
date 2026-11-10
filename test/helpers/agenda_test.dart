import 'package:devjobs/helpers/agenda.dart';
import 'package:devjobs/models/job_application.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  JobApplication app({
    int rowIndex = 1,
    String empresa = 'Acme',
    String estado = 'En revisión',
    bool porGestionar = false,
    String fechaPostulacion = '',
    String fechaSeguimiento = '',
  }) {
    return JobApplication(
      rowIndex: rowIndex,
      empresa: empresa,
      estado: estado,
      porGestionar: porGestionar,
      fechaPostulacion: fechaPostulacion,
      fechaSeguimiento: fechaSeguimiento,
    );
  }

  group('isInAgendaSection', () {
    test('Por gestionar tiene prioridad sobre las demás secciones', () {
      final application = app(
        estado: 'Entrevista agendada',
        porGestionar: true,
      );

      expect(
        isInAgendaSection(application, AgendaSectionKind.porGestionar),
        isTrue,
      );
      expect(
        isInAgendaSection(
          application,
          AgendaSectionKind.entrevistaAgendada,
        ),
        isFalse,
      );
    });

    test('detecta entrevista agendada y oferta recibida', () {
      final interview = app(estado: 'Entrevista agendada');
      final offer = app(estado: 'Oferta recibida');

      expect(
        isInAgendaSection(interview, AgendaSectionKind.entrevistaAgendada),
        isTrue,
      );
      expect(
        isInAgendaSection(interview, AgendaSectionKind.ofertaRecibida),
        isFalse,
      );
      expect(
        isInAgendaSection(offer, AgendaSectionKind.ofertaRecibida),
        isTrue,
      );
      expect(
        isInAgendaSection(offer, AgendaSectionKind.entrevistaAgendada),
        isFalse,
      );
    });

    test('ignora entrevistas realizadas, rechazadas y estados normales', () {
      for (final estado in [
        'Entrevista realizada',
        'Rechazada',
        'En revisión',
        'Enviada',
      ]) {
        final application = app(estado: estado);
        for (final kind in AgendaSectionKind.values) {
          expect(
            isInAgendaSection(application, kind),
            isFalse,
            reason: '$estado no debería estar en $kind',
          );
        }
      }
    });

    test('las finalizadas no entran en entrevista ni oferta', () {
      expect(
        isInAgendaSection(
          app(estado: 'Aceptada'),
          AgendaSectionKind.ofertaRecibida,
        ),
        isFalse,
      );
      expect(
        isInAgendaSection(
          app(estado: 'Rechazada'),
          AgendaSectionKind.entrevistaAgendada,
        ),
        isFalse,
      );
    });

    test('una finalizada marcada Por gestionar sí aparece', () {
      expect(
        isInAgendaSection(
          app(estado: 'Aceptada', porGestionar: true),
          AgendaSectionKind.porGestionar,
        ),
        isTrue,
      );
    });

    test('ignora mayúsculas y tildes', () {
      expect(
        isInAgendaSection(
          app(estado: 'ENTREVISTA AGENDADA'),
          AgendaSectionKind.entrevistaAgendada,
        ),
        isTrue,
      );
      expect(
        isInAgendaSection(
          app(estado: 'OFERTA RECIBIDA'),
          AgendaSectionKind.ofertaRecibida,
        ),
        isTrue,
      );
    });
  });

  group('agendaSections', () {
    test('devuelve las tres secciones en orden', () {
      final sections = agendaSections([
        app(rowIndex: 1, estado: 'En revisión', porGestionar: true),
        app(rowIndex: 2, estado: 'Entrevista agendada'),
        app(rowIndex: 3, estado: 'Oferta recibida'),
        app(rowIndex: 4, estado: 'En revisión'),
      ]);

      expect(sections.length, equals(3));
      expect(sections[0].kind, equals(AgendaSectionKind.porGestionar));
      expect(sections[0].applications.length, equals(1));
      expect(sections[1].kind, equals(AgendaSectionKind.entrevistaAgendada));
      expect(sections[1].applications.length, equals(1));
      expect(sections[2].kind, equals(AgendaSectionKind.ofertaRecibida));
      expect(sections[2].applications.length, equals(1));
    });

    test('ordena cada sección por última novedad', () {
      final sections = agendaSections([
        app(
          rowIndex: 1,
          empresa: 'Antigua',
          porGestionar: true,
          fechaPostulacion: '01/01/2026',
        ),
        app(
          rowIndex: 2,
          empresa: 'Reciente',
          porGestionar: true,
          fechaPostulacion: '10/01/2026',
        ),
      ]);

      expect(
        sections.first.applications.map((application) => application.empresa),
        equals(['Reciente', 'Antigua']),
      );
    });

    test('lista vacía devuelve secciones vacías', () {
      final sections = agendaSections([]);
      expect(sections.length, equals(3));
      expect(sections.every((section) => section.applications.isEmpty), isTrue);
    });
  });

  group('agendaCount', () {
    test('cuenta sin duplicar entre secciones', () {
      expect(
        agendaCount([
          app(rowIndex: 1, porGestionar: true),
          app(rowIndex: 2, estado: 'Entrevista agendada'),
          app(rowIndex: 3, estado: 'Oferta recibida'),
          app(rowIndex: 4, estado: 'En revisión'),
        ]),
        equals(3),
      );
      expect(agendaCount([]), equals(0));
    });

    test('una postulación marcada y con oferta cuenta una vez', () {
      expect(
        agendaCount([
          app(
            rowIndex: 1,
            estado: 'Oferta recibida',
            porGestionar: true,
          ),
        ]),
        equals(1),
      );
    });
  });

  test('agendaSectionTitle devuelve los títulos visibles', () {
    expect(
      agendaSectionTitle(AgendaSectionKind.porGestionar),
      equals('Por gestionar'),
    );
    expect(
      agendaSectionTitle(AgendaSectionKind.entrevistaAgendada),
      equals('Entrevistas agendadas'),
    );
    expect(
      agendaSectionTitle(AgendaSectionKind.ofertaRecibida),
      equals('Ofertas recibidas'),
    );
  });
}

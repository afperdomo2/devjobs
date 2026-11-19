import 'package:devjobs/helpers/company_analysis.dart';
import 'package:devjobs/models/company_insight.dart';
import 'package:devjobs/models/job_application.dart';
import 'package:flutter_test/flutter_test.dart';

JobApplication app({
  int rowIndex = 1,
  String estado = '',
  String fechaPostulacion = '',
  String fechaSeguimiento = '',
  String comentarios = '',
  String salarioOfrecido = '',
  String link = '',
  bool entrevistaRealizada = false,
  bool porGestionar = false,
}) {
  return JobApplication(
    rowIndex: rowIndex,
    empresa: 'Acme',
    vacante: 'Dev',
    estado: estado,
    fechaPostulacion: fechaPostulacion,
    fechaSeguimiento: fechaSeguimiento,
    comentarios: comentarios,
    salarioOfrecido: salarioOfrecido,
    link: link,
    entrevistaRealizada: entrevistaRealizada,
    porGestionar: porGestionar,
  );
}

void main() {
  final now = DateTime(2026, 11, 19);

  group('companyAnalysisFacts', () {
    test('lista vacía devuelve todo en cero', () {
      final facts = companyAnalysisFacts(const [], now: now);

      expect(facts.total, 0);
      expect(facts.activas, 0);
      expect(facts.finalizadas, 0);
      expect(facts.conRespuesta, 0);
      expect(facts.estancadas, 0);
      expect(facts.notas, 0);
      expect(facts.promedioDiasRespuesta, isNull);
      expect(facts.promedioCierre, isNull);
      expect(facts.salarios, isEmpty);
      expect(facts.plataformas, isEmpty);
      expect(facts.ultimaNovedad, isNull);
    });

    test('cuenta respuestas, entrevistas y notas', () {
      final facts = companyAnalysisFacts(
        [
          app(
            rowIndex: 1,
            estado: 'En revisión',
            fechaPostulacion: '01/11/2026',
            fechaSeguimiento: '05/11/2026',
            comentarios: '- 5/11/2026: Me llamaron\n- 6/11/2026: Entrevista',
          ),
          app(rowIndex: 2, estado: 'Enviada', fechaPostulacion: '02/11/2026'),
          app(
            rowIndex: 3,
            estado: 'Rechazada',
            fechaPostulacion: '01/11/2026',
            fechaSeguimiento: '11/11/2026',
            entrevistaRealizada: true,
            porGestionar: true,
          ),
        ],
        now: now,
      );

      expect(facts.total, 3);
      expect(facts.activas, 2);
      expect(facts.finalizadas, 1);
      expect(facts.conRespuesta, 2); // En revisión + Rechazada
      expect(facts.entrevistas, 1);
      expect(facts.porGestionar, 1);
      expect(facts.notas, 2);
      // (4 + 10) / 2 = 7 días hasta la respuesta.
      expect(facts.promedioDiasRespuesta, 7);
      // Solo la rechazada cuenta para el cierre: 10 días.
      expect(facts.promedioCierre, 10);
    });

    test('marca estancadas las activas sin novedad reciente', () {
      final facts = companyAnalysisFacts(
        [
          // 30 días sin novedad: estancada.
          app(rowIndex: 1, estado: 'Enviada', fechaPostulacion: '20/10/2026'),
          // 2 días: al día.
          app(rowIndex: 2, estado: 'Enviada', fechaPostulacion: '17/11/2026'),
          // Finalizada vieja: nunca cuenta como estancada.
          app(
            rowIndex: 3,
            estado: 'Aceptada',
            fechaPostulacion: '01/01/2026',
            fechaSeguimiento: '05/01/2026',
          ),
        ],
        now: now,
      );

      expect(facts.estancadas, 1);
      expect(facts.ultimaNovedad, DateTime(2026, 11, 17));
    });

    test('agrupa salarios y plataformas; sin enlace queda como "sin enlace"',
        () {
      final facts = companyAnalysisFacts(
        [
          app(
            rowIndex: 1,
            salarioOfrecido: '3.000.000 COP',
            link: 'https://www.linkedin.com/jobs/1',
          ),
          app(
            rowIndex: 2,
            salarioOfrecido: '5.000.000 COP',
            link: 'https://www.linkedin.com/jobs/2',
          ),
          app(rowIndex: 3, salarioOfrecido: 'yo puse 2M'),
        ],
        now: now,
      );

      expect(facts.salarios.length, 1);
      expect(facts.salarios.first.count, 2);
      expect(facts.plataformas, {'Linkedin': 2, 'sin enlace': 1});
    });
  });

  group('ultimaNovedadDe', () {
    test('considera las notas fechadas además de las fechas de la fila', () {
      final apps = [
        app(
          rowIndex: 1,
          estado: 'Enviada',
          fechaPostulacion: '01/11/2026',
          comentarios: '- 15/11/2026: Me escribieron',
        ),
      ];
      expect(ultimaNovedadDe(apps), DateTime(2026, 11, 15));
    });

    test('ignora notas sin fecha y listas vacías', () {
      final apps = [
        app(
          rowIndex: 1,
          estado: 'Enviada',
          fechaPostulacion: '01/11/2026',
          comentarios: '- Pendiente de respuesta',
        ),
      ];
      expect(ultimaNovedadDe(apps), DateTime(2026, 11, 1));
      expect(ultimaNovedadDe(const []), isNull);
    });
  });

  group('isInsightStale', () {
    CompanyInsight insight({
      int totalPostulaciones = 2,
      DateTime? datosAl,
    }) {
      return CompanyInsight(
        empresa: 'Acme',
        totalPostulaciones: totalPostulaciones,
        datosAl: datosAl ?? DateTime(2026, 11, 10),
      );
    }

    final apps = [
      app(rowIndex: 1, estado: 'Enviada', fechaPostulacion: '01/11/2026'),
      app(rowIndex: 2, estado: 'Enviada', fechaPostulacion: '02/11/2026'),
    ];

    test('fresco: mismas postulaciones y sin novedades posteriores', () {
      expect(isInsightStale(insight(), apps), isFalse);
    });

    test('desactualizado con postulaciones nuevas', () {
      expect(
        isInsightStale(
          insight(totalPostulaciones: 1),
          apps,
        ),
        isTrue,
      );
    });

    test('desactualizado con una novedad posterior a datosAl', () {
      final withNews = [
        ...apps,
        app(
          rowIndex: 3,
          estado: 'En revisión',
          fechaPostulacion: '02/11/2026',
          fechaSeguimiento: '12/11/2026',
        ),
      ];
      expect(
        isInsightStale(insight(totalPostulaciones: 3), withNews),
        isTrue,
      );
    });

    test('sin datosAl y con postulaciones se considera desactualizado', () {
      const sinDatosAl = CompanyInsight(empresa: 'Acme', totalPostulaciones: 2);
      expect(isInsightStale(sinDatosAl, apps), isTrue);
    });
  });
}

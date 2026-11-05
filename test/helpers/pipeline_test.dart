import 'package:devjobs/helpers/pipeline.dart';
import 'package:devjobs/models/job_application.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  JobApplication app({
    int rowIndex = 1,
    String empresa = 'Acme',
    String estado = '',
    bool porGestionar = false,
    String fechaPostulacion = '01/01/2026',
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

  group('pipelineStageOf', () {
    test('mapea los estados del pipeline', () {
      expect(pipelineStageOf('Sin respuesta').label, 'Sin respuesta');
      expect(pipelineStageOf('En revisión').label, 'En revisión');
      expect(pipelineStageOf('Prueba técnica').label, 'Prueba técnica');
      expect(pipelineStageOf('Entrevista agendada').label, 'Entrevista');
      expect(pipelineStageOf('Entrevista realizada').label, 'Entrevista');
      expect(pipelineStageOf('Oferta recibida').label, 'Oferta');
      expect(pipelineStageOf('Aceptada').label, 'Aceptada');
      expect(pipelineStageOf('Enviada').label, 'Enviada');
      expect(pipelineStageOf('Rechazada').label, 'Rechazada');
      expect(pipelineStageOf('Retirada').label, 'Retirada');
    });

    test('ignora mayúsculas, tildes y espacios', () {
      expect(pipelineStageOf('  EN REVISIÓN  ').label, 'En revisión');
      expect(pipelineStageOf('prueba tecnica').label, 'Prueba técnica');
      expect(pipelineStageOf('SIN RESPUESTA').label, 'Sin respuesta');
    });

    test('estados vacíos o desconocidos caen en Otros', () {
      expect(pipelineStageOf('').label, 'Otros');
      expect(pipelineStageOf('Estado nuevo').label, 'Otros');
    });
  });

  group('pipelineSegments', () {
    test('lista vacía retorna vacía', () {
      expect(pipelineSegments([]), isEmpty);
    });

    test('cuenta por etapa y respeta el orden', () {
      final applications = [
        app(rowIndex: 1, estado: 'Sin respuesta'),
        app(rowIndex: 2, estado: 'En revisión'),
        app(rowIndex: 3, estado: 'En revisión'),
        app(rowIndex: 4, estado: 'Prueba técnica'),
        app(rowIndex: 5, estado: 'Entrevista realizada'),
        app(rowIndex: 6, estado: 'Oferta recibida'),
        app(rowIndex: 7, estado: 'Aceptada'),
        app(rowIndex: 8, estado: 'Enviada'),
        app(rowIndex: 9, estado: 'Rechazada'),
        app(rowIndex: 10, estado: 'Retirada'),
        app(rowIndex: 11, estado: 'Desconocido'),
      ];

      final segments = pipelineSegments(applications);
      expect(
        segments.map((segment) => segment.$1.label).toList(),
        equals([
          'Sin respuesta',
          'En revisión',
          'Prueba técnica',
          'Entrevista',
          'Oferta',
          'Aceptada',
          'Enviada',
          'Rechazada',
          'Retirada',
          'Otros',
        ]),
      );
      expect(
        segments.firstWhere((segment) => segment.$1.label == 'En revisión').$2,
        equals(2),
      );
      expect(
        segments.firstWhere((segment) => segment.$1.label == 'Otros').$2,
        equals(1),
      );
    });
  });

  group('applicationsInStage', () {
    test('filtra solo la etapa pedida', () {
      final entrevista = pipelineStages.firstWhere(
        (stage) => stage.label == 'Entrevista',
      );
      final applications = [
        app(rowIndex: 1, empresa: 'Entrevista', estado: 'Entrevista realizada'),
        app(rowIndex: 2, empresa: 'Revisión', estado: 'En revisión'),
      ];

      final result = applicationsInStage(applications, entrevista);

      expect(result.length, equals(1));
      expect(result.first.empresa, equals('Entrevista'));
    });

    test('ordena con el criterio general: Por gestionar primero', () {
      final entrevista = pipelineStages.firstWhere(
        (stage) => stage.label == 'Entrevista',
      );
      final applications = [
        app(
          rowIndex: 1,
          empresa: 'Reciente',
          estado: 'Entrevista realizada',
          fechaSeguimiento: '10/01/2026',
        ),
        app(
          rowIndex: 2,
          empresa: 'Pendiente',
          estado: 'Entrevista agendada',
          porGestionar: true,
          fechaSeguimiento: '01/01/2026',
        ),
      ];

      final result = applicationsInStage(applications, entrevista);

      expect(
        result.map((application) => application.empresa).toList(),
        equals(['Pendiente', 'Reciente']),
      );
    });

    test('etapa sin postulaciones retorna vacía', () {
      final etapa = pipelineStages.firstWhere(
        (stage) => stage.label == 'Oferta',
      );

      expect(applicationsInStage([], etapa), isEmpty);
    });
  });

  test('isInPipelineStage compara por etapa', () {
    final entrevista = pipelineStages.firstWhere(
      (stage) => stage.label == 'Entrevista',
    );
    final oferta = pipelineStages.firstWhere(
      (stage) => stage.label == 'Oferta',
    );

    expect(
      isInPipelineStage(
        app(estado: 'Entrevista realizada'),
        entrevista,
      ),
      isTrue,
    );
    expect(
      isInPipelineStage(
        app(estado: 'Oferta recibida'),
        entrevista,
      ),
      isFalse,
    );
    expect(
      isInPipelineStage(
        app(estado: 'Oferta recibida'),
        oferta,
      ),
      isTrue,
    );
  });
}

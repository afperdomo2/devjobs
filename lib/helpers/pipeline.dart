import '../models/job_application.dart';
import 'application_sort.dart';
import 'status.dart';

/// Una etapa del pipeline de postulaciones.
class PipelineStage {
  final String label;
  final bool Function(String normalizedStatus) matches;

  const PipelineStage(this.label, this.matches);
}

/// Etapas en el orden en que se pintan. El orden importa: una variante de
/// estado se queda con la primera etapa que la reconoce.
final List<PipelineStage> pipelineStages = [
  PipelineStage('Sin respuesta', (status) => status == 'sin respuesta'),
  PipelineStage('En revisión', (status) => status.contains('revision')),
  PipelineStage('Prueba técnica', (status) => status.contains('prueba')),
  PipelineStage('Entrevista', (status) => status.contains('entrevista')),
  PipelineStage('Oferta', (status) => status.contains('oferta')),
  PipelineStage('Aceptada', (status) => status == 'aceptada'),
  PipelineStage('Enviada', (status) => status.contains('enviada')),
  PipelineStage('Rechazada', (status) => status.contains('rechazada')),
  PipelineStage('Retirada', (status) => status.contains('retirada')),
  PipelineStage('Otros', (_) => true),
];

/// Etapa que corresponde a un estado, normalizando mayúsculas y tildes.
PipelineStage pipelineStageOf(String status) {
  final normalized = normalizeStatus(status);
  for (final stage in pipelineStages) {
    if (stage.matches(normalized)) return stage;
  }
  return pipelineStages.last;
}

/// Conteo por etapa, en el orden de [pipelineStages] y solo con las presentes.
List<(PipelineStage, int)> pipelineSegments(List<JobApplication> applications) {
  final counts = <String, int>{};
  for (final application in applications) {
    final label = pipelineStageOf(application.estado).label;
    counts[label] = (counts[label] ?? 0) + 1;
  }

  return [
    for (final stage in pipelineStages)
      if (counts.containsKey(stage.label)) (stage, counts[stage.label]!),
  ];
}

bool isInPipelineStage(JobApplication application, PipelineStage stage) {
  return pipelineStageOf(application.estado).label == stage.label;
}

/// Postulaciones de una etapa, ordenadas con el criterio general de la app.
List<JobApplication> applicationsInStage(
  List<JobApplication> applications,
  PipelineStage stage,
) {
  return sortApplications(
    applications.where((application) => isInPipelineStage(application, stage)),
  );
}

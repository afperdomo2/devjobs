import '../models/job_application.dart';
import 'status.dart';

/// Secciones de la pestaña Agenda.
enum AgendaSectionKind {
  porGestionar,
  entrevistaAgendada,
  ofertaRecibida,
}

class AgendaSection {
  final AgendaSectionKind kind;
  final List<JobApplication> applications;

  const AgendaSection({required this.kind, required this.applications});
}

String agendaSectionTitle(AgendaSectionKind kind) {
  return switch (kind) {
    AgendaSectionKind.porGestionar => 'Por gestionar',
    AgendaSectionKind.entrevistaAgendada => 'Entrevistas agendadas',
    AgendaSectionKind.ofertaRecibida => 'Ofertas recibidas',
  };
}

/// Una postulación pertenece a una sola sección, en este orden:
/// Por gestionar > Entrevista agendada > Oferta recibida.
bool isInAgendaSection(JobApplication application, AgendaSectionKind kind) {
  final normalized = normalizeStatus(application.estado);
  final hasGestion = application.porGestionar;
  final hasInterview =
      !application.isFinalizado && isInterviewScheduled(application.estado);
  final hasOffer = !application.isFinalizado && normalized.contains('oferta');

  return switch (kind) {
    AgendaSectionKind.porGestionar => hasGestion,
    AgendaSectionKind.entrevistaAgendada => !hasGestion && hasInterview,
    AgendaSectionKind.ofertaRecibida =>
      !hasGestion && !hasInterview && hasOffer,
  };
}

/// Secciones en el orden de [AgendaSectionKind]. Cada una puede estar vacía.
List<AgendaSection> agendaSections(List<JobApplication> applications) {
  return [
    for (final kind in AgendaSectionKind.values)
      AgendaSection(
        kind: kind,
        applications: applications
            .where((application) => isInAgendaSection(application, kind))
            .toList(),
      ),
  ];
}

/// Cantidad de postulaciones con algo pendiente, sin duplicados.
int agendaCount(List<JobApplication> applications) {
  return applications.where((application) {
    return AgendaSectionKind.values.any(
      (kind) => isInAgendaSection(application, kind),
    );
  }).length;
}

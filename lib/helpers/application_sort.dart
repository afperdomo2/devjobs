import '../models/job_application.dart';
import 'date_formatter.dart';

/// Orden único de postulaciones en toda la app: por última novedad
/// (`fechaSeguimiento` o, si no hay, `fechaPostulacion`) de más reciente a
/// más antigua.
///
/// El flag "Por gestionar" no altera el orden: esas vacantes se ven en la
/// pestaña Agenda. Las postulaciones sin fecha válida quedan al final y el
/// desempate es por `rowIndex` ascendente para que el orden sea estable.
int compareApplications(JobApplication a, JobApplication b) {
  final dateA = parseDate(a.fechaSeguimiento) ?? parseDate(a.fechaPostulacion);
  final dateB = parseDate(b.fechaSeguimiento) ?? parseDate(b.fechaPostulacion);

  if (dateA == null && dateB == null) return a.rowIndex.compareTo(b.rowIndex);
  if (dateA == null) return 1;
  if (dateB == null) return -1;

  final byDate = dateB.compareTo(dateA);
  if (byDate != 0) return byDate;

  return a.rowIndex.compareTo(b.rowIndex);
}

/// Devuelve una copia ordenada con [compareApplications].
List<JobApplication> sortApplications(Iterable<JobApplication> applications) {
  final list = applications.toList()..sort(compareApplications);
  return list;
}

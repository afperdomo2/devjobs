import '../models/job_application.dart';
import 'date_formatter.dart';

/// Orden único de postulaciones en toda la app:
/// 1. Las marcadas "Por gestionar".
/// 2. Las que tienen fecha de seguimiento, de más reciente a más antigua.
/// 3. El resto, por fecha de postulación de más reciente a más antigua.
int compareApplications(JobApplication a, JobApplication b) {
  if (a.porGestionar != b.porGestionar) return a.porGestionar ? -1 : 1;

  final aHasSeguimiento = a.fechaSeguimiento.isNotEmpty;
  final bHasSeguimiento = b.fechaSeguimiento.isNotEmpty;

  if (aHasSeguimiento && !bHasSeguimiento) return -1;
  if (!aHasSeguimiento && bHasSeguimiento) return 1;

  if (aHasSeguimiento && bHasSeguimiento) {
    final bySeguimiento = _compareDateStrings(
      b.fechaSeguimiento,
      a.fechaSeguimiento,
    );
    if (bySeguimiento != 0) return bySeguimiento;
  }

  return _compareDateStrings(b.fechaPostulacion, a.fechaPostulacion);
}

/// Devuelve una copia ordenada con [compareApplications].
List<JobApplication> sortApplications(Iterable<JobApplication> applications) {
  final list = applications.toList()..sort(compareApplications);
  return list;
}

int _compareDateStrings(String a, String b) {
  final dateA = parseDate(a);
  final dateB = parseDate(b);
  if (dateA == null && dateB == null) return 0;
  if (dateA == null) return 1;
  if (dateB == null) return -1;
  return dateA.compareTo(dateB);
}

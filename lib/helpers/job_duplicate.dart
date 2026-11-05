import '../models/job_application.dart';
import 'job_url.dart';

/// Busca una postulación existente con el mismo enlace canónico.
///
/// Solo compara enlaces (alta precisión). La coincidencia por empresa+vacante
/// se deja como aviso blando en el futuro para no bloquear procesos distintos.
JobApplication? findDuplicateByLink(
  List<JobApplication> applications,
  String link,
) {
  final canonical = canonicalJobLink(link);
  if (canonical.isEmpty) return null;

  for (final application in applications) {
    if (application.link.trim().isEmpty) continue;
    if (canonicalJobLink(application.link) == canonical) {
      return application;
    }
  }
  return null;
}

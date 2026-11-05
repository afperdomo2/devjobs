import '../models/job_application.dart';
import 'text_normalizer.dart';

/// Convierte una consulta en tokens normalizados (minúsculas y sin tildes).
///
/// Varias palabras se tratan como una búsqueda AND: todas deben aparecer en
/// algún campo de la postulación, aunque sea en campos distintos.
List<String> searchTokens(String query) {
  return normalizeText(query)
      .split(RegExp(r'\s+'))
      .where((token) => token.isNotEmpty)
      .toList();
}

/// Texto plano con todos los campos que participan en la búsqueda global.
///
/// [JobApplication.plataforma] se deriva del enlace, pero se incluye aparte
/// para que buscar "linkedin" funcione aunque el dominio esté abreviado.
String searchableText(JobApplication application) {
  return [
    application.empresa,
    application.vacante,
    application.tipoContrato,
    application.modalidad,
    application.ciudad,
    application.salarioOfrecido,
    application.estado,
    application.link,
    application.plataforma,
    application.descripcion,
    application.contacto,
    application.comentarios,
  ].map(normalizeText).join(' ');
}

/// true si [application] contiene todos los tokens de [query].
///
/// Una consulta vacía (o con solo espacios) no filtra nada.
bool matchesSearch(JobApplication application, String query) {
  final tokens = searchTokens(query);
  if (tokens.isEmpty) return true;
  final text = searchableText(application);
  return tokens.every(text.contains);
}

/// Filtra [applications] conservando el orden recibido.
List<JobApplication> searchApplications(
  Iterable<JobApplication> applications,
  String query,
) {
  final tokens = searchTokens(query);
  if (tokens.isEmpty) return applications.toList();

  final results = <JobApplication>[];
  for (final application in applications) {
    final text = searchableText(application);
    if (tokens.every(text.contains)) results.add(application);
  }
  return results;
}

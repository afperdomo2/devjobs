import 'offer_link.dart';

const Set<String> _trackingParams = {
  'ref',
  'refid',
  'trk',
  'trackingid',
  'source',
  'src',
  'fbclid',
  'gclid',
  'mc_cid',
  'mc_eid',
  'ittk',
  'fgoa',
  'spm',
  'campaign',
};

/// Normaliza el enlace de una vacante para guardarlo y compararlo.
///
/// - Fuerza `https`, quita `www.`, el fragmento y los parámetros de tracking.
/// - Convierte una búsqueda de LinkedIn con `currentJobId` en el enlace
///   canónico `/jobs/view/<id>`, que sí devuelve la vacante.
String normalizeJobUrl(String raw) {
  final uri = parseOfferUri(raw);
  if (uri == null) return raw.trim();

  var host = uri.host.toLowerCase();
  if (host.startsWith('www.')) host = host.substring(4);

  final path = uri.path.isEmpty ? '/' : uri.path;

  if (host == 'linkedin.com' &&
      (path.contains('/jobs/search') ||
          path.contains('/jobs/search-results'))) {
    final id = uri.queryParameters['currentJobId']?.trim() ?? '';
    if (id.isNotEmpty) {
      return 'https://www.linkedin.com/jobs/view/$id';
    }
  }

  final params = Map<String, String>.from(uri.queryParameters);
  params.removeWhere(
    (key, _) =>
        _trackingParams.contains(key.toLowerCase()) ||
        key.toLowerCase().startsWith('utm_'),
  );

  var normalized = Uri(
    scheme: 'https',
    host: host,
    path: path,
    query: params.isEmpty ? null : Uri(queryParameters: params).query,
  ).toString();

  if (normalized.endsWith('/') && path != '/') {
    normalized = normalized.substring(0, normalized.length - 1);
  }
  return normalized;
}

/// Enlace canónico para detectar duplicados.
String canonicalJobLink(String raw) => normalizeJobUrl(raw);

/// Aviso para enlaces que sabemos que no son una vacante (publicaciones,
/// formularios de postulación, búsquedas sin oferta seleccionada).
String? jobUrlHint(String raw) {
  final uri = parseOfferUri(raw);
  if (uri == null) return null;

  final host = uri.host.toLowerCase();
  final path = uri.path.toLowerCase();

  if (host.endsWith('linkedin.com')) {
    if (path.contains('/posts')) {
      return 'Ese enlace es una publicación de LinkedIn, no una vacante.';
    }
    if (path.contains('/jobs/search') &&
        (uri.queryParameters['currentJobId'] ?? '').trim().isEmpty) {
      return 'Ese enlace es una búsqueda de LinkedIn. Abre la vacante y comparte su enlace.';
    }
  }

  if (host.endsWith('getonbrd.com') && path.contains('/applications')) {
    return 'Ese enlace es tu postulación en GetOnBrd, no la vacante.';
  }

  if (host.endsWith('hirehive.com') && path.contains('/complete')) {
    return 'Ese enlace es un formulario de postulación, no la vacante.';
  }

  if (host.endsWith('bairesdev.com') && path.contains('/apply')) {
    return 'Ese enlace es el formulario de postulación de BairesDev, no la vacante.';
  }

  return null;
}

bool isKnownNonJobUrl(String raw) => jobUrlHint(raw) != null;

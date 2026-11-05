/// Valida y normaliza el enlace externo de una postulación.
///
/// Acepta solo `http`/`https` con un host con dominio. Si el usuario guardó
/// `linkedin.com/jobs/1` sin esquema, se completa con `https://`.
Uri? parseOfferUri(String link) {
  final raw = link.trim();
  if (raw.isEmpty) return null;
  if (raw.contains(RegExp(r'\s'))) return null;

  var uri = Uri.tryParse(raw);
  if (uri == null) return null;

  if (!uri.hasScheme) {
    if (!_looksLikeDomain(raw)) return null;
    uri = Uri.tryParse('https://$raw');
    if (uri == null) return null;
  }

  if (uri.scheme != 'http' && uri.scheme != 'https') return null;

  final host = uri.host;
  if (host.isEmpty) return null;
  if (!host.contains('.') && host != 'localhost') return null;

  return uri;
}

/// Dominio visible del enlace, sin `www.`; vacío si el enlace no es válido.
String offerLinkDomain(String link) {
  final uri = parseOfferUri(link);
  if (uri == null) return '';
  return uri.host.replaceFirst(
    RegExp(r'^www\.', caseSensitive: false),
    '',
  );
}

bool _looksLikeDomain(String value) {
  final host = value.split('/').first.split('?').first.split('#').first;
  return RegExp(r'^[a-zA-Z0-9-]+(\.[a-zA-Z0-9-]+)+$').hasMatch(host);
}

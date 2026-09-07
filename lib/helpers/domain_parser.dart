const _multiPartSuffixes = {
  'com.co',
  'com.ar',
  'com.mx',
  'com.pe',
  'com.ec',
  'com.ve',
  'com.bo',
  'com.py',
  'com.uy',
  'com.br',
  'co.uk',
  'com.au',
  'net.co',
  'org.co',
};

String extractPlatform(String link) {
  final trimmed = link.trim();
  if (trimmed.isEmpty) return '';

  var url = trimmed;
  if (!url.startsWith('http://') && !url.startsWith('https://')) {
    url = 'https://$url';
  }

  final uri = Uri.tryParse(url);
  var host = uri?.host.trim().toLowerCase() ?? '';
  if (host.isEmpty) return '';
  if (host.startsWith('www.')) host = host.substring(4);
  if (host.isEmpty) return '';
  // Remove port if present (Uri.host already strips it, but be safe)
  host = host.split(':').first;

  final parts = host.split('.');
  if (parts.length == 1) {
    return '${parts[0][0].toUpperCase()}${parts[0].substring(1)}';
  }

  // Detect multi-part suffix (e.g. com.co)
  String root;
  if (parts.length >= 3) {
    final lastTwo = '${parts[parts.length - 2]}.${parts[parts.length - 1]}';
    if (_multiPartSuffixes.contains(lastTwo)) {
      // e.g. computrabajo.com.co -> root is 'computrabajo'
      root = parts[parts.length - 3];
    } else {
      // e.g. co.computrabajo.com -> suffix 'com', root 'computrabajo'
      root = parts[parts.length - 2];
    }
  } else {
    // e.g. linkedin.com -> root 'linkedin'
    root = parts[parts.length - 2];
  }

  if (root.isEmpty) return '';
  return '${root[0].toUpperCase()}${root.substring(1)}';
}

import 'dart:convert';

import '../models/job_import.dart';
import 'job_url.dart';
import 'text_normalizer.dart';

/// Convierte HTML en texto visible razonablemente limpio.
String htmlToText(String html) {
  var text = html;
  text = text.replaceAll(
    RegExp(
      r'<(script|style|noscript|svg|template)\b[^>]*>.*?</\1>',
      caseSensitive: false,
      dotAll: true,
    ),
    ' ',
  );
  text = text.replaceAll(
    RegExp(
      r'<(nav|footer|header)\b[^>]*>.*?</\1>',
      caseSensitive: false,
      dotAll: true,
    ),
    ' ',
  );
  text = text.replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n');
  text = text.replaceAll(
    RegExp(r'</(p|div|li|h[1-6]|tr|section|article)\s*>', caseSensitive: false),
    '\n',
  );
  text = text.replaceAll(RegExp(r'<li\b[^>]*>', caseSensitive: false), '• ');
  text = text.replaceAll(RegExp(r'<[^>]+>'), ' ');
  text = decodeHtmlEntities(text);
  text = text.replaceAll(RegExp(r'[ \t\f\v]+'), ' ');
  text = text.replaceAll(RegExp(r'\n\s*\n\s*\n+'), '\n\n');
  return text.trim();
}

const Map<String, String> _entities = {
  'amp': '&',
  'lt': '<',
  'gt': '>',
  'quot': '"',
  'apos': "'",
  'nbsp': ' ',
  'ndash': '–',
  'mdash': '—',
  'hellip': '…',
  'aacute': 'á',
  'eacute': 'é',
  'iacute': 'í',
  'oacute': 'ó',
  'uacute': 'ú',
  'ntilde': 'ñ',
  'Aacute': 'Á',
  'Eacute': 'É',
  'Iacute': 'Í',
  'Oacute': 'Ó',
  'Uacute': 'Ú',
  'Ntilde': 'Ñ',
  'laquo': '«',
  'raquo': '»',
  'middot': '·',
};

String decodeHtmlEntities(String value) {
  return value.replaceAllMapped(RegExp(r'&(#x?[0-9a-fA-F]+|[a-zA-Z]+);'), (
    match,
  ) {
    final code = match.group(1)!;
    if (code.startsWith('#x') || code.startsWith('#X')) {
      final parsed = int.tryParse(code.substring(2), radix: 16);
      return parsed == null ? match.group(0)! : String.fromCharCode(parsed);
    }
    if (code.startsWith('#')) {
      final parsed = int.tryParse(code.substring(1));
      return parsed == null ? match.group(0)! : String.fromCharCode(parsed);
    }
    return _entities[code] ?? match.group(0)!;
  });
}

String? extractHtmlTitle(String html) {
  final title = RegExp(
    r'<title[^>]*>(.*?)</title>',
    caseSensitive: false,
    dotAll: true,
  ).firstMatch(html);
  if (title != null) {
    final text = htmlToText(title.group(1)!);
    if (text.isNotEmpty) return text;
  }

  final patterns = [
    RegExp(
      r'''<meta[^>]+property=["']og:title["'][^>]+content=["']([^"']*)''',
      caseSensitive: false,
      dotAll: true,
    ),
    RegExp(
      r'''<meta[^>]+content=["']([^"']*)["'][^>]+property=["']og:title["']''',
      caseSensitive: false,
      dotAll: true,
    ),
  ];
  for (final pattern in patterns) {
    final match = pattern.firstMatch(html);
    final text = match?.group(1)?.trim();
    if (text != null && text.isNotEmpty) return decodeHtmlEntities(text);
  }
  return null;
}

String? extractH1(String html) {
  final match = RegExp(
    r'<h1[^>]*>(.*?)</h1>',
    caseSensitive: false,
    dotAll: true,
  ).firstMatch(html);
  if (match == null) return null;
  final text = htmlToText(match.group(1)!);
  return text.isEmpty ? null : text;
}

List<dynamic> _jsonLdNodes(String html) {
  final blocks = RegExp(
    r'''<script[^>]*type=["']application/ld\+json["'][^>]*>(.*?)</script>''',
    caseSensitive: false,
    dotAll: true,
  ).allMatches(html);

  final nodes = <dynamic>[];
  for (final block in blocks) {
    final raw = block.group(1)?.trim();
    if (raw == null || raw.isEmpty) continue;
    try {
      nodes.add(jsonDecode(raw));
    } catch (_) {
      // Un bloque roto no debe impedir leer los demás.
    }
  }
  return nodes;
}

Map<String, dynamic>? _findJobPosting(dynamic node) {
  if (node is Map) {
    final type = node['@type'];
    final types = type is List ? type : [type];
    final isJobPosting = types.any(
      (item) => item is String && item.toLowerCase() == 'jobposting',
    );
    if (isJobPosting) return Map<String, dynamic>.from(node);

    for (final value in node.values) {
      final found = _findJobPosting(value);
      if (found != null) return found;
    }
  } else if (node is List) {
    for (final value in node) {
      final found = _findJobPosting(value);
      if (found != null) return found;
    }
  }
  return null;
}

Map<String, dynamic>? findJobPosting(String html) {
  Map<String, dynamic>? fallback;
  for (final node in _jsonLdNodes(html)) {
    final job = _findJobPosting(node);
    if (job == null) continue;
    fallback ??= job;
    final title = _string(job['title']);
    if (title != null) return job;
  }
  return fallback;
}

String? _string(dynamic value) {
  if (value is String) {
    final text = value.trim();
    return text.isEmpty ? null : text;
  }
  if (value is num) return value.toString();
  if (value is List) {
    for (final item in value) {
      final text = _string(item);
      if (text != null) return text;
    }
  }
  return null;
}

List<String> _strings(dynamic value) {
  if (value is String) {
    final text = value.trim();
    return text.isEmpty ? const [] : [text];
  }
  if (value is List) {
    return [for (final item in value) ..._strings(item)];
  }
  return const [];
}

String? _company(dynamic organization) {
  if (organization is Map) return _string(organization['name']);
  return _string(organization);
}

String? _city(dynamic jobLocation) {
  final places = jobLocation is List ? jobLocation : [jobLocation];
  final cities = <String>[];

  for (final place in places) {
    if (place is! Map) continue;
    final address = place['address'];
    if (address is Map) {
      for (final key in ['addressLocality', 'addressRegion']) {
        cities.addAll(_strings(address[key]));
      }
    } else {
      cities.addAll(_strings(address));
    }
  }

  if (cities.isEmpty) return null;
  return cities.toSet().join(', ');
}

String _numberText(dynamic value) {
  if (value is num) return value.toString();
  return value.toString().trim();
}

String? _salaryText(dynamic baseSalary) {
  final salary = baseSalary is List
      ? (baseSalary.isEmpty ? null : baseSalary.first)
      : baseSalary;
  if (salary is! Map) return null;

  final value = salary['value'];
  dynamic min;
  dynamic max;
  String? currency = _string(salary['currency']);
  String? unit;

  if (value is Map) {
    min = value['minValue'] ?? value['value'];
    max = value['maxValue'];
    currency ??= _string(value['currency']);
    unit = _string(value['unitText']);
  } else {
    min = value;
  }

  if (min == null && max == null) return null;

  final parts = <String>[
    ?currency,
    if (min != null) _numberText(min),
    if (max != null && max != min) '– ${_numberText(max)}',
    if (unit != null && unit.toUpperCase() != 'MONTH') unit,
  ];
  return parts.join(' ').trim();
}

String? _description(dynamic raw) {
  final value = _string(raw);
  if (value == null) return null;
  final text = htmlToText(value);
  return text.length >= 80 ? text : null;
}

String _mainHtml(String html) {
  final main = RegExp(
    r'<main\b[^>]*>(.*?)</main>',
    caseSensitive: false,
    dotAll: true,
  ).firstMatch(html);
  if (main != null) return main.group(1)!;

  final article = RegExp(
    r'<article\b[^>]*>(.*?)</article>',
    caseSensitive: false,
    dotAll: true,
  ).firstMatch(html);
  if (article != null) return article.group(1)!;

  return html;
}

bool looksLikeListing({String? title, String? h1, required String text}) {
  final header = normalizeText('${title ?? ''} ${h1 ?? ''}');
  const signals = [
    'ofertas de trabajo',
    'bolsa de empleo',
    'job search',
    'search results',
    'resultados de busqueda',
    'empleos disponibles',
    'vacantes disponibles',
    'ofertas disponibles',
  ];
  if (signals.any(header.contains)) return true;

  final matches = RegExp(
    r'ver oferta|postularme|aplicar ahora|ver empleo',
    caseSensitive: false,
  ).allMatches(text).length;
  return matches >= 6;
}

JobPageKind classifyJobPage({
  required int? status,
  required String text,
  required String? title,
  required String? h1,
  required bool hasJobPosting,
}) {
  if (status == 401 || status == 403 || status == 429) {
    return JobPageKind.blocked;
  }
  if (hasJobPosting) return JobPageKind.detail;
  if (text.length < 300) return JobPageKind.spa;
  if (looksLikeListing(title: title, h1: h1, text: text)) {
    return JobPageKind.listing;
  }
  return JobPageKind.detail;
}

String? _warningFor(JobPageKind kind) {
  return switch (kind) {
    JobPageKind.listing =>
      'Este enlace parece una búsqueda o un listado, no una vacante específica. Abre la oferta y comparte su enlace, o pega la descripción.',
    JobPageKind.spa =>
      'La página no entregó texto suficiente. Puede cargar la vacante con JavaScript; pega la descripción.',
    JobPageKind.blocked =>
      'El sitio bloqueó la lectura automática. Pega la descripción de la vacante.',
    JobPageKind.notAJob =>
      'Ese enlace no es una vacante. Abre la oferta específica o pega la descripción.',
    _ => null,
  };
}

ParsedJobPage parseJobPage({
  required String html,
  required Uri uri,
  int? status,
}) {
  final htmlTitle = extractHtmlTitle(html);
  final h1 = extractH1(html);
  final job = findJobPosting(html);
  final hasJobPosting = job != null;

  final visibleText = htmlToText(_mainHtml(html));
  final structuredDescription = job == null
      ? null
      : _description(job['description']);

  final text = visibleText.length >= 80
      ? visibleText
      : (structuredDescription ?? visibleText);

  // La descripción final solo se toma de los datos estructurados. El texto
  // visible se usa como entrada para la IA, no como descripción: suele
  // incluir menús y ofertas relacionadas.
  final description = structuredDescription;

  final kind = classifyJobPage(
    status: status,
    text: text,
    title: htmlTitle,
    h1: h1,
    hasJobPosting: hasJobPosting,
  );

  final hint = jobUrlHint(uri.toString());

  return ParsedJobPage(
    kind: kind,
    text: text,
    title: job != null ? _string(job['title']) ?? htmlTitle : htmlTitle,
    company: job == null ? null : _company(job['hiringOrganization']),
    city: job == null ? null : _city(job['jobLocation']),
    employmentType: job == null ? null : _string(job['employmentType']),
    salaryText: job == null ? null : _salaryText(job['baseSalary']),
    description: description,
    warning: hint ?? _warningFor(kind),
    hasJobPosting: hasJobPosting,
  );
}

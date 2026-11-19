import 'text_normalizer.dart';

/// Nombre canónico para las vacantes sin empresa real.
const kConfidencialCompany = 'Empresa confidencial';

/// Clave de comparación de nombres de empresa: minúsculas, sin acentos, sin
/// puntuación y con espacios simples. "xpertgroup S.A.S." y "XpertGroup"
/// comparten clave.
String companyMatchKey(String name) {
  final cleaned =
      normalizeText(name).replaceAll(RegExp(r'[^a-z0-9 ]+'), ' ');
  return cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
}

/// Similitud entre dos nombres en el rango 0..1 (1 = misma clave).
double companySimilarity(String a, String b) {
  final keyA = companyMatchKey(a);
  final keyB = companyMatchKey(b);
  if (keyA.isEmpty || keyB.isEmpty) return 0;
  if (keyA == keyB) return 1;
  return _levenshteinRatio(keyA, keyB);
}

/// Nombres candidatos parecidos a [value]: avisos de posibles duplicados
/// al crear o editar una postulación.
///
/// - No incluye coincidencias exactas (postular varias veces a la misma
///   empresa es normal).
/// - Detecta sufijos (`xpertgroup` ∼ `xpertgroup sas`), palabra raíz común
///   (`stefanini latam` ∼ `stefanini group`), palabra inicial de uno dentro
///   del otro (`confidencial` ∼ `empresa confidencial`) y errores de tipeo
///   (`xpergroup` ∼ `xpertgroup`).
/// - Ordena de más a menos parecido y devuelve como máximo [maxResults].
List<String> similarCompanyNames(
  String value,
  Iterable<String> candidates, {
  int maxResults = 3,
}) {
  final key = companyMatchKey(value);
  if (key.length < 4) return const [];

  final scored = <(String, double)>[];
  final seen = <String>{};
  for (final candidate in candidates) {
    final candidateKey = companyMatchKey(candidate);
    if (candidateKey.length < 4 || candidateKey == key) continue;
    if (!seen.add(candidateKey)) continue;

    final score = _matchScore(key, candidateKey);
    if (score > 0) scored.add((candidate, score));
  }

  scored.sort((a, b) => b.$2.compareTo(a.$2));
  return [for (final entry in scored.take(maxResults)) entry.$1];
}

/// true si el nombre corresponde al bucket de vacantes sin empresa real
/// ("Empresa confidencial" y variantes). Sus métricas mezclan empresas
/// distintas y su análisis IA no tiene sentido.
bool isConfidentialCompany(String name) =>
    companyMatchKey(name).contains('confidencial');

/// Puntuación 0..1 de "se parece" entre claves. 0 = no sugerir.
double _matchScore(String key, String candidateKey) {
  // Contención: "xpertgroup" dentro de "xpertgroup sas".
  if (key.contains(candidateKey) || candidateKey.contains(key)) return 0.95;

  // Palabra inicial significativa compartida: "stefanini latam" /
  // "stefanini group".
  final firstA = _firstToken(key);
  final firstB = _firstToken(candidateKey);
  if (firstA.length >= 5 && firstA == firstB) return 0.9;

  // Palabra inicial de uno presente en el otro: "confidencial" /
  // "empresa confidencial".
  if (firstA.length >= 5 && _tokens(candidateKey).contains(firstA)) {
    return 0.85;
  }
  if (firstB.length >= 5 && _tokens(key).contains(firstB)) return 0.85;

  // Error de tipeo: "xpergroup" / "xpertgroup".
  final ratio = _levenshteinRatio(key, candidateKey);
  return ratio >= 0.85 ? ratio : 0;
}

String _firstToken(String key) {
  final tokens = _tokens(key);
  return tokens.isEmpty ? '' : tokens.first;
}

List<String> _tokens(String key) =>
    key.split(' ').where((t) => t.isNotEmpty).toList();

double _levenshteinRatio(String a, String b) {
  final longest = a.length > b.length ? a.length : b.length;
  if (longest == 0) return 0;
  return 1 - _levenshtein(a, b) / longest;
}

int _levenshtein(String a, String b) {
  if (a.isEmpty) return b.length;
  if (b.isEmpty) return a.length;

  var previous = List<int>.generate(b.length + 1, (j) => j);
  var current = List<int>.filled(b.length + 1, 0);

  for (var i = 1; i <= a.length; i++) {
    current[0] = i;
    for (var j = 1; j <= b.length; j++) {
      final cost = a.codeUnitAt(i - 1) == b.codeUnitAt(j - 1) ? 0 : 1;
      current[j] = [
        current[j - 1] + 1,
        previous[j] + 1,
        previous[j - 1] + cost,
      ].reduce((x, y) => x < y ? x : y);
    }
    final swap = previous;
    previous = current;
    current = swap;
  }
  return previous[b.length];
}

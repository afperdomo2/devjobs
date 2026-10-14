import 'dart:convert';

/// Interpreta la respuesta HTTP de una acción POST (update/create) contra
/// la API de Apps Script.
///
/// Apps Script siempre responde 200 cuando el script se ejecuta; los errores
/// reales llegan en el body como `{"_error": "..."}`. Devuelve un mensaje de
/// error si la respuesta no indica éxito, o `null` si todo está bien.
String? postActionError(String action, int statusCode, String body) {
  if (statusCode != 200) {
    return 'Failed to $action: $statusCode';
  }
  final trimmed = body.trim();
  if (trimmed.isEmpty || !trimmed.startsWith('{')) {
    return null;
  }
  try {
    final decoded = jsonDecode(trimmed);
    if (decoded is Map && decoded['_error'] != null) {
      return 'Failed to $action: ${decoded['_error']}';
    }
  } catch (_) {
    // Body no es JSON: no se puede interpretar, se asume éxito parcial.
  }
  return null;
}

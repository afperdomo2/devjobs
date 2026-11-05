/// Convierte el texto libre de la columna Comentarios en líneas limpias.
///
/// Cada línea se recorta, se eliminan las vacías y se quita el prefijo `- `
/// que usa la Sheet para las notas.
List<String> parseComments(String raw) {
  return raw
      .split('\n')
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .map((line) => line.startsWith('- ') ? line.substring(2) : line)
      .toList();
}

/// Agrega una nota con fecha al final de [existing].
///
/// La nota se guarda como `- d/M/yyyy: texto`. Los saltos de línea internos
/// se convierten en espacios para que siga siendo una sola entrada.
String appendComment(
  String existing,
  String text, {
  DateTime? date,
}) {
  final clean = text.trim();
  if (clean.isEmpty) return existing.trimRight();

  final value = date ?? DateTime.now();
  final body = clean.replaceAll(RegExp(r'\s*\n\s*'), ' ');
  final line = '- ${value.day}/${value.month}/${value.year}: $body';
  final base = existing.trimRight();

  return base.isEmpty ? line : '$base\n$line';
}

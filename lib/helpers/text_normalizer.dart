/// Normaliza texto para comparaciones: minúsculas, sin acentos y sin
/// espacios sobrantes.
///
/// Se usa para estados, búsqueda y cualquier comparación que deba ignorar
/// mayúsculas, tildes y la ñ/ç.
String normalizeText(String value) {
  final input = value.trim().toLowerCase();
  final buffer = StringBuffer();

  for (var i = 0; i < input.length; i++) {
    switch (input[i]) {
      case 'á':
      case 'à':
      case 'ä':
        buffer.write('a');
      case 'é':
      case 'è':
      case 'ë':
        buffer.write('e');
      case 'í':
      case 'ì':
      case 'ï':
        buffer.write('i');
      case 'ó':
      case 'ò':
      case 'ö':
        buffer.write('o');
      case 'ú':
      case 'ù':
      case 'ü':
        buffer.write('u');
      case 'ñ':
        buffer.write('n');
      case 'ç':
        buffer.write('c');
      default:
        buffer.write(input[i]);
    }
  }

  return buffer.toString();
}

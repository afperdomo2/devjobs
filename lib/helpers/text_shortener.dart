String truncate(String s, int max) {
  final t = s.trim();
  if (t.length <= max) return t;
  return '${t.substring(0, max).trimRight()}…';
}

String shortContract(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return '';
  final lower = t.toLowerCase();
  const exact = {
    'tiempo completo': 'T. completo',
    'tiempo parcial': 'T. parcial',
    'prestación de servicios': 'Prestación',
    'prestacion de servicios': 'Prestación',
    'contrato a término fijo': 'T. fijo',
    'contrato a termino fijo': 'T. fijo',
    'término fijo': 'T. fijo',
    'termino fijo': 'T. fijo',
    'indefinido': 'Indefinido',
    'fijo': 'T. fijo',
    'freelance': 'Freelance',
    'prácticas': 'Prácticas',
    'practicas': 'Prácticas',
    'pasantía': 'Prácticas',
    'pasantia': 'Prácticas',
    'obra o labor': 'Obra/labor',
    'medio tiempo': 'T. parcial',
  };
  final mapped = exact[lower];
  if (mapped != null) return mapped;
  return truncate(t, 14);
}

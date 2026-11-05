import 'package:intl/intl.dart';

import 'text_shortener.dart';

final _salarioFormat = NumberFormat.decimalPattern('es');
final _compactFormat = NumberFormat('0.#', 'es');
final _numericOnly = RegExp(r'^\d+$');

String formatSalario(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return raw;
  if (!_numericOnly.hasMatch(trimmed)) return raw;
  return _salarioFormat.format(int.parse(trimmed));
}

/// Abrevia un monto para mostrarlo en una tarjeta:
/// 5.000.000 → 5M, 5.900.000 → 5,9M, 100.000 → 100K, 1.300 → 1,3K.
String formatCompactSalary(int value) {
  if (value >= 1000000) return '${_formatCompact(value / 1000000)}M';
  if (value >= 1000) return '${_formatCompact(value / 1000)}K';
  return '$value';
}

String _formatCompact(double value) {
  final rounded = (value * 10).round() / 10;
  return _compactFormat.format(rounded);
}

final _moneyRegex = RegExp(r'\d{1,3}(?:[.,]\d{3})+|\d{4,}');

int _toInt(String m) => int.parse(m.replaceAll(RegExp(r'[^\d]'), ''));

String _compactMoney(int n) => '\$${formatCompactSalary(n)}';

String _normalizeSalarioText(String s) => truncate(s, 18);

String extractSalario(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return '';
  final matches = _moneyRegex.allMatches(trimmed).toList();
  if (matches.isEmpty) return _normalizeSalarioText(trimmed);
  final amounts = <int>[];
  for (final m in matches) {
    final n = _toInt(m.group(0)!);
    if (n <= 0) continue;
    if (!amounts.contains(n)) amounts.add(n);
    if (amounts.length >= 2) break;
  }
  if (amounts.isEmpty) return _normalizeSalarioText(trimmed);
  if (amounts.length == 1) return _salarioFormat.format(amounts[0]);
  return '${_compactMoney(amounts[0])} – ${_compactMoney(amounts[1])}';
}

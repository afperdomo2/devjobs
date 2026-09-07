import 'package:intl/intl.dart';

import 'text_shortener.dart';

final _salarioFormat = NumberFormat.decimalPattern('es');

String formatSalario(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return raw;
  if (!RegExp(r'^\d+$').hasMatch(trimmed)) return raw;
  return _salarioFormat.format(int.parse(trimmed));
}

final _moneyRegex = RegExp(r'\d{1,3}(?:[.,]\d{3})+|\d{4,}');

int _toInt(String m) => int.parse(m.replaceAll(RegExp(r'[^\d]'), ''));

String _compactMoney(int n) {
  if (n >= 1000000) {
    final v = n / 1000000;
    final rounded = (v * 10).round() / 10;
    final s = rounded == rounded.roundToDouble()
        ? rounded.toStringAsFixed(0)
        : rounded.toStringAsFixed(1).replaceAll('.', ',');
    return '\$$s' 'M';
  }
  if (n >= 1000) return '\$${(n / 1000).round()}K';
  return '\$$n';
}

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

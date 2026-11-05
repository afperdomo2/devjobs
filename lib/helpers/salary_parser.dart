import 'dart:math' as math;

import 'text_normalizer.dart';

/// Moneda detectada en el campo Salario ofrecido.
enum SalaryCurrency {
  cop('COP'),
  usd('USD');

  final String label;

  const SalaryCurrency(this.label);
}

/// Un salario parseado: puede ser un valor único o un rango.
class ParsedSalary {
  final SalaryCurrency currency;
  final int min;
  final int max;

  const ParsedSalary({
    required this.currency,
    required this.min,
    required this.max,
  });

  bool get isRange => min != max;
  double get midpoint => (min + max) / 2;
}

final _subjectiveRegex = RegExp(
  r'\b(yo\s+)?(puse|propuse|sugeri)\b',
);
final _numberRegex = RegExp(r'\d[\d.,]*');

/// Interpreta el campo Salario ofrecido.
///
/// - Excluye valores subjetivos: "Yo puse...", "puse...", "propuse...",
///   "sugerí...".
/// - Detecta USD por `USD`, `US$`, `U$S` o `dólares`; si no, asume COP.
/// - Toma hasta dos números. Uno → valor único; dos → rango.
/// - Acepta separadores de miles y decimales: "4.500.000", "1.300,50".
ParsedSalary? parseSalary(String raw) {
  final text = raw.trim();
  if (text.isEmpty) return null;

  final normalized = normalizeText(text);
  if (_subjectiveRegex.hasMatch(normalized)) return null;

  final currency = _currencyOf(normalized);
  final tokens = _numberRegex
      .allMatches(text)
      .map((match) => match.group(0)!)
      .take(2)
      .toList();

  final amounts = <int>[];
  for (final token in tokens) {
    final amount = _parseAmount(token);
    if (amount != null && amount > 0) amounts.add(amount);
  }
  if (amounts.isEmpty) return null;

  return ParsedSalary(
    currency: currency,
    min: amounts.reduce(math.min),
    max: amounts.reduce(math.max),
  );
}

SalaryCurrency _currencyOf(String normalized) {
  if (normalized.contains('usd') ||
      normalized.contains('dolar') ||
      normalized.contains(r'us$') ||
      normalized.contains(r'u$s')) {
    return SalaryCurrency.usd;
  }
  return SalaryCurrency.cop;
}

int? _parseAmount(String token) {
  final cleaned = token.replaceAll(RegExp(r'[^\d.,]'), '');
  if (cleaned.isEmpty) return null;

  final lastDot = cleaned.lastIndexOf('.');
  final lastComma = cleaned.lastIndexOf(',');
  final lastSeparator = math.max(lastDot, lastComma);

  if (lastSeparator != -1) {
    final decimals = cleaned.length - lastSeparator - 1;
    if (decimals == 1 || decimals == 2) {
      final integerPart = cleaned
          .substring(0, lastSeparator)
          .replaceAll(RegExp(r'[.,]'), '');
      final decimalPart = cleaned.substring(lastSeparator + 1);
      final value = double.tryParse('$integerPart.$decimalPart');
      if (value == null) return null;
      return value.round();
    }
  }

  final digits = cleaned.replaceAll(RegExp(r'[.,]'), '');
  return int.tryParse(digits);
}

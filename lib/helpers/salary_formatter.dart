import 'package:intl/intl.dart';

final _salarioFormat = NumberFormat.decimalPattern('es');

String formatSalario(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return raw;
  if (!RegExp(r'^\d+$').hasMatch(trimmed)) return raw;
  return _salarioFormat.format(int.parse(trimmed));
}
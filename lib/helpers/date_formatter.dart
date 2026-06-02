import 'package:intl/intl.dart';

final _formatter = DateFormat('d \'de\' MMMM, yyyy', 'es');
final _isoRegex = RegExp(r'(\d{4})-(\d{2})-(\d{2})');

DateTime? _parseRawDate(String raw) {
  if (raw.isEmpty) return null;

  // Try "d/M/yyyy" (MM/DD/YYYY or DD/MM/YYYY)
  try {
    final parts = raw.split('/');
    if (parts.length == 3 && parts[2].length == 4) {
      final y = int.parse(parts[2]);
      final a = int.parse(parts[0]);
      final b = int.parse(parts[1]);
      return DateTime(y, b, a);
    }
  } catch (_) {}

  // Try ISO embedded: "...2026-06-02..."
  try {
    final m = _isoRegex.firstMatch(raw);
    if (m != null) {
      return DateTime(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
    }
  } catch (_) {}

  return null;
}

String formatDate(String rawDate) {
  final date = _parseRawDate(rawDate);
  if (date == null) return rawDate;
  return _formatter.format(date);
}

String formatDateShort(String rawDate) {
  final date = _parseRawDate(rawDate);
  if (date == null) return rawDate;
  const days = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
  const months = ['', 'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic'];
  return '${days[date.weekday - 1]} ${date.day} ${months[date.month]} ${date.year}';
}

DateTime? parseDate(String raw) => _parseRawDate(raw);

import 'package:intl/intl.dart';

final _formatter = DateFormat('d \'de\' MMMM, yyyy', 'es');
final _isoRegex = RegExp(r'(\d{4})-(\d{2})-(\d{2})');

/// Valida que [DateTime] no haya normalizado la fecha (p.ej. 31/02 -> 03/03).
DateTime? _validDate(int year, int month, int day) {
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) return null;
  return date;
}

DateTime? _parseRawDate(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return null;

  // Formato de la hoja: d/M/yyyy (con o sin ceros a la izquierda).
  final parts = value.split('/');
  if (parts.length == 3 && parts[2].trim().length == 4) {
    final day = int.tryParse(parts[0].trim());
    final month = int.tryParse(parts[1].trim());
    final year = int.tryParse(parts[2].trim());
    if (day == null || month == null || year == null) return null;
    return _validDate(year, month, day);
  }

  // ISO date-only, también embebido en un timestamp.
  final match = _isoRegex.firstMatch(value);
  if (match != null) {
    return _validDate(
      int.parse(match[1]!),
      int.parse(match[2]!),
      int.parse(match[3]!),
    );
  }

  return null;
}

/// Fecha de calendario -> ISO `yyyy-MM-dd` para enviarla a Apps Script.
///
/// No usa hora ni zona horaria: solo los componentes de calendario.
String formatApiDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

/// Fecha ya parseada -> formato largo español (`4 de noviembre, 2026`).
String formatDateValue(DateTime date) => _formatter.format(date);

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

/// Pluralización de días: `1 día`, `0 días`, `15 días`.
String formatDias(int dias) => dias == 1 ? '1 día' : '$dias días';

/// Texto para días transcurridos desde la última novedad:
/// `hoy`, `hace 1 día`, `hace 15 días`.
String formatSinNovedad(int dias) =>
    dias == 0 ? 'hoy' : 'hace ${formatDias(dias)}';

/// Texto para duración de un proceso finalizado:
/// `Mismo día`, `Duró 1 día`, `Duró 15 días`.
String formatDuracion(int dias) =>
    dias == 0 ? 'Mismo día' : 'Duró ${formatDias(dias)}';

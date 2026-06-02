import 'package:intl/intl.dart';

final _formatter = DateFormat('d \'de\' MMMM, yyyy', 'es');

String formatDate(String rawDate) {
  if (rawDate.isEmpty) return '';
  try {
    final parts = rawDate.split('/');
    if (parts.length == 3) {
      final date = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      return _formatter.format(date);
    }
    return rawDate;
  } catch (_) {
    return rawDate;
  }
}

DateTime? parseDate(String raw) {
  if (raw.isEmpty) return null;
  try {
    final parts = raw.split('/');
    if (parts.length == 3) {
      return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
    }
    return null;
  } catch (_) {
    return null;
  }
}

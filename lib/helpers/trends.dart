import '../models/job_application.dart';
import 'date_formatter.dart';

/// Conteo de postulaciones de un mes concreto.
class MonthlyCount {
  /// Primer día del mes.
  final DateTime month;
  final int count;

  const MonthlyCount({required this.month, required this.count});
}

/// Conteo de postulaciones por mes para los últimos [months] meses,
/// del más antiguo al más reciente e incluyendo los meses en cero.
List<MonthlyCount> monthlyApplicationCounts(
  List<JobApplication> applications, {
  int months = 6,
  DateTime? now,
}) {
  if (months <= 0) return const [];

  final reference = now ?? DateTime.now();
  final currentMonth = DateTime(reference.year, reference.month, 1);

  final counts = <int, int>{};
  for (final application in applications) {
    final date = parseDate(application.fechaPostulacion);
    if (date == null) continue;
    final key = date.year * 100 + date.month;
    counts[key] = (counts[key] ?? 0) + 1;
  }

  final result = <MonthlyCount>[];
  for (var i = months - 1; i >= 0; i--) {
    final month = DateTime(currentMonth.year, currentMonth.month - i, 1);
    final key = month.year * 100 + month.month;
    result.add(MonthlyCount(month: month, count: counts[key] ?? 0));
  }
  return result;
}

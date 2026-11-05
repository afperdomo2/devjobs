import 'dart:math' as math;

import '../models/job_application.dart';
import 'date_formatter.dart';

/// Un movimiento reciente de una postulación.
class Movement {
  final JobApplication application;

  /// Fecha de la última novedad (seguimiento o, si no hay, postulación).
  final DateTime date;

  /// Días transcurridos desde [date].
  final int daysAgo;

  const Movement({
    required this.application,
    required this.date,
    required this.daysAgo,
  });
}

/// Cuenta postulaciones creadas en los últimos [days] días.
int countApplicationsSince(
  List<JobApplication> applications,
  int days, {
  DateTime? now,
}) {
  final cutoff = (now ?? DateTime.now()).subtract(Duration(days: days));
  var count = 0;
  for (final application in applications) {
    final date = parseDate(application.fechaPostulacion);
    if (date != null && !date.isBefore(cutoff)) count++;
  }
  return count;
}

/// Últimos [limit] movimientos, del más reciente al más antiguo.
///
/// La fecha de un movimiento es `fechaSeguimiento` cuando existe; si está
/// vacía o no se puede parsear, se usa `fechaPostulacion`. Las postulaciones
/// sin ninguna fecha se omiten.
List<Movement> recentMovements(
  List<JobApplication> applications, {
  int limit = 3,
  DateTime? now,
}) {
  if (limit <= 0) return const [];

  final reference = now ?? DateTime.now();
  final movements = <Movement>[];

  for (final application in applications) {
    final date =
        parseDate(application.fechaSeguimiento) ??
        parseDate(application.fechaPostulacion);
    if (date == null) continue;

    movements.add(
      Movement(
        application: application,
        date: date,
        daysAgo: math.max(0, reference.difference(date).inDays),
      ),
    );
  }

  movements.sort((a, b) {
    final byDate = b.date.compareTo(a.date);
    if (byDate != 0) return byDate;

    final byCompany = a.application.empresa
        .toLowerCase()
        .compareTo(b.application.empresa.toLowerCase());
    if (byCompany != 0) return byCompany;

    return a.application.rowIndex.compareTo(b.application.rowIndex);
  });

  return movements.take(limit).toList();
}

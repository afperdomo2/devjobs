import '../models/job_application.dart';
import 'salary_parser.dart';

/// Resumen salarial de una moneda.
class SalaryGroup {
  final SalaryCurrency currency;

  /// Cantidad de postulaciones con salario válido (un rango cuenta como 1).
  final int count;

  /// Extremos globales de todos los valores y rangos.
  final int min;
  final int max;

  /// Promedio de los puntos medios de cada valor/rango.
  final int average;

  const SalaryGroup({
    required this.currency,
    required this.count,
    required this.min,
    required this.max,
    required this.average,
  });
}

/// Agrupa los salarios por moneda, ignorando textos subjetivos y valores
/// inválidos. Devuelve solo las monedas con al menos [minSamples] datos.
List<SalaryGroup> salaryInsights(
  List<JobApplication> applications, {
  int minSamples = 1,
}) {
  final parsedByCurrency = <SalaryCurrency, List<ParsedSalary>>{};

  for (final application in applications) {
    final parsed = parseSalary(application.salarioOfrecido);
    if (parsed == null) continue;
    parsedByCurrency.putIfAbsent(parsed.currency, () => []).add(parsed);
  }

  final groups = <SalaryGroup>[];
  for (final currency in SalaryCurrency.values) {
    final entries = parsedByCurrency[currency];
    if (entries == null || entries.length < minSamples) continue;

    var min = entries.first.min;
    var max = entries.first.max;
    var midpointSum = 0.0;

    for (final entry in entries) {
      if (entry.min < min) min = entry.min;
      if (entry.max > max) max = entry.max;
      midpointSum += entry.midpoint;
    }

    groups.add(
      SalaryGroup(
        currency: currency,
        count: entries.length,
        min: min,
        max: max,
        average: (midpointSum / entries.length).round(),
      ),
    );
  }

  return groups;
}

import 'package:devjobs/helpers/salary_insights.dart';
import 'package:devjobs/helpers/salary_parser.dart';
import 'package:devjobs/models/job_application.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  JobApplication app({
    int rowIndex = 1,
    String salarioOfrecido = '',
  }) {
    return JobApplication(
      rowIndex: rowIndex,
      salarioOfrecido: salarioOfrecido,
    );
  }

  group('salaryInsights', () {
    test('lista vacía retorna lista vacía', () {
      expect(salaryInsights([]), isEmpty);
    });

    test('separa pesos y dólares y conserva el orden COP/USD', () {
      final groups = salaryInsights([
        app(rowIndex: 1, salarioOfrecido: '600 - 850 USD'),
        app(rowIndex: 2, salarioOfrecido: '4.500.000 - 6.000.000'),
        app(rowIndex: 3, salarioOfrecido: '1.300 USD'),
        app(rowIndex: 4, salarioOfrecido: '6.000.000'),
      ]);

      expect(groups.length, equals(2));
      expect(groups[0].currency, equals(SalaryCurrency.cop));
      expect(groups[1].currency, equals(SalaryCurrency.usd));
    });

    test('calcula conteo, mínimo, máximo y promedio por moneda', () {
      final groups = salaryInsights([
        app(rowIndex: 1, salarioOfrecido: '4.500.000 - 6.000.000'),
        app(rowIndex: 2, salarioOfrecido: '6.000.000'),
        app(rowIndex: 3, salarioOfrecido: '600 - 850 USD'),
        app(rowIndex: 4, salarioOfrecido: '1.300 USD'),
      ]);

      final cop = groups.firstWhere(
        (group) => group.currency == SalaryCurrency.cop,
      );
      expect(cop.count, equals(2));
      expect(cop.min, equals(4500000));
      expect(cop.max, equals(6000000));
      expect(cop.average, equals(5625000));

      final usd = groups.firstWhere(
        (group) => group.currency == SalaryCurrency.usd,
      );
      expect(usd.count, equals(2));
      expect(usd.min, equals(600));
      expect(usd.max, equals(1300));
      expect(usd.average, equals(1013));
    });

    test('ignora textos subjetivos y valores inválidos', () {
      final groups = salaryInsights([
        app(rowIndex: 1, salarioOfrecido: 'Yo puse 5.000.000'),
        app(rowIndex: 2, salarioOfrecido: 'A convenir'),
        app(rowIndex: 3, salarioOfrecido: '1.300 USD'),
        app(rowIndex: 4, salarioOfrecido: ''),
      ]);

      expect(groups.length, equals(1));
      expect(groups.first.currency, equals(SalaryCurrency.usd));
      expect(groups.first.count, equals(1));
      expect(groups.first.average, equals(1300));
    });

    test('respeta el mínimo de muestras por moneda', () {
      final applications = [
        app(rowIndex: 1, salarioOfrecido: '1.000 USD'),
        app(rowIndex: 2, salarioOfrecido: '1.500 USD'),
        app(rowIndex: 3, salarioOfrecido: '6.000.000'),
      ];

      expect(salaryInsights(applications).length, equals(2));
      final filtered = salaryInsights(applications, minSamples: 2);
      expect(filtered.length, equals(1));
      expect(filtered.first.currency, equals(SalaryCurrency.usd));
    });
  });
}

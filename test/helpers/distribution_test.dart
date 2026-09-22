import 'package:devjobs/helpers/distribution.dart';
import 'package:devjobs/models/job_application.dart';
import 'package:flutter_test/flutter_test.dart';

JobApplication _app({
  String ciudad = '',
  String modalidad = '',
  String link = '',
}) {
  return JobApplication(
    rowIndex: 1,
    ciudad: ciudad,
    modalidad: modalidad,
    link: link,
  );
}

void main() {
  group('distributionCounts', () {
    test('cuenta y ordena descendente por valor', () {
      final apps = [
        _app(ciudad: 'Bogotá'),
        _app(ciudad: 'Medellín'),
        _app(ciudad: 'Bogotá'),
        _app(ciudad: 'Bogotá'),
        _app(ciudad: 'Cali'),
      ];
      final result = distributionCounts(apps, (a) => a.ciudad);
      expect(result, equals([('Bogotá', 3), ('Cali', 1), ('Medellín', 1)]));
    });

    test('ignora valores vacíos y con solo espacios', () {
      final apps = [
        _app(ciudad: 'Bogotá'),
        _app(ciudad: ''),
        _app(ciudad: '   '),
        _app(ciudad: 'Bogotá'),
      ];
      final result = distributionCounts(apps, (a) => a.ciudad);
      expect(result, equals([('Bogotá', 2)]));
    });

    test('lista vacía retorna lista vacía', () {
      expect(distributionCounts([], (a) => a.ciudad), isEmpty);
    });

    test('empate se mantiene estable y agrupa valores trimmeados', () {
      final apps = [
        _app(modalidad: 'Remoto'),
        _app(modalidad: '  Remoto  '),
        _app(modalidad: 'Híbrido'),
        _app(modalidad: 'Híbrido'),
      ];
      final result = distributionCounts(apps, (a) => a.modalidad);
      expect(result, equals([('Híbrido', 2), ('Remoto', 2)]));
    });

    test('plataforma usa el getter desde el link', () {
      final apps = [
        _app(link: 'https://www.linkedin.com/jobs/view/1'),
        _app(link: 'https://www.linkedin.com/jobs/view/2'),
        _app(link: 'https://co.computrabajo.com/empleo/1'),
      ];
      final result = distributionCounts(apps, (a) => a.plataforma);
      expect(result, equals([('Linkedin', 2), ('Computrabajo', 1)]));
    });
  });

  group('topDistribution', () {
    test('limita a los n primeros', () {
      final apps = [
        _app(ciudad: 'Bogotá'),
        _app(ciudad: 'Bogotá'),
        _app(ciudad: 'Medellín'),
        _app(ciudad: 'Cali'),
      ];
      final result = topDistribution(apps, (a) => a.ciudad, 2);
      expect(result, equals([('Bogotá', 2), ('Cali', 1)]));
    });

    test('n mayor que el total devuelve todo', () {
      final apps = [_app(ciudad: 'Bogotá'), _app(ciudad: 'Cali')];
      final result = topDistribution(apps, (a) => a.ciudad, 10);
      expect(result.length, equals(2));
    });

    test('n <= 0 devuelve lista vacía', () {
      final apps = [_app(ciudad: 'Bogotá')];
      expect(topDistribution(apps, (a) => a.ciudad, 0), isEmpty);
      expect(topDistribution(apps, (a) => a.ciudad, -1), isEmpty);
    });
  });
}
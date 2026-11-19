import 'package:devjobs/helpers/company_merge.dart';
import 'package:devjobs/models/job_application.dart';
import 'package:flutter_test/flutter_test.dart';

JobApplication app({int rowIndex = 1, String empresa = 'Acme'}) {
  return JobApplication(
    rowIndex: rowIndex,
    empresa: empresa,
    vacante: 'Dev',
  );
}

void main() {
  group('mergeRenameTargets', () {
    test('renombra las filas seleccionadas que no llevan el nombre final', () {
      final apps = [
        app(rowIndex: 1, empresa: 'xpertgroup'),
        app(rowIndex: 2, empresa: 'xpertgroup sas'),
        app(rowIndex: 3, empresa: 'xpertgroup sas'),
        app(rowIndex: 4, empresa: 'Globex'),
      ];

      final targets = mergeRenameTargets(
        apps,
        ['xpertgroup', 'xpertgroup sas'],
        'xpertgroup',
      );

      expect(targets.map((a) => a.rowIndex), [2, 3]);
    });

    test('no toca las filas que ya llevan el nombre final', () {
      final apps = [app(rowIndex: 1, empresa: 'xpertgroup')];
      expect(
        mergeRenameTargets(apps, ['xpertgroup', 'xpertgroup sas'], 'xpertgroup'),
        isEmpty,
      );
    });

    test('unifica variantes de mayúsculas hacia el nombre final', () {
      final apps = [app(rowIndex: 1, empresa: 'XpertGroup')];

      // Seleccionada por su clave normalizada; se renombra al nombre final.
      final targets = mergeRenameTargets(apps, ['XpertGroup'], 'xpertgroup');
      expect(targets.single.rowIndex, 1);

      // Una clave distinta ("xpertgroup sas") no arrastra esta fila.
      expect(mergeRenameTargets(apps, ['xpertgroup sas'], 'xpertgroup'), isEmpty);
    });

    test('selección vacía o nombre final vacío no renombra nada', () {
      final apps = [app(rowIndex: 1, empresa: 'xpertgroup sas')];
      expect(mergeRenameTargets(apps, [], 'xpertgroup'), isEmpty);
      expect(mergeRenameTargets(apps, ['xpertgroup sas'], '  '), isEmpty);
    });

    test('solo renombra las empresas seleccionadas', () {
      final apps = [
        app(rowIndex: 1, empresa: 'Globex'),
        app(rowIndex: 2, empresa: 'Initech'),
      ];

      final targets = mergeRenameTargets(apps, ['Globex'], 'Globex SAS');
      expect(targets.map((a) => a.rowIndex), [1]);
    });
  });
}

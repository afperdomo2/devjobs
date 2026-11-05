import 'package:devjobs/helpers/job_duplicate.dart';
import 'package:devjobs/models/job_application.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('findDuplicateByLink', () {
    test('encuentra el mismo enlace aunque cambie el tracking', () {
      const existing = JobApplication(
        rowIndex: 3,
        link: 'https://www.linkedin.com/jobs/view/123/?trk=public',
      );

      final found = findDuplicateByLink(const [
        existing,
      ], 'https://linkedin.com/jobs/view/123');

      expect(found?.rowIndex, equals(3));
    });

    test('no confunde enlaces distintos', () {
      const existing = JobApplication(
        rowIndex: 3,
        link: 'https://linkedin.com/jobs/view/123',
      );

      expect(
        findDuplicateByLink(const [
          existing,
        ], 'https://linkedin.com/jobs/view/999'),
        isNull,
      );
    });

    test('ignora postulaciones sin enlace', () {
      const existing = JobApplication(rowIndex: 3, empresa: 'Acme');

      expect(
        findDuplicateByLink(const [
          existing,
        ], 'https://linkedin.com/jobs/view/123'),
        isNull,
      );
    });

    test('enlace vacío no es duplicado', () {
      expect(findDuplicateByLink(const [], ''), isNull);
    });
  });
}

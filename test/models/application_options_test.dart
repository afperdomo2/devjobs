import 'package:devjobs/helpers/status.dart';
import 'package:devjobs/models/application_options.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('los estados finales son terminales', () {
    for (final estado in applicationFinalStatuses) {
      expect(isTerminalStatus(estado), isTrue, reason: estado);
    }
  });

  test('los estados finales existen en el catálogo de estados', () {
    for (final estado in applicationFinalStatuses) {
      expect(applicationStatuses, contains(estado), reason: estado);
    }
  });

  test('el catálogo de estados finales no está vacío ni duplicado', () {
    expect(applicationFinalStatuses, isNotEmpty);
    expect(
      applicationFinalStatuses.toSet().length,
      equals(applicationFinalStatuses.length),
    );
  });
}

import 'package:devjobs/services/sheets_api_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreateResult.fromJson', () {
    test('parsea rowIndex y shifted=false', () {
      final result = CreateResult.fromJson(<String, dynamic>{
        'rowIndex': 13,
        'shifted': false,
      });

      expect(result.rowIndex, 13);
      expect(result.shifted, isFalse);
    });

    test('parsea shifted=true', () {
      final result = CreateResult.fromJson(<String, dynamic>{
        'rowIndex': 2,
        'shifted': true,
      });

      expect(result.rowIndex, 2);
      expect(result.shifted, isTrue);
    });

    test('sin shifted asume true para scripts viejos', () {
      final result = CreateResult.fromJson(<String, dynamic>{'rowIndex': 14});

      expect(result.shifted, isTrue);
    });

    test('acepta shifted como string', () {
      final result = CreateResult.fromJson(<String, dynamic>{
        'rowIndex': 13,
        'shifted': 'false',
      });

      expect(result.shifted, isFalse);
    });

    test('lanza FormatException si falta rowIndex', () {
      expect(
        () => CreateResult.fromJson(<String, dynamic>{'shifted': false}),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

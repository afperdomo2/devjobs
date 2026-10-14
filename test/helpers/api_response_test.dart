import 'package:flutter_test/flutter_test.dart';
import 'package:devjobs/helpers/api_response.dart';

void main() {
  group('postActionError', () {
    test('status 200 con body vacío → sin error', () {
      expect(postActionError('update', 200, ''), isNull);
    });

    test('status 200 con {"_ok":true} → sin error', () {
      expect(
        postActionError('update', 200, '{"_ok":true,"rowIndex":5}'),
        isNull,
      );
    });

    test('status 200 con {"_error":...} → error con el mensaje del script', () {
      final error = postActionError(
        'update',
        200,
        '{"_error":"TypeError: ..."}',
      );
      expect(error, 'Failed to update: TypeError: ...');
    });

    test('status 200 con body no-JSON → sin error (tolerante)', () {
      expect(postActionError('create', 200, 'html suelto'), isNull);
    });

    test('status 200 con JSON inválido → sin error (tolerante)', () {
      expect(postActionError('update', 200, '{roto'), isNull);
    });

    test('status 302 → error con código', () {
      expect(postActionError('update', 302, ''), 'Failed to update: 302');
    });

    test('status 500 → error con código', () {
      expect(postActionError('create', 500, ''), 'Failed to create: 500');
    });
  });
}

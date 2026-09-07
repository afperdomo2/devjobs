import 'dart:io';

import 'package:devjobs/helpers/network_error.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

void main() {
  group('isNetworkError', () {
    test('SocketException es network error', () {
      expect(isNetworkError(const SocketException('x')), isTrue);
    });

    test('ClientException es network error', () {
      expect(isNetworkError(http.ClientException('x')), isTrue);
    });

    test('Exception con socketexception en mensaje', () {
      expect(isNetworkError(Exception('SocketException: failed')), isTrue);
    });

    test('failed host lookup', () {
      expect(isNetworkError(Exception('Failed host lookup: x')), isTrue);
    });

    test('network is unreachable', () {
      expect(
          isNetworkError(Exception('Network is unreachable')), isTrue);
    });

    test('connection failed/refused', () {
      expect(isNetworkError(Exception('Connection failed')), isTrue);
      expect(isNetworkError(Exception('Connection refused')), isTrue);
    });

    test('otro error no es network', () {
      expect(isNetworkError(Exception('algo raro')), isFalse);
      expect(isNetworkError(Exception('Failed to load')), isFalse);
    });
  });

  group('friendlyErrorMessage', () {
    test('network error → mensaje amistoso', () {
      expect(friendlyErrorMessage(const SocketException('x')),
          contains('Sin conexión'));
    });

    test('remueve prefijo Exception: ', () {
      expect(friendlyErrorMessage(Exception('algo')), equals('algo'));
    });

    test('normaliza Exception: con prefijo doble', () {
      final msg = friendlyErrorMessage(Exception('Exception: algo'));
      expect(msg, equals('Exception: algo'));
    });

    test('trunca mensajes muy largos', () {
      final long = 'a' * 400;
      final msg = friendlyErrorMessage(Exception(long));
      expect(msg.length, equals(301));
      expect(msg.endsWith('…'), isTrue);
    });
  });
}

import 'package:devjobs/helpers/offer_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseOfferUri', () {
    test('acepta https y http válidos', () {
      final https = parseOfferUri('https://www.linkedin.com/jobs/1');
      expect(https?.scheme, 'https');
      expect(https?.host, 'www.linkedin.com');

      final http = parseOfferUri('http://example.com/oferta');
      expect(http?.scheme, 'http');
      expect(http?.host, 'example.com');
    });

    test('completa https cuando falta el esquema', () {
      final uri = parseOfferUri('linkedin.com/jobs/1');
      expect(uri?.toString(), 'https://linkedin.com/jobs/1');
    });

    test('ignora espacios alrededor', () {
      final uri = parseOfferUri('  https://example.com  ');
      expect(uri?.host, 'example.com');
    });

    test('rechaza vacío, sin dominio o con esquema no web', () {
      expect(parseOfferUri(''), isNull);
      expect(parseOfferUri('   '), isNull);
      expect(parseOfferUri('no-es-un-link'), isNull);
      expect(parseOfferUri('ftp://example.com/file'), isNull);
      expect(parseOfferUri('javascript:alert(1)'), isNull);
      expect(parseOfferUri('https://'), isNull);
    });

    test('rechaza texto con espacios', () {
      expect(parseOfferUri('https://example.com/oferta con espacios'), isNull);
    });
  });

  group('offerLinkDomain', () {
    test('quita el prefijo www', () {
      expect(offerLinkDomain('https://www.linkedin.com/jobs/1'), 'linkedin.com');
    });

    test('devuelve el host sin esquema en enlaces abreviados', () {
      expect(offerLinkDomain('example.com/oferta'), 'example.com');
    });

    test('enlace inválido devuelve vacío', () {
      expect(offerLinkDomain('no-es-un-link'), '');
      expect(offerLinkDomain(''), '');
    });
  });
}

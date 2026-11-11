import 'package:devjobs/models/ai_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AiConfig', () {
    test('serializa y recupera la configuración', () {
      const config = AiConfig(
        baseUrl: 'https://opencode.ai/inference/go/openai/v1',
        apiKey: 'oc_sk_123',
        models: ['deepseek-v4.1-flash', 'glm-5.3-flash'],
      );

      final restored = AiConfig.fromJson(config.toJson());

      expect(restored, equals(config));
      expect(restored.primaryModel, equals('deepseek-v4.1-flash'));
      expect(restored.providerHost, equals('opencode.ai'));
    });

    test('normaliza espacios, vacíos y duplicados al leer', () {
      final config = AiConfig.fromJson({
        'baseUrl': '  https://api.example.com/v1  ',
        'apiKey': ' key ',
        'models': [' a ', 'a', '', '  ', 42, 'b'],
      });

      expect(config.baseUrl, equals('https://api.example.com/v1'));
      expect(config.apiKey, equals('key'));
      expect(config.models, equals(['a', 'b']));
    });

    test('una configuración vacía no habilita la IA', () {
      expect(AiConfig.empty.isEnabled, isFalse);
      expect(AiConfig.empty.primaryModel, isEmpty);
      expect(AiConfig.empty.validate(), isNotNull);

      expect(AiConfig.fromJson(const <String, dynamic>{}).isEnabled, isFalse);
    });

    test('isEnabled exige proveedor, clave y al menos un modelo', () {
      const base = AiConfig(
        baseUrl: 'https://api.example.com/v1',
        apiKey: 'key',
        models: ['m'],
      );
      expect(base.isEnabled, isTrue);

      expect(base.copyWith(baseUrl: ' ').isEnabled, isFalse);
      expect(base.copyWith(apiKey: '').isEnabled, isFalse);
      expect(base.copyWith(models: const []).isEnabled, isFalse);
    });

    test('validateBaseUrl rechaza esquemas que no sean http/https', () {
      const bad = AiConfig(baseUrl: 'ftp://x', apiKey: 'k', models: ['m']);
      expect(bad.validateBaseUrl(), isNotNull);
      expect(bad.validate(), isNotNull);

      const good = AiConfig(
        baseUrl: 'https://api.example.com/v1',
        apiKey: 'k',
        models: ['m'],
      );
      expect(good.validateBaseUrl(), isNull);
      expect(good.validate(), isNull);
    });
  });
}

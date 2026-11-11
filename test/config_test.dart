import 'package:devjobs/config.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  void load(String envString) {
    dotenv.loadFromString(envString: envString);
  }

  test('un modelo simple da una lista de uno', () {
    load('AI_MODEL=deepseek-v4.1-flash');

    expect(kAiModels, equals(['deepseek-v4.1-flash']));
    expect(kAiModel, equals('deepseek-v4.1-flash'));
  });

  test('varios modelos separados por comas se conservan en orden', () {
    load('AI_MODEL=deepseek-v4.1-flash,glm-5.3-flash,gpt-6-luna');

    expect(
      kAiModels,
      equals(['deepseek-v4.1-flash', 'glm-5.3-flash', 'gpt-6-luna']),
    );
    expect(kAiConfig.models, equals(kAiModels));
  });

  test('ignora espacios, entradas vacías y duplicados', () {
    load('AI_MODEL= a , ,b,a ');

    expect(kAiModels, equals(['a', 'b']));
  });

  test('sin AI_MODEL usa el modelo por defecto', () {
    load('API_URL=https://example.com');

    expect(kAiModels, equals(['deepseek-v4.1-flash']));
  });

  test('AI_MODEL vacío usa el modelo por defecto', () {
    load('AI_MODEL=   ');

    expect(kAiModels, equals(['deepseek-v4.1-flash']));
  });

  test('dotenv sin inicializar no rompe la semilla', () {
    dotenv.clean();

    expect(kAiModels, equals(['deepseek-v4.1-flash']));
    expect(kAiConfig.isEnabled, isFalse);
  });
}

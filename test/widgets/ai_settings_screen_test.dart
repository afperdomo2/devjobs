import 'package:devjobs/models/ai_config.dart';
import 'package:devjobs/providers/app_state.dart';
import 'package:devjobs/screens/ai_settings_screen.dart';
import 'package:devjobs/services/sheets_api_service.dart';
import 'package:devjobs/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeApi extends SheetsApiService {
  _FakeApi() : super(baseUrl: 'http://test');
}

void main() {
  Future<AppState> pumpScreen(
    WidgetTester tester, {
    List<String> models = const ['m1'],
    Size size = const Size(800, 1600),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState(apiService: _FakeApi());
    await state.updateAiConfig(
      AiConfig(
        baseUrl: 'https://api.example.com/v1',
        apiKey: 'key',
        models: models,
      ),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          theme: AppTheme.light,
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: FilledButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => const AiSettingsScreen(),
                    ),
                  ),
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    return state;
  }

  testWidgets('muestra la configuración actual y guarda un modelo nuevo', (
    tester,
  ) async {
    final state = await pumpScreen(tester, models: ['m1']);

    expect(find.text('m1'), findsOneWidget);

    await tester.tap(find.byKey(const Key('ai-add-model')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('model-input')), 'm2');
    await tester.tap(find.byKey(const Key('model-submit')));
    await tester.pumpAndSettle();

    expect(find.text('m2'), findsOneWidget);

    await tester.tap(find.byKey(const Key('ai-save')));
    await tester.pumpAndSettle();

    expect(state.aiConfig.models, equals(['m1', 'm2']));
    expect(state.aiConfig.apiKey, equals('key'));
    // Vuelve a la pantalla anterior.
    expect(find.byKey(const Key('ai-save')), findsNothing);
    expect(find.text('Abrir'), findsOneWidget);
  });

  testWidgets('muestra errores si falta la clave', (tester) async {
    final state = await pumpScreen(tester, models: ['m1']);

    await tester.enterText(find.byKey(const Key('ai-api-key')), '');
    await tester.tap(find.byKey(const Key('ai-save')));
    await tester.pumpAndSettle();

    expect(find.text('La API key es obligatoria'), findsOneWidget);
    expect(state.aiConfig.apiKey, equals('key'));
    expect(find.byKey(const Key('ai-save')), findsOneWidget);
  });

  testWidgets('reordena los modelos con las flechas', (tester) async {
    final state = await pumpScreen(tester, models: ['m1', 'm2']);

    await tester.tap(find.byKey(const Key('ai-model-up-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('ai-save')));
    await tester.pumpAndSettle();

    expect(state.aiConfig.models, equals(['m2', 'm1']));
  });

  testWidgets('no permite borrar el único modelo', (tester) async {
    await pumpScreen(tester, models: ['m1']);

    final delete = tester.widget<IconButton>(
      find.byKey(const Key('ai-model-delete-0')),
    );
    expect(delete.onPressed, isNull);
  });

  testWidgets('rechaza un modelo duplicado', (tester) async {
    await pumpScreen(tester, models: ['m1']);

    await tester.tap(find.byKey(const Key('ai-add-model')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('model-input')), 'm1');
    await tester.tap(find.byKey(const Key('model-submit')));
    await tester.pumpAndSettle();

    expect(find.text('Ese modelo ya está en la lista'), findsOneWidget);
    expect(find.byKey(const Key('model-input')), findsOneWidget);
  });

  testWidgets('restablece a los valores del .env', (tester) async {
    final state = await pumpScreen(tester, models: ['m1']);

    await tester.tap(find.byKey(const Key('ai-reset')));
    await tester.pumpAndSettle();

    expect(state.aiConfig.models, equals(['deepseek-v4.1-flash']));
    expect(state.aiConfig.apiKey, isEmpty);
  });

  testWidgets('no desborda a 420×880 con varios modelos', (tester) async {
    await pumpScreen(
      tester,
      models: ['deepseek-v4.1-flash', 'glm-5.3-flash', 'gpt-6-luna'],
      size: const Size(420, 880),
    );

    expect(find.byKey(const Key('ai-save')), findsOneWidget);

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -600),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ai-reset')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

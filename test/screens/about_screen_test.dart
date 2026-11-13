import 'package:devjobs/models/app_build_info.dart';
import 'package:devjobs/screens/about_screen.dart';
import 'package:devjobs/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final complete = AppBuildInfo(
    version: '0.2.0',
    buildNumber: '2',
    commit: '3d8890b',
    buildDate: DateTime(2026, 11, 12, 14, 22),
    platform: 'Linux x64',
    channel: 'release',
  );

  Future<void> pumpAbout(WidgetTester tester, AppBuildInfo info) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: AboutScreen(buildInfo: Future.value(info)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('muestra la versión y los datos de la compilación', (
    tester,
  ) async {
    await pumpAbout(tester, complete);

    expect(find.text('Acerca de'), findsOneWidget);
    expect(find.text('v0.2.0 (2)'), findsOneWidget);
    expect(find.text('3d8890b'), findsOneWidget);
    expect(find.text('12 nov 2026 · 14:22'), findsOneWidget);
    expect(find.text('Linux x64'), findsOneWidget);
    expect(find.text('release'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('avisa cuando hay cambios sin commitear', (tester) async {
    await pumpAbout(
      tester,
      AppBuildInfo(
        version: '0.2.0',
        buildNumber: '2',
        commit: '3d8890b',
        dirty: true,
        platform: 'Linux x64',
        channel: 'release',
      ),
    );

    expect(find.text('3d8890b *'), findsOneWidget);
    expect(
      find.textContaining('Compilada con cambios sin commitear'),
      findsOneWidget,
    );
  });

  testWidgets('sin script de build muestra "No disponible" en commit y fecha', (
    tester,
  ) async {
    await pumpAbout(
      tester,
      const AppBuildInfo(
        version: '0.2.0',
        buildNumber: '2',
        platform: 'Linux x64',
        channel: 'debug',
      ),
    );

    expect(
      tester.widget<Text>(find.byKey(const Key('about-commit'))).data,
      'No disponible',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('about-date'))).data,
      'No disponible',
    );
    expect(find.textContaining('cambios sin commitear'), findsNothing);
  });

  testWidgets(
    'copiar información envía versión y compilación al portapapeles',
    (tester) async {
      final clipboardCalls = <MethodCall>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') clipboardCalls.add(call);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );

      await pumpAbout(tester, complete);

      await tester.tap(find.byKey(const Key('about-copy')));
      await tester.pumpAndSettle();

      expect(clipboardCalls, hasLength(1));
      final text = (clipboardCalls.single.arguments as Map)['text'] as String;
      expect(text, complete.copyText);
      expect(text, contains('DevJobs v0.2.0 (2)'));
      expect(text, contains('Commit: 3d8890b'));
      expect(find.text('Información copiada al portapapeles'), findsOneWidget);
    },
  );
}

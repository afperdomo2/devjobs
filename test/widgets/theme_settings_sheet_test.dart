import 'package:devjobs/providers/app_state.dart';
import 'package:devjobs/services/sheets_api_service.dart';
import 'package:devjobs/theme.dart';
import 'package:devjobs/widgets/theme_settings_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';

class _FakeApi extends SheetsApiService {
  _FakeApi() : super(baseUrl: 'http://test');
}

void main() {
  setUp(() {
    // Evita la lectura real del paquete en el test del tile "Acerca de".
    PackageInfo.setMockInitialValues(
      appName: 'devjobs',
      packageName: 'com.example.devjobs',
      version: '0.2.0',
      buildNumber: '2',
      buildSignature: '',
    );
  });

  Future<void> pumpApp(WidgetTester tester, AppState state) async {
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: Consumer<AppState>(
          builder: (_, current, _) => MaterialApp(
            theme: AppTheme.light,
            darkTheme: AppTheme.dark,
            themeMode: current.themeMode,
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: TextButton(
                    onPressed: () => showThemeSettingsSheet(context),
                    child: const Text('Abrir ajustes'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openSheet(WidgetTester tester) async {
    await tester.tap(find.text('Abrir ajustes'));
    await tester.pumpAndSettle();
  }

  testWidgets('muestra las tres opciones y aplica el tema al instante', (
    tester,
  ) async {
    final state = AppState(apiService: _FakeApi());
    await pumpApp(tester, state);
    await openSheet(tester);

    expect(find.text('Sistema'), findsOneWidget);
    expect(find.text('Claro'), findsOneWidget);
    expect(find.text('Oscuro'), findsOneWidget);

    await tester.tap(find.text('Oscuro'));
    await tester.pumpAndSettle();

    expect(state.themeMode, ThemeMode.dark);
    expect(
      tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
      ThemeMode.dark,
    );
    // La hoja se cierra al elegir.
    expect(find.text('Abrir ajustes'), findsOneWidget);
    expect(find.text('Claro'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('marca la opción activa al abrir el menú', (tester) async {
    final state = AppState(
      apiService: _FakeApi(),
      initialThemeMode: ThemeMode.light,
    );
    await pumpApp(tester, state);
    await openSheet(tester);

    final selected = tester
        .widgetList<ListTile>(find.byType(ListTile))
        .where((tile) => tile.selected)
        .toList();
    expect(selected, hasLength(1));
    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('abre la configuración de la importación con IA', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState(apiService: _FakeApi());
    await pumpApp(tester, state);
    await openSheet(tester);

    expect(find.byKey(const Key('ai-settings')), findsOneWidget);
    expect(find.text('Sin configurar'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('ai-settings')));
    await tester.tap(find.byKey(const Key('ai-settings')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('ai-save')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('muestra la versión y abre Acerca de', (tester) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState(apiService: _FakeApi());
    await pumpApp(tester, state);
    await openSheet(tester);

    expect(find.byKey(const Key('about-settings')), findsOneWidget);
    expect(find.text('Acerca de DevJobs'), findsOneWidget);

    await tester.ensureVisible(find.byKey(const Key('about-settings')));
    await tester.tap(find.byKey(const Key('about-settings')));
    await tester.pumpAndSettle();

    expect(find.text('COMPILACIÓN'), findsOneWidget);
    expect(find.byKey(const Key('about-copy')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

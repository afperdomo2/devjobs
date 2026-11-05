import 'package:devjobs/models/job_application.dart';
import 'package:devjobs/providers/app_state.dart';
import 'package:devjobs/screens/main_screen.dart';
import 'package:devjobs/services/sheets_api_service.dart';
import 'package:devjobs/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

class _FakeApi extends SheetsApiService {
  final List<JobApplication> data;

  _FakeApi(this.data) : super(baseUrl: 'http://test');

  @override
  Future<List<JobApplication>> fetchAll() async => data;
}

void main() {
  Future<AppState> pumpMain(
    WidgetTester tester,
    List<JobApplication> apps, {
    Size size = const Size(600, 1200),
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final state = AppState(apiService: _FakeApi(apps));
    await state.fetchApplications(forceRefresh: true);

    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: state,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const MainScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return state;
  }

  testWidgets('tiene cuatro pestañas y badge de Agenda', (tester) async {
    await pumpMain(tester, [
      const JobApplication(
        rowIndex: 1,
        empresa: 'Pendiente',
        estado: 'En revisión',
        porGestionar: true,
      ),
      const JobApplication(
        rowIndex: 2,
        empresa: 'Entrevista',
        estado: 'Entrevista agendada',
      ),
      const JobApplication(
        rowIndex: 3,
        empresa: 'Normal',
        estado: 'En revisión',
      ),
    ]);

    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Postulaciones'), findsOneWidget);
    expect(find.text('Empresas'), findsOneWidget);
    expect(find.text('Agenda'), findsOneWidget);

    final badges = tester.widgetList<Badge>(find.byType(Badge)).toList();
    expect(badges.any((badge) => badge.isLabelVisible), isTrue);
    expect(
      find.descendant(of: find.byType(Badge), matching: find.text('2')),
      findsWidgets,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('al tocar Agenda muestra sus secciones', (tester) async {
    await pumpMain(tester, [
      const JobApplication(
        rowIndex: 1,
        empresa: 'Pendiente',
        estado: 'En revisión',
        porGestionar: true,
      ),
      const JobApplication(
        rowIndex: 2,
        empresa: 'Entrevista',
        estado: 'Entrevista agendada',
      ),
    ]);

    await tester.tap(find.text('Agenda'));
    await tester.pumpAndSettle();

    expect(find.text('2 pendientes'), findsOneWidget);
    expect(find.text('Por gestionar'), findsOneWidget);
    expect(find.text('Entrevistas agendadas'), findsOneWidget);
    expect(find.text('Pendiente'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el ícono de ajustes abre el menú de tema', (tester) async {
    final state = await pumpMain(tester, []);

    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Sistema'), findsOneWidget);
    expect(find.text('Claro'), findsOneWidget);
    expect(find.text('Oscuro'), findsOneWidget);

    await tester.tap(find.text('Oscuro'));
    await tester.pumpAndSettle();

    expect(state.themeMode, ThemeMode.dark);
    expect(tester.takeException(), isNull);
  });
}

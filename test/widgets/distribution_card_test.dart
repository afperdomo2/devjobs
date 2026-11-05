import 'package:devjobs/theme.dart';
import 'package:devjobs/widgets/distribution_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  /// A 360 px de ancho los dos segmentos deben entrar sin desbordar.
  Future<void> pumpCard(
    WidgetTester tester, {
    List<(String, int)> modalidades = const [('Remoto', 2), ('Híbrido', 1)],
    List<(String, int)> ciudades = const [('Bogotá', 2)],
  }) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(AppSpace.lg),
            child: DistributionCard(
              modalidades: modalidades,
              ciudades: ciudades,
              colorModalidades: AppColors.indigo,
              colorCiudades: AppColors.info,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('pinta los dos segmentos y por defecto modalidades', (
    tester,
  ) async {
    await pumpCard(tester);

    expect(find.text('Modalidades'), findsOneWidget);
    expect(find.text('Ciudades'), findsOneWidget);
    // Plataformas tiene su propia card y Empresas su propia pestaña.
    expect(find.text('Plataformas'), findsNothing);
    expect(find.text('Empresas'), findsNothing);

    // Solo se pinta el grupo activo.
    expect(find.text('Remoto'), findsOneWidget);
    expect(find.text('Híbrido'), findsOneWidget);
    expect(find.text('Bogotá'), findsNothing);
    expect(find.text('Ver todas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('al tocar Ciudades cambia el grupo visible', (tester) async {
    await pumpCard(tester);

    await tester.tap(find.text('Ciudades'));
    await tester.pumpAndSettle();

    expect(find.text('Bogotá'), findsOneWidget);
    expect(find.text('Remoto'), findsNothing);
    expect(find.text('Ver todas'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('un grupo sin datos muestra el guion', (tester) async {
    await pumpCard(tester, ciudades: const []);

    await tester.tap(find.text('Ciudades'));
    await tester.pumpAndSettle();

    expect(find.text('—'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

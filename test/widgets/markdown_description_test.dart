import 'package:devjobs/theme.dart';
import 'package:devjobs/widgets/markdown_description.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpDescription(WidgetTester tester, String data) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: MarkdownDescription(data: data),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renderiza secciones con iconos y viñetas', (tester) async {
    const markdown = '''
## Resumen

Rol backend para Acme.

## Responsabilidades

- Diseñar APIs REST.
- Colaborar con producto.

## Requisitos

- **Experiencia:** 3 años.
''';

    await pumpDescription(tester, markdown);

    expect(find.text('Resumen'), findsOneWidget);
    expect(find.text('Responsabilidades'), findsOneWidget);
    expect(find.text('Requisitos'), findsOneWidget);
    expect(find.byIcon(Icons.summarize_outlined), findsOneWidget);
    expect(find.byIcon(Icons.checklist_rtl), findsOneWidget);
    expect(find.byIcon(Icons.rule), findsOneWidget);
    expect(find.textContaining('Diseñar APIs REST.'), findsOneWidget);
  });

  testWidgets('mantiene el texto plano antiguo', (tester) async {
    const plain = 'Descripción antigua\ncon saltos de línea.';

    await pumpDescription(tester, plain);

    expect(find.text(plain), findsOneWidget);
    expect(find.byType(MarkdownBody), findsNothing);
  });
}

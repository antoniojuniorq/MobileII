import 'package:ace_design_system/ace_design_system.dart';
import 'package:ace_design_system_example/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() => AceTypography.useGoogleFonts = false);

  testWidgets('galeria abre e alterna para o tema escuro', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const AceSampleApp());
    expect(find.text('ACE CONTROL'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.dark_mode_outlined));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
  });
}

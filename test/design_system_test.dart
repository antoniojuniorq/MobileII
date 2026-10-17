import 'package:ace_control_ds/design_system/design_system.dart';
import 'package:ace_control_ds/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  setUpAll(() => AceTypography.useGoogleFonts = false);

  group('Acessibilidade (WCAG AA, 4.5:1)', () {
    test('status têm contraste suficiente nos dois temas', () {
      for (final b in Brightness.values) {
        for (final s in AceStatus.values) {
          final c = s.colors(b);
          expect(contrast(c.fg, c.bg), greaterThanOrEqualTo(4.5), reason: '${s.name} $b');
        }
      }
    });

    test('texto sobre cor primária e sobre superfície', () {
      for (final t in [AceTheme.light, AceTheme.dark]) {
        final c = t.colorScheme;
        expect(contrast(c.onPrimary, c.primary), greaterThanOrEqualTo(4.5));
        expect(contrast(c.onSurface, c.surface), greaterThanOrEqualTo(4.5));
        expect(contrast(t.extension<AceSemantic>()!.textMuted, c.surface), greaterThanOrEqualTo(4.5));
      }
    });
  });

  testWidgets('selo mostra o texto de cada status', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: AceTheme.light,
      home: Scaffold(
        body: Column(children: [for (final s in AceStatus.values) AceStatusBadge(status: s)]),
      ),
    ));
    for (final s in AceStatus.values) {
      expect(find.text(s.label), findsOneWidget);
    }
  });

  testWidgets('botão em carregamento não dispara onPressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(MaterialApp(
      theme: AceTheme.light,
      home: Scaffold(body: AceButton(label: 'Salvar', loading: true, onPressed: () => taps++)),
    ));
    await tester.tap(find.byType(FilledButton));
    expect(taps, 0);
  });

  testWidgets('galeria abre e alterna para o tema escuro', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const AceControlApp());
    expect(find.text('ACE CONTROL'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.dark_mode_outlined));
    await tester.pumpAndSettle();
    expect(find.byIcon(Icons.light_mode_outlined), findsOneWidget);
  });
}

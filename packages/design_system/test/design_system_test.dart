import 'package:ace_design_system/ace_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

Widget host(Widget child) => MaterialApp(
      theme: AceTheme.light,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

void main() {
  setUpAll(() => AceTypography.useGoogleFonts = false);

  group('Acessibilidade (WCAG AA, 4.5:1)', () {
    test('status têm contraste suficiente nos dois temas', () {
      for (final b in Brightness.values) {
        for (final s in AceStatus.values) {
          final c = s.colors(b);
          expect(contrast(c.fg, c.bg), greaterThanOrEqualTo(4.5),
              reason: '${s.name} $b');
        }
      }
    });

    test('texto sobre cor primária e sobre superfície', () {
      for (final t in [AceTheme.light, AceTheme.dark]) {
        final c = t.colorScheme;
        expect(contrast(c.onPrimary, c.primary), greaterThanOrEqualTo(4.5));
        expect(contrast(c.onSurface, c.surface), greaterThanOrEqualTo(4.5));
        expect(
          contrast(t.extension<AceSemantic>()!.textMuted, c.surface),
          greaterThanOrEqualTo(4.5),
        );
      }
    });
  });

  testWidgets('selo mostra o texto de cada status', (tester) async {
    await tester.pumpWidget(host(Column(children: [
      for (final s in AceStatus.values) AceStatusBadge(status: s),
    ])));
    for (final s in AceStatus.values) {
      expect(find.text(s.label), findsOneWidget);
    }
  });

  testWidgets('botão em carregamento não dispara onPressed', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(
      AceButton(label: 'Salvar', loading: true, onPressed: () => taps++),
    ));
    await tester.tap(find.byType(FilledButton));
    expect(taps, 0);
  });

  testWidgets('mensagem inline mostra o texto', (tester) async {
    await tester.pumpWidget(host(
      const AceInlineMessage(message: 'Matrícula ou senha incorreta.'),
    ));
    expect(find.text('Matrícula ou senha incorreta.'), findsOneWidget);
  });

  testWidgets('seletor de status devolve o status tocado', (tester) async {
    AceStatus? picked;
    await tester.pumpWidget(host(
      AceStatusSelector(value: null, onChanged: (s) => picked = s),
    ));
    await tester.tap(find.text('Fechado'));
    expect(picked, AceStatus.fechado);
  });

  testWidgets('barra de progresso limita o valor entre 0 e 1', (tester) async {
    await tester.pumpWidget(host(const AceProgressBar(value: 1.7)));
    final bar = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(bar.value, 1.0);
  });
}

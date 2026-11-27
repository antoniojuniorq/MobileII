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

  group('Componentes do mapa e da visita', () {
    test('selos de lote têm contraste AA nos dois temas', () {
      for (final b in Brightness.values) {
        for (final s in AceLotStatus.values) {
          final c = s.colors(b);
          expect(contrast(c.fg, c.bg), greaterThanOrEqualTo(4.5), reason: '${s.name} $b');
        }
      }
    });

    testWidgets('contador soma, subtrai e não fica negativo', (tester) async {
      var value = 0;
      await tester.pumpWidget(host(StatefulBuilder(
        builder: (context, setState) => AceCounterField(
          label: 'Larvas',
          value: value,
          onChanged: (v) => setState(() => value = v),
        ),
      )));
      await tester.tap(find.byTooltip('Aumentar larvas'));
      await tester.pump();
      await tester.tap(find.byTooltip('Aumentar larvas'));
      await tester.pump();
      expect(value, 2);
      await tester.tap(find.byTooltip('Diminuir larvas'));
      await tester.pump();
      expect(value, 1);
      await tester.enterText(find.byType(TextField), '30');
      await tester.pump();
      expect(value, 30);
    });

    testWidgets('cartão de escolha chama onTap e marca a seleção', (tester) async {
      var tapped = false;
      await tester.pumpWidget(host(AceChoiceCard(
        icon: Icons.person,
        title: 'Supervisor',
        selected: true,
        onTap: () => tapped = true,
      )));
      await tester.tap(find.text('Supervisor'));
      expect(tapped, isTrue);
      expect(find.byIcon(Icons.radio_button_checked), findsOneWidget);
    });

    testWidgets('campo de senha esconde o texto e mostra ao tocar no olho', (tester) async {
      await tester.pumpWidget(host(const AceTextField(label: 'Senha', obscure: true)));
      TextField field() => tester.widget<TextField>(find.byType(TextField));
      expect(field().obscureText, isTrue);
      expect(field().enableSuggestions, isFalse);
      expect(field().autocorrect, isFalse);
      expect(field().keyboardType, TextInputType.visiblePassword);
      await tester.tap(find.byTooltip('Mostrar senha'));
      await tester.pump();
      expect(field().obscureText, isFalse);
    });

    testWidgets('mapa 3D: tocar num bloco devolve o lote', (tester) async {
      AceIsoLot? tapped;
      List<Offset> rect(double x, double y) =>
          [Offset(x, y), Offset(x + 7, y), Offset(x + 7, y + 13), Offset(x, y + 13)];
      await tester.pumpWidget(MaterialApp(
        theme: AceTheme.light,
        home: Scaffold(
          body: SizedBox(
            width: 400,
            height: 400,
            child: AceIsoMap(
              worldWidth: 14,
              worldHeight: 13,
              groups: const [AceIsoGroup(id: 'g', label: 'QI 01', bounds: Rect.fromLTWH(0, 0, 14, 13))],
              lots: [
                AceIsoLot(id: 'a', polygon: rect(0, 0), status: AceLotStatus.pendente, label: '1'),
                AceIsoLot(id: 'b', polygon: rect(7, 0), status: AceLotStatus.visitado, label: '2'),
              ],
              onLotTap: (l) => tapped = l,
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      // mapa pequeno já aparece grande na tela: o toque vai direto para o bloco
      final box = tester.getRect(find.byType(GestureDetector).last);
      await tester.tapAt(box.center + Offset(box.width * 0.22, 0));
      await tester.pump();
      expect(tapped?.id, 'b');
    });

    testWidgets('legenda mostra a quantidade de cada situação', (tester) async {
      await tester.pumpWidget(host(const AceLotLegend(counts: {
        AceLotStatus.pendente: 3,
        AceLotStatus.visitado: 1,
        AceLotStatus.semAcesso: 2,
      })));
      expect(find.text('3 a visitar'), findsOneWidget);
      expect(find.text('1 visitado'), findsOneWidget);
      expect(find.text('2 recusa / ausente'), findsOneWidget);
    });
  });
}

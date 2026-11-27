import 'dart:convert';

import 'package:ace_control_app/app.dart';
import 'package:ace_core/ace_core.dart';
import 'package:ace_design_system/ace_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response _json(Object? body, [int status = 200]) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

const _agent = {
  'id': 1,
  'nome': 'Antonio Junior',
  'matricula': '123456',
  'municipio': 'Palmas - TO',
  'area': 'Área 07',
  'perfil': 'agente',
};
const _supervisor = {
  'id': 2,
  'nome': 'Marina Lopes',
  'matricula': '654321',
  'municipio': 'Palmas - TO',
  'area': 'Supervisão',
  'perfil': 'supervisor',
};

Map<String, dynamic> _lote(int n, String status,
    [Map<String, dynamic>? visita]) {
  // dois lotes por fila (7 × 13), como na planta: 1 e 2 em cima, 3 e 4 embaixo
  final x = ((n - 1) % 2) * 7.0;
  final y = n <= 2 ? 0.0 : 13.0;
  return {
    'id': 'QI01-L${n.toString().padLeft(2, '0')}',
    'numero': '$n',
    'poly': [
      [x, y],
      [x + 7, y],
      [x + 7, y + 13],
      [x, y + 13]
    ],
    'status': status,
    'visita': visita,
  };
}

Map<String, dynamic> _visita(String resultado, {int larvas = 0}) => {
      'resultado': resultado,
      'horario': '08:00',
      'agente': 'Antonio Junior',
      'criadouros': 0,
      'larvas': larvas,
      'animais': 0,
      'focos': 0,
    };

/// Backend falso em memória (espelha o contrato do MockServer).
class FakeBackend {
  FakeBackend({this.sessionValid = true});

  final bool sessionValid;
  final lotes = [
    _lote(1, 'visitado', _visita('visitado', larvas: 4)),
    _lote(2, 'sem_acesso', _visita('recusado')),
    _lote(3, 'pendente'),
    _lote(4, 'pendente'),
  ];
  Map<String, dynamic>? lastVisitBody;
  Map<String, dynamic>? user;

  Map<String, dynamic> _resumo() => {
        'id': '1106',
        'nome': 'Quadra 1106 Sul',
        'bairro': 'ARSE 112 · Palmas - TO',
        'total_lotes': lotes.length,
        'visitados': lotes.where((l) => l['status'] == 'visitado').length,
        'sem_acesso': lotes.where((l) => l['status'] == 'sem_acesso').length,
        'pendentes': lotes.where((l) => l['status'] == 'pendente').length,
      };

  late final MockClient client = MockClient((req) async {
    final path = req.url.path;
    if (path == '/auth/login') {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      final users = {
        '123456': (_agent, 'ace123'),
        '654321': (_supervisor, 'sup123')
      };
      final found = users[body['matricula']];
      if (found == null || found.$2 != body['senha']) {
        return _json({
          'error': {
            'code': 'invalid_credentials',
            'message': 'Matrícula ou senha incorreta.'
          },
        }, 401);
      }
      if (found.$1['perfil'] != body['perfil']) {
        return _json({
          'error': {
            'code': 'wrong_profile',
            'message': 'Esta matrícula não entra como supervisor.'
          },
        }, 403);
      }
      user = found.$1;
      return _json({
        'auth_code': 'abc123',
        'expires_at': '2026-11-07T12:00:00Z',
        'agent': found.$1
      });
    }
    if (path == '/auth/logout') return http.Response('', 204);
    if (!sessionValid) {
      return _json({
        'error': {
          'code': 'unauthorized',
          'message': 'Sessão expirada. Entre novamente.'
        },
      }, 401);
    }
    if (path == '/me') return _json(user ?? _agent);
    if (path == '/quadras') return _json([_resumo()]);
    if (path == '/quadras/1106') {
      return _json({
        ..._resumo(),
        'largura': 14,
        'altura': 26,
        'areas': [],
        'conjuntos': [
          {
            'id': 'QI01',
            'nome': 'QI 01',
            'alameda': 'Alameda 1',
            'lotes': lotes
          },
        ],
      });
    }
    if (path.endsWith('/visita') && req.method == 'POST') {
      final id = path.split('/')[4];
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      lastVisitBody = body;
      final l = lotes.firstWhere((e) => e['id'] == id);
      final ok = body['resultado'] == 'visitado';
      l['status'] = ok ? 'visitado' : 'sem_acesso';
      l['visita'] = {..._visita(body['resultado'] as String), if (ok) ...body}
        ..remove('id');
      return _json(l);
    }
    return _json({
      'error': {'code': 'not_found', 'message': 'Não encontrado'}
    }, 404);
  });
}

Future<AceCore> _pumpApp(
  WidgetTester tester, {
  required FakeBackend backend,
  InMemoryAuthStorage? storage,
}) async {
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);

  final core = AceCore.create(
    baseUrl: 'http://api.test',
    storage: storage ?? InMemoryAuthStorage(),
    httpClient: backend.client,
  );
  await tester.pumpWidget(AceControlApp(core: core));
  await tester.pumpAndSettle();
  return core;
}

Future<void> _login(WidgetTester tester, String matricula, String senha,
    {bool supervisor = false}) async {
  if (supervisor) {
    await tester.tap(find.text('Supervisor'));
    await tester.pump();
  }
  await tester.enterText(find.byType(TextField).at(0), matricula);
  await tester.enterText(find.byType(TextField).at(1), senha);
  await tester.tap(find.byType(FilledButton));
  await tester.pumpAndSettle();
}

InMemoryAuthStorage _agentSession() =>
    InMemoryAuthStorage('abc123', 'agente', '1106');

void main() {
  setUpAll(() => AceTypography.useGoogleFonts = false);

  testWidgets('sem sessão mostra o Login com as duas entradas', (tester) async {
    await _pumpApp(tester, backend: FakeBackend());
    expect(find.text('Agente de campo'), findsOneWidget);
    expect(find.text('Supervisor'), findsOneWidget);
    expect(find.text('Entrar como agente'), findsOneWidget);
  });

  testWidgets('escolher supervisor muda o botão de entrar', (tester) async {
    await _pumpApp(tester, backend: FakeBackend());
    await tester.tap(find.text('Supervisor'));
    await tester.pump();
    expect(find.text('Entrar como supervisor'), findsOneWidget);
  });

  testWidgets('campos vazios mostram erro de validação', (tester) async {
    await _pumpApp(tester, backend: FakeBackend());
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(find.text('Informe sua matrícula.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);
  });

  testWidgets('senha usa teclado de texto, sem sugestões, e pode ser mostrada',
      (tester) async {
    await _pumpApp(tester, backend: FakeBackend());
    final senha = tester.widget<TextField>(find.byType(TextField).at(1));
    expect(senha.obscureText, isTrue);
    expect(senha.keyboardType, TextInputType.visiblePassword);
    expect(senha.enableSuggestions, isFalse);

    // "próximo" na matrícula leva o foco para a senha
    await tester.showKeyboard(find.byType(TextField).at(0));
    await tester.testTextInput.receiveAction(TextInputAction.next);
    await tester.pumpAndSettle();
    final focused =
        tester.widget<TextField>(find.byType(TextField).at(1)).focusNode!;
    expect(focused.hasFocus, isTrue);
  });

  testWidgets('agente entra, escolhe a quadra 1106 e vê a Home',
      (tester) async {
    final storage = InMemoryAuthStorage();
    await _pumpApp(tester, backend: FakeBackend(), storage: storage);
    await _login(tester, '123456', 'ace123');

    expect(await storage.readAuthCode(), 'abc123');
    expect(find.text('Em qual quadra você trabalha hoje?'), findsOneWidget);
    await tester.tap(find.text('Abrir mapa da quadra'));
    await tester.pumpAndSettle();

    expect(await storage.readQuadra(), '1106');
    expect(find.text('Últimas visitas'), findsOneWidget);
    expect(find.text('2 lotes esperam visita hoje.'), findsOneWidget);
  });

  testWidgets('login com erro mostra a mensagem e não guarda nada',
      (tester) async {
    final storage = InMemoryAuthStorage();
    await _pumpApp(tester, backend: FakeBackend(), storage: storage);
    await _login(tester, '123456', 'errada');

    expect(find.text('Matrícula ou senha incorreta.'), findsOneWidget);
    expect(await storage.readAuthCode(), isNull);
  });

  testWidgets('matrícula de agente não entra como supervisor', (tester) async {
    await _pumpApp(tester, backend: FakeBackend());
    await _login(tester, '123456', 'ace123', supervisor: true);
    expect(
        find.text('Esta matrícula não entra como supervisor.'), findsOneWidget);
  });

  testWidgets('supervisor entra no painel da quadra', (tester) async {
    final storage = InMemoryAuthStorage();
    await _pumpApp(tester, backend: FakeBackend(), storage: storage);
    await _login(tester, '654321', 'sup123', supervisor: true);

    expect(await storage.readPerfil(), 'supervisor');
    expect(find.text('Andamento de hoje'), findsOneWidget);
    expect(find.text('Visitas registradas (2)'), findsOneWidget);
  });

  testWidgets('com sessão e quadra salvas abre direto na Home', (tester) async {
    await _pumpApp(tester, backend: FakeBackend(), storage: _agentSession());
    expect(find.text('Últimas visitas'), findsOneWidget);
    expect(find.byType(FilledButton), findsWidgets);
    expect(find.text('Entrar como agente'), findsNothing);
  });

  testWidgets('sessão expirada limpa o storage e volta ao Login',
      (tester) async {
    final storage = _agentSession();
    await _pumpApp(tester,
        backend: FakeBackend(sessionValid: false), storage: storage);
    expect(find.text('Entrar como agente'), findsOneWidget);
    expect(await storage.readAuthCode(), isNull);
  });

  testWidgets('aba Mapa mostra o mapa 3D e a legenda', (tester) async {
    await _pumpApp(tester, backend: FakeBackend(), storage: _agentSession());
    await tester.tap(find.text('Mapa'));
    await tester.pumpAndSettle();
    expect(find.byType(AceIsoMap), findsOneWidget);
    expect(find.text('2 a visitar'), findsOneWidget);
    expect(find.text('1 visitado'), findsOneWidget);
    expect(find.text('1 recusa / ausente'), findsOneWidget);
  });

  testWidgets('lote recusado vira visitado com as contagens', (tester) async {
    final backend = FakeBackend();
    await _pumpApp(tester, backend: backend, storage: _agentSession());

    await tester.tap(find.textContaining('recusa ou ninguém em casa'));
    await tester.pumpAndSettle();
    expect(find.text('Resultado da visita'), findsOneWidget);

    await tester.tap(find.text('Visitado').last);
    await tester.pumpAndSettle();
    expect(find.text('Criadouros encontrados'), findsOneWidget);

    await tester.tap(find.byTooltip('Aumentar larvas'));
    await tester.pump();
    await tester.tap(find.byTooltip('Aumentar larvas'));
    await tester.pump();
    await tester.tap(find.byTooltip('Aumentar locais com focos'));
    await tester.pump();
    await tester.tap(find.text('Salvar visita'));
    await tester.pumpAndSettle();

    expect(backend.lastVisitBody, {
      'resultado': 'visitado',
      'criadouros': 0,
      'larvas': 2,
      'animais': 0,
      'focos': 1
    });
    expect(backend.lotes[1]['status'], 'visitado');
    expect(find.text('Resultado da visita'), findsNothing);
  });

  testWidgets('salvar sem escolher o resultado pede a escolha', (tester) async {
    final backend = FakeBackend();
    await _pumpApp(tester, backend: backend, storage: _agentSession());
    await tester.tap(find.text('Mapa'));
    await tester.pumpAndSettle();
    // mapa pequeno (2 × 4 lotes): o toque cai direto na casa do lote 4 (pendente)
    final map = tester.getRect(find.byType(AceIsoMap));
    await tester.tapAt(map.center + Offset(0, map.height * 0.22));
    await tester.pumpAndSettle();
    expect(find.text('Resultado da visita'), findsOneWidget);
    expect(find.text('Lote 4'), findsOneWidget);
    await tester.tap(find.text('Salvar visita'));
    await tester.pumpAndSettle();
    expect(find.text('Escolha o resultado da visita.'), findsOneWidget);
    expect(backend.lastVisitBody, isNull);
  });
}

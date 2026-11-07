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
};

List<Map<String, dynamic>> _seed() => [
      {'id': 1, 'lote': '07', 'endereco': 'Rua das Mangabas, 120', 'quadra': 'Quadra 12', 'horario': '08:40', 'status': 'visitado', 'observacao': null},
      {'id': 6, 'lote': '12', 'endereco': 'Rua dos Buritis, 61', 'quadra': 'Quadra 14', 'horario': null, 'status': 'pendente', 'observacao': null},
      {'id': 7, 'lote': '13', 'endereco': 'Rua dos Buritis, 77', 'quadra': 'Quadra 14', 'horario': null, 'status': 'pendente', 'observacao': null},
    ];

/// Backend falso em memória (espelha o contrato do MockServer).
class FakeBackend {
  FakeBackend({this.loginOk = true, this.sessionValid = true});

  final bool loginOk;
  final bool sessionValid;
  final visits = _seed();

  late final MockClient client = MockClient((req) async {
    final path = req.url.path;
    if (path == '/auth/login') {
      return loginOk
          ? _json({
              'auth_code': 'abc123',
              'expires_at': '2026-11-07T12:00:00Z',
              'agent': _agent,
            })
          : _json({
              'error': {
                'code': 'invalid_credentials',
                'message': 'Matrícula ou senha incorreta.',
              },
            }, 401);
    }
    if (path == '/auth/logout') return http.Response('', 204);
    if (!sessionValid) {
      return _json({
        'error': {'code': 'unauthorized', 'message': 'Sessão expirada. Entre novamente.'},
      }, 401);
    }
    if (path == '/me') return _json(_agent);
    if (path == '/summary/today') {
      final pending = visits.where((v) => v['status'] == 'pendente').length;
      return _json({
        'date': '2026-11-07',
        'goal': 10,
        'visits_total': visits.length,
        'visits_done': visits.length - pending,
        'visits_pending': pending,
        'focos_found': visits.where((v) => v['status'] == 'com_foco').length,
      });
    }
    if (path == '/visits' && req.method == 'GET') return _json(visits);
    if (path.startsWith('/visits/') && req.method == 'PATCH') {
      final id = int.parse(path.split('/').last);
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      final v = visits.firstWhere((e) => e['id'] == id);
      v['status'] = body['status'];
      v['observacao'] = body['observacao'];
      v['horario'] ??= '10:00';
      return _json(v);
    }
    return _json({'error': {'code': 'not_found', 'message': 'Não encontrado'}}, 404);
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

Future<void> _fillAndSubmitLogin(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).at(0), '123456');
  await tester.enterText(find.byType(TextField).at(1), 'ace123');
  await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
  await tester.pumpAndSettle();
}

void main() {
  setUpAll(() => AceTypography.useGoogleFonts = false);

  testWidgets('sem sessão mostra o Login', (tester) async {
    await _pumpApp(tester, backend: FakeBackend());
    expect(find.text('ACE CONTROL'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Entrar'), findsOneWidget);
  });

  testWidgets('campos vazios mostram erro de validação', (tester) async {
    await _pumpApp(tester, backend: FakeBackend());
    await tester.tap(find.widgetWithText(FilledButton, 'Entrar'));
    await tester.pumpAndSettle();
    expect(find.text('Informe sua matrícula.'), findsOneWidget);
    expect(find.text('Informe sua senha.'), findsOneWidget);
  });

  testWidgets('login com sucesso guarda o auth code e abre a Home',
      (tester) async {
    final storage = InMemoryAuthStorage();
    await _pumpApp(tester, backend: FakeBackend(), storage: storage);
    await _fillAndSubmitLogin(tester);

    expect(await storage.readAuthCode(), 'abc123');
    expect(find.text('Roteiro de hoje'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Entrar'), findsNothing);
  });

  testWidgets('login com erro mostra a mensagem na tela de Login',
      (tester) async {
    final storage = InMemoryAuthStorage();
    await _pumpApp(tester, backend: FakeBackend(loginOk: false), storage: storage);
    await _fillAndSubmitLogin(tester);

    expect(find.text('Matrícula ou senha incorreta.'), findsOneWidget);
    expect(find.text('Roteiro de hoje'), findsNothing);
    expect(await storage.readAuthCode(), isNull);
  });

  testWidgets('com auth code salvo abre direto na Home', (tester) async {
    await _pumpApp(
      tester,
      backend: FakeBackend(),
      storage: InMemoryAuthStorage('abc123'),
    );
    expect(find.text('Roteiro de hoje'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Entrar'), findsNothing);
  });

  testWidgets('sessão expirada limpa o storage e volta ao Login',
      (tester) async {
    final storage = InMemoryAuthStorage('velho');
    await _pumpApp(
      tester,
      backend: FakeBackend(sessionValid: false),
      storage: storage,
    );
    expect(find.widgetWithText(FilledButton, 'Entrar'), findsOneWidget);
    expect(await storage.readAuthCode(), isNull);
  });

  testWidgets('registrar visita envia o status para a API', (tester) async {
    final backend = FakeBackend();
    await _pumpApp(
      tester,
      backend: backend,
      storage: InMemoryAuthStorage('abc123'),
    );

    await tester.tap(find.text('Rua dos Buritis, 61'));
    await tester.pumpAndSettle();
    expect(find.text('Resultado da visita'), findsOneWidget);

    await tester.tap(find.descendant(
      of: find.byType(AceStatusSelector),
      matching: find.text('Com foco'),
    ));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Salvar visita'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    final saved = backend.visits.firstWhere((v) => v['id'] == 6);
    expect(saved['status'], 'com_foco');
    expect(find.text('Resultado da visita'), findsNothing);
  });
}

import 'dart:convert';

import 'package:ace_core/ace_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

http.Response jsonResponse(Object body, [int status = 200]) => http.Response(
      jsonEncode(body),
      status,
      headers: {'content-type': 'application/json; charset=utf-8'},
    );

const loginBody = {
  'auth_code': 'abc123',
  'expires_at': '2026-11-07T12:00:00Z',
  'agent': {
    'id': 1,
    'nome': 'Antonio Junior',
    'matricula': '123456',
    'municipio': 'Palmas - TO',
    'area': 'Área 07',
  },
};

void main() {
  group('ApiClient', () {
    test('envia Bearer quando há auth code', () async {
      String? header;
      final api = ApiClient(
        baseUrl: 'http://x',
        authCodeProvider: () async => 'tok',
        httpClient: MockClient((req) async {
          header = req.headers['Authorization'];
          return jsonResponse({'ok': true});
        }),
      );
      await api.get('/me');
      expect(header, 'Bearer tok');
    });

    test('converte erro da API em ApiException', () async {
      final api = ApiClient(
        baseUrl: 'http://x',
        httpClient: MockClient((_) async => jsonResponse({
              'error': {
                'code': 'invalid_credentials',
                'message': 'Matrícula ou senha incorreta.',
              },
            }, 401)),
      );
      expect(
        api.post('/auth/login', body: {}),
        throwsA(isA<ApiException>()
            .having((e) => e.code, 'code', 'invalid_credentials')
            .having((e) => e.isUnauthorized, 'isUnauthorized', false)
            .having(
                (e) => e.message, 'message', 'Matrícula ou senha incorreta.')),
      );
    });

    test('401 unauthorized marca sessão expirada', () async {
      final api = ApiClient(
        baseUrl: 'http://x',
        httpClient: MockClient((_) async => jsonResponse({
              'error': {'code': 'unauthorized', 'message': 'Sessão expirada.'},
            }, 401)),
      );
      expect(
        api.get('/me'),
        throwsA(isA<ApiException>().having((e) => e.isUnauthorized, 'u', true)),
      );
    });

    test('falha de rede vira ApiException(network)', () async {
      final api = ApiClient(
        baseUrl: 'http://x',
        httpClient: MockClient((_) async => throw http.ClientException('x')),
      );
      expect(
        api.get('/me'),
        throwsA(isA<ApiException>().having((e) => e.code, 'code', 'network')),
      );
    });

    test('resposta de erro sem JSON usa mensagem padrão', () async {
      final api = ApiClient(
        baseUrl: 'http://x',
        httpClient: MockClient((_) async => http.Response('<html>', 502)),
      );
      expect(
        api.get('/me'),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 502)),
      );
    });
  });

  group('AuthRepository', () {
    test('login guarda o auth code e devolve o agente', () async {
      final storage = InMemoryAuthStorage();
      final core = AceCore.create(
        baseUrl: 'http://x',
        storage: storage,
        httpClient: MockClient((_) async => jsonResponse(loginBody)),
      );
      final agent = await core.auth.login(matricula: '123456', senha: 'ace123');
      expect(agent.primeiroNome, 'Antonio');
      expect(await storage.readAuthCode(), 'abc123');
      expect(await core.auth.hasSession(), isTrue);
    });

    test('login com erro não guarda nada', () async {
      final storage = InMemoryAuthStorage();
      final core = AceCore.create(
        baseUrl: 'http://x',
        storage: storage,
        httpClient: MockClient((_) async => jsonResponse({
              'error': {'code': 'invalid_credentials', 'message': 'Erro'},
            }, 401)),
      );
      await expectLater(
        core.auth.login(matricula: '1', senha: '2'),
        throwsA(isA<ApiException>()),
      );
      expect(await core.auth.hasSession(), isFalse);
    });

    test('logout limpa o storage mesmo se a API falhar', () async {
      final storage = InMemoryAuthStorage('abc');
      final core = AceCore.create(
        baseUrl: 'http://x',
        storage: storage,
        httpClient: MockClient((_) async => throw http.ClientException('x')),
      );
      await core.auth.logout();
      expect(await storage.readAuthCode(), isNull);
    });
  });

  group('Modelos e repositórios', () {
    test('Summary calcula progresso limitado a 1.0', () {
      final s = Summary.fromJson({
        'date': '2026-11-07',
        'goal': 10,
        'visits_total': 12,
        'visits_done': 12,
        'visits_pending': 0,
        'focos_found': 1,
      });
      expect(s.progress, 1.0);
    });

    test('VisitStatus converte de/para a API', () {
      expect(VisitStatus.fromApi('com_foco'), VisitStatus.comFoco);
      expect(VisitStatus.comFoco.apiValue, 'com_foco');
      expect(VisitStatus.fromApi('desconhecido'), VisitStatus.pendente);
    });

    test('VisitsRepository.update envia status e observação', () async {
      Map<String, dynamic>? sent;
      final core = AceCore.create(
        baseUrl: 'http://x',
        storage: InMemoryAuthStorage('t'),
        httpClient: MockClient((req) async {
          sent = jsonDecode(req.body) as Map<String, dynamic>;
          return jsonResponse({
            'id': 6,
            'lote': '12',
            'endereco': 'Rua X',
            'quadra': 'Quadra 14',
            'horario': '10:00',
            'status': 'com_foco',
            'observacao': 'Pneus',
          });
        }),
      );
      final v = await core.visits
          .update(6, status: VisitStatus.comFoco, observacao: 'Pneus');
      expect(sent, {'status': 'com_foco', 'observacao': 'Pneus'});
      expect(v.status, VisitStatus.comFoco);
    });
  });
}

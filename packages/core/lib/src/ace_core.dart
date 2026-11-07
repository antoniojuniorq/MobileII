import 'package:http/http.dart' as http;

import 'config/api_config.dart';
import 'network/api_client.dart';
import 'repositories/agent_repository.dart';
import 'repositories/auth_repository.dart';
import 'repositories/visits_repository.dart';
import 'storage/auth_storage.dart';

/// Ponto único de entrada do Core: monta cliente, storage e repositórios.
class AceCore {
  AceCore._({
    required this.api,
    required this.storage,
    required this.auth,
    required this.agent,
    required this.visits,
  });

  final ApiClient api;
  final AuthStorage storage;
  final AuthRepository auth;
  final AgentRepository agent;
  final VisitsRepository visits;

  /// [baseUrl], [httpClient] e [storage] existem para testes; no app use `create()`.
  factory AceCore.create({
    String? baseUrl,
    http.Client? httpClient,
    AuthStorage? storage,
  }) {
    final store = storage ?? SharedPrefsAuthStorage();
    final api = ApiClient(
      baseUrl: baseUrl ?? ApiConfig.baseUrl,
      httpClient: httpClient,
      authCodeProvider: store.readAuthCode,
    );
    return AceCore._(
      api: api,
      storage: store,
      auth: AuthRepository(api, store),
      agent: AgentRepository(api),
      visits: VisitsRepository(api),
    );
  }
}

import '../models/agent.dart';
import '../models/login_response.dart';
import '../network/api_client.dart';
import '../network/api_exception.dart';
import '../storage/auth_storage.dart';

/// Login, logout e estado da sessão.
class AuthRepository {
  AuthRepository(this._api, this._storage);

  final ApiClient _api;
  final AuthStorage _storage;

  /// Faz login e guarda o auth code no storage.
  Future<Agent> login({required String matricula, required String senha}) async {
    final json = await _api.post(
      '/auth/login',
      body: {'matricula': matricula, 'senha': senha},
    );
    final response = LoginResponse.fromJson(json as Map<String, dynamic>);
    await _storage.saveAuthCode(response.authCode);
    return response.agent;
  }

  Future<bool> hasSession() async {
    final code = await _storage.readAuthCode();
    return code != null && code.isNotEmpty;
  }

  /// Encerra a sessão. Sempre limpa o storage, mesmo se a API falhar.
  Future<void> logout() async {
    try {
      await _api.post('/auth/logout');
    } on ApiException {
      // Sessão local é removida de qualquer forma.
    } finally {
      await _storage.clear();
    }
  }
}

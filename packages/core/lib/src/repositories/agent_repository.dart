import '../models/agent.dart';
import '../network/api_client.dart';

class AgentRepository {
  AgentRepository(this._api);
  final ApiClient _api;

  Future<Agent> me() async =>
      Agent.fromJson(await _api.get('/me') as Map<String, dynamic>);
}

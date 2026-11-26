import 'package:ace_core/ace_core.dart';

import '../scene_view_model.dart';

enum HomeStatus { loading, ready, failure, unauthorized }

/// Dia do agente na quadra escolhida: planta, situação dos lotes e registro.
class HomeViewModel extends SceneViewModel {
  HomeViewModel({
    required this.quadraId,
    required AgentRepository agentRepository,
    required QuadrasRepository quadrasRepository,
    required AuthRepository authRepository,
  })  : _agentRepo = agentRepository,
        _quadras = quadrasRepository,
        _auth = authRepository;

  final String quadraId;
  final AgentRepository _agentRepo;
  final QuadrasRepository _quadras;
  final AuthRepository _auth;

  HomeStatus status = HomeStatus.loading;
  Agent? agent;
  Quadra? quadra;
  String? errorMessage;

  /// Falha ao atualizar com dados já na tela (mantém o conteúdo visível).
  String? refreshError;

  Future<void> load({bool silent = false}) async {
    final hasData = agent != null && quadra != null;
    if (!(silent && hasData)) {
      status = HomeStatus.loading;
      errorMessage = null;
      notifyListeners();
    }
    refreshError = null;

    try {
      final me = await _agentRepo.me();
      final q = await _quadras.get(quadraId);
      agent = me;
      quadra = q;
      status = HomeStatus.ready;
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        status = HomeStatus.unauthorized;
      } else if (silent && hasData) {
        refreshError = e.message;
        status = HomeStatus.ready;
      } else {
        status = HomeStatus.failure;
        errorMessage = e.message;
      }
    } catch (_) {
      status = HomeStatus.failure;
      errorMessage = 'Não foi possível carregar. Tente novamente.';
    }
    notifyListeners();
  }

  /// Salva a visita do lote. Retorna `null` se deu certo, ou a mensagem de erro.
  Future<String?> registrar(Lote lote, ResultadoVisita resultado, Achados achados) async {
    try {
      await _quadras.registrarVisita(
        quadraId: quadraId,
        loteId: lote.id,
        resultado: resultado,
        achados: achados,
      );
      await load(silent: true);
      return null;
    } on ApiException catch (e) {
      if (e.isUnauthorized) {
        status = HomeStatus.unauthorized;
        notifyListeners();
      }
      return e.message;
    } catch (_) {
      return 'Não foi possível salvar. Tente novamente.';
    }
  }

  Future<void> logout() => _auth.logout();
}

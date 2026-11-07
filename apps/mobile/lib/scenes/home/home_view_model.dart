import 'package:ace_core/ace_core.dart';

import '../scene_view_model.dart';

enum HomeStatus { loading, ready, failure, unauthorized }

class HomeViewModel extends SceneViewModel {
  HomeViewModel({
    required AgentRepository agentRepository,
    required VisitsRepository visitsRepository,
    required AuthRepository authRepository,
  })  : _agentRepo = agentRepository,
        _visitsRepo = visitsRepository,
        _auth = authRepository;

  final AgentRepository _agentRepo;
  final VisitsRepository _visitsRepo;
  final AuthRepository _auth;

  HomeStatus status = HomeStatus.loading;
  Agent? agent;
  Summary? summary;
  List<Visit> visits = const [];
  String? errorMessage;

  /// Falha ao atualizar com dados já na tela (mantém o conteúdo visível).
  String? refreshError;

  /// Pendentes primeiro, depois as já visitadas.
  List<Visit> get pendingFirst {
    final pending = visits.where((v) => v.status == VisitStatus.pendente);
    final others = visits.where((v) => v.status != VisitStatus.pendente);
    return [...pending, ...others];
  }

  Future<void> load({bool silent = false}) async {
    final hasData = agent != null && summary != null;
    if (!(silent && hasData)) {
      status = HomeStatus.loading;
      errorMessage = null;
      notifyListeners();
    }
    refreshError = null;

    try {
      final me = await _agentRepo.me();
      final todaySummary = await _visitsRepo.summaryToday();
      final todayVisits = await _visitsRepo.list();
      agent = me;
      summary = todaySummary;
      visits = todayVisits;
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

  /// Salva o resultado da visita. Retorna `null` se deu certo, ou a mensagem de erro.
  Future<String?> saveVisit(
    Visit visit,
    VisitStatus newStatus,
    String? observacao,
  ) async {
    try {
      await _visitsRepo.update(
        visit.id,
        status: newStatus,
        observacao: observacao,
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

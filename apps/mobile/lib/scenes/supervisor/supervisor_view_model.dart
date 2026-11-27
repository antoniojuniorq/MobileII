import 'package:ace_core/ace_core.dart';

import '../scene_view_model.dart';

enum SupervisorStatus { loading, ready, failure, unauthorized }

class SupervisorViewModel extends SceneViewModel {
  SupervisorViewModel(this._agentRepo, this._quadras, this._auth);

  final AgentRepository _agentRepo;
  final QuadrasRepository _quadras;
  final AuthRepository _auth;

  SupervisorStatus status = SupervisorStatus.loading;
  Agent? me;
  List<QuadraResumo> quadras = const [];
  Quadra? quadra;
  String? errorMessage;

  Future<void> load({String? quadraId, bool silent = false}) async {
    if (!silent) {
      status = SupervisorStatus.loading;
      notifyListeners();
    }
    try {
      me = await _agentRepo.me();
      quadras = await _quadras.list();
      final id = quadraId ?? quadra?.id ?? quadras.firstOrNull?.id;
      quadra = id == null ? null : await _quadras.get(id);
      status = SupervisorStatus.ready;
    } on ApiException catch (e) {
      status = e.isUnauthorized
          ? SupervisorStatus.unauthorized
          : SupervisorStatus.failure;
      errorMessage = e.message;
    } catch (_) {
      status = SupervisorStatus.failure;
      errorMessage = 'Não foi possível carregar. Tente novamente.';
    }
    notifyListeners();
  }

  Future<void> logout() => _auth.logout();
}

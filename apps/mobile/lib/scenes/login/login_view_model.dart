import 'package:ace_core/ace_core.dart';

import '../scene_view_model.dart';

enum LoginStatus { idle, loading, success, failure }

class LoginViewModel extends SceneViewModel {
  LoginViewModel(this._auth);

  final AuthRepository _auth;

  LoginStatus status = LoginStatus.idle;
  String? errorMessage;
  String? matriculaError;
  String? senhaError;

  bool get isLoading => status == LoginStatus.loading;

  Future<void> submit(String matricula, String senha) async {
    matriculaError = matricula.trim().isEmpty ? 'Informe sua matrícula.' : null;
    senhaError = senha.isEmpty ? 'Informe sua senha.' : null;
    errorMessage = null;

    if (matriculaError != null || senhaError != null) {
      status = LoginStatus.idle;
      notifyListeners();
      return;
    }

    status = LoginStatus.loading;
    notifyListeners();
    try {
      await _auth.login(matricula: matricula.trim(), senha: senha);
      status = LoginStatus.success;
    } on ApiException catch (e) {
      status = LoginStatus.failure;
      errorMessage = e.message;
    } catch (_) {
      status = LoginStatus.failure;
      errorMessage = 'Não foi possível entrar. Tente novamente.';
    }
    notifyListeners();
  }
}

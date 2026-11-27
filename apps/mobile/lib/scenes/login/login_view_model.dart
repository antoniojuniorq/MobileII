import 'package:ace_core/ace_core.dart';

import '../scene_view_model.dart';

enum LoginStatus { idle, loading, success, failure }

class LoginViewModel extends SceneViewModel {
  LoginViewModel(this._auth);

  final AuthRepository _auth;

  LoginStatus status = LoginStatus.idle;
  Perfil perfil = Perfil.agente;
  String? errorMessage;
  String? matriculaError;
  String? senhaError;

  bool get isLoading => status == LoginStatus.loading;

  String get submitLabel =>
      perfil == Perfil.agente ? 'Entrar como agente' : 'Entrar como supervisor';

  void choosePerfil(Perfil p) {
    if (isLoading || p == perfil) return;
    perfil = p;
    errorMessage = null;
    notifyListeners();
  }

  Future<void> submit(String matricula, String senha) async {
    if (isLoading) return;
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
      await _auth.login(
          matricula: matricula.trim(), senha: senha, perfil: perfil);
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

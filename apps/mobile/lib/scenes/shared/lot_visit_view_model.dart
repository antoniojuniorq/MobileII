import 'package:ace_core/ace_core.dart';

import '../scene_view_model.dart';

/// Salva a visita. Retorna `null` se deu certo, ou a mensagem de erro.
typedef SalvarVisita = Future<String?> Function(
    ResultadoVisita resultado, Achados achados);

/// Estado do formulário de visita de um lote: resultado escolhido, as quatro
/// contagens, validação e envio. Quem de fato grava é [SalvarVisita]
/// (no agente, `HomeViewModel.registrar`).
class LotVisitViewModel extends SceneViewModel {
  LotVisitViewModel({required Lote lote, SalvarVisita? salvar})
      : _salvar = salvar,
        resultado = lote.visita?.resultado,
        achados = lote.visita?.achados ?? const Achados();

  final SalvarVisita? _salvar;

  ResultadoVisita? resultado;
  Achados achados;
  bool saving = false;
  bool saved = false;
  String? error;

  /// Supervisor: só consulta.
  bool get readOnly => _salvar == null;

  bool get visitado => resultado == ResultadoVisita.visitado;

  void escolher(ResultadoVisita r) {
    if (saving || readOnly) return;
    resultado = r;
    error = null;
    notifyListeners();
  }

  void setCriadouros(int n) => _setAchados(criadouros: n);
  void setLarvas(int n) => _setAchados(larvas: n);
  void setAnimais(int n) => _setAchados(animais: n);
  void setFocos(int n) => _setAchados(focos: n);

  void _setAchados({int? criadouros, int? larvas, int? animais, int? focos}) {
    achados = Achados(
      criadouros: criadouros ?? achados.criadouros,
      larvas: larvas ?? achados.larvas,
      animais: animais ?? achados.animais,
      focos: focos ?? achados.focos,
    );
    notifyListeners();
  }

  /// Valida e envia. Em recusa os números vão zerados.
  Future<void> salvar() async {
    if (saving || readOnly) return;
    final r = resultado;
    if (r == null) {
      error = 'Escolha o resultado da visita.';
      notifyListeners();
      return;
    }
    saving = true;
    error = null;
    notifyListeners();

    final falha = await _salvar!(
        r, r == ResultadoVisita.visitado ? achados : const Achados());
    saving = false;
    saved = falha == null;
    error = falha;
    notifyListeners();
  }
}

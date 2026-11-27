import 'package:ace_core/ace_core.dart';

import '../scene_view_model.dart';

enum QuadraPickerStatus { loading, ready, failure, unauthorized }

class QuadraPickerViewModel extends SceneViewModel {
  QuadraPickerViewModel(this._quadras, this._auth);

  final QuadrasRepository _quadras;
  final AuthRepository _auth;

  QuadraPickerStatus status = QuadraPickerStatus.loading;
  List<QuadraResumo> quadras = const [];
  String? selected;
  String? errorMessage;

  Future<void> load() async {
    status = QuadraPickerStatus.loading;
    notifyListeners();
    try {
      quadras = await _quadras.list();
      selected = await _quadras.quadraEscolhida() ?? quadras.firstOrNull?.id;
      status = QuadraPickerStatus.ready;
    } on ApiException catch (e) {
      status = e.isUnauthorized
          ? QuadraPickerStatus.unauthorized
          : QuadraPickerStatus.failure;
      errorMessage = e.message;
    } catch (_) {
      status = QuadraPickerStatus.failure;
      errorMessage = 'Não foi possível carregar as quadras.';
    }
    notifyListeners();
  }

  void choose(String id) {
    selected = id;
    notifyListeners();
  }

  Future<void> confirm() async => _quadras.escolherQuadra(selected!);

  Future<void> logout() => _auth.logout();
}

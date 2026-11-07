import 'package:flutter/foundation.dart';

/// Base dos ViewModels das cenas (padrão: Scene + ViewModel).
///
/// A cena só desenha e repassa ações; o ViewModel guarda o estado e fala com
/// os repositórios do Core. `notifyListeners` é seguro após o `dispose`.
abstract class SceneViewModel extends ChangeNotifier {
  bool _disposed = false;

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

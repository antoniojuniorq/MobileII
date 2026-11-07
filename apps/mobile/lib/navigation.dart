import 'package:ace_core/ace_core.dart';
import 'package:flutter/material.dart';

import 'scenes/home/home_scene.dart';
import 'scenes/login/login_scene.dart';

/// Navegação entre cenas. Limpa a pilha: Login e Home nunca ficam empilhados.
void goToHome(BuildContext context, AceCore core) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => HomeScene(core: core)),
    (_) => false,
  );
}

void goToLogin(BuildContext context, AceCore core) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => LoginScene(core: core)),
    (_) => false,
  );
}

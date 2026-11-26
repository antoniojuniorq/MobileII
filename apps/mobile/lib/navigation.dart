import 'package:ace_core/ace_core.dart';
import 'package:flutter/material.dart';

import 'scenes/home/home_scene.dart';
import 'scenes/login/login_scene.dart';
import 'scenes/quadra/quadra_picker_scene.dart';
import 'scenes/supervisor/supervisor_scene.dart';

/// Primeira cena de uma sessão aberta: supervisor vai para o painel; agente
/// vai para a sua quadra (ou escolhe uma, se ainda não escolheu).
Future<Widget> startSceneFor(AceCore core) async {
  if (!await core.auth.hasSession()) return LoginScene(core: core);
  if (await core.auth.perfil() == Perfil.supervisor) {
    return SupervisorScene(core: core);
  }
  final quadra = await core.quadras.quadraEscolhida();
  return quadra == null
      ? QuadraPickerScene(core: core)
      : HomeScene(core: core, quadraId: quadra);
}

/// Navegação entre cenas. Limpa a pilha: Login e Home nunca ficam empilhados.
void _replaceAll(BuildContext context, Widget scene) {
  Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute<void>(builder: (_) => scene),
    (_) => false,
  );
}

Future<void> goToStart(BuildContext context, AceCore core) async {
  final scene = await startSceneFor(core);
  if (context.mounted) _replaceAll(context, scene);
}

void goToHome(BuildContext context, AceCore core, String quadraId) =>
    _replaceAll(context, HomeScene(core: core, quadraId: quadraId));

void goToQuadraPicker(BuildContext context, AceCore core) =>
    _replaceAll(context, QuadraPickerScene(core: core));

void goToLogin(BuildContext context, AceCore core) =>
    _replaceAll(context, LoginScene(core: core));

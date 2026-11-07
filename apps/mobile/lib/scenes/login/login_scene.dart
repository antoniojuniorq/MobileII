import 'package:ace_core/ace_core.dart';
import 'package:ace_design_system/ace_design_system.dart';
import 'package:flutter/material.dart';

import '../../navigation.dart';
import 'login_view_model.dart';

class LoginScene extends StatefulWidget {
  const LoginScene({super.key, required this.core});

  final AceCore core;

  @override
  State<LoginScene> createState() => _LoginSceneState();
}

class _LoginSceneState extends State<LoginScene> {
  late final LoginViewModel _vm = LoginViewModel(widget.core.auth);
  final _matricula = TextEditingController();
  final _senha = TextEditingController();

  @override
  void initState() {
    super.initState();
    _vm.addListener(_onChanged);
  }

  void _onChanged() {
    if (_vm.status == LoginStatus.success && mounted) {
      goToHome(context, widget.core);
    }
  }

  @override
  void dispose() {
    _vm.removeListener(_onChanged);
    _vm.dispose();
    _matricula.dispose();
    _senha.dispose();
    super.dispose();
  }

  void _submit() => _vm.submit(_matricula.text, _senha.text);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AceSpacing.x5),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: ListenableBuilder(
                listenable: _vm,
                builder: (context, _) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: CircleAvatar(
                        radius: 32,
                        backgroundColor: context.colors.primaryContainer,
                        child: Icon(
                          Icons.health_and_safety_outlined,
                          size: 34,
                          color: context.colors.onPrimaryContainer,
                        ),
                      ),
                    ),
                    const SizedBox(height: AceSpacing.x4),
                    Text('ACE CONTROL', style: context.text.headlineMedium),
                    const SizedBox(height: AceSpacing.x2),
                    Text(
                      'Entre com sua matrícula para ver o roteiro do dia.',
                      style: context.text.bodyLarge
                          ?.copyWith(color: context.ace.textMuted),
                    ),
                    const SizedBox(height: AceSpacing.x6),
                    AceTextField(
                      label: 'Matrícula',
                      controller: _matricula,
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                      error: _vm.matriculaError,
                      enabled: !_vm.isLoading,
                      textInputAction: TextInputAction.next,
                    ),
                    const SizedBox(height: AceSpacing.x4),
                    AceTextField(
                      label: 'Senha',
                      controller: _senha,
                      icon: Icons.lock_outline,
                      obscure: true,
                      error: _vm.senhaError,
                      enabled: !_vm.isLoading,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                    ),
                    if (_vm.errorMessage != null) ...[
                      const SizedBox(height: AceSpacing.x4),
                      AceInlineMessage(message: _vm.errorMessage!),
                    ],
                    const SizedBox(height: AceSpacing.x5),
                    AceButton(
                      label: 'Entrar',
                      loading: _vm.isLoading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

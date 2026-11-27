import 'package:ace_core/ace_core.dart';
import 'package:ace_design_system/ace_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  final _matriculaFocus = FocusNode();
  final _senhaFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _vm.addListener(_onChanged);
  }

  void _onChanged() {
    if (_vm.status == LoginStatus.success && mounted) {
      TextInput.finishAutofillContext();
      goToStart(context, widget.core);
    }
  }

  @override
  void dispose() {
    _vm.removeListener(_onChanged);
    _vm.dispose();
    _matricula.dispose();
    _senha.dispose();
    _matriculaFocus.dispose();
    _senhaFocus.dispose();
    super.dispose();
  }

  /// "Próximo" no teclado numérico da matrícula.
  ///
  /// Correção do teclado da senha: em vários Android o teclado numérico da
  /// matrícula continuava aberto ao passar para a senha (só números, a senha
  /// não podia ser digitada). Fechar a conexão com o teclado e focar a senha
  /// no quadro seguinte obriga o sistema a abrir o teclado de texto.
  void _toSenha() {
    _matriculaFocus.unfocus();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _senhaFocus.requestFocus();
    });
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    _vm.submit(_matricula.text, _senha.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) => CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _LoginHero()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AceSpacing.page,
                AceSpacing.x5,
                AceSpacing.page,
                AceSpacing.x6,
              ),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: AutofillGroup(child: _form(context)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _form(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Como você vai entrar?', style: context.text.titleMedium),
        const SizedBox(height: AceSpacing.x3),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: AceChoiceCard(
                  compact: true,
                  icon: Icons.directions_walk,
                  title: 'Agente de campo',
                  subtitle: 'Registrar visitas nos lotes',
                  selected: _vm.perfil == Perfil.agente,
                  onTap: () => _vm.choosePerfil(Perfil.agente),
                ),
              ),
              const SizedBox(width: AceSpacing.x3),
              Expanded(
                child: AceChoiceCard(
                  compact: true,
                  icon: Icons.insights_outlined,
                  title: 'Supervisor',
                  subtitle: 'Acompanhar a quadra e a equipe',
                  selected: _vm.perfil == Perfil.supervisor,
                  onTap: () => _vm.choosePerfil(Perfil.supervisor),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AceSpacing.x5),
        AceTextField(
          label: 'Matrícula',
          controller: _matricula,
          focusNode: _matriculaFocus,
          icon: Icons.badge_outlined,
          keyboardType: TextInputType.number,
          autofillHints: const [AutofillHints.username],
          error: _vm.matriculaError,
          enabled: !_vm.isLoading,
          textInputAction: TextInputAction.next,
          onSubmitted: (_) => _toSenha(),
        ),
        const SizedBox(height: AceSpacing.x4),
        AceTextField(
          label: 'Senha',
          controller: _senha,
          focusNode: _senhaFocus,
          icon: Icons.lock_outline,
          obscure: true,
          autofillHints: const [AutofillHints.password],
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
          label: _vm.submitLabel,
          icon: Icons.arrow_forward,
          loading: _vm.isLoading,
          onPressed: _submit,
        ),
      ],
    );
  }
}

/// Topo do login: marca e uma frase sobre o trabalho, sobre o petróleo da
/// marca. Entra uma vez ao abrir.
class _LoginHero extends StatefulWidget {
  const _LoginHero();

  @override
  State<_LoginHero> createState() => _LoginHeroState();
}

class _LoginHeroState extends State<_LoginHero> {
  bool _shown = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;
    const onBrand = AceColors.teal50;
    return Container(
      color: AceColors.teal700,
      padding: EdgeInsets.fromLTRB(
          AceSpacing.page, top + AceSpacing.x6, AceSpacing.page, AceSpacing.x6),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: AnimatedSlide(
            offset: _shown ? Offset.zero : const Offset(0, 0.06),
            duration: const Duration(milliseconds: 520),
            curve: AceMotion.curve,
            child: AnimatedOpacity(
              opacity: _shown ? 1 : 0,
              duration: const Duration(milliseconds: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AceColors.white,
                          borderRadius: BorderRadius.circular(AceRadius.sm),
                        ),
                        child: const Icon(Icons.health_and_safety,
                            color: AceColors.teal700, size: 20),
                      ),
                      const SizedBox(width: AceSpacing.x3),
                      Text(
                        'ACE CONTROL',
                        style: context.text.titleMedium?.copyWith(
                            color: AceColors.white, letterSpacing: 1.4),
                      ),
                    ],
                  ),
                  const SizedBox(height: AceSpacing.x6),
                  Text(
                    'Visita casa a casa, lote por lote.',
                    style: context.text.headlineMedium
                        ?.copyWith(color: AceColors.white),
                  ),
                  const SizedBox(height: AceSpacing.x2),
                  Text(
                    'Combate às endemias em Palmas - TO.',
                    style: context.text.bodyLarge
                        ?.copyWith(color: onBrand.withValues(alpha: 0.9)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

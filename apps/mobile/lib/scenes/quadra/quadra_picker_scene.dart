import 'package:ace_core/ace_core.dart';
import 'package:ace_design_system/ace_design_system.dart';
import 'package:flutter/material.dart';

import '../../navigation.dart';
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
      status = e.isUnauthorized ? QuadraPickerStatus.unauthorized : QuadraPickerStatus.failure;
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

/// O agente escolhe a quadra de atuação antes de ir a campo.
class QuadraPickerScene extends StatefulWidget {
  const QuadraPickerScene({super.key, required this.core});

  final AceCore core;

  @override
  State<QuadraPickerScene> createState() => _QuadraPickerSceneState();
}

class _QuadraPickerSceneState extends State<QuadraPickerScene> {
  late final _vm = QuadraPickerViewModel(widget.core.quadras, widget.core.auth);

  @override
  void initState() {
    super.initState();
    _vm.addListener(_onChanged);
    _vm.load();
  }

  void _onChanged() {
    if (_vm.status == QuadraPickerStatus.unauthorized) _logout();
  }

  Future<void> _logout() async {
    await _vm.logout();
    if (mounted) goToLogin(context, widget.core);
  }

  Future<void> _confirm() async {
    await _vm.confirm();
    if (mounted) goToHome(context, widget.core, _vm.selected!);
  }

  @override
  void dispose() {
    _vm.removeListener(_onChanged);
    _vm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quadra de atuação'),
        actions: [
          IconButton(tooltip: 'Sair da conta', onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) => switch (_vm.status) {
          QuadraPickerStatus.loading || QuadraPickerStatus.unauthorized =>
            const Center(child: CircularProgressIndicator()),
          QuadraPickerStatus.failure => Center(
              child: AceEmptyState(
                icon: Icons.cloud_off_outlined,
                title: 'Não foi possível carregar',
                message: _vm.errorMessage ?? 'Tente novamente.',
                actionLabel: 'Tentar de novo',
                onAction: _vm.load,
              ),
            ),
          QuadraPickerStatus.ready => _list(context),
        },
      ),
    );
  }

  Widget _list(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(AceSpacing.page),
              children: [
                Text('Em qual quadra você trabalha hoje?', style: context.text.headlineSmall),
                const SizedBox(height: AceSpacing.x2),
                Text(
                  'O mapa e as visitas do dia ficam nesta quadra. Dá para trocar depois no Perfil.',
                  style: context.text.bodyMedium?.copyWith(color: context.ace.textMuted),
                ),
                const SizedBox(height: AceSpacing.x5),
                for (final q in _vm.quadras) ...[
                  AceChoiceCard(
                    icon: Icons.grid_view_rounded,
                    title: q.nome,
                    subtitle: '${q.bairro} · ${q.totalLotes} lotes · ${q.pendentes} a visitar',
                    selected: _vm.selected == q.id,
                    onTap: () => _vm.choose(q.id),
                  ),
                  const SizedBox(height: AceSpacing.x3),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AceSpacing.page),
            child: AceButton(
              label: 'Abrir mapa da quadra',
              icon: Icons.arrow_forward,
              onPressed: _vm.selected == null ? null : _confirm,
            ),
          ),
        ],
      ),
    );
  }
}

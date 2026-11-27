import 'package:ace_core/ace_core.dart';
import 'package:ace_design_system/ace_design_system.dart';
import 'package:flutter/material.dart';

import '../../navigation.dart';
import '../home/widgets/profile_tab.dart';
import '../shared/lot_presenters.dart';
import '../shared/lot_visit_sheet.dart';
import '../shared/quadra_map_view.dart';
import '../shared/quadra_widgets.dart';
import 'supervisor_view_model.dart';

/// Painel do supervisor: andamento da quadra, achados, mapa e visitas (só leitura).
class SupervisorScene extends StatefulWidget {
  const SupervisorScene({super.key, required this.core});

  final AceCore core;

  @override
  State<SupervisorScene> createState() => _SupervisorSceneState();
}

class _SupervisorSceneState extends State<SupervisorScene> {
  late final _vm = SupervisorViewModel(
      widget.core.agent, widget.core.quadras, widget.core.auth);
  int _tab = 0;
  bool _leaving = false;
  String? _selectedLote;

  @override
  void initState() {
    super.initState();
    _vm.addListener(_onChanged);
    _vm.load();
  }

  void _onChanged() {
    if (_vm.status == SupervisorStatus.unauthorized) _leave();
  }

  Future<void> _leave() async {
    if (_leaving) return;
    _leaving = true;
    await _vm.logout();
    if (mounted) goToLogin(context, widget.core);
  }

  @override
  void dispose() {
    _vm.removeListener(_onChanged);
    _vm.dispose();
    super.dispose();
  }

  Future<void> _openLote(Lote lote) async {
    setState(() => _selectedLote = lote.id);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.colors.surface,
      builder: (_) => LotVisitSheet(quadra: _vm.quadra!, lote: lote),
    );
    if (mounted) setState(() => _selectedLote = null);
  }

  Widget _body() {
    switch (_vm.status) {
      case SupervisorStatus.loading:
      case SupervisorStatus.unauthorized:
        return const Center(child: CircularProgressIndicator());
      case SupervisorStatus.failure:
        return Center(
          child: AceEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Não foi possível carregar',
            message: _vm.errorMessage ?? 'Tente novamente.',
            actionLabel: 'Tentar de novo',
            onAction: _vm.load,
          ),
        );
      case SupervisorStatus.ready:
        break;
    }
    final q = _vm.quadra;
    if (_tab == 2) return ProfileTab(agent: _vm.me!, onLogout: _leave);
    if (q == null) {
      return const Center(
        child: AceEmptyState(
          icon: Icons.grid_view_rounded,
          title: 'Nenhuma quadra',
          message: 'As quadras da sua região aparecem aqui.',
        ),
      );
    }
    if (_tab == 1) {
      return QuadraMapView(
        quadra: q,
        selectedLoteId: _selectedLote,
        onLoteTap: _openLote,
        hint: 'Toque num conjunto para aproximar e num lote para ver a visita.',
      );
    }
    return _overview(q);
  }

  Widget _overview(Quadra q) {
    final trabalhados = lotesTrabalhados(q);
    return RefreshIndicator(
      onRefresh: () => _vm.load(silent: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            AceSpacing.page, AceSpacing.x5, AceSpacing.page, AceSpacing.x6),
        children: [
          Text('Andamento de hoje', style: context.text.headlineSmall),
          const SizedBox(height: AceSpacing.x1),
          Text(
            'Atualize puxando a tela para baixo.',
            style:
                context.text.bodyMedium?.copyWith(color: context.ace.textMuted),
          ),
          if (_vm.quadras.length > 1) ...[
            const SizedBox(height: AceSpacing.x3),
            Wrap(
              spacing: AceSpacing.x2,
              children: [
                for (final r in _vm.quadras)
                  ChoiceChip(
                    label: Text(r.nome),
                    selected: r.id == q.id,
                    onSelected: (_) => _vm.load(quadraId: r.id),
                  ),
              ],
            ),
          ],
          const SizedBox(height: AceSpacing.x5),
          QuadraProgressCard(quadra: q),
          const SizedBox(height: AceSpacing.x5),
          Text('Encontrado na quadra', style: context.text.titleMedium),
          const SizedBox(height: AceSpacing.x3),
          AchadosRow(achados: q.achados),
          const SizedBox(height: AceSpacing.x3),
          AceButton(
            label: 'Ver mapa 3D da quadra',
            icon: Icons.view_in_ar_outlined,
            variant: AceButtonVariant.secondary,
            onPressed: () => setState(() => _tab = 1),
          ),
          AceSectionHeader(
              title: 'Visitas registradas (${trabalhados.length})'),
          if (trabalhados.isEmpty)
            const AceCard(
              child: AceEmptyState(
                icon: Icons.fact_check_outlined,
                title: 'Nenhuma visita ainda',
                message:
                    'As visitas dos agentes aparecem aqui assim que forem salvas.',
              ),
            )
          else
            for (final l in trabalhados)
              Padding(
                padding: const EdgeInsets.only(bottom: AceSpacing.x2),
                child: LoteTile(quadra: q, lote: l, onTap: () => _openLote(l)),
              ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ListenableBuilder(
          listenable: _vm,
          builder: (context, _) => Text(
            _vm.quadra == null
                ? 'Supervisão'
                : 'Supervisão · ${_vm.quadra!.nome}',
          ),
        ),
      ),
      body:
          ListenableBuilder(listenable: _vm, builder: (context, _) => _body()),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) {
          setState(() => _tab = i);
          if (i != 2) _vm.load(silent: true);
        },
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: 'Painel'),
          NavigationDestination(
            icon: Icon(Icons.view_in_ar_outlined),
            selectedIcon: Icon(Icons.view_in_ar),
            label: 'Mapa',
          ),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Perfil'),
        ],
      ),
    );
  }
}

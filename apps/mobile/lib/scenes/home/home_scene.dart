import 'package:ace_core/ace_core.dart';
import 'package:ace_design_system/ace_design_system.dart';
import 'package:flutter/material.dart';

import '../../navigation.dart';
import '../shared/lot_visit_sheet.dart';
import '../shared/quadra_map_view.dart';
import 'home_view_model.dart';
import 'widgets/home_dashboard.dart';
import 'widgets/profile_tab.dart';
import 'widgets/visits_tab.dart';

/// Home do agente de campo, sempre numa quadra escolhida.
class HomeScene extends StatefulWidget {
  const HomeScene({super.key, required this.core, required this.quadraId});

  final AceCore core;
  final String quadraId;

  @override
  State<HomeScene> createState() => _HomeSceneState();
}

class _HomeSceneState extends State<HomeScene> {
  late final HomeViewModel _vm = HomeViewModel(
    quadraId: widget.quadraId,
    agentRepository: widget.core.agent,
    quadrasRepository: widget.core.quadras,
    authRepository: widget.core.auth,
  );
  int _tab = 0;
  bool _leaving = false;
  String? _selectedLote;

  @override
  void initState() {
    super.initState();
    _vm.addListener(_onChanged);
    _vm.load();
  }

  /// Sessão expirada: limpa o storage e volta para o Login.
  void _onChanged() {
    if (_vm.status == HomeStatus.unauthorized) _leave();
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
    final q = _vm.quadra;
    if (q == null) return;
    setState(() => _selectedLote = lote.id);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.colors.surface,
      builder: (_) => LotVisitSheet(
        quadra: q,
        lote: lote,
        onSave: (resultado, achados) => _vm.registrar(lote, resultado, achados),
      ),
    );
    if (!mounted) return;
    setState(() => _selectedLote = null);
    if (saved == true) {
      AceSnackbar.show(context, 'Visita do lote ${lote.numero} registrada',
          type: AceFeedback.success);
    }
  }

  Widget _body() {
    switch (_vm.status) {
      case HomeStatus.loading:
      case HomeStatus.unauthorized:
        return const Center(child: CircularProgressIndicator());
      case HomeStatus.failure:
        return Center(
          child: SingleChildScrollView(
            child: AceEmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Não foi possível carregar',
              message: _vm.errorMessage ?? 'Tente novamente em instantes.',
              actionLabel: 'Tentar de novo',
              onAction: () => _vm.load(),
            ),
          ),
        );
      case HomeStatus.ready:
        break;
    }
    final q = _vm.quadra!;
    return switch (_tab) {
      0 => HomeDashboard(
          vm: _vm,
          onOpenLote: _openLote,
          onOpenMap: () => setState(() => _tab = 1),
          onSeeAll: () => setState(() => _tab = 2),
          onChangeQuadra: () => goToQuadraPicker(context, widget.core),
        ),
      1 => QuadraMapView(
          quadra: q, selectedLoteId: _selectedLote, onLoteTap: _openLote),
      2 => VisitsTab(quadra: q, onOpenLote: _openLote),
      _ => ProfileTab(
          agent: _vm.agent!,
          onLogout: _leave,
          quadraNome: q.nome,
          onChangeQuadra: () => goToQuadraPicker(context, widget.core),
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: ListenableBuilder(
          listenable: _vm,
          builder: (context, _) => Text(_vm.quadra?.nome ?? 'ACE CONTROL'),
        ),
      ),
      body:
          ListenableBuilder(listenable: _vm, builder: (context, _) => _body()),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Início'),
          NavigationDestination(
            icon: Icon(Icons.view_in_ar_outlined),
            selectedIcon: Icon(Icons.view_in_ar),
            label: 'Mapa',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check),
            label: 'Visitas',
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

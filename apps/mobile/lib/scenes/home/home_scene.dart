import 'package:ace_core/ace_core.dart';
import 'package:ace_design_system/ace_design_system.dart';
import 'package:flutter/material.dart';

import '../../navigation.dart';
import 'home_view_model.dart';
import 'widgets/home_dashboard.dart';
import 'widgets/profile_tab.dart';
import 'widgets/soon_tab.dart';
import 'widgets/visit_status_sheet.dart';
import 'widgets/visits_tab.dart';

class HomeScene extends StatefulWidget {
  const HomeScene({super.key, required this.core});

  final AceCore core;

  @override
  State<HomeScene> createState() => _HomeSceneState();
}

class _HomeSceneState extends State<HomeScene> {
  late final HomeViewModel _vm = HomeViewModel(
    agentRepository: widget.core.agent,
    visitsRepository: widget.core.visits,
    authRepository: widget.core.auth,
  );
  int _tab = 0;
  bool _leaving = false;

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

  Future<void> _openVisit(Visit visit) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: context.colors.surface,
      builder: (_) => VisitStatusSheet(
        visit: visit,
        onSave: (status, obs) => _vm.saveVisit(visit, status, obs),
      ),
    );
    if (saved == true && mounted) {
      AceSnackbar.show(context, 'Visita registrada', type: AceFeedback.success);
    }
  }

  Widget _body() {
    return switch (_tab) {
      0 => HomeDashboard(
          vm: _vm,
          onOpenVisit: _openVisit,
          onSeeAll: () => setState(() => _tab = 2),
        ),
      1 => const SoonTab(
          icon: Icons.map_outlined,
          title: 'Mapa em desenvolvimento',
          message: 'Em breve você verá os lotes da sua área no mapa.',
        ),
      2 => VisitsTab(vm: _vm, onOpenVisit: _openVisit),
      _ => ProfileTab(vm: _vm, onLogout: _leave),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ACE CONTROL')),
      body: ListenableBuilder(
        listenable: _vm,
        builder: (context, _) => _body(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map),
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
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

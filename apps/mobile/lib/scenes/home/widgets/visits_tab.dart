import 'package:ace_core/ace_core.dart';
import 'package:ace_design_system/ace_design_system.dart';
import 'package:flutter/material.dart';

import '../home_view_model.dart';
import '../visit_presenters.dart';

/// Aba "Visitas": lista completa do dia.
class VisitsTab extends StatelessWidget {
  const VisitsTab({super.key, required this.vm, required this.onOpenVisit});

  final HomeViewModel vm;
  final ValueChanged<Visit> onOpenVisit;

  @override
  Widget build(BuildContext context) {
    if (vm.status != HomeStatus.ready) {
      return const Center(child: CircularProgressIndicator());
    }
    final visits = vm.pendingFirst;
    return RefreshIndicator(
      onRefresh: () => vm.load(silent: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AceSpacing.page),
        children: [
          Text('Visitas de hoje', style: context.text.headlineSmall),
          const SizedBox(height: AceSpacing.x1),
          Text(
            '${visits.length} imóveis no roteiro',
            style: context.text.bodyMedium?.copyWith(color: context.ace.textMuted),
          ),
          const SizedBox(height: AceSpacing.x4),
          for (final v in visits)
            Padding(
              padding: const EdgeInsets.only(bottom: AceSpacing.x2),
              child: AceVisitTile(
                lot: v.lote,
                address: v.endereco,
                detail: visitDetail(v),
                status: aceStatusOf(v.status),
                onTap: () => onOpenVisit(v),
              ),
            ),
        ],
      ),
    );
  }
}

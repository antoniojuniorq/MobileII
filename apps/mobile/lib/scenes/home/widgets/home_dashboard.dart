import 'package:ace_core/ace_core.dart';
import 'package:ace_design_system/ace_design_system.dart';
import 'package:flutter/material.dart';

import '../home_view_model.dart';
import '../visit_presenters.dart';

/// Aba "Início": saudação, meta do dia, números e roteiro.
class HomeDashboard extends StatelessWidget {
  const HomeDashboard({
    super.key,
    required this.vm,
    required this.onOpenVisit,
    required this.onSeeAll,
  });

  final HomeViewModel vm;
  final ValueChanged<Visit> onOpenVisit;
  final VoidCallback onSeeAll;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    switch (vm.status) {
      case HomeStatus.loading:
      case HomeStatus.unauthorized:
        return const Center(child: CircularProgressIndicator());
      case HomeStatus.failure:
        return Center(
          child: SingleChildScrollView(
            child: AceEmptyState(
              icon: Icons.cloud_off_outlined,
              title: 'Não foi possível carregar',
              message: vm.errorMessage ?? 'Tente novamente em instantes.',
              actionLabel: 'Tentar de novo',
              onAction: () => vm.load(),
            ),
          ),
        );
      case HomeStatus.ready:
        break;
    }

    final agent = vm.agent!;
    final summary = vm.summary!;
    final visits = vm.pendingFirst.take(5).toList();

    return RefreshIndicator(
      onRefresh: () => vm.load(silent: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AceSpacing.page,
          AceSpacing.x5,
          AceSpacing.page,
          AceSpacing.x6,
        ),
        children: [
          Text(
            '${_greeting()}, ${agent.primeiroNome}',
            style: context.text.headlineSmall,
          ),
          const SizedBox(height: AceSpacing.x1),
          Text(
            '${agent.area} · ${agent.municipio}',
            style: context.text.bodyMedium?.copyWith(color: context.ace.textMuted),
          ),
          if (vm.refreshError != null) ...[
            const SizedBox(height: AceSpacing.x4),
            AceInlineMessage(message: vm.refreshError!),
          ],
          const SizedBox(height: AceSpacing.x5),
          AceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Meta do dia', style: context.text.titleMedium),
                    Text(
                      '${summary.visitsDone} de ${summary.goal} visitas',
                      style: context.text.bodyMedium,
                    ),
                  ],
                ),
                const SizedBox(height: AceSpacing.x3),
                AceProgressBar(value: summary.progress, semanticLabel: 'Meta do dia'),
              ],
            ),
          ),
          const SizedBox(height: AceSpacing.x3),
          Row(
            children: [
              Expanded(
                child: AceStatCard(
                  value: '${summary.visitsDone}',
                  label: 'Feitas',
                  icon: Icons.check_circle_outline,
                ),
              ),
              const SizedBox(width: AceSpacing.x3),
              Expanded(
                child: AceStatCard(
                  value: '${summary.visitsPending}',
                  label: 'Pendentes',
                  icon: Icons.schedule,
                ),
              ),
              const SizedBox(width: AceSpacing.x3),
              Expanded(
                child: AceStatCard(
                  value: '${summary.focosFound}',
                  label: 'Focos',
                  icon: Icons.bug_report_outlined,
                ),
              ),
            ],
          ),
          AceSectionHeader(
            title: 'Roteiro de hoje',
            actionLabel: 'Ver tudo',
            onAction: onSeeAll,
          ),
          if (visits.isEmpty)
            const AceCard(
              child: AceEmptyState(
                icon: Icons.map_outlined,
                title: 'Nenhuma visita hoje',
                message: 'Quando houver um roteiro para você, ele aparece aqui.',
              ),
            )
          else
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

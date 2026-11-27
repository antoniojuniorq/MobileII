import 'package:ace_core/ace_core.dart';
import 'package:ace_design_system/ace_design_system.dart';
import 'package:flutter/material.dart';

import '../../shared/lot_presenters.dart';
import '../../shared/quadra_widgets.dart';
import '../home_view_model.dart';

/// Aba "Início": saudação, progresso da quadra, achados e últimas visitas.
class HomeDashboard extends StatelessWidget {
  const HomeDashboard({
    super.key,
    required this.vm,
    required this.onOpenLote,
    required this.onOpenMap,
    required this.onSeeAll,
    required this.onChangeQuadra,
  });

  final HomeViewModel vm;
  final ValueChanged<Lote> onOpenLote;
  final VoidCallback onOpenMap;
  final VoidCallback onSeeAll;
  final VoidCallback onChangeQuadra;

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    final agent = vm.agent!;
    final q = vm.quadra!;
    final recentes = lotesTrabalhados(q).take(4).toList();

    return RefreshIndicator(
      onRefresh: () => vm.load(silent: true),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
            AceSpacing.page, AceSpacing.x5, AceSpacing.page, AceSpacing.x6),
        children: [
          Text('${_greeting()}, ${agent.primeiroNome}',
              style: context.text.headlineSmall),
          const SizedBox(height: AceSpacing.x1),
          Text(
            '${q.resumo.pendentes} lotes esperam visita hoje.',
            style:
                context.text.bodyMedium?.copyWith(color: context.ace.textMuted),
          ),
          if (vm.refreshError != null) ...[
            const SizedBox(height: AceSpacing.x4),
            AceInlineMessage(message: vm.refreshError!),
          ],
          const SizedBox(height: AceSpacing.x5),
          QuadraProgressCard(quadra: q, onChange: onChangeQuadra),
          const SizedBox(height: AceSpacing.x3),
          AceButton(
              label: 'Abrir mapa 3D da quadra',
              icon: Icons.view_in_ar_outlined,
              onPressed: onOpenMap),
          const SizedBox(height: AceSpacing.x5),
          Text('Encontrado hoje', style: context.text.titleMedium),
          const SizedBox(height: AceSpacing.x3),
          AchadosRow(achados: q.achados),
          AceSectionHeader(
              title: 'Últimas visitas',
              actionLabel: 'Ver todas',
              onAction: onSeeAll),
          if (recentes.isEmpty)
            const AceCard(
              child: AceEmptyState(
                icon: Icons.map_outlined,
                title: 'Nenhuma visita ainda',
                message: 'Toque num lote do mapa para registrar a primeira.',
              ),
            )
          else
            for (final l in recentes)
              Padding(
                padding: const EdgeInsets.only(bottom: AceSpacing.x2),
                child: LoteTile(quadra: q, lote: l, onTap: () => onOpenLote(l)),
              ),
        ],
      ),
    );
  }
}

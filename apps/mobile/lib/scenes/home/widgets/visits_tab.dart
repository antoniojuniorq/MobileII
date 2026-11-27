import 'package:ace_core/ace_core.dart';
import 'package:ace_design_system/ace_design_system.dart';
import 'package:flutter/material.dart';

import '../../shared/lot_presenters.dart';
import '../../shared/quadra_widgets.dart';

/// Lista dos lotes trabalhados, com filtro por situação.
class VisitsTab extends StatefulWidget {
  const VisitsTab({super.key, required this.quadra, required this.onOpenLote});

  final Quadra quadra;
  final ValueChanged<Lote> onOpenLote;

  @override
  State<VisitsTab> createState() => _VisitsTabState();
}

class _VisitsTabState extends State<VisitsTab> {
  LoteStatus? _filter;

  @override
  Widget build(BuildContext context) {
    final q = widget.quadra;
    final all = lotesTrabalhados(q);
    final shown =
        _filter == null ? all : all.where((l) => l.status == _filter).toList();
    return ListView(
      padding: const EdgeInsets.all(AceSpacing.page),
      children: [
        Wrap(
          spacing: AceSpacing.x2,
          children: [
            ChoiceChip(
              label: Text('Todas (${all.length})'),
              selected: _filter == null,
              onSelected: (_) => setState(() => _filter = null),
            ),
            for (final s in [LoteStatus.visitado, LoteStatus.semAcesso])
              ChoiceChip(
                label: Text(
                    '${aceLotStatusOf(s).label} (${all.where((l) => l.status == s).length})'),
                selected: _filter == s,
                onSelected: (_) => setState(() => _filter = s),
              ),
          ],
        ),
        const SizedBox(height: AceSpacing.x4),
        if (shown.isEmpty)
          const AceEmptyState(
            icon: Icons.fact_check_outlined,
            title: 'Nada por aqui',
            message: 'As visitas registradas no mapa aparecem nesta lista.',
          )
        else
          for (final l in shown)
            Padding(
              padding: const EdgeInsets.only(bottom: AceSpacing.x2),
              child: LoteTile(
                  quadra: q, lote: l, onTap: () => widget.onOpenLote(l)),
            ),
      ],
    );
  }
}

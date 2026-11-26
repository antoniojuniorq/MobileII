import 'package:flutter/material.dart';

import '../theme/ace_theme.dart';
import '../tokens/ace_spacing.dart';
import '../tokens/ace_status.dart';

/// Legenda do mapa: cor + ícone + texto + quantidade de cada situação.
class AceLotLegend extends StatelessWidget {
  const AceLotLegend({super.key, required this.counts});

  final Map<AceLotStatus, int> counts;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Wrap(
      spacing: AceSpacing.x2,
      runSpacing: AceSpacing.x2,
      children: [
        for (final s in AceLotStatus.values)
          Semantics(
            label: '${s.label}: ${counts[s] ?? 0}',
            excludeSemantics: true,
            child: Container(
              padding: const EdgeInsets.fromLTRB(AceSpacing.x2, 6, AceSpacing.x3, 6),
              decoration: BoxDecoration(
                color: s.colors(b).bg,
                borderRadius: BorderRadius.circular(AceRadius.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(color: s.color, borderRadius: BorderRadius.circular(3)),
                  ),
                  const SizedBox(width: 6),
                  Icon(s.icon, size: 14, color: s.colors(b).fg),
                  const SizedBox(width: 4),
                  Text(
                    s.countLabel(counts[s] ?? 0),
                    style: context.text.labelMedium?.copyWith(color: s.colors(b).fg),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// Selo da situação do lote (folha de registro, listas).
class AceLotBadge extends StatelessWidget {
  const AceLotBadge({super.key, required this.status});
  final AceLotStatus status;

  @override
  Widget build(BuildContext context) {
    final col = status.colors(Theme.of(context).brightness);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AceSpacing.x3, vertical: 6),
      decoration: BoxDecoration(color: col.bg, borderRadius: BorderRadius.circular(AceRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 16, color: col.fg),
          const SizedBox(width: 6),
          Text(status.label, style: context.text.labelMedium?.copyWith(color: col.fg)),
        ],
      ),
    );
  }
}

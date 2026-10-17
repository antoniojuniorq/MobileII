import 'package:flutter/material.dart';
import '../theme/ace_theme.dart';
import '../tokens/ace_spacing.dart';
import '../tokens/ace_status.dart';
import 'ace_card.dart';
import 'ace_status_badge.dart';

/// Linha de visita: lote + endereço + status.
class AceVisitTile extends StatelessWidget {
  const AceVisitTile({
    super.key,
    required this.lot,
    required this.address,
    required this.detail,
    required this.status,
    this.onTap,
  });

  final String lot;
  final String address;
  final String detail;
  final AceStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AceCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.ace.surfaceMuted,
              borderRadius: BorderRadius.circular(AceRadius.md),
              border: Border.all(color: context.ace.line),
            ),
            child: Text(lot, style: context.text.titleMedium?.copyWith(color: c.primary)),
          ),
          const SizedBox(width: AceSpacing.x3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(address, style: context.text.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(detail, style: context.text.bodySmall?.copyWith(color: context.ace.textMuted)),
              ],
            ),
          ),
          const SizedBox(width: AceSpacing.x2),
          AceStatusBadge(status: status),
        ],
      ),
    );
  }
}

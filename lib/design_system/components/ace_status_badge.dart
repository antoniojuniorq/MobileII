import 'package:flutter/material.dart';
import '../theme/ace_theme.dart';
import '../tokens/ace_spacing.dart';
import '../tokens/ace_status.dart';

/// Selo de status: ícone + texto + cor.
class AceStatusBadge extends StatelessWidget {
  const AceStatusBadge({super.key, required this.status});
  final AceStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = status.colors(Theme.of(context).brightness);
    return Semantics(
      label: 'Status: ${status.label}',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: AceSpacing.x3, vertical: AceSpacing.x1 + 2),
        decoration: BoxDecoration(
          color: colors.bg,
          borderRadius: BorderRadius.circular(AceRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(status.icon, size: 16, color: colors.fg),
            const SizedBox(width: AceSpacing.x1 + 2),
            Text(status.label, style: context.text.labelMedium?.copyWith(color: colors.fg)),
          ],
        ),
      ),
    );
  }
}

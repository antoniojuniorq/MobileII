import 'package:flutter/material.dart';
import '../theme/ace_theme.dart';
import '../tokens/ace_spacing.dart';
import 'ace_card.dart';

/// Indicador numérico (ex.: visitas do dia).
class AceStatCard extends StatelessWidget {
  const AceStatCard({super.key, required this.value, required this.label, required this.icon});
  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return AceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AceSpacing.x2),
            decoration: BoxDecoration(
              color: c.primaryContainer,
              borderRadius: BorderRadius.circular(AceRadius.sm),
            ),
            child: Icon(icon, size: 20, color: c.onPrimaryContainer),
          ),
          const SizedBox(height: AceSpacing.x3),
          Text(value, style: context.text.headlineMedium),
          Text(label, style: context.text.bodySmall?.copyWith(color: context.ace.textMuted)),
        ],
      ),
    );
  }
}

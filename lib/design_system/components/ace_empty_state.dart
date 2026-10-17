import 'package:flutter/material.dart';
import '../theme/ace_theme.dart';
import '../tokens/ace_spacing.dart';
import 'ace_button.dart';

/// Estado vazio: diz o que aconteceu e qual é a próxima ação.
class AceEmptyState extends StatelessWidget {
  const AceEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AceSpacing.x5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: context.colors.primaryContainer,
            child: Icon(icon, size: 30, color: context.colors.onPrimaryContainer),
          ),
          const SizedBox(height: AceSpacing.x4),
          Text(title, style: context.text.titleLarge, textAlign: TextAlign.center),
          const SizedBox(height: AceSpacing.x2),
          Text(
            message,
            style: context.text.bodyMedium?.copyWith(color: context.ace.textMuted),
            textAlign: TextAlign.center,
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: AceSpacing.x5),
            AceButton(label: actionLabel!, onPressed: onAction, expanded: false),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/ace_theme.dart';
import '../tokens/ace_spacing.dart';

class AceSectionHeader extends StatelessWidget {
  const AceSectionHeader({super.key, required this.title, this.actionLabel, this.onAction});
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AceSpacing.x5, bottom: AceSpacing.x3),
      child: Row(
        children: [
          Expanded(child: Text(title, style: context.text.titleLarge)),
          if (actionLabel != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

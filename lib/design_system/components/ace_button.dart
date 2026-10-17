import 'package:flutter/material.dart';
import '../theme/ace_theme.dart';
import '../tokens/ace_spacing.dart';

enum AceButtonVariant { primary, secondary, ghost, danger }

/// Botão padrão. Altura mínima de 52 dp; `loading` bloqueia toques repetidos.
class AceButton extends StatelessWidget {
  const AceButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AceButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AceButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final fg = switch (variant) {
      AceButtonVariant.primary => c.onPrimary,
      AceButtonVariant.danger => c.onError,
      AceButtonVariant.secondary || AceButtonVariant.ghost => c.primary,
    };

    final content = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: fg),
          )
        else if (icon != null)
          Icon(icon, size: 20),
        if (loading || icon != null) const SizedBox(width: AceSpacing.x2),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );

    final tap = loading ? null : onPressed;
    return switch (variant) {
      AceButtonVariant.primary => FilledButton(onPressed: tap, child: content),
      AceButtonVariant.danger => FilledButton(
          onPressed: tap,
          style: FilledButton.styleFrom(backgroundColor: c.error, foregroundColor: c.onError),
          child: content,
        ),
      AceButtonVariant.secondary => OutlinedButton(onPressed: tap, child: content),
      AceButtonVariant.ghost => TextButton(onPressed: tap, child: content),
    };
  }
}

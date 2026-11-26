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
    final button = switch (variant) {
      AceButtonVariant.primary => FilledButton(onPressed: tap, child: content),
      AceButtonVariant.danger => FilledButton(
          onPressed: tap,
          style: FilledButton.styleFrom(backgroundColor: c.error, foregroundColor: c.onError),
          child: content,
        ),
      AceButtonVariant.secondary => OutlinedButton(onPressed: tap, child: content),
      AceButtonVariant.ghost => TextButton(onPressed: tap, child: content),
    };
    return _Pressable(enabled: tap != null, child: button);
  }
}

/// Afunda 3% enquanto o dedo está no botão; volta ao soltar.
class _Pressable extends StatefulWidget {
  const _Pressable({required this.enabled, required this.child});
  final bool enabled;
  final Widget child;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (widget.enabled && v != _down) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: AceMotion.fast,
        curve: AceMotion.curve,
        child: widget.child,
      ),
    );
  }
}

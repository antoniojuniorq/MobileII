import 'package:flutter/material.dart';
import '../theme/ace_theme.dart';
import '../tokens/ace_spacing.dart';
import '../tokens/ace_status.dart';

/// Seletor dos seis status, usado ao registrar uma visita.
class AceStatusSelector extends StatelessWidget {
  const AceStatusSelector({super.key, required this.value, required this.onChanged});

  final AceStatus? value;
  final ValueChanged<AceStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Wrap(
      spacing: AceSpacing.x2,
      runSpacing: AceSpacing.x2,
      children: [
        for (final s in AceStatus.values)
          Semantics(
            button: true,
            selected: value == s,
            label: s.label,
            excludeSemantics: true,
            child: _Option(
              status: s,
              colors: s.colors(brightness),
              selected: value == s,
              onTap: () => onChanged(s),
            ),
          ),
      ],
    );
  }
}

class _Option extends StatelessWidget {
  const _Option({required this.status, required this.colors, required this.selected, required this.onTap});
  final AceStatus status;
  final AceStatusColors colors;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AceMotion.fast,
      curve: AceMotion.curve,
      constraints: const BoxConstraints(minHeight: 48),
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.circular(AceRadius.md),
        border: Border.all(color: selected ? colors.fg : Colors.transparent, width: 2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AceRadius.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AceSpacing.x4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(selected ? Icons.check : status.icon, size: 18, color: colors.fg),
              const SizedBox(width: AceSpacing.x2),
              Text(status.label, style: context.text.labelLarge?.copyWith(color: colors.fg)),
            ],
          ),
        ),
      ),
    );
  }
}

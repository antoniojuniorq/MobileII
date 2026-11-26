import 'package:flutter/material.dart';

import '../theme/ace_theme.dart';
import '../tokens/ace_spacing.dart';

/// Opção grande e exclusiva (como um botão de rádio): ícone, título e linha
/// de apoio. Usada na escolha de perfil do login e no resultado da visita.
class AceChoiceCard extends StatelessWidget {
  const AceChoiceCard({
    super.key,
    required this.icon,
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
    this.accent,
    this.compact = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback? onTap;

  /// Cor da opção quando escolhida (padrão: cor primária).
  final Color? accent;

  /// Ícone acima do texto, para duas opções lado a lado.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tone = accent ?? c.primary;
    final bg = selected ? Color.lerp(c.surface, tone, 0.10)! : c.surface;
    final iconTile = AnimatedContainer(
      duration: AceMotion.normal,
      curve: AceMotion.curve,
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: selected ? tone : Color.lerp(c.surface, tone, 0.12),
        borderRadius: BorderRadius.circular(AceRadius.md),
      ),
      child: Icon(icon, size: 24, color: selected ? _on(tone) : tone),
    );
    final texts = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title, style: context.text.titleMedium),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(subtitle!, style: context.text.bodySmall?.copyWith(color: context.ace.textMuted)),
        ],
      ],
    );
    final mark = AnimatedSwitcher(
      duration: AceMotion.fast,
      child: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        key: ValueKey(selected),
        color: selected ? tone : context.ace.line,
      ),
    );

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      label: subtitle == null ? title : '$title. $subtitle',
      excludeSemantics: true,
      child: AnimatedContainer(
        duration: AceMotion.normal,
        curve: AceMotion.curve,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AceRadius.lg),
          border: Border.all(color: selected ? tone : context.ace.line, width: selected ? 2 : 1),
        ),
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            borderRadius: BorderRadius.circular(AceRadius.lg),
            onTap: onTap,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AceSpacing.touch + 16),
              child: Padding(
                padding: const EdgeInsets.all(AceSpacing.x3),
                child: compact
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [iconTile, const Spacer(), mark]),
                          const SizedBox(height: AceSpacing.x3),
                          texts,
                        ],
                      )
                    : Row(
                        children: [
                          iconTile,
                          const SizedBox(width: AceSpacing.x3),
                          Expanded(child: texts),
                          mark,
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Color _on(Color bg) =>
      ThemeData.estimateBrightnessForColor(bg) == Brightness.dark ? Colors.white : const Color(0xFF12201D);
}

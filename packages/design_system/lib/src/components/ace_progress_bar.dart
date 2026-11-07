import 'package:flutter/material.dart';
import '../theme/ace_theme.dart';
import '../tokens/ace_spacing.dart';

/// Barra de progresso (0.0 a 1.0), ex.: meta de visitas do dia.
class AceProgressBar extends StatelessWidget {
  const AceProgressBar({super.key, required this.value, this.semanticLabel});

  final double value;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final v = value.clamp(0.0, 1.0);
    return Semantics(
      label: semanticLabel ?? 'Progresso',
      value: '${(v * 100).round()}%',
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AceRadius.pill),
        child: LinearProgressIndicator(
          value: v,
          minHeight: 10,
          color: context.colors.primary,
          backgroundColor: context.ace.line,
        ),
      ),
    );
  }
}

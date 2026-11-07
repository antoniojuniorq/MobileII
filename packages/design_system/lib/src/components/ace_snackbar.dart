import 'package:flutter/material.dart';
import '../tokens/ace_colors.dart';
import '../tokens/ace_spacing.dart';

enum AceFeedback { success, error, info }

/// Avisos rápidos. Texto descreve o que aconteceu (ex.: "Visita registrada").
abstract final class AceSnackbar {
  static void show(BuildContext context, String message, {AceFeedback type = AceFeedback.info}) {
    final (bg, icon) = switch (type) {
      AceFeedback.success => (AceColors.green800, Icons.check_circle_outline),
      AceFeedback.error => (AceColors.red600, Icons.error_outline),
      AceFeedback.info => (AceColors.ink900, Icons.info_outline),
    };
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          backgroundColor: bg,
          content: Row(
            children: [
              Icon(icon, color: AceColors.white),
              const SizedBox(width: AceSpacing.x3),
              Expanded(child: Text(message, style: const TextStyle(color: AceColors.white))),
            ],
          ),
        ),
      );
  }
}

import 'package:flutter/material.dart';
import '../theme/ace_theme.dart';
import '../tokens/ace_spacing.dart';
import '../tokens/ace_status.dart';
import 'ace_snackbar.dart';

/// Mensagem fixa dentro da tela (erro de login, aviso de formulário).
/// Anunciada por leitores de tela (liveRegion). Cores reaproveitam os pares
/// de status, que já têm contraste AA nos dois temas.
class AceInlineMessage extends StatelessWidget {
  const AceInlineMessage({
    super.key,
    required this.message,
    this.type = AceFeedback.error,
  });

  final String message;
  final AceFeedback type;

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    final (colors, icon) = switch (type) {
      AceFeedback.error => (AceStatus.recusado.colors(b), Icons.error_outline),
      AceFeedback.success =>
        (AceStatus.visitado.colors(b), Icons.check_circle_outline),
      AceFeedback.info => (AceStatus.recuperado.colors(b), Icons.info_outline),
    };
    return Semantics(
      liveRegion: true,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AceSpacing.x3),
        decoration: BoxDecoration(
          color: colors.bg,
          borderRadius: BorderRadius.circular(AceRadius.md),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: colors.fg),
            const SizedBox(width: AceSpacing.x2),
            Expanded(
              child: Text(
                message,
                style: context.text.bodyMedium?.copyWith(color: colors.fg),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

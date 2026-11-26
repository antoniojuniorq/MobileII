import 'package:flutter/material.dart';

/// Os seis status de visita a um imóvel/lote.
/// Cada status combina cor + ícone + texto (nunca só cor).
enum AceStatus { pendente, visitado, fechado, recusado, recuperado, comFoco }

@immutable
class AceStatusColors {
  const AceStatusColors(this.fg, this.bg);
  final Color fg;
  final Color bg;
}

extension AceStatusX on AceStatus {
  String get label => switch (this) {
        AceStatus.pendente => 'Pendente',
        AceStatus.visitado => 'Visitado',
        AceStatus.fechado => 'Fechado',
        AceStatus.recusado => 'Recusado',
        AceStatus.recuperado => 'Recuperado',
        AceStatus.comFoco => 'Com foco',
      };

  IconData get icon => switch (this) {
        AceStatus.pendente => Icons.schedule,
        AceStatus.visitado => Icons.check_circle_outline,
        AceStatus.fechado => Icons.lock_outline,
        AceStatus.recusado => Icons.block,
        AceStatus.recuperado => Icons.restart_alt,
        AceStatus.comFoco => Icons.bug_report_outlined,
      };

  AceStatusColors colors(Brightness b) {
    final dark = b == Brightness.dark;
    return switch (this) {
      AceStatus.pendente => dark
          ? const AceStatusColors(Color(0xFFF5C86A), Color(0xFF3B2D0F))
          : const AceStatusColors(Color(0xFF7A4B00), Color(0xFFFCEFD2)),
      AceStatus.visitado => dark
          ? const AceStatusColors(Color(0xFF8FDDB5), Color(0xFF0F3A2A))
          : const AceStatusColors(Color(0xFF14573F), Color(0xFFDDF1E7)),
      AceStatus.fechado => dark
          ? const AceStatusColors(Color(0xFFB9C6D1), Color(0xFF2B353D))
          : const AceStatusColors(Color(0xFF3D4B57), Color(0xFFE3E8EC)),
      AceStatus.recusado => dark
          ? const AceStatusColors(Color(0xFFF5A5A2), Color(0xFF47171A))
          : const AceStatusColors(Color(0xFF8F1D1D), Color(0xFFFBE1E0)),
      AceStatus.recuperado => dark
          ? const AceStatusColors(Color(0xFFA8CBF5), Color(0xFF12304F))
          : const AceStatusColors(Color(0xFF1D4E89), Color(0xFFDCE9F8)),
      AceStatus.comFoco => dark
          ? const AceStatusColors(Color(0xFFE9AEE4), Color(0xFF45173F))
          : const AceStatusColors(Color(0xFF6B1F66), Color(0xFFF6E0F4)),
    };
  }
}

/// Situação de um lote no mapa da quadra.
///
/// Vermelho = ainda não visitado, verde = visitado, cinza = recusa ou ninguém
/// em casa. No mapa a cor vem sempre com a legenda (ícone + texto).
enum AceLotStatus { pendente, visitado, semAcesso }

extension AceLotStatusX on AceLotStatus {
  String get label => switch (this) {
        AceLotStatus.pendente => 'A visitar',
        AceLotStatus.visitado => 'Visitado',
        AceLotStatus.semAcesso => 'Recusa / sem morador',
      };

  /// "472 a visitar", "1 visitado", "2 recusa / ausente".
  String countLabel(int n) => switch (this) {
        AceLotStatus.pendente => '$n a visitar',
        AceLotStatus.visitado => n == 1 ? '1 visitado' : '$n visitados',
        AceLotStatus.semAcesso => '$n recusa / ausente',
      };

  IconData get icon => switch (this) {
        AceLotStatus.pendente => Icons.radio_button_unchecked,
        AceLotStatus.visitado => Icons.check_circle,
        AceLotStatus.semAcesso => Icons.do_not_disturb_on,
      };

  /// Cor do telhado e das paredes (iguais nos dois temas: o mapa tem chão próprio).
  Color get color => switch (this) {
        AceLotStatus.pendente => const Color(0xFFD5432F),
        AceLotStatus.visitado => const Color(0xFF239A5E),
        AceLotStatus.semAcesso => const Color(0xFF8E989E),
      };

  /// Texto e fundo para selos fora do mapa (contraste AA).
  AceStatusColors colors(Brightness b) {
    final dark = b == Brightness.dark;
    return switch (this) {
      AceLotStatus.pendente => dark
          ? const AceStatusColors(Color(0xFFF7A99C), Color(0xFF4A1A14))
          : const AceStatusColors(Color(0xFF9E2A1B), Color(0xFFFBE3DE)),
      AceLotStatus.visitado => dark
          ? const AceStatusColors(Color(0xFF8FDDB5), Color(0xFF0F3A2A))
          : const AceStatusColors(Color(0xFF14573F), Color(0xFFDDF1E7)),
      AceLotStatus.semAcesso => dark
          ? const AceStatusColors(Color(0xFFC5CDD2), Color(0xFF2E3539))
          : const AceStatusColors(Color(0xFF454F55), Color(0xFFE6EAEC)),
    };
  }
}

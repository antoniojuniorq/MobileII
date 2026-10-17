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

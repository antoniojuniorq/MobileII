import 'package:flutter/material.dart';

/// Cores primitivas do ACE CONTROL.
///
/// Conceito "Cerrado": verde-folha profundo (marca), âmbar de sol (atenção)
/// e neutros com leve tom esverdeado. Pensado para uso em campo, sob sol forte:
/// contraste alto e nenhuma informação transmitida apenas por cor.
///
/// Telas e componentes NÃO devem usar estas constantes diretamente;
/// usem o tema (`Theme.of(context)`) e `context.ace`.
abstract final class AceColors {
  // Verde Cerrado (marca)
  static const green50 = Color(0xFFE6F3EC);
  static const green100 = Color(0xFFC5E4D5);
  static const green300 = Color(0xFF6FD0A5);
  static const green600 = Color(0xFF1B6B4F);
  static const green800 = Color(0xFF0F4A36);
  static const green950 = Color(0xFF06251A);

  // Âmbar Sol (acento)
  static const amber500 = Color(0xFFE8A317);
  static const amber900 = Color(0xFF1F1500);

  // Neutros - tema claro
  static const ink900 = Color(0xFF12201D);
  static const ink600 = Color(0xFF4A5A55);
  static const ink100 = Color(0xFFD5DDD9);
  static const mist50 = Color(0xFFF2F5F3);
  static const white = Color(0xFFFFFFFF);

  // Neutros - tema escuro
  static const night900 = Color(0xFF0F1614);
  static const night800 = Color(0xFF17201D);
  static const night600 = Color(0xFF2B3A35);
  static const night200 = Color(0xFFA9B8B2);
  static const night50 = Color(0xFFE8EFEC);

  // Feedback
  static const red600 = Color(0xFFB3261E);
  static const red300 = Color(0xFFF5A5A2);
}

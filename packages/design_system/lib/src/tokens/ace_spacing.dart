import 'package:flutter/animation.dart';

/// Escala de espaçamento em grade de 4 dp.
abstract final class AceSpacing {
  static const double x1 = 4;
  static const double x2 = 8;
  static const double x3 = 12;
  static const double x4 = 16;
  static const double x5 = 24;
  static const double x6 = 32;
  static const double x8 = 48;

  /// Altura mínima de qualquer alvo de toque (agentes usam luvas e andam).
  static const double touch = 52;

  /// Margem lateral padrão das telas.
  static const double page = 16;
}

/// Raios de borda. Controles menores que cartões; selos totalmente arredondados.
abstract final class AceRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 999;
}

/// Durações e curvas de animação. Movimento só para responder a uma ação.
abstract final class AceMotion {
  static const fast = Duration(milliseconds: 120);
  static const normal = Duration(milliseconds: 220);
  static const curve = Curves.easeOutCubic;
}

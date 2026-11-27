import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tipografia (v3): Schibsted Grotesk em tudo, escolhida pela Taste Skill
/// ("sólida, confiável"). Uma família só deixa a tela calma; a hierarquia vem
/// de tamanho e peso. Mínimo de 12 sp; textos de ação a partir de 15 sp.
abstract final class AceTypography {
  /// Desative em testes para não buscar fontes na rede.
  static bool useGoogleFonts = true;

  static TextStyle _s(double size, FontWeight w, double h, [double ls = 0]) =>
      useGoogleFonts
          ? GoogleFonts.schibstedGrotesk(fontSize: size, fontWeight: w, height: h, letterSpacing: ls)
          : TextStyle(
              fontFamily: 'SchibstedGrotesk',
              fontSize: size,
              fontWeight: w,
              height: h,
              letterSpacing: ls,
            );

  static TextTheme get textTheme => TextTheme(
        displaySmall: _s(34, FontWeight.w600, 1.1, -0.8),
        headlineMedium: _s(28, FontWeight.w600, 1.15, -0.6),
        headlineSmall: _s(22, FontWeight.w600, 1.2, -0.3),
        titleLarge: _s(18, FontWeight.w600, 1.3, -0.1),
        titleMedium: _s(16, FontWeight.w600, 1.35),
        titleSmall: _s(14, FontWeight.w600, 1.35),
        bodyLarge: _s(16, FontWeight.w400, 1.5),
        bodyMedium: _s(14, FontWeight.w400, 1.5),
        bodySmall: _s(12.5, FontWeight.w400, 1.4),
        labelLarge: _s(15, FontWeight.w600, 1.2),
        labelMedium: _s(13, FontWeight.w600, 1.2),
        labelSmall: _s(12, FontWeight.w600, 1.2, 0.2),
      );
}

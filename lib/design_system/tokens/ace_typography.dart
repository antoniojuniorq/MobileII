import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tipografia: Sora (títulos, números) + Public Sans (texto e rótulos).
/// Mínimo de 12 sp; textos de ação a partir de 15 sp para leitura em campo.
abstract final class AceTypography {
  /// Desative em testes para não buscar fontes na rede.
  static bool useGoogleFonts = true;

  static TextStyle _sora(double size, FontWeight w, double h, [double ls = 0]) =>
      useGoogleFonts
          ? GoogleFonts.sora(fontSize: size, fontWeight: w, height: h, letterSpacing: ls)
          : TextStyle(fontFamily: 'Sora', fontSize: size, fontWeight: w, height: h, letterSpacing: ls);

  static TextStyle _public(double size, FontWeight w, double h) => useGoogleFonts
      ? GoogleFonts.publicSans(fontSize: size, fontWeight: w, height: h)
      : TextStyle(fontFamily: 'PublicSans', fontSize: size, fontWeight: w, height: h);

  static TextTheme get textTheme => TextTheme(
        displaySmall: _sora(32, FontWeight.w700, 1.15, -0.5),
        headlineMedium: _sora(26, FontWeight.w700, 1.2, -0.3),
        headlineSmall: _sora(22, FontWeight.w600, 1.25),
        titleLarge: _sora(18, FontWeight.w600, 1.3),
        titleMedium: _public(16, FontWeight.w600, 1.35),
        titleSmall: _public(14, FontWeight.w600, 1.35),
        bodyLarge: _public(16, FontWeight.w400, 1.5),
        bodyMedium: _public(14, FontWeight.w400, 1.5),
        bodySmall: _public(12, FontWeight.w400, 1.4),
        labelLarge: _public(15, FontWeight.w600, 1.2),
        labelMedium: _public(13, FontWeight.w600, 1.2),
        labelSmall: _public(12, FontWeight.w600, 1.2),
      );
}

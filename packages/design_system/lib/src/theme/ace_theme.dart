import 'package:flutter/material.dart';
import '../tokens/ace_colors.dart';
import '../tokens/ace_spacing.dart';
import '../tokens/ace_typography.dart';

/// Tokens semânticos que o ColorScheme do Material não cobre.
@immutable
class AceSemantic extends ThemeExtension<AceSemantic> {
  const AceSemantic({
    required this.line,
    required this.surfaceMuted,
    required this.textMuted,
  });

  final Color line;
  final Color surfaceMuted;
  final Color textMuted;

  static const light = AceSemantic(
    line: AceColors.line,
    surfaceMuted: AceColors.frost100,
    textMuted: AceColors.ink600,
  );
  static const dark = AceSemantic(
    line: AceColors.night600,
    surfaceMuted: AceColors.night800,
    textMuted: AceColors.night300,
  );

  @override
  AceSemantic copyWith({Color? line, Color? surfaceMuted, Color? textMuted}) =>
      AceSemantic(
        line: line ?? this.line,
        surfaceMuted: surfaceMuted ?? this.surfaceMuted,
        textMuted: textMuted ?? this.textMuted,
      );

  @override
  AceSemantic lerp(ThemeExtension<AceSemantic>? other, double t) {
    if (other is! AceSemantic) return this;
    return AceSemantic(
      line: Color.lerp(line, other.line, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      textMuted: Color.lerp(textMuted, other.textMuted, t)!,
    );
  }
}

extension AceContext on BuildContext {
  AceSemantic get ace => Theme.of(this).extension<AceSemantic>()!;
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}

abstract final class AceTheme {
  static ThemeData get light => _build(
        const ColorScheme(
          brightness: Brightness.light,
          primary: AceColors.teal600,
          onPrimary: AceColors.white,
          primaryContainer: AceColors.teal50,
          onPrimaryContainer: AceColors.teal700,
          secondary: AceColors.amber500,
          onSecondary: AceColors.amber900,
          error: AceColors.red600,
          onError: AceColors.white,
          surface: AceColors.white,
          onSurface: AceColors.ink900,
          outline: AceColors.line,
        ),
        AceSemantic.light,
        AceColors.frost50,
      );

  static ThemeData get dark => _build(
        const ColorScheme(
          brightness: Brightness.dark,
          primary: AceColors.teal300,
          onPrimary: AceColors.teal900,
          primaryContainer: AceColors.teal700,
          onPrimaryContainer: AceColors.teal50,
          secondary: AceColors.amber500,
          onSecondary: AceColors.amber900,
          error: AceColors.red300,
          onError: Color(0xFF3A0A08),
          surface: AceColors.night900,
          onSurface: AceColors.night50,
          outline: AceColors.night600,
        ),
        AceSemantic.dark,
        AceColors.night950,
      );

  static ThemeData _build(ColorScheme c, AceSemantic s, Color background) {
    final text = AceTypography.textTheme.apply(
      bodyColor: c.onSurface,
      displayColor: c.onSurface,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AceRadius.md),
    );
    const minSize = Size(0, AceSpacing.touch);

    OutlineInputBorder border(Color color, [double w = 1.5]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AceRadius.md),
          borderSide: BorderSide(color: color, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: c.brightness,
      colorScheme: c,
      scaffoldBackgroundColor: background,
      textTheme: text,
      extensions: [s],
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: c.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: text.titleLarge,
      ),
      dividerTheme: DividerThemeData(color: s.line, space: 1, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AceSpacing.x4,
          vertical: AceSpacing.x3,
        ),
        border: border(s.line, 1),
        enabledBorder: border(s.line, 1),
        focusedBorder: border(c.primary, 2),
        errorBorder: border(c.error),
        focusedErrorBorder: border(c.error, 2),
        hintStyle: text.bodyLarge?.copyWith(color: s.textMuted),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: minSize,
          shape: shape,
          textStyle: text.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: minSize,
          shape: shape,
          side: BorderSide(color: c.primary, width: 1.5),
          textStyle: text.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: minSize,
          shape: shape,
          textStyle: text.labelLarge,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        indicatorColor: c.primaryContainer,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStatePropertyAll(text.labelSmall),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        dragHandleColor: s.line,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AceRadius.lg + 6)),
        ),
      ),
      chipTheme: ChipThemeData(
        selectedColor: c.primaryContainer,
        secondarySelectedColor: c.primaryContainer,
        side: BorderSide(color: s.line),
        labelStyle: text.labelLarge,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AceRadius.md)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: shape,
      ),
    );
  }
}

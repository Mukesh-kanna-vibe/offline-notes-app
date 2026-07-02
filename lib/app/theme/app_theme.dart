import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

abstract final class AppTheme {
  // Warm editorial palette from the reference landing design.
  static const pageBackground = Color(0xFFF7F5EE);
  static const cardWhite = Color(0xFFFFFFFF);
  static const ink = Color(0xFF1A1A1A);
  static const inkMuted = Color(0xFF666666);
  static const inkSoft = Color(0xFF8E938D);
  static const border = Color(0xFFE8E6DC);
  static const foldShadow = Color(0xFFEDEAE2);
  static const onlineGreen = Color(0xFF4A6741);
  static const onlineBg = Color(0xFFE6F0E6);
  static const offlineBg = Color(0xFFF0EEE6);
  static const fabDark = Color(0xFF1A1A1A);
  static const pendingAmber = Color(0xFFB8860B);
  static const conflictRed = Color(0xFFB54A4A);

  /// Subtle dark-grey shimmer tones (light black feel on warm background).
  static const shimmerBase = Color(0xFFDDDAD2);
  static const shimmerHighlight = Color(0xFFEDEBE4);
  static const shimmerBlock = Color(0xFFCCC9C0);

  static const cardRadius = 16.0;
  static const inputRadius = 32.0;
  static const fabRadius = 28.0;
  static const chipRadius = 999.0;

  static ThemeData light() => _build(Brightness.light);

  static ThemeData dark() => _build(Brightness.dark);

  static Color pageColor(Brightness brightness) {
    return brightness == Brightness.light ? pageBackground : const Color(0xFF1A1916);
  }

  static Color cardColor(Brightness brightness) {
    return brightness == Brightness.light ? cardWhite : const Color(0xFF26241F);
  }

  static Color elevatedSurfaceHighlight(Brightness brightness) {
    return brightness == Brightness.light
        ? const Color(0xFFF2F0E8)
        : const Color(0xFF322F2A);
  }

  static BoxDecoration pageDecoration(Brightness brightness) {
    return BoxDecoration(color: pageColor(brightness));
  }

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final colorScheme = ColorScheme(
      brightness: brightness,
      primary: isLight ? ink : const Color(0xFFF7F5EE),
      onPrimary: isLight ? cardWhite : ink,
      secondary: onlineGreen,
      onSecondary: cardWhite,
      error: conflictRed,
      onError: cardWhite,
      surface: pageColor(brightness),
      onSurface: isLight ? ink : const Color(0xFFF7F5EE),
      onSurfaceVariant: isLight ? inkMuted : const Color(0xFF8E938D),
      outline: border,
      outlineVariant: border,
      surfaceContainerHighest: cardColor(brightness),
      surfaceContainerLowest: cardColor(brightness),
    );

    final textTheme = _textTheme(colorScheme);

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: pageColor(brightness),
      textTheme: textTheme,
      primaryTextTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onSurface,
        titleTextStyle: textTheme.titleMedium,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: cardColor(brightness),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
        ),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardColor(brightness),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(inputRadius),
          borderSide: const BorderSide(color: ink, width: 1.2),
        ),
        hintStyle: textTheme.bodyMedium?.copyWith(color: inkSoft),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          backgroundColor: fabDark,
          foregroundColor: cardWhite,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          side: const BorderSide(color: border),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: textTheme.labelLarge,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 4,
        highlightElevation: 6,
        backgroundColor: fabDark,
        foregroundColor: cardWhite,
        extendedPadding: const EdgeInsets.symmetric(horizontal: 22),
        extendedTextStyle: textTheme.labelLarge,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(fabRadius),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(40, 40),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          visualDensity: VisualDensity.compact,
          foregroundColor: inkMuted,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        contentTextStyle: textTheme.bodyMedium?.copyWith(color: cardWhite),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor(brightness),
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: cardColor(brightness),
        surfaceTintColor: Colors.transparent,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        textStyle: textTheme.bodyMedium?.copyWith(color: ink),
      ),
      dividerTheme: const DividerThemeData(
        color: border,
        thickness: 1,
        space: 1,
      ),
    );
  }

  static TextTheme _textTheme(ColorScheme scheme) {
    final base = GoogleFonts.interTextTheme();

    TextStyle heading(TextStyle? style, {double? size, double? height}) {
      return (style ?? const TextStyle()).copyWith(
        fontWeight: FontWeight.w700,
        color: scheme.onSurface,
        fontSize: size,
        height: height,
      );
    }

    TextStyle subheading(TextStyle? style, {double? size, double? height}) {
      return (style ?? const TextStyle()).copyWith(
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
        fontSize: size,
        height: height,
      );
    }

    TextStyle body(
      TextStyle? style, {
      double? size,
      double? height,
      Color? color,
    }) {
      return (style ?? const TextStyle()).copyWith(
        fontWeight: FontWeight.w400,
        color: color ?? scheme.onSurface,
        fontSize: size,
        height: height,
      );
    }

    TextStyle caption(TextStyle? style, {double? size, Color? color}) {
      return (style ?? const TextStyle()).copyWith(
        fontWeight: FontWeight.w400,
        color: color ?? scheme.onSurfaceVariant,
        fontSize: size,
      );
    }

    return base.copyWith(
      displayLarge: heading(base.displayLarge, size: 57, height: 1.12),
      displayMedium: heading(base.displayMedium, size: 45, height: 1.16),
      displaySmall: heading(base.displaySmall, size: 36, height: 1.15),
      headlineLarge: heading(base.headlineLarge, size: 32, height: 1.2),
      headlineMedium: heading(base.headlineMedium, size: 28, height: 1.2),
      headlineSmall: heading(
        base.headlineSmall,
        size: 32,
        height: 1.15,
      ).copyWith(letterSpacing: -0.6),
      titleLarge: subheading(base.titleLarge, size: 22, height: 1.25),
      titleMedium: subheading(
        base.titleMedium,
        size: 18,
        height: 1.25,
      ).copyWith(letterSpacing: -0.2),
      titleSmall: subheading(
        base.titleSmall,
        size: 16,
        height: 1.25,
      ).copyWith(letterSpacing: -0.15),
      bodyLarge: body(
        base.bodyLarge,
        size: 16,
        height: 1.55,
      ).copyWith(letterSpacing: -0.1),
      bodyMedium: body(
        base.bodyMedium,
        size: 14,
        height: 1.5,
        color: scheme.onSurfaceVariant,
      ).copyWith(letterSpacing: -0.05),
      bodySmall: body(
        base.bodySmall,
        size: 13,
        height: 1.45,
        color: scheme.onSurfaceVariant,
      ),
      labelLarge: subheading(
        base.labelLarge,
        size: 14,
        height: 1.2,
      ).copyWith(letterSpacing: -0.1),
      labelMedium: subheading(base.labelMedium, size: 12, height: 1.2),
      labelSmall: caption(
        base.labelSmall,
        size: 12,
      ).copyWith(letterSpacing: 0.1),
    );
  }

  static List<BoxShadow> cardShadow(BuildContext context) {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.03),
        blurRadius: 4,
        offset: const Offset(0, 1),
      ),
    ];
  }

  static BoxDecoration squareIconButtonDecoration(Brightness brightness) {
    return BoxDecoration(
      color: cardColor(brightness),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: border),
    );
  }
}

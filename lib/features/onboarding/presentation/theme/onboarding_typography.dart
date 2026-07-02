import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../app/theme/app_theme.dart';

abstract final class OnboardingTypography {
  static TextStyle heading({
    required double fontSize,
    Color color = AppTheme.ink,
    double letterSpacing = -0.6,
    FontWeight fontWeight = FontWeight.w700,
  }) {
    return GoogleFonts.playfairDisplay(
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: 1.15,
      color: color,
    );
  }

  static TextStyle body({
    required double fontSize,
    Color color = AppTheme.inkMuted,
    FontWeight fontWeight = FontWeight.w400,
    double height = 1.55,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      color: color,
    );
  }

  static TextStyle label({
    required double fontSize,
    Color color = AppTheme.ink,
    FontWeight fontWeight = FontWeight.w600,
  }) {
    return GoogleFonts.inter(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }
}

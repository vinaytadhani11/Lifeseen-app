import 'package:flutter/material.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';

/// Plus Jakarta Sans + JetBrains Mono are bundled variable fonts.
/// Weights go through the `wght` axis so we do not fetch Google Fonts at runtime.
class AppText {
  AppText._();

  static const sans = 'Plus Jakarta Sans';
  static const monoFamily = 'JetBrains Mono';

  static TextStyle jakarta(
    double size,
    FontWeight weight, {
    Color color = AppColors.text,
    double height = 1.35,
    double spacing = 0,
  }) {
    return TextStyle(
      fontFamily: sans,
      fontSize: size,
      fontWeight: weight,
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
      color: color,
      height: height,
      letterSpacing: spacing,
    );
  }

  static TextStyle mono(
    double size,
    FontWeight weight, {
    Color color = AppColors.muted,
    double spacing = 0,
    double height = 1.3,
  }) {
    return TextStyle(
      fontFamily: monoFamily,
      fontSize: size,
      fontWeight: weight,
      fontVariations: [FontVariation('wght', weight.value.toDouble())],
      color: color,
      letterSpacing: spacing,
      height: height,
    );
  }

  static TextStyle get h1 => jakarta(27, FontWeight.w800, height: 1.15, spacing: -0.4);
  static TextStyle get h2 => jakarta(26, FontWeight.w800, height: 1.15, spacing: -0.4);
  static TextStyle get sub => jakarta(15, FontWeight.w400, color: AppColors.grey, height: 1.45);
  static TextStyle get small => jakarta(12.5, FontWeight.w400, color: AppColors.grey);
  static TextStyle get bodyBold => jakarta(15, FontWeight.w700);
}

bool lsReduceMotion(BuildContext context) => MediaQuery.disableAnimationsOf(context);

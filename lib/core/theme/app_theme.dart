import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tableflow_plus/core/theme/app_colors.dart';
import 'package:tableflow_plus/core/theme/app_text.dart';

/// Light theme used only inside the friends screen-time flow.
/// The app-wide theme in `main.dart` stays dark for WhatsApp mode.
class AppTheme {
  AppTheme._();

  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bg,
      fontFamily: AppText.sans,
      colorScheme: const ColorScheme.light(
        primary: AppColors.green,
        onPrimary: AppColors.ink,
        surface: AppColors.white,
        onSurface: AppColors.text,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      splashFactory: InkSparkle.splashFactory,
    );
  }
}

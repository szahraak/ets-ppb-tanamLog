import 'package:flutter/material.dart';

// ── Colors ────────────────────────────────────────────────────────────────────
class AppColors {
  static const Color primary = Color(0xFF4CAF50);
  static const Color primaryDark = Color(0xFF1B5E20);
  static const Color primaryContainer = Color(0xFFC8E6C9);
  static const Color onPrimary = Colors.white;
  
  static const Color secondary = Color(0xFF81C784);
  static const Color secondaryContainer = Color(0xFFC8E6C9);
  static const Color onSecondary = Colors.white;
  
  static const Color tertiary = Color(0xFF66BB6A);
  static const Color tertiaryContainer = Color(0xFFC8E6C9);
  static const Color onTertiary = Colors.white;
  
  static const Color surface = Color(0xFFFAFCFA);
  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainer = Color(0xFFF5F7F5);
  
  static const Color onSurface = Color(0xFF1B1B1B);
  static const Color outline = Color(0xFF79747E);
  static const Color outlineVariant = Color(0xFFCAC7D0);
  
  static const Color error = Color(0xFFB3261E);
  static const Color errorContainer = Color(0xFFF9DEDC);
  static const Color onError = Colors.white;
}

// ── Spacing ───────────────────────────────────────────────────────────────────
class AppSpacing {
  static const double stackXs = 4.0;
  static const double stackSm = 8.0;
  static const double stackMd = 12.0;
  static const double stackLg = 16.0;
  static const double stackXl = 24.0;
  static const double stackXxl = 32.0;
  
  static const double gutter = 12.0;
  static const double containerMargin = 16.0;
}

// ── Border Radius ─────────────────────────────────────────────────────────────
class AppRadius {
  static const BorderRadius defBR = BorderRadius.all(Radius.circular(8.0));
  static const BorderRadius mdBR = BorderRadius.all(Radius.circular(12.0));
  static const BorderRadius lgBR = BorderRadius.all(Radius.circular(16.0));
  static const BorderRadius xlBR = BorderRadius.all(Radius.circular(20.0));
  static const BorderRadius fullBR = BorderRadius.all(Radius.circular(100.0));
}

// ── Theme Data ────────────────────────────────────────────────────────────────
ThemeData appTheme() {
  const String fontFamily = 'Plus Jakarta Sans';
  
  return ThemeData(
    useMaterial3: true,
    fontFamily: fontFamily,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      surface: AppColors.surface,
      onSurface: AppColors.onSurface,
    ),
    textTheme: TextTheme(
      displaySmall: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.onSurface,
      ),
      headlineSmall: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurface,
      ),
      titleMedium: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      ),
      titleSmall: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.onSurface,
      ),
      bodyMedium: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: AppColors.onSurface,
      ),
      bodySmall: const TextStyle(
        fontFamily: fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: AppColors.outline,
      ),
    ),
  );
}

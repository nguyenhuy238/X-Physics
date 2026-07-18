import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'x_design_system.dart';

class AppTheme {
  static ThemeData light() {
    return _build(brightness: Brightness.light);
  }

  static ThemeData dark() {
    return _build(brightness: Brightness.dark);
  }

  static ThemeData _build({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;
    const seed = AppColors.primary;
    final textColor = isDark ? const Color(0xFFE5E7EB) : AppColors.textPrimary;
    final secondaryTextColor = isDark
        ? const Color(0xFFCBD5E1)
        : AppColors.textSecondary;
    final background = isDark ? const Color(0xFF0F172A) : AppColors.background;
    final surface = isDark ? const Color(0xFF111827) : AppColors.surface;
    final surfaceVariant = isDark
        ? const Color(0xFF1F2937)
        : AppColors.surfaceVariant;
    final border = isDark ? const Color(0xFF334155) : AppColors.border;
    return ThemeData(
      useMaterial3: true,
      fontFamily: 'Roboto',
      colorScheme: ColorScheme.fromSeed(
        seedColor: seed,
        brightness: brightness,
        primary: seed,
        secondary: AppColors.secondary,
        tertiary: AppColors.info,
        surface: surface,
        error: AppColors.danger,
      ),
      scaffoldBackgroundColor: background,
      extensions: const [XSpacing(), XRadius(), XGradients()],
      textTheme: TextTheme(
        displaySmall: TextStyle(
          fontSize: 32,
          height: 1.18,
          fontWeight: FontWeight.w900,
          color: textColor,
        ),
        headlineMedium: TextStyle(
          fontSize: 24,
          height: 1.25,
          fontWeight: FontWeight.w900,
          color: textColor,
        ),
        titleLarge: TextStyle(
          fontSize: 20,
          height: 1.3,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          height: 1.4,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
        bodyLarge: TextStyle(fontSize: 16, height: 1.55, color: textColor),
        bodyMedium: TextStyle(
          fontSize: 14,
          height: 1.5,
          color: secondaryTextColor,
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          height: 1.35,
          fontWeight: FontWeight.w800,
          color: textColor,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: isDark ? .18 : .06),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: seed, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.danger),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          side: BorderSide(color: border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceVariant,
        selectedColor: AppColors.accent,
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: border,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.w900,
        ),
      ),
      dividerTheme: DividerThemeData(color: border),
    );
  }
}

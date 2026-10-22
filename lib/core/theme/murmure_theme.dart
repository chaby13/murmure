import 'package:flutter/material.dart';

import 'murmure_colors.dart';

/// Thèmes clair et sombre de Murmure.
abstract final class MurmureTheme {
  /// Police de titre : serif système (aucune police téléchargée).
  static const titleFamily = 'serif';
  static const titleFallback = ['Georgia', 'Noto Serif', 'Times New Roman'];

  static ThemeData light() => _build(
    const ColorScheme(
      brightness: Brightness.light,
      primary: MurmureColors.deepGreen,
      onPrimary: Colors.white,
      primaryContainer: MurmureColors.paleGreen,
      onPrimaryContainer: MurmureColors.inkLight,
      secondary: MurmureColors.deepGreen,
      onSecondary: Colors.white,
      secondaryContainer: MurmureColors.paleGreen,
      onSecondaryContainer: MurmureColors.inkLight,
      tertiary: Color(0xFF6B5A45),
      onTertiary: Colors.white,
      tertiaryContainer: MurmureColors.beige,
      onTertiaryContainer: MurmureColors.inkLight,
      error: MurmureColors.error,
      onError: Colors.white,
      surface: MurmureColors.ivory,
      onSurface: MurmureColors.inkLight,
      onSurfaceVariant: MurmureColors.mutedLight,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: MurmureColors.surfaceLight,
      surfaceContainer: MurmureColors.surfaceLight,
      surfaceContainerHigh: Color(0xFFEDE7DC),
      surfaceContainerHighest: MurmureColors.beige,
      outline: Color(0xFF8B958F),
      outlineVariant: MurmureColors.outlineLight,
    ),
  );

  static ThemeData dark() => _build(
    const ColorScheme(
      brightness: Brightness.dark,
      primary: MurmureColors.sageDark,
      onPrimary: MurmureColors.onSageDark,
      primaryContainer: Color(0xFF2F4741),
      onPrimaryContainer: MurmureColors.inkDark,
      secondary: MurmureColors.sageDark,
      onSecondary: MurmureColors.onSageDark,
      secondaryContainer: Color(0xFF2F4741),
      onSecondaryContainer: MurmureColors.inkDark,
      tertiary: Color(0xFFD9C8B2),
      onTertiary: Color(0xFF2A2116),
      tertiaryContainer: Color(0xFF3D352B),
      onTertiaryContainer: MurmureColors.inkDark,
      error: MurmureColors.errorDark,
      onError: Color(0xFF3A0905),
      surface: MurmureColors.backgroundDark,
      onSurface: MurmureColors.inkDark,
      onSurfaceVariant: MurmureColors.mutedDark,
      surfaceContainerLowest: Color(0xFF101614),
      surfaceContainerLow: MurmureColors.surfaceDark,
      surfaceContainer: MurmureColors.surfaceDark,
      surfaceContainerHigh: MurmureColors.surfaceHighDark,
      surfaceContainerHighest: Color(0xFF323F3A),
      outline: Color(0xFF7E8A85),
      outlineVariant: MurmureColors.outlineDark,
    ),
  );

  static ThemeData _build(ColorScheme scheme) {
    final base = ThemeData(colorScheme: scheme, useMaterial3: true);
    final text = base.textTheme;
    TextStyle serif(TextStyle? style) => (style ?? const TextStyle()).copyWith(
      fontFamily: titleFamily,
      fontFamilyFallback: titleFallback,
      color: scheme.onSurface,
    );

    return base.copyWith(
      scaffoldBackgroundColor: scheme.surface,
      textTheme: text.copyWith(
        displaySmall: serif(text.displaySmall),
        headlineLarge: serif(text.headlineLarge),
        headlineMedium: serif(text.headlineMedium),
        headlineSmall: serif(text.headlineSmall),
        titleLarge: serif(text.titleLarge),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: serif(text.titleLarge).copyWith(fontSize: 24),
      ),
      cardTheme: CardThemeData(
        color: scheme.surfaceContainerLow,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        indicatorColor: scheme.primaryContainer,
        surfaceTintColor: Colors.transparent,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLow,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

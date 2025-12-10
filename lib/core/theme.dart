// lib/core/theme.dart
// Theme configuration using ForUi with custom neutral colors for POS application

import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import '../providers/settings_provider.dart';

class AppTheme {
  // Orange, Black & White Theme - Light Mode
  static const Color lightPrimary = Color(0xFFFF6B35); // Orange principal
  static const Color lightPrimaryForeground = Color(0xFFFFFFFF); // Blanc
  static const Color lightSecondary = Color(0xFFFF8C52); // Orange doux
  static const Color lightSecondaryForeground = Color(0xFFFFFFFF); // Blanc
  static const Color lightBackground = Color(0xFFFFFFFF); // Blanc pur
  static const Color lightForeground = Color(0xFF000000); // Noir pur
  static const Color lightMuted = Color(0xFFF5F5F5); // Gris très clair
  static const Color lightMutedForeground = Color(0xFF757575); // Gris moyen
  static const Color lightBorder = Color(0xFFE0E0E0); // Gris clair pour bordures
  static const Color lightDestructive = Color(0xFFD32F2F); // Rouge
  static const Color lightDestructiveForeground = Color(0xFFFFFFFF);
  static const Color lightSuccess = Color(0xFF4CAF50); // Vert
  static const Color lightSuccessForeground = Color(0xFFFFFFFF);
  static const Color lightWarning = Color(0xFFFF9800); // Orange warning
  static const Color lightWarningForeground = Color(0xFFFFFFFF);

  // Orange, Black & White Theme - Dark Mode
  static const Color darkPrimary = Color(0xFFFF6B35); // Orange principal (même couleur)
  static const Color darkPrimaryForeground = Color(0xFFFFFFFF); // Blanc
  static const Color darkSecondary = Color(0xFFBDBDBD); // Gris clair
  static const Color darkSecondaryForeground = Color(0xFF000000); // Noir
  static const Color darkBackground = Color(0xFF000000); // Noir pur
  static const Color darkForeground = Color(0xFFFFFFFF); // Blanc pur
  static const Color darkMuted = Color(0xFF1A1A1A); // Gris très foncé
  static const Color darkMutedForeground = Color(0xFF9E9E9E); // Gris moyen
  static const Color darkBorder = Color(0xFF424242); // Gris foncé pour bordures
  static const Color darkDestructive = Color(0xFFF44336); // Rouge clair
  static const Color darkDestructiveForeground = Color(0xFF000000);
  static const Color darkSuccess = Color(0xFF66BB6A); // Vert clair
  static const Color darkSuccessForeground = Color(0xFF000000);
  static const Color darkWarning = Color(0xFFFFB74D); // Orange clair
  static const Color darkWarningForeground = Color(0xFF000000);

  static FThemeData lightTheme({AppThemeType themeType = AppThemeType.neutral}) {
    switch (themeType) {
      case AppThemeType.neutral:
        return _createNeutralLightTheme();
      case AppThemeType.zinc:
        return FThemes.zinc.light;
      case AppThemeType.slate:
        return FThemes.slate.light;
      case AppThemeType.blue:
        return FThemes.blue.light;
      case AppThemeType.green:
        return FThemes.green.light;
      case AppThemeType.orange:
        return _createOrangeLightTheme();
    }
  }

  static FThemeData darkTheme({AppThemeType themeType = AppThemeType.neutral}) {
    switch (themeType) {
      case AppThemeType.neutral:
        return _createNeutralDarkTheme();
      case AppThemeType.zinc:
        return FThemes.zinc.dark;
      case AppThemeType.slate:
        return FThemes.slate.dark;
      case AppThemeType.blue:
        return FThemes.blue.dark;
      case AppThemeType.green:
        return FThemes.green.dark;
      case AppThemeType.orange:
        return _createOrangeDarkTheme();
    }
  }

  static FThemeData _createNeutralLightTheme() {
    // Use zinc theme as base and modify specific colors
    final baseTheme = FThemes.zinc.light;
    return baseTheme.copyWith(
      colors: baseTheme.colors.copyWith(
        primary: lightPrimary,
        primaryForeground: lightPrimaryForeground,
        secondary: lightSecondary,
        secondaryForeground: lightSecondaryForeground,
        background: lightBackground,
        foreground: lightForeground,
        muted: lightMuted,
        mutedForeground: lightMutedForeground,
        border: lightBorder,
        destructive: lightDestructive,
        destructiveForeground: lightDestructiveForeground,
      ),
    );
  }

  static FThemeData _createNeutralDarkTheme() {
    // Use zinc theme as base and modify specific colors
    final baseTheme = FThemes.zinc.dark;
    return baseTheme.copyWith(
      colors: baseTheme.colors.copyWith(
        primary: darkPrimary,
        primaryForeground: darkPrimaryForeground,
        secondary: darkSecondary,
        secondaryForeground: darkSecondaryForeground,
        background: darkBackground,
        foreground: darkForeground,
        muted: darkMuted,
        mutedForeground: darkMutedForeground,
        border: darkBorder,
        destructive: darkDestructive,
        destructiveForeground: darkDestructiveForeground,
      ),
    );
  }

  static FThemeData _createOrangeLightTheme() {
    // Use zinc theme as base and modify with orange colors
    final baseTheme = FThemes.zinc.light;
    return baseTheme.copyWith(
      colors: baseTheme.colors.copyWith(
        primary: lightPrimary,
        primaryForeground: lightPrimaryForeground,
        secondary: lightSecondary,
        secondaryForeground: lightSecondaryForeground,
        background: lightBackground,
        foreground: lightForeground,
        muted: lightMuted,
        mutedForeground: lightMutedForeground,
        border: lightBorder,
        destructive: lightDestructive,
        destructiveForeground: lightDestructiveForeground,
      ),
    );
  }

  static FThemeData _createOrangeDarkTheme() {
    // Use zinc theme as base and modify with orange colors
    final baseTheme = FThemes.zinc.dark;
    return baseTheme.copyWith(
      colors: baseTheme.colors.copyWith(
        primary: darkPrimary,
        primaryForeground: darkPrimaryForeground,
        secondary: darkSecondary,
        secondaryForeground: darkSecondaryForeground,
        background: darkBackground,
        foreground: darkForeground,
        muted: darkMuted,
        mutedForeground: darkMutedForeground,
        border: darkBorder,
        destructive: darkDestructive,
        destructiveForeground: darkDestructiveForeground,
      ),
    );
  }

  // Helper to wrap the MaterialApp with ForUi theme
  static Widget wrapApp(Widget child, {required bool darkMode, AppThemeType themeType = AppThemeType.neutral}) {
    return FTheme(
      data: darkMode ? darkTheme(themeType: themeType) : lightTheme(themeType: themeType),
      child: child,
    );
  }

}

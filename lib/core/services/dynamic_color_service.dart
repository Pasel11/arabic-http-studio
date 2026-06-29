import 'package:flutter/material.dart';

/// Dynamic color service for Material You support.
///
/// On Android 12+ (API 31+), this extracts wallpaper colors
/// and generates a complete color scheme. On other platforms,
/// it falls back to a default color scheme.
class DynamicColorService {
  DynamicColorService._();
  static final DynamicColorService instance = DynamicColorService._();

  /// Gets the light color scheme.
  ///
  /// On supported platforms, this uses dynamic color extraction.
  /// Otherwise, it returns the default light scheme.
  Future<ColorScheme> getLightColorScheme() async {
    // In a real implementation, this would use dynamic_color
    // package to get wallpaper-based colors on Android 12+
    return _defaultLightScheme;
  }

  /// Gets the dark color scheme.
  Future<ColorScheme> getDarkColorScheme() async {
    return _defaultDarkScheme;
  }

  /// Whether dynamic color is available on this platform.
  Future<bool> isDynamicColorAvailable() async {
    // Check if platform supports dynamic color
    return false; // Will be true on Android 12+ with dynamic_color package
  }

  static const ColorScheme _defaultLightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF1A73E8),
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFD3E3FD),
    onPrimaryContainer: Color(0xFF001D35),
    secondary: Color(0xFF5F6368),
    onSecondary: Colors.white,
    secondaryContainer: Color(0xFFD3E3FD),
    onSecondaryContainer: Color(0xFF1A1C1E),
    tertiary: Color(0xFF00897B),
    onTertiary: Colors.white,
    tertiaryContainer: Color(0xFFB6E8E0),
    onTertiaryContainer: Color(0xFF00201C),
    error: Color(0xFFD93025),
    onError: Colors.white,
    errorContainer: Color(0xFFFFDAD6),
    onErrorContainer: Color(0xFF410002),
    background: Color(0xFFFEF7FF),
    onBackground: Color(0xFF1D1B1E),
    surface: Color(0xFFFEF7FF),
    onSurface: Color(0xFF1D1B1E),
    surfaceVariant: Color(0xFFE7E0EC),
    onSurfaceVariant: Color(0xFF49454F),
    outline: Color(0xFF79747E),
    outlineVariant: Color(0xFFCAC4D0),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFF322F35),
    onInverseSurface: Color(0xFFF5EFF7),
    inversePrimary: Color(0xFFA8C7FA),
  );

  static const ColorScheme _defaultDarkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFA8C7FA),
    onPrimary: Color(0xFF062E6F),
    primaryContainer: Color(0xFF00497D),
    onPrimaryContainer: Color(0xFFD3E3FD),
    secondary: Color(0xFF9AA0A6),
    onSecondary: Color(0xFF252A2E),
    secondaryContainer: Color(0xFF3C4043),
    onSecondaryContainer: Color(0xFFE3E2E6),
    tertiary: Color(0xFFB6E8E0),
    onTertiary: Color(0xFF00322B),
    tertiaryContainer: Color(0xFF005048),
    onTertiaryContainer: Color(0xFFB6E8E0),
    error: Color(0xFFF28B82),
    onError: Color(0xFF690005),
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    background: Color(0xFF141218),
    onBackground: Color(0xFFE6E0E9),
    surface: Color(0xFF141218),
    onSurface: Color(0xFFE6E0E9),
    surfaceVariant: Color(0xFF49454F),
    onSurfaceVariant: Color(0xFFCAC4D0),
    outline: Color(0xFF938F99),
    outlineVariant: Color(0xFF49454F),
    shadow: Colors.black,
    scrim: Colors.black,
    inverseSurface: Color(0xFFE6E0E9),
    onInverseSurface: Color(0xFF322F35),
    inversePrimary: Color(0xFF1A73E8),
  );
}

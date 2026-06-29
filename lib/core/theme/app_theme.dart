import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Application theme configuration with Material 3 support
class AppTheme {
  AppTheme._();

  /// Light theme colors
  static const Color _lightPrimary = Color(0xFF1A73E8);
  static const Color _lightOnPrimary = Color(0xFFFFFFFF);
  static const Color _lightSecondary = Color(0xFF5F6368);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightBackground = Color(0xFFF8F9FA);
  static const Color _lightError = Color(0xFFD93025);
  static const Color _lightOnSurface = Color(0xFF202124);

  /// Dark theme colors
  static const Color _darkPrimary = Color(0xFF8AB4F8);
  static const Color _darkOnPrimary = Color(0xFF062E6F);
  static const Color _darkSecondary = Color(0xFF9AA0A6);
  static const Color _darkSurface = Color(0xFF292A2D);
  static const Color _darkBackground = Color(0xFF202124);
  static const Color _darkError = Color(0xFFF28B82);
  static const Color _darkOnSurface = Color(0xFFE8EAED);

  /// Status colors
  static const Color successColor = Color(0xFF34A853);
  static const Color warningColor = Color(0xFFFBBC04);
  static const Color infoColor = Color(0xFF4285F4);

  /// Method colors
  static const Color getColor = Color(0xFF34A853);
  static const Color postColor = Color(0xFF4285F4);
  static const Color putColor = Color(0xFFFBBC04);
  static const Color patchColor = Color(0xFF9334E8);
  static const Color deleteColor = Color(0xFFEA4335);
  static const Color headColor = Color(0xFF5F6368);
  static const Color optionsColor = Color(0xFF00897B);

  /// Light theme
  static ThemeData get lightTheme => _buildTheme(
        brightness: Brightness.light,
        primary: _lightPrimary,
        onPrimary: _lightOnPrimary,
        secondary: _lightSecondary,
        surface: _lightSurface,
        background: _lightBackground,
        error: _lightError,
        onSurface: _lightOnSurface,
      );

  /// Dark theme
  static ThemeData get darkTheme => _buildTheme(
        brightness: Brightness.dark,
        primary: _darkPrimary,
        onPrimary: _darkOnPrimary,
        secondary: _darkSecondary,
        surface: _darkSurface,
        background: _darkBackground,
        error: _darkError,
        onSurface: _darkOnSurface,
      );

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color primary,
    required Color onPrimary,
    required Color secondary,
    required Color surface,
    required Color background,
    required Color error,
    required Color onSurface,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      onPrimary: onPrimary,
      secondary: secondary,
      surface: surface,
      onSurface: onSurface,
      error: error,
      background: background,
    );

    final isDark = brightness == Brightness.dark;
    final textTheme = GoogleFonts.cairoTextTheme(
      ThemeData(
        colorScheme: colorScheme,
        brightness: brightness,
      ).textTheme,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: isDark ? 1 : 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: onPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary,
          side: BorderSide(color: primary),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary,
          textStyle: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? _darkSurface : _lightBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? Colors.grey[800] : Colors.grey[300],
        thickness: 1,
        space: 1,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: secondary,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: GoogleFonts.cairo(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.cairo(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        selectedIconTheme: IconThemeData(color: primary),
        unselectedIconTheme: IconThemeData(color: secondary),
        selectedLabelTextStyle: GoogleFonts.cairo(
          color: primary,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: GoogleFonts.cairo(
          color: secondary,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? _darkSurface : _lightBackground,
        selectedColor: primary,
        labelStyle: GoogleFonts.cairo(fontSize: 12),
        secondaryLabelStyle: GoogleFonts.cairo(fontSize: 12),
        brightness: brightness,
      ),
      tabBarTheme: TabBarTheme(
        labelColor: primary,
        unselectedLabelColor: secondary,
        labelStyle: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(color: primary, width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? _darkSurface : _lightOnSurface,
        contentTextStyle: GoogleFonts.cairo(
          color: isDark ? _darkOnSurface : _lightSurface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: surface,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: onSurface,
        ),
        contentTextStyle: GoogleFonts.cairo(
          fontSize: 14,
          color: onSurface,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      listTileTheme: ListTileThemeData(
        textColor: onSurface,
        iconColor: primary,
        titleTextStyle: GoogleFonts.cairo(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        subtitleTextStyle: GoogleFonts.cairo(
          fontSize: 12,
          color: secondary,
        ),
      ),
    );
  }

  /// Get color for HTTP method
  static Color getMethodColor(String method) {
    switch (method.toUpperCase()) {
      case 'GET':
        return getColor;
      case 'POST':
        return postColor;
      case 'PUT':
        return putColor;
      case 'PATCH':
        return patchColor;
      case 'DELETE':
        return deleteColor;
      case 'HEAD':
        return headColor;
      case 'OPTIONS':
        return optionsColor;
      default:
        return secondary;
    }
  }

  /// Get color for status code
  static Color getStatusColor(int status) {
    if (status >= 200 && status < 300) return successColor;
    if (status >= 300 && status < 400) return infoColor;
    if (status >= 400 && status < 500) return warningColor;
    if (status >= 500) return errorColor;
    return secondary;
  }
}

/// Extension to add codeTextStyle to ThemeData
extension ThemeDataExtension on ThemeData {
  TextStyle get codeTextStyle => GoogleFonts.jetBrainsMono(
        fontSize: 13,
        height: 1.5,
        color: colorScheme.onSurface,
      );
}

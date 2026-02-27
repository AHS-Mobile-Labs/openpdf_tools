import 'package:flutter/material.dart';
import 'package:openpdf_tools/utils/platform_helper.dart';

/// Global app configuration
class AppConfig {
  // App constants
  static const String appTitle = 'OpenPDF Tools';
  static const String appVersion = '1.0.0';
  static const String githubUrl =
      'https://github.com/AHS-Mobile-Labs/openpdf_tools';

  // Colors
  static const Color primaryColor = Color(0xFFC6302C);
  static const Color darkRedColor = Color(0xFF9A0000);
  static const Color accentColor = Color(0xFFFFB81C);

  // Responsive breakpoints
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1200;

  // Font sizes
  static const double fontSizeSmall = 12;
  static const double fontSizeBase = 14;
  static const double fontSizeLarge = 16;
  static const double fontSizeXLarge = 20;
  static const double fontSizeXXLarge = 24;

  // Padding & margins
  static const double paddingXSmall = 4;
  static const double paddingSmall = 8;
  static const double paddingBase = 12;
  static const double paddingLarge = 16;
  static const double paddingXLarge = 24;

  // Border radius
  static const double radiusSmall = 4;
  static const double radiusBase = 8;
  static const double radiusLarge = 12;
  static const double radiusXLarge = 16;

  /// Get theme data for the app
  static ThemeData getThemeData({bool isDark = false}) {
    if (isDark) {
      return _getDarkThemeData();
    }
    return _getLightThemeData();
  }

  /// Get light theme
  static ThemeData _getLightThemeData() {
    // Modern light theme with vibrant colors and good contrast
    const lightBgColor = Color(0xFFF8F9FA); // Clean light gray background
    const lightSurfaceColor = Color(0xFFFFFFFF); // Pure white for cards
    const lightSecondaryColor = Color(0xFF4A90E2); // Professional blue
    // const lightAccentRed = Color(0xFFE94560); // Vibrant pink-red
    // const lightAccentGreen = Color(0xFF2ECC71); // Fresh green

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: lightBgColor,
      colorScheme: ColorScheme.light(
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: lightSecondaryColor,
        onSecondary: Colors.white,
        surface: lightSurfaceColor,
        error: Colors.red,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 1,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusBase),
          ),
          elevation: 2,
          textStyle: const TextStyle(
            fontSize: fontSizeBase,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            fontSize: fontSizeBase,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        color: lightSurfaceColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusBase),
          side: const BorderSide(color: Color(0xFFE0E0E0), width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: paddingLarge,
          vertical: paddingBase,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusBase),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusBase),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusBase),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(
          color: Color(0xFF333333),
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: TextStyle(color: Color(0xFF555555)),
        labelLarge: TextStyle(
          color: Color(0xFF333333),
          fontWeight: FontWeight.w500,
        ),
        headlineSmall: TextStyle(
          color: Color(0xFF222222),
          fontWeight: FontWeight.bold,
        ),
        titleMedium: TextStyle(
          color: Color(0xFF222222),
          fontWeight: FontWeight.w600,
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightSurfaceColor,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey[600],
        elevation: 1,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: Colors.white,
        selectedIconTheme: const IconThemeData(color: Color(0xFFC6302C)),
        unselectedIconTheme: IconThemeData(color: Colors.grey.shade600),
        selectedLabelTextStyle: const TextStyle(
          color: Color(0xFFC6302C),
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(color: Colors.grey.shade600),
        indicatorColor: const Color(0xFFC6302C).withValues(alpha: 0.1),
      ),
    );
  }

  /// Get dark theme
  static ThemeData _getDarkThemeData() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFF0F0F0F),
      colorScheme: const ColorScheme.dark(
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: primaryColor,
        onSecondary: Colors.white,
        surface: Color(0xFF1C1C1C),
        onSurface: Colors.white,
        error: Color(0xFFCF6679),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1C1C1C),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusBase),
          ),
          textStyle: const TextStyle(
            fontSize: fontSizeBase,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: const TextStyle(
            fontSize: fontSizeBase,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: const Color(0xFF1C1C1C),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusBase),
          side: const BorderSide(color: Color(0xFF2E2E2E), width: 0.5),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0F0F0F),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: paddingLarge,
          vertical: paddingBase,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusBase),
          borderSide: const BorderSide(color: Color(0xFF2E2E2E)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusBase),
          borderSide: const BorderSide(color: Color(0xFF2E2E2E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusBase),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: Color(0xFFE8E8E8)),
        bodyMedium: TextStyle(color: Color(0xFFD0D0D0)),
        labelLarge: TextStyle(color: Color(0xFFE8E8E8)),
        headlineSmall: TextStyle(color: Colors.white),
        titleMedium: TextStyle(color: Colors.white),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: const Color(0xFF1C1C1C),
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey[500],
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: const Color(0xFF1C1C1C),
        selectedIconTheme: const IconThemeData(color: Color(0xFFC6302C)),
        unselectedIconTheme: IconThemeData(color: Colors.grey.shade500),
        selectedLabelTextStyle: const TextStyle(
          color: Color(0xFFC6302C),
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(color: Colors.grey.shade500),
        indicatorColor: const Color(0xFFC6302C).withValues(alpha: 0.15),
      ),
    );
  }

  /// Get window size configuration
  static (double width, double height) getWindowSize() {
    if (PlatformHelper.isWindows) {
      return (1400, 900);
    } else if (PlatformHelper.isMacOS) {
      return (1300, 850);
    } else if (PlatformHelper.isLinux) {
      return (1300, 850);
    }
    return (1400, 900);
  }

  /// Get animation duration
  static Duration get animationDuration => const Duration(milliseconds: 300);
  static Duration get shortAnimationDuration =>
      const Duration(milliseconds: 150);
  static Duration get longAnimationDuration =>
      const Duration(milliseconds: 500);

  /// Check if should use compact layout
  static bool shouldUseCompactLayout(double screenWidth) {
    return screenWidth < mobileMaxWidth;
  }

  /// Get app bar height based on platform
  static double getAppBarHeight() {
    if (PlatformHelper.isMobile) return 56;
    return 64;
  }

  /// Get navigation bar height
  static double getNavigationBarHeight() {
    if (PlatformHelper.isMobile) return 56;
    return 64;
  }
}

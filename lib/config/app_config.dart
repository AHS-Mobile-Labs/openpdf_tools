import 'package:flutter/material.dart';
import 'package:openpdf_tools/utils/platform_helper.dart';

/// Global app configuration
class AppConfig {
  // App constants
  static const String appTitle = 'OpenPDF Tools';
  static const String appVersion = '1.0.0';
  
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
  static ThemeData getThemeData() {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: Colors.white,
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        onPrimary: Colors.white,
        secondary: Colors.white,
        onSecondary: Colors.black,
        surface: Colors.white,
        error: Colors.red,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        centerTitle: false,
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
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusBase),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: paddingLarge,
          vertical: paddingBase,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusBase),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusBase),
          borderSide: const BorderSide(color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusBase),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
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
  static Duration get shortAnimationDuration => const Duration(milliseconds: 150);
  static Duration get longAnimationDuration => const Duration(milliseconds: 500);
  
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

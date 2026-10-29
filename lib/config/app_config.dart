import 'package:flutter/material.dart';
import 'package:openpdf_tools/utils/platform_helper.dart';

class AppConfig {
  static const String appTitle = 'OpenPDF Tools';
  static const String appVersion = '1.0.0';
  static const String githubUrl =
      'https://github.com/AHS-Mobile-Labs/openpdf_tools';
  static const Color primaryColor = Color(0xFFE1251B);
  static const Color darkRedColor = Color(0xFFB71C1C);
  static const Color accentColor = Color(0xFF1473E6);
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1200;
  static const double fontSizeSmall = 12;
  static const double fontSizeBase = 14;
  static const double fontSizeLarge = 16;
  static const double fontSizeXLarge = 20;
  static const double fontSizeXXLarge = 24;
  static const double paddingXSmall = 4;
  static const double paddingSmall = 8;
  static const double paddingBase = 12;
  static const double paddingLarge = 16;
  static const double paddingXLarge = 24;
  static const double radiusSmall = 4;
  static const double radiusBase = 8;
  static const double radiusLarge = 12;
  static const double radiusXLarge = 16;


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

  static Duration get animationDuration => const Duration(milliseconds: 300);
  static Duration get shortAnimationDuration =>
      const Duration(milliseconds: 150);
  static Duration get longAnimationDuration =>
      const Duration(milliseconds: 500);
  static bool shouldUseCompactLayout(double screenWidth) {
    return screenWidth < mobileMaxWidth;
  }

  static double getAppBarHeight() {
    if (PlatformHelper.isMobile) return 56;
    return 64;
  }

  static double getNavigationBarHeight() {
    if (PlatformHelper.isMobile) return 56;
    return 64;
  }
}

import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Utility class for platform detection and platform-specific operations
class PlatformHelper {
  /// Check if running on Android
  static bool get isAndroid => Platform.isAndroid;

  /// Check if running on iOS
  static bool get isIOS => Platform.isIOS;

  /// Check if running on mobile (Android or iOS)
  static bool get isMobile => !kIsWeb && (isAndroid || isIOS);

  /// Check if running on desktop (Windows, macOS, or Linux)
  static bool get isDesktop => !kIsWeb && (isWindows || isMacOS || isLinux);

  /// Check if running on Windows
  static bool get isWindows => Platform.isWindows;

  /// Check if running on macOS
  static bool get isMacOS => Platform.isMacOS;

  /// Check if running on Linux
  static bool get isLinux => Platform.isLinux;

  /// Check if running on web
  static bool get isWeb => kIsWeb;

  /// Get platform name for display
  static String get platformName {
    if (isWeb) return 'Web';
    if (isAndroid) return 'Android';
    if (isIOS) return 'iOS';
    if (isWindows) return 'Windows';
    if (isMacOS) return 'macOS';
    if (isLinux) return 'Linux';
    return 'Unknown';
  }

  /// Check if platform requires file permission handling
  static bool get requiresFilePermissions => isMobile;

  /// Get recommended window size for desktop
  static (int, int) get recommendedWindowSize {
    if (isWindows) return (1200, 800);
    if (isMacOS) return (1100, 750);
    if (isLinux) return (1100, 750);
    return (1200, 800);
  }

  /// Check if platform uses system file dialogs
  static bool get usesSystemFileDialog => isDesktop || isWeb;

  /// Check if platform can use native share
  static bool get supportsNativeShare => true;

  /// Get preferred navigation style
  static NavigationStyle get preferredNavigationStyle {
    return isMobile ? NavigationStyle.bottomBar : NavigationStyle.sideBar;
  }
}

enum NavigationStyle { bottomBar, sideBar, tabs }

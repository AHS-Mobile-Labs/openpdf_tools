import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' as io show Platform;
class PlatformHelper {
  static bool get isAndroid => !kIsWeb && io.Platform.isAndroid;
  static bool get isIOS => !kIsWeb && io.Platform.isIOS;
  static bool get isMobile => !kIsWeb && (isAndroid || isIOS);
  static bool get isDesktop => !kIsWeb && (isWindows || isMacOS || isLinux);
  static bool get isWindows => !kIsWeb && io.Platform.isWindows;
  static bool get isMacOS => !kIsWeb && io.Platform.isMacOS;
  static bool get isLinux => !kIsWeb && io.Platform.isLinux;
  static bool get isWeb => kIsWeb;
  static String get platformName {
    if (isWeb) return 'Web';
    if (isAndroid) return 'Android';
    if (isIOS) return 'iOS';
    if (isWindows) return 'Windows';
    if (isMacOS) return 'macOS';
    if (isLinux) return 'Linux';
    return 'Unknown';
  }
  static bool get requiresFilePermissions => isMobile;
  static (int, int) get recommendedWindowSize {
    if (isWindows) return (1200, 800);
    if (isMacOS) return (1100, 750);
    if (isLinux) return (1100, 750);
    return (1200, 800);
  }
  static bool get usesSystemFileDialog => isDesktop || isWeb;
  static bool get supportsNativeShare => true;
  static NavigationStyle get preferredNavigationStyle {
    return isMobile ? NavigationStyle.bottomBar : NavigationStyle.sideBar;
  }
}
enum NavigationStyle { bottomBar, sideBar, tabs }
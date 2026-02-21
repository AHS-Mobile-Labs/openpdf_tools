import 'package:flutter/material.dart';

/// Provides responsive design utilities for different screen sizes
class ResponsiveHelper {
  final BuildContext context;

  ResponsiveHelper(this.context);

  /// Get the screen width
  double get screenWidth => MediaQuery.of(context).size.width;

  /// Get the screen height
  double get screenHeight => MediaQuery.of(context).size.height;

  /// Get the device aspect ratio
  double get aspectRatio => MediaQuery.of(context).size.aspectRatio;

  /// Get the device orientation
  Orientation get orientation => MediaQuery.of(context).orientation;

  /// Check if device is in portrait mode
  bool get isPortrait => orientation == Orientation.portrait;

  /// Check if device is in landscape mode
  bool get isLandscape => orientation == Orientation.landscape;

  /// Get the device padding (for notches, safe areas)
  EdgeInsets get padding => MediaQuery.of(context).padding;

  /// Get the device view insets (keyboard height)
  EdgeInsets get viewInsets => MediaQuery.of(context).viewInsets;

  /// Check if device is mobile (width < 600)
  bool get isMobile => screenWidth < 600;

  /// Check if device is tablet (width >= 600 and < 1200)
  bool get isTablet => screenWidth >= 600 && screenWidth < 1200;

  /// Check if device is desktop (width >= 1200)
  bool get isDesktop => screenWidth >= 1200;

  /// Get device size category
  DeviceSize get deviceSize {
    if (screenWidth < 400) return DeviceSize.small;
    if (screenWidth < 600) return DeviceSize.mobile;
    if (screenWidth < 900) return DeviceSize.tablet;
    if (screenWidth < 1200) return DeviceSize.largeTablet;
    return DeviceSize.desktop;
  }

  /// Get responsive font size based on screen width
  double responsiveFontSize(double baseSize) {
    final scale = screenWidth / 400;
    return baseSize * scale.clamp(0.8, 1.3);
  }

  /// Get responsive padding based on device size
  EdgeInsets responsivePadding({
    double mobile = 12,
    double tablet = 20,
    double desktop = 24,
  }) {
    final padding = isMobile ? mobile : (isTablet ? tablet : desktop);
    return EdgeInsets.all(padding);
  }

  /// Get responsive grid column count
  int get gridColumns {
    if (isMobile) return 2;
    if (isTablet) return 3;
    return 4;
  }

  /// Get responsive list/grid item width
  double getItemWidth(double containerWidth, {int cols = 2}) {
    return (containerWidth - (cols - 1) * 12) / cols;
  }

  /// Get keyboard height
  double get keyboardHeight => viewInsets.bottom;

  /// Check if keyboard is visible
  bool get isKeyboardVisible => keyboardHeight > 0;

  /// Get safe area padding
  EdgeInsets get safeAreaPadding => padding;

  /// Get safe area of specific side
  double getSafeArea(BoxSide side) {
    switch (side) {
      case BoxSide.top:
        return padding.top;
      case BoxSide.bottom:
        return padding.bottom;
      case BoxSide.left:
        return padding.left;
      case BoxSide.right:
        return padding.right;
    }
  }

  /// Get scaled size based on device
  double scale(double size, {double mobileMultiplier = 1, double desktopMultiplier = 1.2}) {
    if (isMobile) return size * mobileMultiplier;
    return size * desktopMultiplier;
  }
}

enum DeviceSize { small, mobile, tablet, largeTablet, desktop }

enum BoxSide { top, bottom, left, right }

/// Extension on BuildContext for easy access to ResponsiveHelper
extension ResponsiveContext on BuildContext {
  ResponsiveHelper get responsive => ResponsiveHelper(this);

  bool get isMobile => ResponsiveHelper(this).isMobile;
  bool get isTablet => ResponsiveHelper(this).isTablet;
  bool get isDesktop => ResponsiveHelper(this).isDesktop;
  double get screenWidth => ResponsiveHelper(this).screenWidth;
  double get screenHeight => ResponsiveHelper(this).screenHeight;
}

import 'package:flutter/material.dart';
class ResponsiveHelper {
  final BuildContext context;
  ResponsiveHelper(this.context);
  double get screenWidth => MediaQuery.of(context).size.width;
  double get screenHeight => MediaQuery.of(context).size.height;
  double get aspectRatio => MediaQuery.of(context).size.aspectRatio;
  Orientation get orientation => MediaQuery.of(context).orientation;
  bool get isPortrait => orientation == Orientation.portrait;
  bool get isLandscape => orientation == Orientation.landscape;
  EdgeInsets get padding => MediaQuery.of(context).padding;
  EdgeInsets get viewInsets => MediaQuery.of(context).viewInsets;
  bool get isMobile => screenWidth < 600;
  bool get isTablet => screenWidth >= 600 && screenWidth < 1200;
  bool get isDesktop => screenWidth >= 1200;
  DeviceSize get deviceSize {
    if (screenWidth < 400) return DeviceSize.small;
    if (screenWidth < 600) return DeviceSize.mobile;
    if (screenWidth < 900) return DeviceSize.tablet;
    if (screenWidth < 1200) return DeviceSize.largeTablet;
    return DeviceSize.desktop;
  }
  double responsiveFontSize(double baseSize) {
    final scale = screenWidth / 400;
    return baseSize * scale.clamp(0.8, 1.3);
  }
  EdgeInsets responsivePadding({
    double mobile = 12,
    double tablet = 20,
    double desktop = 24,
  }) {
    final padding = isMobile ? mobile : (isTablet ? tablet : desktop);
    return EdgeInsets.all(padding);
  }
  int get gridColumns {
    if (isMobile) return 2;
    if (isTablet) return 3;
    return 4;
  }
  double getItemWidth(double containerWidth, {int cols = 2}) {
    return (containerWidth - (cols - 1) * 12) / cols;
  }
  double get keyboardHeight => viewInsets.bottom;
  bool get isKeyboardVisible => keyboardHeight > 0;
  EdgeInsets get safeAreaPadding => padding;
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
  double scale(double size, {double mobileMultiplier = 1, double desktopMultiplier = 1.2}) {
    if (isMobile) return size * mobileMultiplier;
    return size * desktopMultiplier;
  }
}
enum DeviceSize { small, mobile, tablet, largeTablet, desktop }
enum BoxSide { top, bottom, left, right }
extension ResponsiveContext on BuildContext {
  ResponsiveHelper get responsive => ResponsiveHelper(this);
  bool get isMobile => ResponsiveHelper(this).isMobile;
  bool get isTablet => ResponsiveHelper(this).isTablet;
  bool get isDesktop => ResponsiveHelper(this).isDesktop;
  double get screenWidth => ResponsiveHelper(this).screenWidth;
  double get screenHeight => ResponsiveHelper(this).screenHeight;
}
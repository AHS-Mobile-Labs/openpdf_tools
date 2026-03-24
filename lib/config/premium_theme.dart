import 'package:flutter/material.dart';

class PremiumColors {
  static const Color lightBg = Color(0xFFFAFAFA);
  static const Color lightSurfacePrimary = Color(0xFFFFFFFF);
  static const Color lightSurfaceSecondary = Color(0xFFF5F5F5);
  static const Color lightText = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF666666);
  static const Color lightTextTertiary = Color(0xFF999999);
  static const Color lightDivider = Color(0xFFE8E8E8);
  static const Color darkBg = Color(0xFF0F0F0F);
  static const Color darkSurfacePrimary = Color(0xFF1A1A1A);
  static const Color darkSurfaceSecondary = Color(0xFF252525);
  static const Color darkText = Color(0xFFFAFAFA);
  static const Color darkTextSecondary = Color(0xFFB3B3B3);
  static const Color darkTextTertiary = Color(0xFF808080);
  static const Color darkDivider = Color(0xFF333333);
  static const Color luxuryRed = Color(0xFFD4465F);
  static const Color luxuryGold = Color(0xFFD4AF37);
  static const Color luxuryBlue = Color(0xFF4A7BA7);
  static const Color luxuryPurple = Color(0xFF6B5B95);
  static const Color luxuryGreen = Color(0xFF6B8E47);
  static const Color success = Color(0xFF52C41A);
  static const Color warning = Color(0xFFFAA61A);
  static const Color error = Color(0xFFFF4D4F);
  static const Color info = Color(0xFF1890FF);
}

class PremiumTypography {
  static const String fontFamily = 'Outfit';
  static const FontWeight light = FontWeight.w300;
  static const FontWeight regular = FontWeight.w400;
  static const FontWeight medium = FontWeight.w500;
  static const FontWeight semibold = FontWeight.w600;
  static const FontWeight bold = FontWeight.w700;
  static TextStyle displayLarge = const TextStyle(
    fontSize: 32,
    fontWeight: bold,
    letterSpacing: -0.5,
  );
  static TextStyle displayMedium = const TextStyle(
    fontSize: 28,
    fontWeight: bold,
    letterSpacing: -0.3,
  );
  static TextStyle displaySmall = const TextStyle(
    fontSize: 24,
    fontWeight: semibold,
    letterSpacing: -0.2,
  );
  static TextStyle headlineLarge = const TextStyle(
    fontSize: 20,
    fontWeight: semibold,
    letterSpacing: 0,
  );
  static TextStyle headlineMedium = const TextStyle(
    fontSize: 18,
    fontWeight: semibold,
    letterSpacing: 0,
  );
  static TextStyle headlineSmall = const TextStyle(
    fontSize: 16,
    fontWeight: semibold,
    letterSpacing: 0.15,
  );
  static TextStyle bodyLarge = const TextStyle(
    fontSize: 16,
    fontWeight: regular,
    letterSpacing: 0.15,
  );
  static TextStyle bodyMedium = const TextStyle(
    fontSize: 14,
    fontWeight: regular,
    letterSpacing: 0.25,
  );
  static TextStyle bodySmall = const TextStyle(
    fontSize: 12,
    fontWeight: regular,
    letterSpacing: 0.4,
  );
  static TextStyle labelLarge = const TextStyle(
    fontSize: 14,
    fontWeight: semibold,
    letterSpacing: 0.1,
  );
  static TextStyle labelMedium = const TextStyle(
    fontSize: 12,
    fontWeight: semibold,
    letterSpacing: 0.5,
  );
  static TextStyle labelSmall = const TextStyle(
    fontSize: 11,
    fontWeight: semibold,
    letterSpacing: 0.5,
  );
}

class PremiumSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;
  static const double radiusSm = 6;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusXl = 20;
  static const double radiusCircle = 100;
  static const double iconSmall = 16;
  static const double iconMedium = 24;
  static const double iconLarge = 32;
  static const double iconXLarge = 48;
  static const double buttonHeight = 48;
  static const double chipHeight = 32;
  static const double cardElevation = 1;
}

class PremiumShadows {
  static const BoxShadow shadowSm = BoxShadow(
    color: Color(0x00000000),
    blurRadius: 2,
    offset: Offset(0, 1),
  );
  static const BoxShadow shadowMd = BoxShadow(
    color: Color(0x0D000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  );
  static const BoxShadow shadowLg = BoxShadow(
    color: Color(0x14000000),
    blurRadius: 16,
    offset: Offset(0, 4),
  );
  static const BoxShadow shadowXl = BoxShadow(
    color: Color(0x1C000000),
    blurRadius: 24,
    offset: Offset(0, 8),
  );
  static List<BoxShadow> get shadowList => [shadowMd];
  static List<BoxShadow> get elevatedShadow => [shadowLg];
}

ThemeData createLightTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    primaryColor: PremiumColors.luxuryRed,
    scaffoldBackgroundColor: PremiumColors.lightBg,
    colorScheme: const ColorScheme.light(
      primary: PremiumColors.luxuryRed,
      onPrimary: Colors.white,
      secondary: PremiumColors.luxuryGold,
      onSecondary: PremiumColors.lightText,
      surface: PremiumColors.lightSurfacePrimary,
      onSurface: PremiumColors.lightText,
      error: PremiumColors.error,
      onError: Colors.white,
      outline: PremiumColors.lightDivider,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: PremiumColors.lightSurfacePrimary,
      foregroundColor: PremiumColors.lightText,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0.5,
      surfaceTintColor: PremiumColors.lightBg,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: PremiumColors.lightSurfacePrimary,
      selectedItemColor: PremiumColors.luxuryRed,
      unselectedItemColor: PremiumColors.lightTextTertiary,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: PremiumColors.luxuryRed,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(0, PremiumSpacing.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PremiumSpacing.radiusMd),
        ),
        textStyle: PremiumTypography.labelLarge.copyWith(color: Colors.white),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: PremiumColors.luxuryRed,
        minimumSize: const Size(0, 48),
        textStyle: PremiumTypography.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: PremiumColors.luxuryRed,
        minimumSize: const Size(0, PremiumSpacing.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PremiumSpacing.radiusMd),
        ),
        side: const BorderSide(color: PremiumColors.lightDivider, width: 1.5),
        textStyle: PremiumTypography.labelLarge,
      ),
    ),
    cardTheme: CardThemeData(
      color: PremiumColors.lightSurfacePrimary,
      elevation: PremiumSpacing.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PremiumSpacing.radiusLg),
      ),
      shadowColor: Colors.black.withValues(alpha: 0.05),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: PremiumColors.lightSurfaceSecondary,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: PremiumSpacing.lg,
        vertical: PremiumSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(PremiumSpacing.radiusMd),
        borderSide: const BorderSide(color: PremiumColors.lightDivider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(PremiumSpacing.radiusMd),
        borderSide: const BorderSide(color: PremiumColors.lightDivider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(PremiumSpacing.radiusMd),
        borderSide: const BorderSide(color: PremiumColors.luxuryRed, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(PremiumSpacing.radiusMd),
        borderSide: const BorderSide(color: PremiumColors.error),
      ),
      hintStyle: PremiumTypography.bodyMedium.copyWith(
        color: PremiumColors.lightTextTertiary,
      ),
      labelStyle: PremiumTypography.bodyMedium.copyWith(
        color: PremiumColors.lightText,
      ),
      floatingLabelStyle: PremiumTypography.labelMedium.copyWith(
        color: PremiumColors.luxuryRed,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: PremiumColors.lightDivider,
      thickness: 1,
      space: 0,
    ),
    textTheme: TextTheme(
      displayLarge: PremiumTypography.displayLarge.copyWith(
        color: PremiumColors.lightText,
      ),
      displayMedium: PremiumTypography.displayMedium.copyWith(
        color: PremiumColors.lightText,
      ),
      displaySmall: PremiumTypography.displaySmall.copyWith(
        color: PremiumColors.lightText,
      ),
      headlineLarge: PremiumTypography.headlineLarge.copyWith(
        color: PremiumColors.lightText,
      ),
      headlineMedium: PremiumTypography.headlineMedium.copyWith(
        color: PremiumColors.lightText,
      ),
      headlineSmall: PremiumTypography.headlineSmall.copyWith(
        color: PremiumColors.lightText,
      ),
      bodyLarge: PremiumTypography.bodyLarge.copyWith(
        color: PremiumColors.lightText,
      ),
      bodyMedium: PremiumTypography.bodyMedium.copyWith(
        color: PremiumColors.lightTextSecondary,
      ),
      bodySmall: PremiumTypography.bodySmall.copyWith(
        color: PremiumColors.lightTextTertiary,
      ),
      labelLarge: PremiumTypography.labelLarge.copyWith(
        color: PremiumColors.lightText,
      ),
      labelMedium: PremiumTypography.labelMedium.copyWith(
        color: PremiumColors.lightTextSecondary,
      ),
      labelSmall: PremiumTypography.labelSmall.copyWith(
        color: PremiumColors.lightTextTertiary,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: PremiumColors.lightSurfacePrimary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PremiumSpacing.radiusLg),
      ),
      surfaceTintColor: PremiumColors.lightBg,
    ),
  );
}

ThemeData createDarkTheme() {
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    primaryColor: PremiumColors.luxuryRed,
    scaffoldBackgroundColor: PremiumColors.darkBg,
    colorScheme: const ColorScheme.dark(
      primary: PremiumColors.luxuryRed,
      onPrimary: Colors.white,
      secondary: PremiumColors.luxuryGold,
      onSecondary: PremiumColors.darkText,
      surface: PremiumColors.darkSurfaceSecondary,
      onSurface: PremiumColors.darkText,
      error: PremiumColors.error,
      onError: Colors.white,
      outline: PremiumColors.darkDivider,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: PremiumColors.darkSurfacePrimary,
      foregroundColor: PremiumColors.darkText,
      elevation: 0,
      centerTitle: false,
      scrolledUnderElevation: 0.5,
      surfaceTintColor: PremiumColors.darkBg,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: PremiumColors.darkSurfacePrimary,
      selectedItemColor: PremiumColors.luxuryRed,
      unselectedItemColor: PremiumColors.darkTextTertiary,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: PremiumColors.luxuryRed,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size(0, PremiumSpacing.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PremiumSpacing.radiusMd),
        ),
        textStyle: PremiumTypography.labelLarge.copyWith(color: Colors.white),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: PremiumColors.luxuryRed,
        minimumSize: const Size(0, 48),
        textStyle: PremiumTypography.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: PremiumColors.luxuryRed,
        minimumSize: const Size(0, PremiumSpacing.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PremiumSpacing.radiusMd),
        ),
        side: const BorderSide(color: PremiumColors.darkDivider, width: 1.5),
        textStyle: PremiumTypography.labelLarge,
      ),
    ),
    cardTheme: CardThemeData(
      color: PremiumColors.darkSurfaceSecondary,
      elevation: PremiumSpacing.cardElevation,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PremiumSpacing.radiusLg),
      ),
      shadowColor: Colors.black.withValues(alpha: 0.3),
      margin: EdgeInsets.zero,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: PremiumColors.darkSurfaceSecondary,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: PremiumSpacing.lg,
        vertical: PremiumSpacing.md,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(PremiumSpacing.radiusMd),
        borderSide: const BorderSide(color: PremiumColors.darkDivider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(PremiumSpacing.radiusMd),
        borderSide: const BorderSide(color: PremiumColors.darkDivider),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(PremiumSpacing.radiusMd),
        borderSide: const BorderSide(color: PremiumColors.luxuryRed, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(PremiumSpacing.radiusMd),
        borderSide: const BorderSide(color: PremiumColors.error),
      ),
      hintStyle: PremiumTypography.bodyMedium.copyWith(
        color: PremiumColors.darkTextTertiary,
      ),
      labelStyle: PremiumTypography.bodyMedium.copyWith(
        color: PremiumColors.darkText,
      ),
      floatingLabelStyle: PremiumTypography.labelMedium.copyWith(
        color: PremiumColors.luxuryRed,
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: PremiumColors.darkDivider,
      thickness: 1,
      space: 0,
    ),
    textTheme: TextTheme(
      displayLarge: PremiumTypography.displayLarge.copyWith(
        color: PremiumColors.darkText,
      ),
      displayMedium: PremiumTypography.displayMedium.copyWith(
        color: PremiumColors.darkText,
      ),
      displaySmall: PremiumTypography.displaySmall.copyWith(
        color: PremiumColors.darkText,
      ),
      headlineLarge: PremiumTypography.headlineLarge.copyWith(
        color: PremiumColors.darkText,
      ),
      headlineMedium: PremiumTypography.headlineMedium.copyWith(
        color: PremiumColors.darkText,
      ),
      headlineSmall: PremiumTypography.headlineSmall.copyWith(
        color: PremiumColors.darkText,
      ),
      bodyLarge: PremiumTypography.bodyLarge.copyWith(
        color: PremiumColors.darkText,
      ),
      bodyMedium: PremiumTypography.bodyMedium.copyWith(
        color: PremiumColors.darkTextSecondary,
      ),
      bodySmall: PremiumTypography.bodySmall.copyWith(
        color: PremiumColors.darkTextTertiary,
      ),
      labelLarge: PremiumTypography.labelLarge.copyWith(
        color: PremiumColors.darkText,
      ),
      labelMedium: PremiumTypography.labelMedium.copyWith(
        color: PremiumColors.darkTextSecondary,
      ),
      labelSmall: PremiumTypography.labelSmall.copyWith(
        color: PremiumColors.darkTextTertiary,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: PremiumColors.darkSurfacePrimary,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(PremiumSpacing.radiusLg),
      ),
      surfaceTintColor: PremiumColors.darkBg,
    ),
  );
}

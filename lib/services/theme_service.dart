import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Theme mode enumeration
enum ThemeMode {
  light('light'),
  dark('dark'),
  system('system');

  final String value;
  const ThemeMode(this.value);

  static ThemeMode fromString(String value) {
    return ThemeMode.values.firstWhere(
      (mode) => mode.value == value,
      orElse: () => ThemeMode.system,
    );
  }
}

/// Service for managing application theme
class ThemeService extends ChangeNotifier {
  static const String _themeModeKey = 'app_theme_mode';

  late SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.system;
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get isDarkMode {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    // System mode: assume light (context needed for proper detection)
    return false;
  }

  bool get isInitialized => _isInitialized;

  /// Initialize the theme service and load saved preferences
  Future<void> initialize() async {
    try {
      debugPrint('[ThemeService] Initializing theme service');
      _prefs = await SharedPreferences.getInstance();
      final savedTheme = _prefs.getString(_themeModeKey);

      if (savedTheme != null) {
        _themeMode = ThemeMode.fromString(savedTheme);
      } else {
        _themeMode = ThemeMode.system;
      }

      _isInitialized = true;
      debugPrint(
        '[ThemeService] Theme service initialized with mode: $_themeMode',
      );
      notifyListeners();
    } catch (e) {
      debugPrint('[ThemeService] Error during initialization: $e');
      _isInitialized = true; // Mark as initialized to avoid infinite retries
      _themeMode = ThemeMode.system; // Default to system theme
      rethrow;
    }
  }

  /// Set theme mode and persist to SharedPreferences
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    await _prefs.setString(_themeModeKey, mode.value);
    notifyListeners();
  }

  /// Toggle between light and dark mode
  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.dark
        ? ThemeMode.light
        : ThemeMode.dark;
    await setThemeMode(newMode);
  }

  /// Get system brightness
  static Brightness getSystemBrightness(BuildContext context) {
    return MediaQuery.of(context).platformBrightness;
  }
}

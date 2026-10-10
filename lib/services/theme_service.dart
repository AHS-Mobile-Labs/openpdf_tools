import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'file_history_service.dart';

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

class ThemeService extends ChangeNotifier {
  static const String _themeModeKey = 'app_theme_mode';
  static const String _trueBlackKey = 'app_true_black';
  static const String _highContrastKey = 'app_high_contrast';
  static const String _textScaleKey = 'app_text_scale';
  static const String _reduceMotionKey = 'app_reduce_motion';
  static const String _hapticFeedbackKey = 'app_haptic_feedback';
  static const String _defaultPageLayoutKey = 'app_default_page_layout';
  static const String _defaultNightModeKey = 'app_default_night_mode';
  static const String _keepScreenAwakeKey = 'app_keep_screen_awake';
  static const String _recordRecentFilesKey = 'app_record_recent_files';

  late SharedPreferences _prefs;
  ThemeMode _themeMode = ThemeMode.system;
  bool _trueBlack = false;
  bool _highContrast = false;
  double _textScaleFactor = 1.0;
  bool _reduceMotion = false;
  bool _hapticFeedback = true;
  String _defaultPageLayout = 'single'; // 'single' (Fit page) or 'continuous'
  bool _defaultNightMode = false;
  bool _keepScreenAwake = false;
  bool _recordRecentFiles = true;
  bool _isInitialized = false;

  ThemeMode get themeMode => _themeMode;
  bool get trueBlack => _trueBlack;
  bool get highContrast => _highContrast;
  double get textScaleFactor => _textScaleFactor;
  bool get reduceMotion => _reduceMotion;
  bool get hapticFeedback => _hapticFeedback;
  String get defaultPageLayout => _defaultPageLayout;
  bool get defaultNightMode => _defaultNightMode;
  bool get keepScreenAwake => _keepScreenAwake;
  bool get recordRecentFiles => _recordRecentFiles;
  bool get isInitialized => _isInitialized;

  bool get isDarkMode {
    if (_themeMode == ThemeMode.dark) return true;
    if (_themeMode == ThemeMode.light) return false;
    return false;
  }

  Future<void> initialize() async {
    try {
      debugPrint('[ThemeService] Initializing settings and theme service');
      _prefs = await SharedPreferences.getInstance();

      final savedTheme = _prefs.getString(_themeModeKey);
      _themeMode = savedTheme != null ? ThemeMode.fromString(savedTheme) : ThemeMode.system;

      _trueBlack = _prefs.getBool(_trueBlackKey) ?? false;
      _highContrast = _prefs.getBool(_highContrastKey) ?? false;
      _textScaleFactor = _prefs.getDouble(_textScaleKey) ?? 1.0;
      _reduceMotion = _prefs.getBool(_reduceMotionKey) ?? false;
      _hapticFeedback = _prefs.getBool(_hapticFeedbackKey) ?? true;
      _defaultPageLayout = _prefs.getString(_defaultPageLayoutKey) ?? 'single';
      _defaultNightMode = _prefs.getBool(_defaultNightModeKey) ?? false;
      _keepScreenAwake = _prefs.getBool(_keepScreenAwakeKey) ?? false;
      _recordRecentFiles = _prefs.getBool(_recordRecentFilesKey) ?? true;

      _isInitialized = true;
      debugPrint('[ThemeService] Theme & settings initialized: mode=$_themeMode');
      notifyListeners();
    } catch (e) {
      debugPrint('[ThemeService] Error during initialization: $e');
      _isInitialized = true;
      _themeMode = ThemeMode.system;
      rethrow;
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    _themeMode = mode;
    await _prefs.setString(_themeModeKey, mode.value);
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    final newMode = _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(newMode);
  }

  Future<void> setTrueBlack(bool value) async {
    if (_trueBlack == value) return;
    _trueBlack = value;
    await _prefs.setBool(_trueBlackKey, value);
    notifyListeners();
  }

  Future<void> setHighContrast(bool value) async {
    if (_highContrast == value) return;
    _highContrast = value;
    await _prefs.setBool(_highContrastKey, value);
    notifyListeners();
  }

  Future<void> setTextScaleFactor(double value) async {
    if ((_textScaleFactor - value).abs() < 0.01) return;
    _textScaleFactor = value;
    await _prefs.setDouble(_textScaleKey, value);
    notifyListeners();
  }

  Future<void> setReduceMotion(bool value) async {
    if (_reduceMotion == value) return;
    _reduceMotion = value;
    await _prefs.setBool(_reduceMotionKey, value);
    notifyListeners();
  }

  Future<void> setHapticFeedback(bool value) async {
    if (_hapticFeedback == value) return;
    _hapticFeedback = value;
    await _prefs.setBool(_hapticFeedbackKey, value);
    notifyListeners();
  }

  Future<void> setDefaultPageLayout(String value) async {
    if (_defaultPageLayout == value) return;
    _defaultPageLayout = value;
    await _prefs.setString(_defaultPageLayoutKey, value);
    notifyListeners();
  }

  Future<void> setDefaultNightMode(bool value) async {
    if (_defaultNightMode == value) return;
    _defaultNightMode = value;
    await _prefs.setBool(_defaultNightModeKey, value);
    notifyListeners();
  }

  Future<void> setKeepScreenAwake(bool value) async {
    if (_keepScreenAwake == value) return;
    _keepScreenAwake = value;
    await _prefs.setBool(_keepScreenAwakeKey, value);
    notifyListeners();
  }

  Future<void> setRecordRecentFiles(bool value) async {
    if (_recordRecentFiles == value) return;
    _recordRecentFiles = value;
    await _prefs.setBool(_recordRecentFilesKey, value);
    notifyListeners();
  }

  Future<void> clearRecentHistory() async {
    await FileHistoryService.clearHistory();
    notifyListeners();
  }

  Future<int> clearAppCache() async {
    if (kIsWeb) return 0;
    try {
      final tempDir = await getTemporaryDirectory();
      int deletedCount = 0;
      if (await tempDir.exists()) {
        final entities = tempDir.listSync(recursive: true);
        for (final entity in entities) {
          try {
            if (entity is File) {
              await entity.delete();
              deletedCount++;
            }
          } catch (_) {}
        }
      }
      notifyListeners();
      return deletedCount;
    } catch (_) {
      return 0;
    }
  }

  Future<int> clearCache() => clearAppCache();

  static Brightness getSystemBrightness(BuildContext context) {
    return MediaQuery.of(context).platformBrightness;
  }
}

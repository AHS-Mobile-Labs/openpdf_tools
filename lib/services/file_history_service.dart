import 'dart:io';
import 'dart:developer' as developer;
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing file history and favorites using local storage.
///
/// This service provides methods to track recently accessed files and
/// manage user's favorite files using SharedPreferences.
class FileHistoryService {
  static const String _historyKey = 'file_history';
  static const String _favoritesKey = 'file_favorites';
  static const int _maxHistoryItems = 50;
  static const String _delimiter = '|';

  /// Add a file to history
  static Future<void> addToHistory(String filePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList(_historyKey) ?? [];

      // Remove if already exists (to move to top)
      history.removeWhere((item) => item.split(_delimiter).first == filePath);

      // Add to beginning with timestamp
      history.insert(
        0,
        '$filePath$_delimiter${DateTime.now().millisecondsSinceEpoch}',
      );

      // Keep only last 50 items
      if (history.length > _maxHistoryItems) {
        history.removeRange(_maxHistoryItems, history.length);
      }

      await prefs.setStringList(_historyKey, history);
    } catch (e) {
      developer.log('Error adding to history', error: e);
    }
  }

  /// Get all history items
  static Future<List<HistoryItem>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList(_historyKey) ?? [];

      return history
          .map((item) {
            final parts = item.split(_delimiter);
            if (parts.length >= 2) {
              return HistoryItem(
                filePath: parts[0],
                timestamp: int.tryParse(parts[1]) ?? 0,
              );
            }
            return null;
          })
          .whereType<HistoryItem>()
          .toList();
    } catch (e) {
      developer.log('Error getting history', error: e);
      return [];
    }
  }

  /// Toggle favorite status
  static Future<bool> toggleFavorite(String filePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList(_favoritesKey) ?? [];

      if (favorites.contains(filePath)) {
        favorites.remove(filePath);
      } else {
        favorites.add(filePath);
      }

      await prefs.setStringList(_favoritesKey, favorites);
      return favorites.contains(filePath);
    } catch (e) {
      developer.log('Error toggling favorite', error: e);
      return false;
    }
  }

  /// Check if file is favorite
  static Future<bool> isFavorite(String filePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList(_favoritesKey) ?? [];
      return favorites.contains(filePath);
    } catch (e) {
      developer.log('Error checking favorite', error: e);
      return false;
    }
  }

  /// Get all favorites
  static Future<List<String>> getFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_favoritesKey) ?? [];
    } catch (e) {
      developer.log('Error getting favorites', error: e);
      return [];
    }
  }

  /// Clear history
  static Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_historyKey);
    } catch (e) {
      developer.log('Error clearing history', error: e);
    }
  }

  /// Remove single history item
  static Future<void> removeFromHistory(String filePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList(_historyKey) ?? [];
      history.removeWhere((item) => item.split(_delimiter).first == filePath);
      await prefs.setStringList(_historyKey, history);
    } catch (e) {
      developer.log('Error removing from history', error: e);
    }
  }

  /// Remove favorite
  static Future<void> removeFavorite(String filePath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList(_favoritesKey) ?? [];
      favorites.remove(filePath);
      await prefs.setStringList(_favoritesKey, favorites);
    } catch (e) {
      developer.log('Error removing favorite', error: e);
    }
  }

  /// Update file path in history (for when file is renamed)
  static Future<void> updateHistoryPath(String oldPath, String newPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final history = prefs.getStringList(_historyKey) ?? [];
      
      for (int i = 0; i < history.length; i++) {
        final parts = history[i].split(_delimiter);
        if (parts.isNotEmpty && parts[0] == oldPath) {
          history[i] = '$newPath$_delimiter${parts.length > 1 ? parts[1] : DateTime.now().millisecondsSinceEpoch}';
        }
      }
      
      await prefs.setStringList(_historyKey, history);
    } catch (e) {
      developer.log('Error updating history path', error: e);
    }
  }

  /// Update file path in favorites (for when file is renamed)
  static Future<void> updateFavoritePath(String oldPath, String newPath) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favorites = prefs.getStringList(_favoritesKey) ?? [];
      
      final index = favorites.indexOf(oldPath);
      if (index != -1) {
        favorites[index] = newPath;
      }
      
      await prefs.setStringList(_favoritesKey, favorites);
    } catch (e) {
      developer.log('Error updating favorite path', error: e);
    }
  }
}

/// Data class representing a single history item with file path and timestamp.
class HistoryItem {
  final String filePath;
  final int timestamp;

  HistoryItem({
    required this.filePath,
    required this.timestamp,
  });

  String get fileName => filePath.split('/').last;

  DateTime get date => DateTime.fromMillisecondsSinceEpoch(timestamp);

  bool get fileExists => File(filePath).existsSync();
}

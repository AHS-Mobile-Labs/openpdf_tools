import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:openpdf_tools/utils/platform_helper.dart';

/// Scoped Storage compatibility layer for Android 11+ (API 30+)
/// Handles file access with proper path handling for different Android versions
class ScopedStorageHelper {
  /// Check if running on Android 11 or higher
  static bool get isAndroid11Plus {
    if (!PlatformHelper.isAndroid) return false;
    // Android 11 is API level 30
    // We'll assume Android 11+ is in use if on Android
    return true;
  }

  /// Get safe temporary file path for Android
  /// Uses app-specific cache directory which is always accessible
  static Future<Directory> getSafeTempDirectory() async {
    return getTemporaryDirectory();
  }

  /// Get safe downloads directory for Android
  /// For Android 11+, returns app-specific cache directory
  /// which doesn't require MANAGE_EXTERNAL_STORAGE permission
  static Future<Directory?> getSafeDownloadsDirectory() async {
    if (PlatformHelper.isAndroid) {
      try {
        // Use app-specific cache directory (scoped storage compatible)
        final cacheDir = await getApplicationCacheDirectory();
        // Create Downloads subdirectory
        final downloadsDir = Directory('${cacheDir.path}/Downloads');
        if (!downloadsDir.existsSync()) {
          await downloadsDir.create(recursive: true);
        }
        return downloadsDir;
      } catch (e) {
        // Fallback to app documents directory
      }
    }
    return getApplicationDocumentsDirectory();
  }

  /// Get safe cache directory for temporary PDF processing
  /// Uses app-specific cache which requires no special permissions
  static Future<Directory> getSafeCacheDirectory() async {
    final cacheDir = await getApplicationCacheDirectory();
    final pdfCacheDir = Directory('${cacheDir.path}/pdf_temp');
    if (!pdfCacheDir.existsSync()) {
      await pdfCacheDir.create(recursive: true);
    }
    return pdfCacheDir;
  }

  /// Get safe support directory for app-specific files
  static Future<Directory> getSafeSupportDirectory() async {
    final appSupport = await getApplicationSupportDirectory();
    return appSupport;
  }

  /// Save file to safe location with proper Android 11+ handling
  /// Returns the saved file path
  static Future<String?> savePdfToSafeLocation({
    required File sourceFile,
    required String fileName,
  }) async {
    try {
      if (!PlatformHelper.isAndroid) {
        // Non-Android platforms can use default save
        return sourceFile.path;
      }

      // For Android, save to app-specific directory
      final downloadsDir = await getSafeDownloadsDirectory();
      if (downloadsDir == null) return null;

      final targetPath = '${downloadsDir.path}/$fileName';

      // Copy file to safe location
      await sourceFile.copy(targetPath);
      return targetPath;
    } catch (e) {
      return null;
    }
  }

  /// Verify file is accessible (for scoped storage check)
  static Future<bool> isFileAccessible(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Get content URI for Android file access
  /// For Android 11+, some APIs require content:// URIs instead of file paths
  static String getContentUri(String filePath) {
    // This is a placeholder - actual implementation would require platform channel
    // to get proper content URI from Android
    return 'file://$filePath';
  }

  /// Clean up temporary files in scoped storage
  static Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getSafeCacheDirectory();
      if (tempDir.existsSync()) {
        // Delete files older than 24 hours
        final now = DateTime.now();
        final files = tempDir.listSync();
        for (final entity in files) {
          if (entity is File) {
            final stat = entity.statSync();
            final age = now.difference(stat.modified);
            if (age.inHours > 24) {
              await entity.delete();
            }
          }
        }
      }
    } catch (e) {
      // Silently fail
    }
  }
}

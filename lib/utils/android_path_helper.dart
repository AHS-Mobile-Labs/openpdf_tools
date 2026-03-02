import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:openpdf_tools/utils/platform_helper.dart';

/// Android-specific file path handling utilities
/// Ensures proper path handling across different Android versions
class AndroidPathHelper {
  /// Normalize file path for Android
  /// Converts backslashes to forward slashes and handles edge cases
  static String normalizePath(String path) {
    if (path.isEmpty) return '';

    // Convert backslashes to forward slashes
    String normalized = path.replaceAll('\\', '/');

    // Remove multiple consecutive slashes
    normalized = normalized.replaceAll(RegExp(r'/+'), '/');

    // Remove trailing slashes (except for root)
    if (normalized.length > 1 && normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }

    return normalized;
  }

  /// Sanitize filename for Android file system
  /// Removes invalid characters that Android file systems don't support
  static String sanitizeFilename(String filename) {
    if (filename.isEmpty) return 'file';

    // Remove invalid characters: / : * ? " < > |
    String sanitized = filename
        .replaceAll(RegExp(r'[/\\:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');

    // Limit filename length to 255 characters
    if (sanitized.length > 255) {
      final ext = p.extension(sanitized);
      final nameWithoutExt = sanitized.substring(0, 255 - ext.length);
      sanitized = '$nameWithoutExt$ext';
    }

    // Ensure filename is not empty
    return sanitized.isEmpty ? 'file' : sanitized;
  }

  /// Get file extension safely
  static String getFileExtension(String path) {
    try {
      final ext = p.extension(path);
      return ext.isNotEmpty ? ext : '';
    } catch (e) {
      return '';
    }
  }

  /// Get filename from path
  static String getFilenamFromPath(String path) {
    try {
      return p.basename(path);
    } catch (e) {
      return path.split('/').last;
    }
  }

  /// Join path segments safely
  static String joinPathSegments(List<String> segments) {
    if (segments.isEmpty) return '';

    try {
      return p.joinAll(segments);
    } catch (e) {
      // Fallback to manual joining
      return segments.join('/');
    }
  }

  /// Check if path is accessible for Android
  static Future<bool> isPathValidAndAccessible(String path) async {
    try {
      if (path.isEmpty) return false;

      final file = File(path);
      final exists = await file.exists();

      if (!exists) return false;

      // Try to read file metadata
      final stat = await file.stat();
      return stat.type != FileSystemEntityType.notFound;
    } catch (e) {
      return false;
    }
  }

  /// Get file size in human-readable format
  static String formatFileSize(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    double size = bytes.toDouble();
    int suffixIndex = 0;

    while (size > 1024 && suffixIndex < suffixes.length - 1) {
      size /= 1024;
      suffixIndex++;
    }

    return '${size.toStringAsFixed(2)} ${suffixes[suffixIndex]}';
  }

  /// Get file size
  static Future<int> getFileSize(String path) async {
    try {
      final file = File(path);
      final stat = await file.stat();
      return stat.size;
    } catch (e) {
      return 0;
    }
  }

  /// Create temporary file with proper Android handling
  static Future<File?> createTempFile({
    required String directory,
    required String prefix,
    required String suffix,
  }) async {
    try {
      final dir = Directory(directory);
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }

      // Generate unique filename
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = '$prefix$timestamp$suffix';
      final sanitized = sanitizeFilename(filename);

      final filePath = p.join(directory, sanitized);
      final file = File(filePath);

      if (!file.existsSync()) {
        await file.create();
      }

      return file;
    } catch (e) {
      return null;
    }
  }

  /// Create directory if it doesn't exist
  static Future<Directory?> createDirectoryIfNotExists(String path) async {
    try {
      final dir = Directory(path);
      if (!dir.existsSync()) {
        await dir.create(recursive: true);
      }
      return dir;
    } catch (e) {
      return null;
    }
  }

  /// List files in directory with proper error handling
  static Future<List<FileSystemEntity>> listDirectoryContents(
    String path, {
    bool recursive = false,
  }) async {
    try {
      final dir = Directory(path);
      if (!dir.existsSync()) return [];

      return dir.listSync(recursive: recursive);
    } catch (e) {
      return [];
    }
  }

  /// Safe file copy with notification
  static Future<bool> safeCopyFile({
    required String sourcePath,
    required String destinationPath,
  }) async {
    try {
      final source = File(sourcePath);
      if (!await source.exists()) return false;

      // Check destination directory exists
      final destDir = File(destinationPath).parent;
      if (!destDir.existsSync()) {
        await destDir.create(recursive: true);
      }

      await source.copy(destinationPath);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Safe file deletion
  static Future<bool> safeDeleteFile(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return true;

      await file.delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Safe file move/rename
  static Future<bool> safeRenameFile({
    required String oldPath,
    required String newPath,
  }) async {
    try {
      final file = File(oldPath);
      if (!await file.exists()) return false;

      await file.rename(newPath);
      return true;
    } catch (e) {
      // If rename fails, try copy and delete
      try {
        final file = File(oldPath);
        if (await safeCopyFile(sourcePath: oldPath, destinationPath: newPath)) {
          await file.delete();
          return true;
        }
      } catch (_) {
        return false;
      }
      return false;
    }
  }

  /// Get file modification time
  static Future<DateTime?> getFileModificationTime(String path) async {
    try {
      final file = File(path);
      if (!await file.exists()) return null;

      final stat = await file.stat();
      return stat.modified;
    } catch (e) {
      return null;
    }
  }

  /// Check if files is in app-specific directory (safe on Android 11+)
  static bool isInAppSpecificDirectory(String path) {
    if (!PlatformHelper.isAndroid) return true;

    // Check common app-specific directories
    final appSpecificPatterns = [
      '/data/data/', // App private directory
      '/cache/', // Cache directory
      '/files/', // Files directory
    ];

    return appSpecificPatterns.any((pattern) => path.contains(pattern));
  }
}

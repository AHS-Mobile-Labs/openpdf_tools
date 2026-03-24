import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:openpdf_tools/utils/platform_helper.dart';
class AndroidPathHelper {
  static String normalizePath(String path) {
    if (path.isEmpty) return '';
    String normalized = path.replaceAll('\\', '/');
    normalized = normalized.replaceAll(RegExp(r'/+'), '/');
    if (normalized.length > 1 && normalized.endsWith('/')) {
      normalized = normalized.substring(0, normalized.length - 1);
    }
    return normalized;
  }
  static String sanitizeFilename(String filename) {
    if (filename.isEmpty) return 'file';
    String sanitized = filename
        .replaceAll(RegExp(r'[/\\:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), '_');
    if (sanitized.length > 255) {
      final ext = p.extension(sanitized);
      final nameWithoutExt = sanitized.substring(0, 255 - ext.length);
      sanitized = '$nameWithoutExt$ext';
    }
    return sanitized.isEmpty ? 'file' : sanitized;
  }
  static String getFileExtension(String path) {
    try {
      final ext = p.extension(path);
      return ext.isNotEmpty ? ext : '';
    } catch (e) {
      return '';
    }
  }
  static String getFilenamFromPath(String path) {
    try {
      return p.basename(path);
    } catch (e) {
      return path.split('/').last;
    }
  }
  static String joinPathSegments(List<String> segments) {
    if (segments.isEmpty) return '';
    try {
      return p.joinAll(segments);
    } catch (e) {
      return segments.join('/');
    }
  }
  static Future<bool> isPathValidAndAccessible(String path) async {
    try {
      if (path.isEmpty) return false;
      final file = File(path);
      final exists = await file.exists();
      if (!exists) return false;
      final stat = await file.stat();
      return stat.type != FileSystemEntityType.notFound;
    } catch (e) {
      return false;
    }
  }
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
  static Future<int> getFileSize(String path) async {
    try {
      final file = File(path);
      final stat = await file.stat();
      return stat.size;
    } catch (e) {
      return 0;
    }
  }
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
  static Future<bool> safeCopyFile({
    required String sourcePath,
    required String destinationPath,
  }) async {
    try {
      final source = File(sourcePath);
      if (!await source.exists()) return false;
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
  static bool isInAppSpecificDirectory(String path) {
    if (!PlatformHelper.isAndroid) return true;
    final appSpecificPatterns = [
      '/data/data/',       '/data/data/',
      '/cache/',       '/cache/',
      '/files/',       '/files/',
    ];
    return appSpecificPatterns.any((pattern) => path.contains(pattern));
  }
}
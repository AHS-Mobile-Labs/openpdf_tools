import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:openpdf_tools/utils/platform_helper.dart';

/// Platform-specific file handling utilities
class PlatformFileHandler {
  /// Request storage permissions if needed
  static Future<bool> requestStoragePermission() async {
    if (!PlatformHelper.isMobile) return true;

    final status = await Permission.storage.request();
    return status.isGranted;
  }

  /// Request media library access (iOS)
  static Future<bool> requestMediaLibraryAccess() async {
    if (!PlatformHelper.isIOS) return true;

    final status = await Permission.photos.request();
    return status.isGranted;
  }

  /// Request specific file permissions for the platform
  static Future<bool> requestFilePermissions() async {
    if (!PlatformHelper.isMobile) return true;

    if (PlatformHelper.isAndroid) {
      return await requestStoragePermission();
    } else if (PlatformHelper.isIOS) {
      return await requestMediaLibraryAccess();
    }
    return true;
  }

  /// Get platform-specific documents directory
  static Future<Directory> getDocumentsDirectory() async {
    if (PlatformHelper.isAndroid || PlatformHelper.isIOS) {
      return getApplicationDocumentsDirectory();
    } else if (PlatformHelper.isDesktop) {
      return Directory.systemTemp;
    }
    return getApplicationDocumentsDirectory();
  }

  /// Get platform-specific downloads directory
  static Future<Directory?> getDownloadsDirectory() async {
    if (PlatformHelper.isAndroid || PlatformHelper.isIOS) {
      return getApplicationDocumentsDirectory();
    } else if (PlatformHelper.isDesktop) {
      // On desktop, use the system Downloads folder
      if (PlatformHelper.isWindows) {
        return Directory('${Platform.environment['USERPROFILE']}\\Downloads');
      } else if (PlatformHelper.isMacOS || PlatformHelper.isLinux) {
        return Directory('${Platform.environment['HOME']}/Downloads');
      }
    }
    return getApplicationDocumentsDirectory();
  }

  /// Get optimal temporary directory for the platform
  static Future<Directory> getTempDirectory() async {
    return getTemporaryDirectory();
  }

  /// Get app cache directory
  static Future<Directory> getCacheDirectory() async {
    return getApplicationCacheDirectory();
  }

  /// Pick a file with platform-specific optimizations
  static Future<File?> pickFile({
    String? dialogTitle,
    bool allowMultiple = false,
    List<String> allowedExtensions = const ['pdf'],
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        allowMultiple: allowMultiple,
        dialogTitle: dialogTitle,
      );

      if (result != null && result.files.isNotEmpty) {
        return File(result.files.first.path ?? '');
      }
    } catch (e) {
      print('File picker error: $e');
    }
    return null;
  }

  /// Pick multiple files
  static Future<List<File>> pickMultipleFiles({
    String? dialogTitle,
    List<String> allowedExtensions = const ['pdf'],
  }) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowedExtensions,
        allowMultiple: true,
        dialogTitle: dialogTitle,
      );

      if (result != null && result.files.isNotEmpty) {
        return result.files
            .map((file) => File(file.path ?? ''))
            .where((file) => file.path.isNotEmpty)
            .toList();
      }
    } catch (e) {
      print('File picker error: $e');
    }
    return [];
  }

  /// Get file size in human-readable format
  static String getHumanReadableFileSize(int bytes) {
    const suffixes = ['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    int suffixIndex = 0;

    while (size > 1024 && suffixIndex < suffixes.length - 1) {
      size /= 1024;
      suffixIndex++;
    }

    return '${size.toStringAsFixed(2)} ${suffixes[suffixIndex]}';
  }

  /// Check if file exists
  static Future<bool> fileExists(String path) async {
    try {
      return await File(path).exists();
    } catch (e) {
      return false;
    }
  }

  /// Delete file safely
  static Future<bool> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (e) {
      print('Failed to delete file: $e');
    }
    return false;
  }

  /// Copy file to new location
  static Future<File?> copyFile(String sourcePath, String destinationPath) async {
    try {
      final source = File(sourcePath);
      if (!await source.exists()) return null;
      return source.copy(destinationPath);
    } catch (e) {
      print('Failed to copy file: $e');
    }
    return null;
  }

  /// Get file mime type based on extension
  static String getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();
    const mimeTypes = {
      'pdf': 'application/pdf',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'doc': 'application/msword',
      'docx': 'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    };
    return mimeTypes[extension] ?? 'application/octet-stream';
  }

  /// Get default save location for platform
  static Future<String> getDefaultSaveLocation() async {
    final dir = await getDownloadsDirectory();
    return dir?.path ?? (await getDocumentsDirectory()).path;
  }

  /// Check available storage space
  static Future<int> getAvailableStorageSpace() async {
    try {
      if (PlatformHelper.isAndroid) {
        final dir = await getExternalStorageDirectory();
        if (dir != null) {
          final stat = await FileStat.stat(dir.path);
          return stat.size;
        }
      } else if (PlatformHelper.isDesktop) {
        // For desktop, return a large default value
        return 1024 * 1024 * 1024; // 1GB
      }
    } catch (e) {
      print('Error getting storage space: $e');
    }
    return 0;
  }

  /// Check if path is accessible
  static Future<bool> isPathAccessible(String path) async {
    try {
      return await Directory(path).exists();
    } catch (e) {
      return false;
    }
  }
}

/// File operation result wrapper
class FileOperationResult {
  final bool success;
  final String message;
  final File? file;
  final Exception? error;

  FileOperationResult({
    required this.success,
    required this.message,
    this.file,
    this.error,
  });

  factory FileOperationResult.success({
    required String message,
    File? file,
  }) =>
      FileOperationResult(
        success: true,
        message: message,
        file: file,
      );

  factory FileOperationResult.failure({
    required String message,
    Exception? error,
  }) =>
      FileOperationResult(
        success: false,
        message: message,
        error: error,
      );
}

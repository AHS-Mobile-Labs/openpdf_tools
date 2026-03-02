import 'dart:io';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:permission_handler/permission_handler.dart';
import 'package:openpdf_tools/utils/platform_helper.dart';

/// Platform-specific file handling utilities with comprehensive Android support
class PlatformFileHandler {
  /// Request storage permissions with popup dialog (not full-screen)
  static Future<bool> requestStoragePermission() async {
    if (!PlatformHelper.isMobile) return true;

    try {
      if (PlatformHelper.isAndroid) {
        // Use standard storage permission which shows popup dialog
        // On Android 6-12: requests READ/WRITE_EXTERNAL_STORAGE
        // On Android 13+: requests READ_MEDIA_IMAGES/READ_MEDIA_VIDEO
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    } catch (e) {
      // Permission request error - return false to handle gracefully
      return false;
    }
    return true;
  }

  /// Request media permissions for Android 13+
  static Future<bool> requestMediaPermissions() async {
    if (!PlatformHelper.isAndroid) return true;

    try {
      // For Android 13+, request specific media permissions
      final photoStatus = await Permission.photos.request();
      final videoStatus = await Permission.videos.request();

      return photoStatus.isGranted || videoStatus.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Request camera permission for image capture
  static Future<bool> requestCameraPermission() async {
    if (!PlatformHelper.isMobile) return true;

    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Request media library access (iOS)
  static Future<bool> requestMediaLibraryAccess() async {
    if (!PlatformHelper.isIOS) return true;

    try {
      final status = await Permission.photos.request();
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  /// Check if permissions are permanently denied
  static Future<bool> arePermissionsPermanentlyDenied() async {
    if (!PlatformHelper.isAndroid) return false;

    try {
      final storageStatus = await Permission.storage.status;
      return storageStatus.isDenied;
    } catch (e) {
      return false;
    }
  }

  /// Request all necessary permissions for the app
  static Future<bool> requestFilePermissions() async {
    if (!PlatformHelper.isMobile) return true;

    try {
      if (PlatformHelper.isAndroid) {
        // Request storage permissions
        final storageGranted = await requestStoragePermission();

        // Request media permissions for Android 13+
        await requestMediaPermissions();

        return storageGranted;
      } else if (PlatformHelper.isIOS) {
        return await requestMediaLibraryAccess();
      }
    } catch (e) {
      return false;
    }
    return true;
  }

  /// Get platform-specific documents directory
  static Future<Directory> getDocumentsDirectory() async {
    if (PlatformHelper.isAndroid || PlatformHelper.isIOS) {
      return path_provider.getApplicationDocumentsDirectory();
    } else if (PlatformHelper.isDesktop) {
      return Directory.systemTemp;
    }
    return path_provider.getApplicationDocumentsDirectory();
  }

  /// Get platform-specific downloads directory (with proper Android handling)
  static Future<Directory?> getDownloadsDirectory() async {
    if (PlatformHelper.isAndroid || PlatformHelper.isIOS) {
      try {
        // For Android, use the app-specific cache directory
        // This works best with scoped storage on Android 11+
        return await path_provider.getApplicationCacheDirectory();
      } catch (e) {
        // Fallback to app documents directory
      }
      return path_provider.getApplicationDocumentsDirectory();
    } else if (PlatformHelper.isDesktop) {
      // On desktop, use the system Downloads folder
      if (PlatformHelper.isWindows) {
        final userProfile = Platform.environment['USERPROFILE'];
        if (userProfile != null) {
          return Directory('$userProfile\\Downloads');
        }
      } else if (PlatformHelper.isMacOS || PlatformHelper.isLinux) {
        final home = Platform.environment['HOME'];
        if (home != null) {
          return Directory('$home/Downloads');
        }
      }
    }
    return path_provider.getApplicationDocumentsDirectory();
  }

  /// Get app cache directory
  static Future<Directory> getCacheDirectory() async {
    return path_provider.getApplicationCacheDirectory();
  }

  /// Pick a file with platform-specific optimizations
  static Future<File?> pickFile({
    String? dialogTitle,
    bool allowMultiple = false,
    List<String> allowedExtensions = const ['pdf'],
  }) async {
    try {
      // Request permissions before picking file
      final hasPermission = await requestFilePermissions();
      if (!hasPermission && PlatformHelper.isAndroid) {
        // Attempt anyway - file picker might work without explicit permission
      }

      final result = await FilePicker.platform
          .pickFiles(
            type: FileType.custom,
            allowedExtensions: allowedExtensions,
            allowMultiple: allowMultiple,
            dialogTitle: dialogTitle,
            withData: false, // Don't load file data into memory
            withReadStream: true,
          )
          .timeout(const Duration(seconds: 30), onTimeout: () => null);

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path;
        if (filePath != null && filePath.isNotEmpty) {
          final file = File(filePath);
          if (await file.exists()) {
            return file;
          }
        }
      }
    } on PlatformException catch (e) {
      if (e.code != 'read_external_storage_denied') {
        // Handle this error gracefully
      }
    } catch (e) {
      // File picker error handled silently - user might have cancelled
    }
    return null;
  }

  /// Pick multiple files with better error handling
  static Future<List<File>> pickMultipleFiles({
    String? dialogTitle,
    List<String> allowedExtensions = const ['pdf'],
  }) async {
    try {
      // Request permissions before picking files
      final hasPermission = await requestFilePermissions();
      if (!hasPermission && PlatformHelper.isAndroid) {
        // Attempt anyway - file picker might work without explicit permission
      }

      final result = await FilePicker.platform
          .pickFiles(
            type: FileType.custom,
            allowedExtensions: allowedExtensions,
            allowMultiple: true,
            dialogTitle: dialogTitle,
            withData: false,
            withReadStream: true,
          )
          .timeout(const Duration(seconds: 30), onTimeout: () => null);

      if (result != null && result.files.isNotEmpty) {
        return result.files
            .map((file) => File(file.path ?? ''))
            .where((file) => file.path.isNotEmpty)
            .toList();
      }
    } on PlatformException catch (e) {
      if (e.code != 'read_external_storage_denied') {
        // Handle error
      }
    } catch (e) {
      // File picker error handled silently
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
      // Delete file error handled silently
    }
    return false;
  }

  /// Copy file to new location
  static Future<File?> copyFile(
    String sourcePath,
    String destinationPath,
  ) async {
    try {
      final source = File(sourcePath);
      if (!await source.exists()) return null;
      return source.copy(destinationPath);
    } catch (e) {
      // Copy file error handled silently
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
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    };
    return mimeTypes[extension] ?? 'application/octet-stream';
  }

  /// Get default save location for platform
  static Future<String> getDefaultSaveLocation() async {
    final dir = await getDownloadsDirectory();
    return dir?.path ?? (await getDocumentsDirectory()).path;
  }

  /// Check available storage space (Android-optimized)
  static Future<int> getAvailableStorageSpace() async {
    try {
      if (PlatformHelper.isAndroid) {
        final dir = await path_provider.getApplicationCacheDirectory();
        // Use stat to get available space
        final stat = FileStat.statSync(dir.path);
        return stat.size > 0 ? stat.size : 1024 * 1024 * 1024; // 1GB default
      } else if (PlatformHelper.isDesktop) {
        // For desktop, return a large default value
        return 1024 * 1024 * 1024; // 1GB
      }
    } catch (e) {
      // Storage space error - return default
    }
    return 100 * 1024 * 1024; // 100MB default
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

  factory FileOperationResult.success({required String message, File? file}) =>
      FileOperationResult(success: true, message: message, file: file);

  factory FileOperationResult.failure({
    required String message,
    Exception? error,
  }) => FileOperationResult(success: false, message: message, error: error);
}

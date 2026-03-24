import 'dart:io';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:permission_handler/permission_handler.dart';
import 'package:openpdf_tools/utils/platform_helper.dart';

class PlatformFileHandler {
  static Future<bool> requestStoragePermission() async {
    if (!PlatformHelper.isMobile) return true;
    try {
      if (PlatformHelper.isAndroid) {
        final photoStatus = await Permission.photos.status;
        final storageStatus = await Permission.storage.status;
        if (photoStatus.isGranted || storageStatus.isGranted) return true;
        final storageResult = await Permission.storage.request();
        final photoResult = await Permission.photos.request();
        return storageResult.isGranted || photoResult.isGranted;
      }
    } catch (e) {
      return false;
    }
    return true;
  }

  static Future<bool> requestMediaPermissions() async {
    if (!PlatformHelper.isAndroid) return true;
    try {
      final photoResult = await Permission.photos.request();
      final videoResult = await Permission.videos.request();
      return photoResult.isGranted || videoResult.isGranted;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> requestCameraPermission() async {
    if (!PlatformHelper.isMobile) return true;
    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> requestMediaLibraryAccess() async {
    if (!PlatformHelper.isIOS) return true;
    try {
      final status = await Permission.photos.request();
      return status.isGranted;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> arePermissionsPermanentlyDenied() async {
    if (!PlatformHelper.isAndroid) return false;
    try {
      final storageStatus = await Permission.storage.status;
      return storageStatus.isDenied;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> requestManageExternalStoragePermission() async {
    if (!PlatformHelper.isAndroid) return true;
    try {
      debugPrint(
        '[PlatformFileHandler] Requesting MANAGE_EXTERNAL_STORAGE permission',
      );
      final status = await Permission.manageExternalStorage.request();
      debugPrint(
        '[PlatformFileHandler] MANAGE_EXTERNAL_STORAGE status: $status',
      );
      return status.isGranted;
    } catch (e) {
      debugPrint(
        '[PlatformFileHandler] Error requesting manage external storage: $e',
      );
      return false;
    }
  }

  static Future<bool> requestFilePermissions() async {
    if (!PlatformHelper.isMobile) return true;
    try {
      if (PlatformHelper.isAndroid) {
        final storageGranted = await requestStoragePermission();
        await requestMediaPermissions();
        final manageStorageGranted =
            await requestManageExternalStoragePermission();
        return storageGranted || manageStorageGranted;
      } else if (PlatformHelper.isIOS) {
        return await requestMediaLibraryAccess();
      }
    } catch (e) {
      debugPrint('[PlatformFileHandler] Error requesting file permissions: $e');
      return false;
    }
    return true;
  }

  static Future<Directory> getDocumentsDirectory() async {
    if (PlatformHelper.isAndroid || PlatformHelper.isIOS) {
      return path_provider.getApplicationDocumentsDirectory();
    } else if (PlatformHelper.isDesktop) {
      return Directory.systemTemp;
    }
    return path_provider.getApplicationDocumentsDirectory();
  }

  static Future<Directory?> getDownloadsDirectory() async {
    if (PlatformHelper.isAndroid || PlatformHelper.isIOS) {
      try {
        return await path_provider.getApplicationCacheDirectory();
      } catch (_) {}
      return path_provider.getApplicationDocumentsDirectory();
    } else if (PlatformHelper.isDesktop) {
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

  static Future<Directory> getCacheDirectory() async {
    return path_provider.getApplicationCacheDirectory();
  }

  static Future<File?> pickFile({
    String? dialogTitle,
    bool allowMultiple = false,
    List<String> allowedExtensions = const ['pdf'],
  }) async {
    try {
      final hasPermission = await requestFilePermissions();
      if (!hasPermission && PlatformHelper.isAndroid) {}
      final result = await FilePicker.platform
          .pickFiles(
            type: FileType.custom,
            allowedExtensions: allowedExtensions,
            allowMultiple: allowMultiple,
            dialogTitle: dialogTitle,
            withData: false,
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
      if (e.code != 'read_external_storage_denied') {}
    } catch (_) {}
    return null;
  }

  static Future<List<File>> pickMultipleFiles({
    String? dialogTitle,
    List<String> allowedExtensions = const ['pdf'],
  }) async {
    try {
      final hasPermission = await requestFilePermissions();
      if (!hasPermission && PlatformHelper.isAndroid) {}
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
      if (e.code != 'read_external_storage_denied') {}
    } catch (_) {}
    return [];
  }

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

  static Future<bool> fileExists(String path) async {
    try {
      return await File(path).exists();
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<File?> copyFile(
    String sourcePath,
    String destinationPath,
  ) async {
    try {
      final source = File(sourcePath);
      if (!await source.exists()) return null;
      return source.copy(destinationPath);
    } catch (_) {}
    return null;
  }

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

  static Future<String> getDefaultSaveLocation() async {
    final dir = await getDownloadsDirectory();
    return dir?.path ?? (await getDocumentsDirectory()).path;
  }

  static Future<int> getAvailableStorageSpace() async {
    try {
      if (PlatformHelper.isAndroid) {
        final dir = await path_provider.getApplicationCacheDirectory();
        final stat = FileStat.statSync(dir.path);
        return stat.size > 0 ? stat.size : 1024 * 1024 * 1024;
      } else if (PlatformHelper.isDesktop) {
        return 1024 * 1024 * 1024;
      }
    } catch (_) {}
    return 100 * 1024 * 1024;
  }

  static Future<bool> isPathAccessible(String path) async {
    try {
      return await Directory(path).exists();
    } catch (e) {
      return false;
    }
  }
}

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

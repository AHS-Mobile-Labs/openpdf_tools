import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:openpdf_tools/utils/platform_helper.dart';

class ScopedStorageHelper {
  static bool get isAndroid11Plus {
    if (!PlatformHelper.isAndroid) return false;
    return true;
  }

  static Future<Directory> getSafeTempDirectory() async {
    return getTemporaryDirectory();
  }

  static Future<Directory?> getSafeDownloadsDirectory() async {
    if (PlatformHelper.isAndroid) {
      try {
        final cacheDir = await getApplicationCacheDirectory();
        final downloadsDir = Directory('${cacheDir.path}/Downloads');
        if (!downloadsDir.existsSync()) {
          await downloadsDir.create(recursive: true);
        }
        return downloadsDir;
      } catch (_) {}
    }
    return getApplicationDocumentsDirectory();
  }

  static Future<Directory> getSafeCacheDirectory() async {
    final cacheDir = await getApplicationCacheDirectory();
    final pdfCacheDir = Directory('${cacheDir.path}/pdf_temp');
    if (!pdfCacheDir.existsSync()) {
      await pdfCacheDir.create(recursive: true);
    }
    return pdfCacheDir;
  }

  static Future<Directory> getSafeSupportDirectory() async {
    final appSupport = await getApplicationSupportDirectory();
    return appSupport;
  }

  static Future<String?> savePdfToSafeLocation({
    required File sourceFile,
    required String fileName,
  }) async {
    try {
      if (!PlatformHelper.isAndroid) {
        return sourceFile.path;
      }
      final downloadsDir = await getSafeDownloadsDirectory();
      if (downloadsDir == null) return null;
      final targetPath = '${downloadsDir.path}/$fileName';
      await sourceFile.copy(targetPath);
      return targetPath;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> isFileAccessible(String filePath) async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  static String getContentUri(String filePath) {
    return 'file://$filePath';
  }

  static Future<void> cleanupTempFiles() async {
    try {
      final tempDir = await getSafeCacheDirectory();
      if (tempDir.existsSync()) {
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
    } catch (_) {}
  }
}

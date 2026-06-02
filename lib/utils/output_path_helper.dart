import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'platform_helper.dart';

enum OutputCategory { downloads, documents, pictures, exports }

class ExportedFile {
  final String workingPath;
  final String displayPath;
  final String fileName;
  final String? uri;
  final bool isUserVisible;

  const ExportedFile({
    required this.workingPath,
    required this.displayPath,
    required this.fileName,
    required this.isUserVisible,
    this.uri,
  });
}

class OutputPathHelper {
  static const MethodChannel _channel = MethodChannel(
    'com.openpdf.tools/pdfManipulation',
  );

  static Future<String> createWorkingOutputPath({
    required String fileName,
    OutputCategory category = OutputCategory.exports,
  }) async {
    final safeName = sanitizeFileName(fileName);
    if (kIsWeb) return safeName;

    if (PlatformHelper.isAndroid) {
      final tempDir = await getTemporaryDirectory();
      final dir = Directory(p.join(tempDir.path, 'openpdf_tools'));
      await dir.create(recursive: true);
      return _uniquePath(dir, safeName);
    }

    final dir = await _visibleDirectory(category);
    await dir.create(recursive: true);
    return _uniquePath(dir, safeName);
  }

  static Future<ExportedFile> exportGeneratedFile({
    required String sourcePath,
    required String fileName,
    OutputCategory category = OutputCategory.exports,
  }) async {
    if (kIsWeb) {
      return ExportedFile(
        workingPath: sourcePath,
        displayPath: fileName,
        fileName: fileName,
        isUserVisible: false,
      );
    }

    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw Exception('Generated file was not found: $sourcePath');
    }

    final safeName = sanitizeFileName(fileName);

    if (PlatformHelper.isAndroid) {
      try {
        final result = await _channel
            .invokeMapMethod<String, dynamic>('exportToPublicDirectory', {
              'sourcePath': sourcePath,
              'fileName': safeName,
              'category': category.name,
              'mimeType': mimeTypeForFileName(safeName),
            });
        if (result != null) {
          return ExportedFile(
            workingPath: sourcePath,
            displayPath:
                result['displayPath']?.toString() ??
                _displayPathForAndroid(category, safeName),
            fileName: result['fileName']?.toString() ?? safeName,
            uri: result['uri']?.toString(),
            isUserVisible: true,
          );
        }
      } catch (e) {
        debugPrint('[OutputPathHelper] Android public export failed: $e');
      }

      final fallbackDir = await getApplicationDocumentsDirectory();
      final targetPath = await _uniquePath(fallbackDir, safeName);
      await sourceFile.copy(targetPath);
      return ExportedFile(
        workingPath: targetPath,
        displayPath: targetPath,
        fileName: p.basename(targetPath),
        isUserVisible: false,
      );
    }

    final visibleDir = await _visibleDirectory(category);
    await visibleDir.create(recursive: true);
    if (p.equals(p.dirname(sourceFile.absolute.path), visibleDir.path)) {
      return ExportedFile(
        workingPath: sourcePath,
        displayPath: sourcePath,
        fileName: p.basename(sourcePath),
        isUserVisible: true,
      );
    }

    final targetPath = await _uniquePath(visibleDir, safeName);
    await sourceFile.copy(targetPath);
    return ExportedFile(
      workingPath: targetPath,
      displayPath: targetPath,
      fileName: p.basename(targetPath),
      isUserVisible: true,
    );
  }

  static String outputFileName({
    required String sourcePath,
    required String suffix,
    required String extension,
  }) {
    final baseName = p.basenameWithoutExtension(sourcePath).trim();
    final normalizedExt = extension.replaceFirst(RegExp(r'^\.'), '');
    final name = baseName.isEmpty ? 'openpdf' : baseName;
    return sanitizeFileName('${name}_$suffix.$normalizedExt');
  }

  static String sanitizeFileName(String fileName) {
    final cleaned = fileName
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.isEmpty
        ? 'openpdf_${DateTime.now().millisecondsSinceEpoch}'
        : cleaned;
  }

  static String mimeTypeForFileName(String fileName) {
    switch (p.extension(fileName).toLowerCase()) {
      case '.pdf':
        return 'application/pdf';
      case '.txt':
        return 'text/plain';
      case '.rtf':
        return 'application/rtf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.ppt':
        return 'application/vnd.ms-powerpoint';
      case '.pptx':
        return 'application/vnd.openxmlformats-officedocument.presentationml.presentation';
      case '.xls':
        return 'application/vnd.ms-excel';
      case '.xlsx':
        return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      case '.odt':
        return 'application/vnd.oasis.opendocument.text';
      case '.ods':
        return 'application/vnd.oasis.opendocument.spreadsheet';
      case '.odp':
        return 'application/vnd.oasis.opendocument.presentation';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.webp':
        return 'image/webp';
      case '.svg':
        return 'image/svg+xml';
      case '.zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }

  static Future<Directory> _visibleDirectory(OutputCategory category) async {
    if (PlatformHelper.isWindows) {
      final profile = Platform.environment['USERPROFILE'];
      if (profile != null && profile.isNotEmpty) {
        return Directory(p.join(profile, _windowsBaseFolder(category)));
      }
    }

    final home = Platform.environment['HOME'];
    if (home != null && home.isNotEmpty) {
      switch (category) {
        case OutputCategory.documents:
          return Directory(p.join(home, 'Documents', 'OpenPDF Tools'));
        case OutputCategory.pictures:
          return Directory(p.join(home, 'Pictures', 'OpenPDF Tools'));
        case OutputCategory.downloads:
          return Directory(p.join(home, 'Downloads', 'OpenPDF Tools'));
        case OutputCategory.exports:
          return Directory(
            p.join(home, 'Downloads', 'OpenPDF Tools', 'Exports'),
          );
      }
    }

    final documents = await getApplicationDocumentsDirectory();
    return Directory(p.join(documents.path, 'OpenPDF Tools'));
  }

  static String _windowsBaseFolder(OutputCategory category) {
    switch (category) {
      case OutputCategory.documents:
        return p.join('Documents', 'OpenPDF Tools');
      case OutputCategory.pictures:
        return p.join('Pictures', 'OpenPDF Tools');
      case OutputCategory.downloads:
        return p.join('Downloads', 'OpenPDF Tools');
      case OutputCategory.exports:
        return p.join('Downloads', 'OpenPDF Tools', 'Exports');
    }
  }

  static String _displayPathForAndroid(
    OutputCategory category,
    String fileName,
  ) {
    switch (category) {
      case OutputCategory.documents:
        return 'Documents/OpenPDF Tools/$fileName';
      case OutputCategory.pictures:
        return 'Pictures/OpenPDF Tools/$fileName';
      case OutputCategory.downloads:
        return 'Download/OpenPDF Tools/$fileName';
      case OutputCategory.exports:
        return 'Download/OpenPDF Tools/Exports/$fileName';
    }
  }

  static Future<String> _uniquePath(Directory dir, String fileName) async {
    final base = p.basenameWithoutExtension(fileName);
    final ext = p.extension(fileName);
    var candidate = p.join(dir.path, fileName);
    var counter = 1;
    while (await File(candidate).exists()) {
      candidate = p.join(dir.path, '${base}_$counter$ext');
      counter++;
    }
    return candidate;
  }
}

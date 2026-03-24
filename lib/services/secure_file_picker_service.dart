import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/signing_models.dart';

class SecureFilePickerService {
  static const int maxPdfFileSize = 500 * 1024 * 1024;
  static const int maxImageFileSize = 50 * 1024 * 1024;
  static const int maxCertificateFileSize = 5 * 1024 * 1024;
  static Future<File?> pickPdfFile() async {
    if (kIsWeb) return null;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: false,
      );
      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path;
        if (filePath == null || filePath.isEmpty) {
          debugPrint('[SecureFilePickerService] Invalid file path');
          return null;
        }
        final file = File(filePath);
        if (!await _validatePdfFile(file)) {
          return null;
        }
        return file;
      }
    } catch (e) {
      debugPrint('[SecureFilePickerService] Error picking PDF: $e');
    }
    return null;
  }

  static Future<File?> pickCertificateFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['p12', 'pfx', 'pem'],
        withData: false,
      );
      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path;
        if (filePath == null || filePath.isEmpty) {
          debugPrint('[SecureFilePickerService] Invalid file path');
          return null;
        }
        final file = File(filePath);
        if (!await _validateCertificateFile(file)) {
          return null;
        }
        return file;
      }
    } catch (e) {
      debugPrint('[SecureFilePickerService] Error picking certificate: $e');
    }
    return null;
  }

  static Future<File?> pickSignatureImage() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: false,
      );
      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path;
        if (filePath == null || filePath.isEmpty) {
          debugPrint('[SecureFilePickerService] Invalid file path');
          return null;
        }
        final file = File(filePath);
        if (!await _validateImageFile(file)) {
          return null;
        }
        return file;
      }
    } catch (e) {
      debugPrint('[SecureFilePickerService] Error picking image: $e');
    }
    return null;
  }

  static Future<bool> _validatePdfFile(File file) async {
    try {
      if (!file.existsSync()) {
        debugPrint('[SecureFilePickerService] PDF file does not exist');
        return false;
      }
      final fileSize = await file.length();
      if (fileSize == 0) {
        debugPrint('[SecureFilePickerService] PDF file is empty');
        return false;
      }
      if (fileSize > maxPdfFileSize) {
        debugPrint(
          '[SecureFilePickerService] PDF file exceeds maximum size (500 MB)',
        );
        return false;
      }
      final bytes = await file.readAsBytes();
      if (bytes.length < 5) {
        debugPrint('[SecureFilePickerService] PDF file is too small');
        return false;
      }
      if (bytes[0] != 0x25 ||
          bytes[1] != 0x50 ||
          bytes[2] != 0x44 ||
          bytes[3] != 0x46) {
        debugPrint('[SecureFilePickerService] Invalid PDF header');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('[SecureFilePickerService] PDF validation error: $e');
      return false;
    }
  }

  static Future<bool> _validateCertificateFile(File file) async {
    try {
      if (!file.existsSync()) {
        debugPrint('[SecureFilePickerService] Certificate file does not exist');
        return false;
      }
      final fileSize = await file.length();
      if (fileSize == 0) {
        debugPrint('[SecureFilePickerService] Certificate file is empty');
        return false;
      }
      if (fileSize > maxCertificateFileSize) {
        debugPrint(
          '[SecureFilePickerService] Certificate exceeds maximum size (5 MB)',
        );
        return false;
      }
      final fileName = file.path.toLowerCase();
      final validExtensions = ['.p12', '.pfx', '.pem'];
      final hasValidExtension = validExtensions.any(
        (ext) => fileName.endsWith(ext),
      );
      if (!hasValidExtension) {
        debugPrint('[SecureFilePickerService] Invalid certificate format');
        return false;
      }
      final bytes = await file.readAsBytes();
      final isBinary = bytes.length > 3 && bytes[0] == 0x30;
      final isPem = String.fromCharCodes(bytes).contains('BEGIN');
      if (!isBinary && !isPem) {
        debugPrint('[SecureFilePickerService] Invalid certificate data');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('[SecureFilePickerService] Certificate validation error: $e');
      return false;
    }
  }

  static Future<bool> _validateImageFile(File file) async {
    try {
      if (!file.existsSync()) {
        debugPrint('[SecureFilePickerService] Image file does not exist');
        return false;
      }
      final fileSize = await file.length();
      if (fileSize == 0) {
        debugPrint('[SecureFilePickerService] Image file is empty');
        return false;
      }
      if (fileSize > maxImageFileSize) {
        debugPrint(
          '[SecureFilePickerService] Image file exceeds maximum size (50 MB)',
        );
        return false;
      }
      final bytes = await file.readAsBytes();
      if (bytes.length < 2) {
        debugPrint('[SecureFilePickerService] Image file is too small');
        return false;
      }
      final isPng = bytes[0] == 0x89 && bytes[1] == 0x50;
      final isJpg = bytes[0] == 0xFF && bytes[1] == 0xD8;
      final isGif = String.fromCharCodes(bytes.sublist(0, 3)) == 'GIF';
      if (!isPng && !isJpg && !isGif) {
        debugPrint('[SecureFilePickerService] Invalid image format');
        return false;
      }
      return true;
    } catch (e) {
      debugPrint('[SecureFilePickerService] Image validation error: $e');
      return false;
    }
  }

  static Future<String> getOutputDirectory() async {
    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        return downloadsDir.path;
      }
      final documentsDir = await getApplicationDocumentsDirectory();
      return documentsDir.path;
    } catch (e) {
      debugPrint(
        '[SecureFilePickerService] Error getting output directory: $e',
      );
      final tempDir = await getTemporaryDirectory();
      return tempDir.path;
    }
  }

  static String generateOutputFilename(String originalName) {
    final nameParts = originalName.split('.');
    final baseName = nameParts.length > 1
        ? nameParts.sublist(0, nameParts.length - 1).join('.')
        : originalName;
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${baseName}_signed_$timestamp.pdf';
  }

  static Future<bool> validateOutputPath(String outputPath) async {
    try {
      final file = File(outputPath);
      final directory = file.parent;
      if (!directory.existsSync()) {
        try {
          await directory.create(recursive: true);
        } catch (e) {
          debugPrint(
            '[SecureFilePickerService] Cannot create output directory: $e',
          );
          return false;
        }
      }
      return true;
    } catch (e) {
      debugPrint('[SecureFilePickerService] Output path validation error: $e');
      return false;
    }
  }

  static Future<PdfMetadata?> getPdfMetadata(File pdfFile) async {
    try {
      if (!pdfFile.existsSync()) {
        return null;
      }
      final fileSize = await pdfFile.length();
      final fileName = pdfFile.path.split('/').last;
      final lastModified = await pdfFile.lastModified();
      return PdfMetadata(
        pageCount: 1,
        title: fileName.replaceAll('.pdf', ''),
        fileSizeBytes: fileSize,
        modifiedDate: lastModified,
        isEncrypted: false,
        hasSignatures: false,
      );
    } catch (e) {
      debugPrint('[SecureFilePickerService] Error reading PDF metadata: $e');
      return null;
    }
  }

  static Future<File?> createSecureCopy(File sourceFile) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempPath =
          '${tempDir.path}/temp_${timestamp}_${sourceFile.path.split('/').last}';
      final tempFile = File(tempPath);
      final bytes = await sourceFile.readAsBytes();
      await tempFile.writeAsBytes(bytes);
      return tempFile;
    } catch (e) {
      debugPrint('[SecureFilePickerService] Error creating secure copy: $e');
      return null;
    }
  }

  static Future<void> safeDeleteFile(File file) async {
    try {
      if (file.existsSync()) {
        await file.delete();
        debugPrint('[SecureFilePickerService] File deleted: ${file.path}');
      }
    } catch (e) {
      debugPrint('[SecureFilePickerService] Error deleting file: $e');
    }
  }
}

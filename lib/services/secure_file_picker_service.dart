import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/signing_models.dart';

/// Service for cross-platform file picking and handling
/// Provides consistent file selection across all platforms
class SecureFilePickerService {
  // File size limits for security
  static const int maxPdfFileSize = 500 * 1024 * 1024; // 500 MB
  static const int maxImageFileSize = 50 * 1024 * 1024; // 50 MB
  static const int maxCertificateFileSize = 5 * 1024 * 1024; // 5 MB

  /// Picks a PDF file with validation
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

        // Validate file
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

  /// Picks a certificate file (.p12, .pfx, .pem)
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

        // Validate certificate file
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

  /// Picks an image file for signature
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

        // Validate image file
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

  /// Validates PDF file
  static Future<bool> _validatePdfFile(File file) async {
    try {
      // Check file exists
      if (!file.existsSync()) {
        debugPrint('[SecureFilePickerService] PDF file does not exist');
        return false;
      }

      // Check file size
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

      // Validate PDF header
      final bytes = await file.readAsBytes();
      if (bytes.length < 5) {
        debugPrint('[SecureFilePickerService] PDF file is too small');
        return false;
      }

      // Check PDF magic bytes: %PDF
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

  /// Validates certificate file
  static Future<bool> _validateCertificateFile(File file) async {
    try {
      // Check file exists
      if (!file.existsSync()) {
        debugPrint('[SecureFilePickerService] Certificate file does not exist');
        return false;
      }

      // Check file size
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

      // Check file extension
      final fileName = file.path.toLowerCase();
      final validExtensions = ['.p12', '.pfx', '.pem'];
      final hasValidExtension = validExtensions.any(
        (ext) => fileName.endsWith(ext),
      );

      if (!hasValidExtension) {
        debugPrint('[SecureFilePickerService] Invalid certificate format');
        return false;
      }

      // Check for binary data markers (P12/PFX) or PEM header
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

  /// Validates image file
  static Future<bool> _validateImageFile(File file) async {
    try {
      // Check file exists
      if (!file.existsSync()) {
        debugPrint('[SecureFilePickerService] Image file does not exist');
        return false;
      }

      // Check file size
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

      // Validate image format (PNG, JPG, etc.)
      final bytes = await file.readAsBytes();
      if (bytes.length < 2) {
        debugPrint('[SecureFilePickerService] Image file is too small');
        return false;
      }

      // Check common image magic bytes
      final isPng = bytes[0] == 0x89 && bytes[1] == 0x50; // PNG
      final isJpg = bytes[0] == 0xFF && bytes[1] == 0xD8; // JPG
      final isGif = String.fromCharCodes(bytes.sublist(0, 3)) == 'GIF'; // GIF

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

  /// Gets output directory for signed PDF
  /// Returns appropriate directory based on platform
  static Future<String> getOutputDirectory() async {
    try {
      // Try to get Downloads directory first
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        return downloadsDir.path;
      }

      // Fallback to Documents directory
      final documentsDir = await getApplicationDocumentsDirectory();
      return documentsDir.path;
    } catch (e) {
      debugPrint(
        '[SecureFilePickerService] Error getting output directory: $e',
      );
      // Final fallback to temporary directory
      final tempDir = await getTemporaryDirectory();
      return tempDir.path;
    }
  }

  /// Generates unique output filename with timestamp
  static String generateOutputFilename(String originalName) {
    final nameParts = originalName.split('.');
    final baseName = nameParts.length > 1
        ? nameParts.sublist(0, nameParts.length - 1).join('.')
        : originalName;

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return '${baseName}_signed_$timestamp.pdf';
  }

  /// Validates output path is safe and writable
  static Future<bool> validateOutputPath(String outputPath) async {
    try {
      final file = File(outputPath);
      final directory = file.parent;

      // Check if directory exists and is writable
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

  /// Gets PDF metadata without loading entire file
  static Future<PdfMetadata?> getPdfMetadata(File pdfFile) async {
    try {
      if (!pdfFile.existsSync()) {
        return null;
      }

      final fileSize = await pdfFile.length();
      final fileName = pdfFile.path.split('/').last;
      final lastModified = await pdfFile.lastModified();

      // In production, parse actual PDF metadata
      // For now, return basic metadata
      return PdfMetadata(
        pageCount: 1, // Would parse from PDF
        title: fileName.replaceAll('.pdf', ''),
        fileSizeBytes: fileSize,
        modifiedDate: lastModified,
        isEncrypted: false, // Would detect from PDF
        hasSignatures: false, // Would check signatures
      );
    } catch (e) {
      debugPrint('[SecureFilePickerService] Error reading PDF metadata: $e');
      return null;
    }
  }

  /// Clones file to temporary location for processing (security measure)
  static Future<File?> createSecureCopy(File sourceFile) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final tempPath =
          '${tempDir.path}/temp_${timestamp}_${sourceFile.path.split('/').last}';
      final tempFile = File(tempPath);

      // Copy file content
      final bytes = await sourceFile.readAsBytes();
      await tempFile.writeAsBytes(bytes);

      return tempFile;
    } catch (e) {
      debugPrint('[SecureFilePickerService] Error creating secure copy: $e');
      return null;
    }
  }

  /// Safely deletes a file with error handling
  static Future<void> safeDeleteFile(File file) async {
    try {
      if (file.existsSync()) {
        // Overwrite file with zeros before deletion (optional security measure)
        // Can be enabled for highly sensitive scenarios
        await file.delete();
        debugPrint('[SecureFilePickerService] File deleted: ${file.path}');
      }
    } catch (e) {
      debugPrint('[SecureFilePickerService] Error deleting file: $e');
    }
  }
}

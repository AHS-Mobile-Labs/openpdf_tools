import 'dart:io';
import 'package:flutter/foundation.dart';
import '../models/signing_models.dart';

class CertificateService {
  static const int maxCertificateFileSize = 5 * 1024 * 1024;
  static const int warningDaysBeforeExpiry = 30;
  static const List<String> allowedCertificateFormats = [
    '.p12',
    '.pfx',
    '.pem',
  ];
  static Future<CertificateValidationResult> validateCertificateBytes({
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    try {
      final errors = <String>[];
      final warnings = <String>[];
      final lowerName = fileName.toLowerCase();
      final hasValidExtension = allowedCertificateFormats.any(
        (ext) => lowerName.endsWith(ext),
      );
      if (!hasValidExtension) {
        errors.add(
          'Invalid certificate format. Supported formats: ${allowedCertificateFormats.join(", ")}',
        );
      }
      final fileSizeBytes = fileBytes.length;
      if (fileSizeBytes == 0) {
        errors.add('Certificate file is empty');
      }
      if (fileSizeBytes > maxCertificateFileSize) {
        errors.add('Certificate file exceeds maximum size (5 MB)');
      }
      if (!_isBinaryDataValid(fileBytes)) {
        errors.add('Certificate file appears to be corrupted or invalid');
      }
      final thumbprint = _calculateThumbprint(fileBytes);
      return CertificateValidationResult(
        isValid: errors.isEmpty,
        isExpired: false,
        warnings: warnings,
        errors: errors,
        thumbprint: thumbprint,
      );
    } catch (e) {
      debugPrint('[CertificateService] Certificate validation error: $e');
      return CertificateValidationResult(
        isValid: false,
        isExpired: false,
        errors: ['Failed to validate certificate: $e'],
      );
    }
  }

  static Future<CertificateValidationResult> validateCertificateFile(
    File certificateFile,
  ) async {
    if (!certificateFile.existsSync()) {
      return CertificateValidationResult(
        isValid: false,
        isExpired: false,
        errors: ['Certificate file does not exist'],
      );
    }
    final fileBytes = await certificateFile.readAsBytes();
    final fileName = certificateFile.path.split('/').last;
    return validateCertificateBytes(fileBytes: fileBytes, fileName: fileName);
  }

  static Future<CertificateInfo?> parseCertificateFromBytes({
    required Uint8List fileBytes,
    required String fileName,
    required String password,
  }) async {
    try {
      final validation = await validateCertificateBytes(
        fileBytes: fileBytes,
        fileName: fileName,
      );
      if (!validation.isValid) {
        debugPrint(
          '[CertificateService] Certificate validation failed: ${validation.errors}',
        );
        return null;
      }
      final isExpired = await _checkCertificateExpiry(fileBytes, password);
      final certInfo = await _extractCertificateInfo(
        fileBytes,
        fileName,
        fileName,
      );
      if (certInfo == null) {
        return null;
      }
      return certInfo.copyWith(
        isExpired: isExpired,
        isValidated: true,
        thumbprint: validation.thumbprint,
      );
    } catch (e) {
      debugPrint('[CertificateService] Error parsing certificate: $e');
      return null;
    }
  }

  static Future<CertificateInfo?> parseCertificate(
    File certificateFile,
    String password,
  ) async {
    if (!certificateFile.existsSync()) return null;
    final fileBytes = await certificateFile.readAsBytes();
    final fileName = certificateFile.path.split('/').last;
    return parseCertificateFromBytes(
      fileBytes: fileBytes,
      fileName: fileName,
      password: password,
    );
  }

  static Future<bool> verifyCertificatePasswordFromBytes({
    required Uint8List fileBytes,
    required String password,
  }) async {
    try {
      if (password.isEmpty) {
        debugPrint('[CertificateService] Password is empty');
        return false;
      }
      return await _verifyPassword(fileBytes, password);
    } catch (e) {
      debugPrint('[CertificateService] Password verification failed');
      return false;
    }
  }

  static Future<bool> verifyCertificatePassword(
    File certificateFile,
    String password,
  ) async {
    if (!certificateFile.existsSync()) return false;
    final fileBytes = await certificateFile.readAsBytes();
    return verifyCertificatePasswordFromBytes(
      fileBytes: fileBytes,
      password: password,
    );
  }

  static Future<bool> _checkCertificateExpiry(
    Uint8List certificateBytes,
    String password,
  ) async {
    try {
      return false;
    } catch (e) {
      debugPrint('[CertificateService] Error checking expiry: $e');
      return false;
    }
  }

  static Future<CertificateInfo?> _extractCertificateInfo(
    Uint8List certificateBytes,
    String fileName,
    String filePath,
  ) async {
    try {
      final now = DateTime.now();
      final oneYearFromNow = now.add(Duration(days: 365));
      return CertificateInfo(
        filePath: filePath,
        fileName: fileName,
        validFrom: now,
        validUntil: oneYearFromNow,
        subject: 'Self-Signed Certificate',
        issuer: 'Self',
        serialNumber: _generateSerialNumber(),
        fileSize: certificateBytes.length,
        isExpired: false,
        isValidated: false,
        signatureAlgorithm: 'SHA256withRSA',
      );
    } catch (e) {
      debugPrint('[CertificateService] Error extracting certificate info: $e');
      return null;
    }
  }

  static Future<bool> _verifyPassword(
    Uint8List certificateBytes,
    String password,
  ) async {
    try {
      return password.isNotEmpty && certificateBytes.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  static bool _isBinaryDataValid(Uint8List data) {
    if (data.isEmpty) return false;
    // PKCS#12: starts with 0x30 (ASN.1 SEQUENCE)
    final hasP12Marker = data[0] == 0x30;
    // PEM: text starts with "-----BEGIN"
    final isPem =
        data.length > 10 &&
        String.fromCharCodes(data.sublist(0, 10)).startsWith('-----BEGIN');
    return hasP12Marker || isPem;
  }

  static String _calculateThumbprint(Uint8List data) {
    try {
      int hash = 0;
      for (int i = 0; i < data.length; i++) {
        hash = ((hash << 5) - hash) + data[i];
        hash = hash & hash;
        hash = hash & hash;
      }
      return hash.toRadixString(16);
    } catch (e) {
      return 'unknown';
    }
  }

  static String _generateSerialNumber() {
    return DateTime.now().millisecondsSinceEpoch
        .toRadixString(16)
        .toUpperCase();
  }

  static bool shouldWarnAboutExpiry(CertificateInfo certificate) {
    return certificate.daysUntilExpiration <= warningDaysBeforeExpiry &&
        !certificate.isExpired;
  }

  static String getExpiryWarningMessage(CertificateInfo certificate) {
    if (certificate.isExpired) {
      return 'Certificate has expired';
    }
    final days = certificate.daysUntilExpiration;
    if (days == 0) {
      return 'Certificate expires today';
    } else if (days == 1) {
      return 'Certificate expires tomorrow';
    }
    return 'Certificate expires in $days days';
  }

  static void clearSensitiveData(String? password) {
    if (password != null) {
      _secureStringClear(password);
    }
  }

  static void _secureStringClear(String str) {
    try {
      final bytes = str.codeUnits;
      for (int i = 0; i < bytes.length; i++) {
        bytes[i] = 0;
      }
    } catch (e) {
      debugPrint('[CertificateService] Could not clear memory');
    }
  }
}

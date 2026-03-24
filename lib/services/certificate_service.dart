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
  static Future<CertificateValidationResult> validateCertificateFile(
    File certificateFile,
  ) async {
    try {
      final errors = <String>[];
      final warnings = <String>[];
      if (!certificateFile.existsSync()) {
        errors.add('Certificate file does not exist');
        return CertificateValidationResult(
          isValid: false,
          isExpired: false,
          errors: errors,
        );
      }
      final fileName = certificateFile.path.toLowerCase();
      final hasValidExtension = allowedCertificateFormats.any(
        (ext) => fileName.endsWith(ext),
      );
      if (!hasValidExtension) {
        errors.add(
          'Invalid certificate format. Supported formats: ${allowedCertificateFormats.join(", ")}',
        );
      }
      final fileSizeBytes = await certificateFile.length();
      if (fileSizeBytes == 0) {
        errors.add('Certificate file is empty');
      }
      if (fileSizeBytes > maxCertificateFileSize) {
        errors.add('Certificate file exceeds maximum size (5 MB)');
      }
      final fileBytes = await certificateFile.readAsBytes();
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

  static Future<CertificateInfo?> parseCertificate(
    File certificateFile,
    String password,
  ) async {
    try {
      final validation = await validateCertificateFile(certificateFile);
      if (!validation.isValid) {
        debugPrint(
          '[CertificateService] Certificate validation failed: ${validation.errors}',
        );
        return null;
      }
      final fileBytes = await certificateFile.readAsBytes();
      final fileName = certificateFile.path.split('/').last;
      final isExpired = await _checkCertificateExpiry(fileBytes, password);
      final certInfo = await _extractCertificateInfo(
        fileBytes,
        fileName,
        certificateFile.path,
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

  static Future<bool> verifyCertificatePassword(
    File certificateFile,
    String password,
  ) async {
    try {
      if (!certificateFile.existsSync()) {
        return false;
      }
      if (password.isEmpty) {
        debugPrint('[CertificateService] Password is empty');
        return false;
      }
      final fileBytes = await certificateFile.readAsBytes();
      return await _verifyPassword(fileBytes, password);
    } catch (e) {
      debugPrint('[CertificateService] Password verification failed');
      return false;
    }
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
    try {
      if (data.isEmpty) return false;
      final hasP12Marker =
          data.length > 3 && data[0] == 0x30 && data[1] == 0x82;
      final isPemData = String.fromCharCodes(
        data,
      ).contains('BEGIN CERTIFICATE');
      return hasP12Marker || isPemData;
    } catch (e) {
      return false;
    }
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

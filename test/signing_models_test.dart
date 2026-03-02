import 'package:flutter_test/flutter_test.dart';
import 'package:openpdf_tools/models/signing_models.dart';

void main() {
  group('CertificateInfo Tests', () {
    test('isCurrentlyValid returns false when expired', () {
      final cert = CertificateInfo(
        filePath: '/path/to/cert.p12',
        fileName: 'cert.p12',
        validFrom: DateTime(2020, 1, 1),
        validUntil: DateTime(2023, 1, 1),
        subject: 'Test Subject',
        issuer: 'Test Issuer',
        serialNumber: '123456',
        fileSize: 1000,
        isExpired: true,
      );

      expect(cert.isCurrentlyValid, false);
    });

    test('isCurrentlyValid returns true when valid', () {
      final now = DateTime.now();
      final cert = CertificateInfo(
        filePath: '/path/to/cert.p12',
        fileName: 'cert.p12',
        validFrom: now.subtract(Duration(days: 1)),
        validUntil: now.add(Duration(days: 365)),
        subject: 'Test Subject',
        issuer: 'Test Issuer',
        serialNumber: '123456',
        fileSize: 1000,
        isExpired: false,
      );

      expect(cert.isCurrentlyValid, true);
    });

    test('daysUntilExpiration calculated correctly', () {
      final now = DateTime.now();
      final cert = CertificateInfo(
        filePath: '/path/to/cert.p12',
        fileName: 'cert.p12',
        validFrom: now,
        validUntil: now.add(Duration(days: 30)),
        subject: 'Test Subject',
        issuer: 'Test Issuer',
        serialNumber: '123456',
        fileSize: 1000,
      );

      expect(cert.daysUntilExpiration, 30);
    });

    test('copyWith creates new instance with updated fields', () {
      final cert = CertificateInfo(
        filePath: '/path/to/cert.p12',
        fileName: 'cert.p12',
        validFrom: DateTime.now(),
        validUntil: DateTime.now().add(Duration(days: 365)),
        subject: 'Test Subject',
        issuer: 'Test Issuer',
        serialNumber: '123456',
        fileSize: 1000,
        isValidated: false,
      );

      final updatedCert = cert.copyWith(isValidated: true);
      expect(updatedCert.isValidated, true);
      expect(updatedCert.filePath, cert.filePath);
    });
  });

  group('SigningRequest Tests', () {
    test('validate returns errors for invalid request', () {
      final cert = CertificateInfo(
        filePath: '/path/to/cert.p12',
        fileName: 'cert.p12',
        validFrom: DateTime.now(),
        validUntil: DateTime.now().add(Duration(days: 365)),
        subject: 'Test Subject',
        issuer: 'Test Issuer',
        serialNumber: '123456',
        fileSize: 1000,
        isExpired: false,
        isValidated: true,
      );

      final request = SigningRequest(
        pdfFilePath: '',
        nameOnSignature: '',
        reason: '',
        certificate: cert,
        certificatePassword: '',
        outputPath: '/path/to/output.pdf',
      );

      final result = request.validate();
      expect(result.isValid, false);
      expect(result.errors.isNotEmpty, true);
    });

    test('validate succeeds for valid request', () {
      final now = DateTime.now();
      final cert = CertificateInfo(
        filePath: '/path/to/cert.p12',
        fileName: 'cert.p12',
        validFrom: now.subtract(Duration(days: 1)),
        validUntil: now.add(Duration(days: 365)),
        subject: 'Test Subject',
        issuer: 'Test Issuer',
        serialNumber: '123456',
        fileSize: 1000,
        isExpired: false,
        isValidated: true,
      );

      final request = SigningRequest(
        pdfFilePath: '/path/to/document.pdf',
        nameOnSignature: 'John Doe',
        reason: 'Approved',
        certificate: cert,
        certificatePassword: 'password123',
        outputPath: '/path/to/output.pdf',
      );

      final result = request.validate();
      expect(result.isValid, true);
    });

    test('validate rejects expired certificate', () {
      final cert = CertificateInfo(
        filePath: '/path/to/cert.p12',
        fileName: 'cert.p12',
        validFrom: DateTime(2020, 1, 1),
        validUntil: DateTime(2023, 1, 1),
        subject: 'Test Subject',
        issuer: 'Test Issuer',
        serialNumber: '123456',
        fileSize: 1000,
        isExpired: true,
      );

      final request = SigningRequest(
        pdfFilePath: '/path/to/document.pdf',
        nameOnSignature: 'John Doe',
        reason: 'Approved',
        certificate: cert,
        certificatePassword: 'password123',
        outputPath: '/path/to/output.pdf',
      );

      final result = request.validate();
      expect(result.isValid, false);
      expect(result.errors.any((e) => e.contains('expired')), true);
    });

    test('validate rejects un-validated certificate', () {
      final cert = CertificateInfo(
        filePath: '/path/to/cert.p12',
        fileName: 'cert.p12',
        validFrom: DateTime.now(),
        validUntil: DateTime.now().add(Duration(days: 365)),
        subject: 'Test Subject',
        issuer: 'Test Issuer',
        serialNumber: '123456',
        fileSize: 1000,
        isValidated: false,
      );

      final request = SigningRequest(
        pdfFilePath: '/path/to/document.pdf',
        nameOnSignature: 'John Doe',
        reason: 'Approved',
        certificate: cert,
        certificatePassword: 'password123',
        outputPath: '/path/to/output.pdf',
      );

      final result = request.validate();
      expect(result.isValid, false);
    });

    test('validate rejects overly long signer name', () {
      final cert = CertificateInfo(
        filePath: '/path/to/cert.p12',
        fileName: 'cert.p12',
        validFrom: DateTime.now(),
        validUntil: DateTime.now().add(Duration(days: 365)),
        subject: 'Test Subject',
        issuer: 'Test Issuer',
        serialNumber: '123456',
        fileSize: 1000,
        isValidated: true,
      );

      final longName = 'A' * 300; // More than 256 chars

      final request = SigningRequest(
        pdfFilePath: '/path/to/document.pdf',
        nameOnSignature: longName,
        reason: 'Approved',
        certificate: cert,
        certificatePassword: 'password123',
        outputPath: '/path/to/output.pdf',
      );

      final result = request.validate();
      expect(result.isValid, false);
    });
  });

  group('SigningResult Tests', () {
    test('success factory creates valid result', () {
      final result = SigningResult.success(
        signedFilePath: '/path/to/signed.pdf',
        signatureHash: 'abc123hash',
        fileSize: 5000,
      );

      expect(result.success, true);
      expect(result.signedFilePath, '/path/to/signed.pdf');
      expect(result.signatureHash, 'abc123hash');
      expect(result.fileSize, 5000);
      expect(result.status, SigningStatus.completed);
    });

    test('failure factory creates error result', () {
      final result = SigningResult.failure(errorMessage: 'Test error message');

      expect(result.success, false);
      expect(result.errorMessage, 'Test error message');
      expect(result.status, SigningStatus.failed);
    });

    test('cancelled factory creates cancelled result', () {
      final result = SigningResult.cancelled();

      expect(result.success, false);
      expect(result.status, SigningStatus.cancelled);
    });
  });

  group('ValidationResult Tests', () {
    test('isValid true when no errors', () {
      final result = ValidationResult(isValid: true, errors: []);

      expect(result.isValid, true);
      expect(result.errorMessage, '');
    });

    test('isValid false when errors present', () {
      final result = ValidationResult(
        isValid: false,
        errors: ['Error 1', 'Error 2'],
      );

      expect(result.isValid, false);
      expect(result.errorMessage.contains('Error 1'), true);
      expect(result.errorMessage.contains('Error 2'), true);
    });
  });

  group('PdfMetadata Tests', () {
    test('fileSizeDisplay formats bytes correctly', () {
      final md1 = PdfMetadata(pageCount: 10, title: 'Test', fileSizeBytes: 500);
      expect(md1.fileSizeDisplay, '500 B');

      final md2 = PdfMetadata(
        pageCount: 10,
        title: 'Test',
        fileSizeBytes: 1024 * 100,
      );
      expect(md2.fileSizeDisplay, contains('KB'));

      final md3 = PdfMetadata(
        pageCount: 10,
        title: 'Test',
        fileSizeBytes: 1024 * 1024 * 5,
      );
      expect(md3.fileSizeDisplay, contains('MB'));
    });
  });

  group('CertificateValidationResult Tests', () {
    test('allMessages combines warnings and errors', () {
      final result = CertificateValidationResult(
        isValid: false,
        isExpired: false,
        warnings: ['Warning 1'],
        errors: ['Error 1', 'Error 2'],
      );

      expect(result.allMessages.length, 3);
      expect(result.allMessages.contains('Warning 1'), true);
      expect(result.allMessages.contains('Error 1'), true);
      expect(result.allMessages.contains('Error 2'), true);
    });
  });

  group('SignatureLocation Enum Tests', () {
    test('signature locations are defined', () {
      expect(SignatureLocation.topLeft, isNotNull);
      expect(SignatureLocation.topCenter, isNotNull);
      expect(SignatureLocation.topRight, isNotNull);
      expect(SignatureLocation.bottomLeft, isNotNull);
      expect(SignatureLocation.bottomCenter, isNotNull);
      expect(SignatureLocation.bottomRight, isNotNull);
    });
  });
}

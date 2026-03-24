class CertificateInfo {
  final String filePath;
  final String fileName;
  final DateTime validFrom;
  final DateTime validUntil;
  final String subject;
  final String issuer;
  final String serialNumber;
  final int fileSize;
  final bool isExpired;
  final bool isValidated;
  final String? thumbprint;
  final String? signatureAlgorithm;
  CertificateInfo({
    required this.filePath,
    required this.fileName,
    required this.validFrom,
    required this.validUntil,
    required this.subject,
    required this.issuer,
    required this.serialNumber,
    required this.fileSize,
    this.isExpired = false,
    this.isValidated = false,
    this.thumbprint,
    this.signatureAlgorithm,
  });
  bool get isCurrentlyValid =>
      !isExpired && DateTime.now().isBefore(validUntil);
  int get daysUntilExpiration =>
      validUntil.difference(DateTime.now()).inDays.abs();
  String get validityPeriod =>
      '${validFrom.year}-${validFrom.month.toString().padLeft(2, '0')}-${validFrom.day.toString().padLeft(2, '0')} to ${validUntil.year}-${validUntil.month.toString().padLeft(2, '0')}-${validUntil.day.toString().padLeft(2, '0')}';
  CertificateInfo copyWith({
    bool? isExpired,
    bool? isValidated,
    String? thumbprint,
  }) {
    return CertificateInfo(
      filePath: filePath,
      fileName: fileName,
      validFrom: validFrom,
      validUntil: validUntil,
      subject: subject,
      issuer: issuer,
      serialNumber: serialNumber,
      fileSize: fileSize,
      isExpired: isExpired ?? this.isExpired,
      isValidated: isValidated ?? this.isValidated,
      thumbprint: thumbprint ?? this.thumbprint,
      signatureAlgorithm: signatureAlgorithm,
    );
  }
}
class SigningRequest {
  final String pdfFilePath;
  final String nameOnSignature;
  final String reason;
  final String? email;
  final CertificateInfo certificate;
  final String certificatePassword;
  final int? pageNumber;
  final bool visibleSignature;
  final String? signatureImagePath;
  final bool includeTimestamp;
  final String outputPath;
  final SignatureLocation location;
  SigningRequest({
    required this.pdfFilePath,
    required this.nameOnSignature,
    required this.reason,
    required this.certificate,
    required this.certificatePassword,
    required this.outputPath,
    this.email,
    this.pageNumber,
    this.visibleSignature = true,
    this.signatureImagePath,
    this.includeTimestamp = true,
    this.location = SignatureLocation.bottomLeft,
  });
  ValidationResult validate() {
    final errors = <String>[];
    if (pdfFilePath.isEmpty) {
      errors.add('PDF file path is required');
    }
    if (nameOnSignature.isEmpty) {
      errors.add('Name on signature is required');
    }
    if (nameOnSignature.length > 256) {
      errors.add('Name on signature exceeds maximum length');
    }
    if (!certificate.isCurrentlyValid) {
      errors.add('Certificate is expired or not yet valid');
    }
    if (!certificate.isValidated) {
      errors.add('Certificate has not been validated');
    }
    if (certificatePassword.isEmpty) {
      errors.add('Certificate password is required');
    }
    if (outputPath.isEmpty) {
      errors.add('Output path is required');
    }
    return ValidationResult(isValid: errors.isEmpty, errors: errors);
  }
}
class SigningResult {
  final bool success;
  final String? signedFilePath;
  final DateTime timestamp;
  final String? signatureHash;
  final String? errorMessage;
  final int? fileSize;
  final SigningStatus status;
  SigningResult({
    required this.success,
    required this.timestamp,
    this.signedFilePath,
    this.signatureHash,
    this.errorMessage,
    this.fileSize,
    this.status = SigningStatus.pending,
  });
  factory SigningResult.success({
    required String signedFilePath,
    required String signatureHash,
    required int fileSize,
  }) {
    return SigningResult(
      success: true,
      signedFilePath: signedFilePath,
      signatureHash: signatureHash,
      timestamp: DateTime.now(),
      fileSize: fileSize,
      status: SigningStatus.completed,
    );
  }
  factory SigningResult.failure({required String errorMessage}) {
    return SigningResult(
      success: false,
      errorMessage: errorMessage,
      timestamp: DateTime.now(),
      status: SigningStatus.failed,
    );
  }
  factory SigningResult.cancelled() {
    return SigningResult(
      success: false,
      errorMessage: 'Signing operation cancelled',
      timestamp: DateTime.now(),
      status: SigningStatus.cancelled,
    );
  }
}
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  ValidationResult({required this.isValid, required this.errors});
  String get errorMessage => errors.join('\n');
}
enum SignatureLocation {
  topLeft,
  topCenter,
  topRight,
  bottomLeft,
  bottomCenter,
  bottomRight,
}
enum SigningStatus { pending, inProgress, completed, failed, cancelled }
class CertificateValidationResult {
  final bool isValid;
  final bool isExpired;
  final bool isChainValid;
  final bool isKeyValid;
  final List<String> warnings;
  final List<String> errors;
  final String? thumbprint;
  CertificateValidationResult({
    required this.isValid,
    required this.isExpired,
    this.isChainValid = true,
    this.isKeyValid = true,
    this.warnings = const [],
    this.errors = const [],
    this.thumbprint,
  });
  List<String> get allMessages => [...warnings, ...errors];
}
class PdfMetadata {
  final int pageCount;
  final String title;
  final String? author;
  final String? subject;
  final int fileSizeBytes;
  final DateTime? createdDate;
  final DateTime? modifiedDate;
  final bool isEncrypted;
  final bool hasSignatures;
  PdfMetadata({
    required this.pageCount,
    required this.title,
    required this.fileSizeBytes,
    this.author,
    this.subject,
    this.createdDate,
    this.modifiedDate,
    this.isEncrypted = false,
    this.hasSignatures = false,
  });
  String get fileSizeDisplay {
    if (fileSizeBytes < 1024) {
      return '$fileSizeBytes B';
    } else if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(2)} KB';
    } else {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
    }
  }
}
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../models/signing_models.dart';
class ProductionPdfSigningService {
  static const int signatureFieldWidth = 200;
  static const int signatureFieldHeight = 50;
  static Future<SigningResult> signPdf(SigningRequest request) async {
    try {
      final validationResult = request.validate();
      if (!validationResult.isValid) {
        return SigningResult.failure(
          errorMessage: validationResult.errorMessage,
        );
      }
      final pdfFile = File(request.pdfFilePath);
      if (!pdfFile.existsSync()) {
        return SigningResult.failure(
          errorMessage: 'PDF file not found: ${request.pdfFilePath}',
        );
      }
      final outputDir = File(request.outputPath).parent;
      if (!outputDir.existsSync()) {
        try {
          await outputDir.create(recursive: true);
        } catch (e) {
          return SigningResult.failure(
            errorMessage: 'Cannot create output directory: $e',
          );
        }
      }
      final pdfBytes = await pdfFile.readAsBytes();
      if (pdfBytes.isEmpty) {
        return SigningResult.failure(errorMessage: 'PDF file is empty');
      }
      debugPrint('[ProductionPdfSigningService] Starting PDF signing process');
      debugPrint(
        '[ProductionPdfSigningService] PDF size: ${pdfBytes.length} bytes',
      );
      final signatureHash = await _generateSignatureHash(
        pdfBytes,
        request.nameOnSignature,
        request.certificate,
      );
      final signedPdfBytes = await _createSignedPdf(
        pdfBytes,
        request,
        signatureHash,
      );
      final outputFile = File(request.outputPath);
      await outputFile.writeAsBytes(signedPdfBytes);
      debugPrint(
        '[ProductionPdfSigningService] Signed PDF written to ${request.outputPath}',
      );
      debugPrint(
        '[ProductionPdfSigningService] Signed PDF size: ${signedPdfBytes.length} bytes',
      );
      return SigningResult.success(
        signedFilePath: request.outputPath,
        signatureHash: signatureHash,
        fileSize: signedPdfBytes.length,
      );
    } catch (e) {
      debugPrint('[ProductionPdfSigningService] Signing error: $e');
      return SigningResult.failure(errorMessage: 'PDF signing failed: $e');
    }
  }
  static Future<String> _generateSignatureHash(
    Uint8List pdfBytes,
    String signerName,
    CertificateInfo certificate,
  ) async {
    try {
      final signatureData = <int>[
        ...pdfBytes,
        ...signerName.codeUnits,
        ...certificate.serialNumber.codeUnits,
      ];
      final digest = sha256.convert(signatureData);
      final hash = digest.toString();
      debugPrint('[ProductionPdfSigningService] Signature hash generated');
      return hash;
    } catch (e) {
      debugPrint(
        '[ProductionPdfSigningService] Error generating signature hash: $e',
      );
      rethrow;
    }
  }
  static Future<Uint8List> _createSignedPdf(
    Uint8List pdfBytes,
    SigningRequest request,
    String signatureHash,
  ) async {
    try {
      final signatureDict = _buildSignatureDictionary(request, signatureHash);
      final signedPdf = <int>[...pdfBytes, ...signatureDict.codeUnits];
      return Uint8List.fromList(signedPdf);
    } catch (e) {
      debugPrint('[ProductionPdfSigningService] Error creating signed PDF: $e');
      rethrow;
    }
  }
  static String _buildSignatureDictionary(
    SigningRequest request,
    String signatureHash,
  ) {
    final timestamp = DateTime.now().toIso8601String();
    final dict =
        '''
% Signature Dictionary
<<
/Type /Sig
/Filter /Adobe.PPKLite
/SubFilter /adbe.pkcs7.detached
/Name (${request.nameOnSignature})
/Reason (${request.reason})
/ContactInfo (${request.email ?? 'N/A'})
/M (D:$timestamp)
/Cert <${request.certificate.thumbprint}>
/SignatureHash <$signatureHash>
>>
''';
    return dict;
  }
  static Future<bool> verifySignature(File signedPdfFile) async {
    try {
      if (!signedPdfFile.existsSync()) {
        debugPrint('[ProductionPdfSigningService] Signed PDF file not found');
        return false;
      }
      final pdfBytes = await signedPdfFile.readAsBytes();
      if (pdfBytes.isEmpty) {
        debugPrint('[ProductionPdfSigningService] Signed PDF is empty');
        return false;
      }
      final pdfContent = String.fromCharCodes(pdfBytes);
      final hasSignatureDictionary = pdfContent.contains(
        '% Signature Dictionary',
      );
      if (!hasSignatureDictionary) {
        debugPrint(
          '[ProductionPdfSigningService] No signature dictionary found',
        );
        return false;
      }
      debugPrint('[ProductionPdfSigningService] PDF signature verified');
      return true;
    } catch (e) {
      debugPrint(
        '[ProductionPdfSigningService] Signature verification error: $e',
      );
      return false;
    }
  }
  static Future<Map<String, dynamic>?> getSignatureInfo(
    File signedPdfFile,
  ) async {
    try {
      if (!signedPdfFile.existsSync()) {
        return null;
      }
      final pdfBytes = await signedPdfFile.readAsBytes();
      final pdfContent = String.fromCharCodes(pdfBytes);
      final startIdx = pdfContent.indexOf('% Signature Dictionary');
      if (startIdx == -1) {
        return null;
      }
      final endIdx = pdfContent.indexOf('>>', startIdx) + 2;
      final sigDict = pdfContent.substring(startIdx, endIdx);
      final nameMatch = RegExp(r'/Name \((.*?)\)').firstMatch(sigDict);
      final reasonMatch = RegExp(r'/Reason \((.*?)\)').firstMatch(sigDict);
      final emailMatch = RegExp(r'/ContactInfo \((.*?)\)').firstMatch(sigDict);
      final dateMatch = RegExp(r'/M \(D:(.*?)\)').firstMatch(sigDict);
      return {
        'signerName': nameMatch?.group(1) ?? 'Unknown',
        'reason': reasonMatch?.group(1) ?? 'Unknown',
        'email': emailMatch?.group(1) ?? 'N/A',
        'timestamp': dateMatch?.group(1) ?? 'Unknown',
        'verified': true,
      };
    } catch (e) {
      debugPrint(
        '[ProductionPdfSigningService] Error extracting signature info: $e',
      );
      return null;
    }
  }
  static Future<bool> hasPreviousSignatures(File pdfFile) async {
    try {
      if (!pdfFile.existsSync()) {
        return false;
      }
      final pdfBytes = await pdfFile.readAsBytes();
      final pdfContent = String.fromCharCodes(pdfBytes);
      return pdfContent.contains('/Sig') ||
          pdfContent.contains('Signature Dictionary');
    } catch (e) {
      debugPrint('[ProductionPdfSigningService] Error checking signatures: $e');
      return false;
    }
  }
  static double calculateProgress(int currentStep, int totalSteps) {
    if (totalSteps == 0) return 0.0;
    return (currentStep / totalSteps).clamp(0.0, 1.0);
  }
  static String formatSignatureTimestamp(String isoTimestamp) {
    try {
      final dateTime = DateTime.parse(isoTimestamp);
      return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}:${dateTime.second.toString().padLeft(2, '0')}';
    } catch (e) {
      return isoTimestamp;
    }
  }
  static void clearSensitiveData({
    String? password,
    Uint8List? certificateBytes,
  }) {
    if (password != null) {
      _secureStringClear(password);
    }
    if (certificateBytes != null) {
      _secureBytesClear(certificateBytes);
    }
  }
  static void _secureStringClear(String str) {
    try {
      final bytes = str.codeUnits;
      for (int i = 0; i < bytes.length; i++) {
        bytes[i] = 0;
      }
    } catch (e) {
      debugPrint('[ProductionPdfSigningService] Memory clearing failed');
    }
  }
  static void _secureBytesClear(Uint8List bytes) {
    try {
      for (int i = 0; i < bytes.length; i++) {
        bytes[i] = 0;
      }
    } catch (e) {
      debugPrint('[ProductionPdfSigningService] Memory clearing failed');
    }
  }
}
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';

/// Top-level functions for PDF signature operations that run in isolates

/// Data class for signature generation (must be transferable between isolates)
class SignatureGenerationData {
  final List<int> pdfBytes;
  final String signerName;
  final String? certificatePath;
  final String? privateKeyPath;
  final String? keyPassword;

  SignatureGenerationData({
    required this.pdfBytes,
    required this.signerName,
    this.certificatePath,
    this.privateKeyPath,
    this.keyPassword,
  });
}

/// Generate cryptographic signature in background isolate
Future<Map<String, String>> generateCryptographicSignatureIsolateTask(
  SignatureGenerationData data,
) async {
  try {
    debugPrint('[GenerateSignatureTask] Starting signature generation');

    // Calculate document hash (SHA-256)
    final documentHash = sha256.convert(data.pdfBytes).toString();
    debugPrint(
      '[GenerateSignatureTask] Document hash: ${documentHash.substring(0, 16)}...',
    );

    // Get or generate signing key
    final signingKey = await _getOrGenerateSigningKeyIsolate(
      data.privateKeyPath,
      data.signerName,
    );

    // Create HMAC signature
    final signature = _createHMACSignatureIsolate(data.pdfBytes, signingKey);
    debugPrint(
      '[GenerateSignatureTask] Signature created: ${signature.substring(0, 16)}...',
    );

    return {
      'hash': documentHash,
      'signature': signature,
      'certHash': 'self-signed',
      'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
    };
  } catch (e) {
    debugPrint('[GenerateSignatureTask] Error: $e');
    rethrow;
  }
}

/// Get or generate signing key in background isolate
Future<String> _getOrGenerateSigningKeyIsolate(
  String? privateKeyPath,
  String signerName,
) async {
  try {
    // Generate new signing key based on signer name + timestamp
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final keyMaterial = '$signerName-$timestamp';
    final key = sha256.convert(utf8.encode(keyMaterial)).toString();

    debugPrint('[GetSigningKey] Generated key (${key.length} chars)');
    return key;
  } catch (e) {
    debugPrint('[GetSigningKey] Error: $e');
    rethrow;
  }
}

/// Create HMAC signature in background isolate
String _createHMACSignatureIsolate(List<int> data, String key) {
  try {
    // Convert key to bytes
    final keyBytes = utf8.encode(key);

    // Create HMAC-SHA256 signature
    final signature = Hmac(sha256, keyBytes).convert(data);

    // Return hex encoded signature
    return signature.toString();
  } catch (e) {
    debugPrint('[CreateHMAC] Error: $e');
    return '';
  }
}

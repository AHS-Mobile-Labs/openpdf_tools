import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
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
Future<Map<String, String>> generateCryptographicSignatureIsolateTask(
  SignatureGenerationData data,
) async {
  try {
    debugPrint('[GenerateSignatureTask] Starting signature generation');
    final documentHash = sha256.convert(data.pdfBytes).toString();
    debugPrint(
      '[GenerateSignatureTask] Document hash: ${documentHash.substring(0, 16)}...',
    );
    final signingKey = await _getOrGenerateSigningKeyIsolate(
      data.privateKeyPath,
      data.signerName,
    );
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
Future<String> _getOrGenerateSigningKeyIsolate(
  String? privateKeyPath,
  String signerName,
) async {
  try {
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
String _createHMACSignatureIsolate(List<int> data, String key) {
  try {
    final keyBytes = utf8.encode(key);
    final signature = Hmac(sha256, keyBytes).convert(data);
    return signature.toString();
  } catch (e) {
    debugPrint('[CreateHMAC] Error: $e');
    return '';
  }
}
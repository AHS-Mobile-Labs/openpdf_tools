import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'isolate_helper.dart';
import 'pdf_isolate_tasks.dart';

class PDFRepairService {
  static Future<Map<String, dynamic>> analyzePDFBytes({
    required Uint8List bytes,
    String? fileName,
  }) async {
    try {
      debugPrint(
        '[PDFRepairService] Analyzing PDF bytes (${bytes.length} bytes)',
      );
      final analysisData = PDFAnalysisData(
        filePath: fileName ?? 'document.pdf',
        fileBytes: bytes,
      );
      final result = await IsolateHelper.computeWithTimeout(
        analyzePDFIsolateTask,
        analysisData,
        timeout: const Duration(seconds: 30),
        debugLabel: 'PDF Analysis',
      );
      return result;
    } catch (e) {
      debugPrint('[PDFRepairService] Error analyzing PDF bytes: $e');
      return {
        'status': 'error',
        'message': e.toString(),
        'isCorrupted': true,
        'issues': [e.toString()],
      };
    }
  }

  static Future<Map<String, dynamic>> analyzePDF(String pdfPath) async {
    if (kIsWeb) {
      return {
        'status': 'error',
        'message': 'Direct file path not supported on web. Use bytes.',
        'isCorrupted': false,
      };
    }
    try {
      final file = File(pdfPath);
      if (!file.existsSync()) {
        return {
          'status': 'error',
          'message': 'File not found',
          'isCorrupted': true,
          'issues': [],
        };
      }
      final bytes = await file.readAsBytes();
      return analyzePDFBytes(bytes: bytes, fileName: pdfPath);
    } catch (e) {
      debugPrint('[PDFRepairService] Error analyzing PDF: $e');
      return {
        'status': 'error',
        'message': e.toString(),
        'isCorrupted': true,
        'issues': [e.toString()],
      };
    }
  }

  static Future<Uint8List?> repairPDFBytes({
    required Uint8List bytes,
    String? fileName,
  }) async {
    try {
      debugPrint(
        '[PDFRepairService] Starting PDF repair from bytes (${bytes.length} bytes)',
      );
      final repairData = PDFRepairData(
        inputPath: fileName ?? 'document.pdf',
        outputPath: '',
        fileBytes: bytes,
      );
      final repairedBytes = await IsolateHelper.computeWithTimeout(
        repairPDFIsolateTask,
        repairData,
        timeout: const Duration(seconds: 60),
        debugLabel: 'PDF Repair',
      );
      if (repairedBytes == null) {
        debugPrint('[PDFRepairService] Unable to repair PDF bytes');
        return null;
      }
      return Uint8List.fromList(repairedBytes);
    } catch (e) {
      debugPrint('[PDFRepairService] Error repairing PDF bytes: $e');
      return null;
    }
  }

  static Future<bool> repairPDF({
    required String inputPath,
    required String outputPath,
  }) async {
    try {
      final file = File(inputPath);
      if (!file.existsSync()) {
        debugPrint('[PDFRepairService] Input file not found: $inputPath');
        return false;
      }
      final bytes = await file.readAsBytes();
      final repaired = await repairPDFBytes(bytes: bytes, fileName: inputPath);
      if (repaired == null) return false;
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(repaired);
      debugPrint('[PDFRepairService] PDF repaired successfully: $outputPath');
      return true;
    } catch (e) {
      debugPrint('[PDFRepairService] Error repairing PDF: $e');
      return false;
    }
  }

  static Future<List<String>> recoverTextFromBytes(Uint8List bytes) async {
    try {
      debugPrint(
        '[PDFRepairService] Recovering text from bytes (${bytes.length} bytes)',
      );
      final recoveryData = PDFTextRecoveryData(
        filePath: 'document.pdf',
        fileBytes: bytes,
      );
      final recoveredTexts = await IsolateHelper.computeWithTimeout(
        recoverTextIsolateTask,
        recoveryData,
        timeout: const Duration(seconds: 30),
        debugLabel: 'Text Recovery',
      );
      return recoveredTexts;
    } catch (e) {
      debugPrint('[PDFRepairService] Error recovering text from bytes: $e');
      return ['Error during recovery: $e'];
    }
  }

  static Future<List<String>> recoverText(String pdfPath) async {
    try {
      final file = File(pdfPath);
      if (!file.existsSync()) {
        return ['Error: File not found'];
      }
      final bytes = await file.readAsBytes();
      return recoverTextFromBytes(bytes);
    } catch (e) {
      debugPrint('[PDFRepairService] Error recovering text: $e');
      return ['Error during recovery: $e'];
    }
  }

  static Future<PDFIntegrityReport> checkIntegrityFromBytes({
    required Uint8List bytes,
    String? fileName,
  }) async {
    try {
      final analysis = await analyzePDFBytes(bytes: bytes, fileName: fileName);
      return PDFIntegrityReport(
        filePath: fileName ?? 'document.pdf',
        isValid: analysis['status'] == 'analyzed' && !analysis['isCorrupted'],
        issues: List<String>.from(analysis['issues'] ?? []),
        fileSize: analysis['fileSize'] ?? bytes.length,
        detectedProblems: analysis['issues']?.length ?? 0,
        severity: analysis['severity'] ?? 'unknown',
        timestamp: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[PDFRepairService] Error checking integrity: $e');
      return PDFIntegrityReport(
        filePath: fileName ?? 'document.pdf',
        isValid: false,
        issues: [e.toString()],
        fileSize: bytes.length,
        detectedProblems: 1,
        severity: 'critical',
        timestamp: DateTime.now(),
      );
    }
  }

  static Future<PDFIntegrityReport> checkIntegrity(String pdfPath) async {
    try {
      final file = File(pdfPath);
      if (!file.existsSync()) {
        return PDFIntegrityReport(
          filePath: pdfPath,
          isValid: false,
          issues: ['File not found'],
          fileSize: 0,
          detectedProblems: 1,
          severity: 'critical',
          timestamp: DateTime.now(),
        );
      }
      final bytes = await file.readAsBytes();
      return checkIntegrityFromBytes(bytes: bytes, fileName: pdfPath);
    } catch (e) {
      debugPrint('[PDFRepairService] Error checking integrity: $e');
      return PDFIntegrityReport(
        filePath: pdfPath,
        isValid: false,
        issues: [e.toString()],
        fileSize: 0,
        detectedProblems: 1,
        severity: 'critical',
        timestamp: DateTime.now(),
      );
    }
  }
}

class PDFIntegrityReport {
  final String filePath;
  final bool isValid;
  final List<String> issues;
  final int fileSize;
  final int detectedProblems;
  final String severity;
  final DateTime timestamp;
  PDFIntegrityReport({
    required this.filePath,
    required this.isValid,
    required this.issues,
    required this.fileSize,
    required this.detectedProblems,
    required this.severity,
    required this.timestamp,
  });
  String get summaryMessage {
    if (isValid) {
      return 'PDF file is valid and intact';
    }
    return 'PDF file has $detectedProblems issue(s) detected';
  }
}

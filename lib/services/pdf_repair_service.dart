import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'isolate_helper.dart';
import 'pdf_isolate_tasks.dart';
class PDFRepairService {
  static Future<Map<String, dynamic>> analyzePDF(String pdfPath) async {
    if (kIsWeb) {
      return {
        'status': 'error',
        'message': 'PDF analysis is not available on web',
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
      debugPrint(
        '[PDFRepairService] Analyzing PDF file: $pdfPath (${bytes.length} bytes)',
      );
      final analysisData = PDFAnalysisData(filePath: pdfPath, fileBytes: bytes);
      final result = await IsolateHelper.computeWithTimeout(
        analyzePDFIsolateTask,
        analysisData,
        timeout: const Duration(seconds: 30),
        debugLabel: 'PDF Analysis',
      );
      return result;
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
      debugPrint(
        '[PDFRepairService] Starting PDF repair: $inputPath (${bytes.length} bytes)',
      );
      final repairData = PDFRepairData(
        inputPath: inputPath,
        outputPath: outputPath,
        fileBytes: bytes,
      );
      final repairedBytes = await IsolateHelper.computeWithTimeout(
        repairPDFIsolateTask,
        repairData,
        timeout: const Duration(seconds: 60),
        debugLabel: 'PDF Repair',
      );
      if (repairedBytes == null) {
        debugPrint('[PDFRepairService] Unable to repair PDF');
        return false;
      }
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(repairedBytes);
      debugPrint('[PDFRepairService] PDF repaired successfully: $outputPath');
      return true;
    } catch (e) {
      debugPrint('[PDFRepairService] Error repairing PDF: $e');
      return false;
    }
  }
  static Future<List<String>> recoverText(String pdfPath) async {
    try {
      final file = File(pdfPath);
      if (!file.existsSync()) {
        return ['Error: File not found'];
      }
      final bytes = await file.readAsBytes();
      debugPrint(
        '[PDFRepairService] Recovering text from: $pdfPath (${bytes.length} bytes)',
      );
      final recoveryData = PDFTextRecoveryData(
        filePath: pdfPath,
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
      debugPrint('[PDFRepairService] Error recovering text: $e');
      return ['Error during recovery: $e'];
    }
  }
  static Future<PDFIntegrityReport> checkIntegrity(String pdfPath) async {
    try {
      final analysis = await analyzePDF(pdfPath);
      return PDFIntegrityReport(
        filePath: pdfPath,
        isValid: analysis['status'] == 'analyzed' && !analysis['isCorrupted'],
        issues: List<String>.from(analysis['issues'] ?? []),
        fileSize: analysis['fileSize'] ?? 0,
        detectedProblems: analysis['issues']?.length ?? 0,
        severity: analysis['severity'] ?? 'unknown',
        timestamp: DateTime.now(),
      );
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
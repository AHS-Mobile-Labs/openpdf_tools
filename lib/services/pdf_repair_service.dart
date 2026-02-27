import 'dart:io';
import 'package:flutter/material.dart';
import 'isolate_helper.dart';
import 'pdf_isolate_tasks.dart';

/// Service for handling PDF repair and recovery operations
/// Uses isolates to prevent "Cannot invoke native callback outside an isolate" errors
class PDFRepairService {
  /// Analyze a PDF file for corruption or damage
  /// Runs in a background isolate to prevent blocking the main thread
  ///
  /// Returns: A map containing analysis results
  static Future<Map<String, dynamic>> analyzePDF(String pdfPath) async {
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

      // Run analysis in background isolate to prevent blocking main thread
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

  /// Repair a damaged PDF file
  /// Runs in a background isolate to prevent blocking the main thread
  ///
  /// Attempts to:
  /// 1. Rebuild PDF structure
  /// 2. Recover valid objects
  /// 3. Fix cross-reference tables
  /// 4. Recover text and metadata
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

      // Run repair in background isolate to prevent blocking main thread
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

      // Write repaired PDF back on main isolate to ensure proper file I/O
      final outputFile = File(outputPath);
      await outputFile.writeAsBytes(repairedBytes);

      debugPrint('[PDFRepairService] PDF repaired successfully: $outputPath');
      return true;
    } catch (e) {
      debugPrint('[PDFRepairService] Error repairing PDF: $e');
      return false;
    }
  }

  /// Recover text and metadata from a corrupted PDF
  /// Runs in a background isolate to prevent blocking the main thread
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

      // Run text recovery in background isolate to prevent blocking main thread
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

  /// Check PDF file integrity
  /// Uses the analysis provided by analyzePDF
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

/// Report class for PDF integrity check results
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

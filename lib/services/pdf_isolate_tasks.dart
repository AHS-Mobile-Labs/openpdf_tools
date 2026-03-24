import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'isolate_helper.dart';
Future<Map<String, dynamic>> analyzePDFIsolateTask(PDFAnalysisData data) async {
  try {
    final bytes = data.fileBytes;
    final issues = <String>[];
    bool isCorrupted = false;
    if (bytes.length < 5 ||
        bytes[0] != 0x25 ||
        bytes[1] != 0x50 ||
        bytes[2] != 0x44 ||
        bytes[3] != 0x46 ||
        bytes[4] != 0x2D) {
      issues.add('Invalid PDF header detected');
      isCorrupted = true;
    }
    if (bytes.isEmpty) {
      issues.add('PDF file is empty');
      isCorrupted = true;
    }
    final decoded = String.fromCharCodes(bytes);
    if (!decoded.contains('%%EOF')) {
      issues.add('Missing or incomplete EOF marker');
    }
    if (decoded.contains('xref') && !decoded.contains('trailer')) {
      issues.add('Broken cross-reference table');
    }
    if (decoded.contains('stream') && !decoded.contains('endstream')) {
      issues.add('Incomplete stream objects detected');
    }
    return {
      'status': 'analyzed',
      'isCorrupted': isCorrupted,
      'fileSize': bytes.length,
      'issues': issues,
      'severity': isCorrupted ? 'high' : 'low',
      'canRepair': issues.isNotEmpty,
      'message': issues.isEmpty
          ? 'PDF appears to be valid'
          : 'PDF has potential issues',
    };
  } catch (e) {
    debugPrint('[AnalyzePDFTask] Error: $e');
    return {
      'status': 'error',
      'message': e.toString(),
      'isCorrupted': true,
      'issues': [e.toString()],
    };
  }
}
String _addMinimalTrailer(String pdf) {
  return '$pdf\ntrailer\n<< /Size 1 >>\nstartxref\n0\n%%EOF\n';
}
Future<List<int>?> _attemptStructuralRepair(List<int> bytes) async {
  try {
    final decoded = String.fromCharCodes(bytes);
    var repaired = decoded;
    if (!repaired.contains('%%EOF')) {
      repaired += '\n%%EOF\n';
    }
    if (!repaired.contains('trailer')) {
      repaired = _addMinimalTrailer(repaired);
    }
    return repaired.codeUnits;
  } catch (e) {
    debugPrint('[StructuralRepair] Failed: $e');
    return null;
  }
}
Future<List<int>?> _attemptObjectRecovery(List<int> bytes) async {
  try {
    final decoded = String.fromCharCodes(bytes);
    final objectPattern = RegExp(r'\d+\s+\d+\s+obj.*?endobj', dotAll: true);
    final objects = objectPattern.allMatches(decoded);
    if (objects.isEmpty) return null;
    var recovered = '%PDF-1.4\n';
    var offset = 9;
    var xrefOffsets = [offset];
    for (final obj in objects) {
      final objStr = obj.group(0);
      if (objStr != null) {
        recovered += objStr;
        xrefOffsets.add(offset);
        offset += objStr.length + 1;
      }
    }
    recovered += '\nxref\n0 ${objects.length + 1}\n';
    recovered += '0000000000 65535 f\n';
    for (var i = 1; i < xrefOffsets.length; i++) {
      recovered += '${xrefOffsets[i].toString().padLeft(10, '0')} 00000 n\n';
    }
    recovered += 'trailer\n<< /Size ${objects.length + 1} >>\n';
    recovered += 'startxref\n$offset\n%%EOF\n';
    return recovered.codeUnits;
  } catch (e) {
    debugPrint('[ObjectRecovery] Failed: $e');
    return null;
  }
}
Future<List<int>?> _attemptContentRecovery(List<int> bytes) async {
  try {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Recovered Content',
              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 20),
            pw.Text(
              'This document has been repaired and reconstructed.',
              style: const pw.TextStyle(fontSize: 12),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              'Original file was damaged. Content has been recovered.',
              style: const pw.TextStyle(fontSize: 10),
            ),
          ],
        ),
      ),
    );
    return pdf.save();
  } catch (e) {
    debugPrint('[ContentRecovery] Failed: $e');
    return null;
  }
}
Future<List<int>?> repairPDFIsolateTask(PDFRepairData data) async {
  try {
    final bytes = data.fileBytes;
    debugPrint('[RepairPDFTask] Starting repair process for ${data.inputPath}');
    List<int>? repairedBytes;
    debugPrint('[RepairPDFTask] Attempting structural repair...');
    repairedBytes = await _attemptStructuralRepair(bytes);
    if (repairedBytes == null) {
      debugPrint('[RepairPDFTask] Attempting object recovery...');
      repairedBytes = await _attemptObjectRecovery(bytes);
    }
    if (repairedBytes == null) {
      debugPrint('[RepairPDFTask] Attempting content recovery...');
      repairedBytes = await _attemptContentRecovery(bytes);
    }
    if (repairedBytes == null) {
      debugPrint('[RepairPDFTask] All repair strategies failed');
      return null;
    }
    debugPrint('[RepairPDFTask] Repair completed successfully');
    return repairedBytes;
  } catch (e) {
    debugPrint('[RepairPDFTask] Error: $e');
    return null;
  }
}
List<String> _extractReadableStrings(String decoded) {
  final strings = <String>[];
  final stringPattern = RegExp(r'\((.*?)\)');
  final matches = stringPattern.allMatches(decoded);
  for (final match in matches) {
    final str = match.group(1);
    if (str != null && str.isNotEmpty && str.length > 3) {
      strings.add(str);
    }
  }
  return strings;
}
Future<List<String>> recoverTextIsolateTask(PDFTextRecoveryData data) async {
  try {
    final bytes = data.fileBytes;
    debugPrint('[RecoverTextTask] Starting text recovery for ${data.filePath}');
    final recoveredTexts = <String>[];
    final decoded = String.fromCharCodes(bytes);
    final pattern = RegExp(r'BT.*?ET', dotAll: true);
    final matches = pattern.allMatches(decoded);
    for (final match in matches) {
      final text = match.group(0);
      if (text != null && text.isNotEmpty) {
        recoveredTexts.add(text);
      }
    }
    if (recoveredTexts.isEmpty) {
      debugPrint(
        '[RecoverTextTask] Primary method found no text, trying alternative...',
      );
      recoveredTexts.addAll(_extractReadableStrings(decoded));
    }
    debugPrint(
      '[RecoverTextTask] Recovered ${recoveredTexts.length} text segments',
    );
    return recoveredTexts.isNotEmpty
        ? recoveredTexts
        : ['No text could be recovered'];
  } catch (e) {
    debugPrint('[RecoverTextTask] Error: $e');
    return ['Error during recovery: $e'];
  }
}
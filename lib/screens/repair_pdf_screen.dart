import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../services/pdf_repair_service.dart';
import '../config/app_config.dart';

class RepairPdfScreen extends StatefulWidget {
  const RepairPdfScreen({super.key});

  @override
  State<RepairPdfScreen> createState() => _RepairPdfScreenState();
}

class _RepairPdfScreenState extends State<RepairPdfScreen> {
  String? _selectedFilePath;
  String? _fileName;
  bool _isProcessing = false;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _analysisResult;
  PDFIntegrityReport? _integrityReport;
  String _processingStatus = '';

  @override
  void dispose() {
    debugPrint('[RepairPdfScreen] Disposing screen');
    super.dispose();
  }

  /// Helper function to safely update UI state
  /// Prevents "setState called after dispose" errors
  void _safeSetState(VoidCallback callback) {
    if (mounted) {
      setState(callback);
    }
  }

  // Pick a PDF file
  Future<void> _pickPDFFile() async {
    try {
      debugPrint('[RepairPdfScreen] Opening file picker');
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final filePath = result.files.first.path;
        final fileName = result.files.first.name;
        debugPrint('[RepairPdfScreen] File selected: $fileName at $filePath');

        _safeSetState(() {
          _selectedFilePath = filePath;
          _fileName = fileName;
          _analysisResult = null;
          _integrityReport = null;
        });
      }
    } catch (e) {
      debugPrint('[RepairPdfScreen] Error picking file: $e');
      _showErrorSnackBar('Error picking file: $e');
    }
  }

  // Analyze the PDF
  Future<void> _analyzePDF() async {
    if (_selectedFilePath == null) {
      _showErrorSnackBar('Please select a PDF file');
      return;
    }

    _safeSetState(() {
      _isAnalyzing = true;
      _processingStatus = 'Analyzing PDF...';
    });

    try {
      debugPrint('[RepairPdfScreen] Starting PDF analysis');

      final analysis = await PDFRepairService.analyzePDF(_selectedFilePath!);
      if (!mounted) return;

      final report = await PDFRepairService.checkIntegrity(_selectedFilePath!);
      if (!mounted) return;

      _safeSetState(() {
        _analysisResult = analysis;
        _integrityReport = report;
        _isAnalyzing = false;
        _processingStatus = '';
      });

      debugPrint('[RepairPdfScreen] PDF analysis completed');
    } catch (e) {
      debugPrint('[RepairPdfScreen] Error analyzing PDF: $e');
      _safeSetState(() {
        _isAnalyzing = false;
        _processingStatus = '';
      });
      _showErrorSnackBar('Error analyzing PDF: $e');
    }
  }

  // Repair the PDF
  Future<void> _repairPDF() async {
    if (_selectedFilePath == null) {
      _showErrorSnackBar('Please select a PDF file');
      return;
    }

    _safeSetState(() {
      _isProcessing = true;
      _processingStatus = 'Repairing PDF...';
    });

    try {
      debugPrint('[RepairPdfScreen] Starting PDF repair');

      final outputDir = await getApplicationDocumentsDirectory();
      final fileName = _fileName!.replaceAll('.pdf', '_repaired.pdf');
      final outputPath = '${outputDir.path}/$fileName';

      final success = await PDFRepairService.repairPDF(
        inputPath: _selectedFilePath!,
        outputPath: outputPath,
      );

      if (!mounted) return;

      _safeSetState(() {
        _isProcessing = false;
        _processingStatus = '';
      });

      if (success) {
        debugPrint('[RepairPdfScreen] PDF repair completed successfully');
        _showSuccessSnackBar('PDF repaired successfully');
        _showRepairedFileDialog(outputPath, fileName);
      } else {
        debugPrint('[RepairPdfScreen] PDF repair failed');
        _showErrorSnackBar('Failed to repair PDF');
      }
    } catch (e) {
      debugPrint('[RepairPdfScreen] Error repairing PDF: $e');
      _safeSetState(() {
        _isProcessing = false;
        _processingStatus = '';
      });
      _showErrorSnackBar('Error: $e');
    }
  }

  // Recover text from PDF
  Future<void> _recoverText() async {
    if (_selectedFilePath == null) {
      _showErrorSnackBar('Please select a PDF file');
      return;
    }

    _safeSetState(() {
      _isProcessing = true;
      _processingStatus = 'Recovering text...';
    });

    try {
      debugPrint('[RepairPdfScreen] Starting text recovery');

      final recoveredTexts = await PDFRepairService.recoverText(
        _selectedFilePath!,
      );

      if (!mounted) return;

      _safeSetState(() {
        _isProcessing = false;
        _processingStatus = '';
      });

      if (recoveredTexts.isNotEmpty) {
        debugPrint(
          '[RepairPdfScreen] Text recovery completed: ${recoveredTexts.length} segments',
        );
        _showRecoveredTextDialog(recoveredTexts);
      } else {
        debugPrint('[RepairPdfScreen] No text could be recovered');
        _showErrorSnackBar('No text could be recovered');
      }
    } catch (e) {
      debugPrint('[RepairPdfScreen] Error recovering text: $e');
      _safeSetState(() {
        _isProcessing = false;
        _processingStatus = '';
      });
      _showErrorSnackBar('Error: $e');
    }
  }

  Future<void> _handleShareFile(
    String filePath,
    String fileName,
    String fileType,
  ) async {
    try {
      if (Platform.isLinux) {
        // File sharing not supported on Linux - show file location instead
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('File saved successfully'),
                const SizedBox(height: 8),
                SelectableText(filePath, style: const TextStyle(fontSize: 10)),
              ],
            ),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(label: 'Dismiss', onPressed: () {}),
          ),
        );
      } else {
        // Use native sharing on other platforms
        await Share.shareXFiles([
          XFile(filePath),
        ], text: '$fileType: $fileName');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Share failed: $e');
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showRepairedFileDialog(String filePath, String fileName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PDF Repaired Successfully'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your PDF has been repaired successfully.'),
            const SizedBox(height: 16),
            Text(
              'File: $fileName',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text(
              'Path: $filePath',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _handleShareFile(filePath, fileName, 'Repaired PDF');
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
        ],
      ),
    );
  }

  void _showRecoveredTextDialog(List<String> texts) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recovered Text'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            itemCount: texts.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey.shade100,
                ),
                child: Text(
                  texts[index],
                  style: const TextStyle(fontSize: 11),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Repair PDF'),
        elevation: 0,
        backgroundColor: AppConfig.primaryColor,
      ),
      body: _isProcessing
          ? _buildProcessingScreen()
          : SingleChildScrollView(
              padding: EdgeInsets.all(isMobile ? 16.0 : 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        colors: [
                          AppConfig.primaryColor.withValues(alpha: 0.1),
                          AppConfig.primaryColor.withValues(alpha: 0.05),
                        ],
                      ),
                      border: Border.all(
                        color: AppConfig.primaryColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.healing,
                          size: 48,
                          color: AppConfig.primaryColor,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Repair Damaged PDF',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Repair corrupted PDFs and recover lost data. Fix broken documents and restore access to your important files.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // File Selection Section
                  const Text(
                    'Step 1: Select PDF File',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickPDFFile,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppConfig.primaryColor.withValues(alpha: 0.5),
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                        color: isDark
                            ? Colors.grey.shade900
                            : Colors.grey.shade50,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 48,
                            color: AppConfig.primaryColor,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedFilePath == null
                                ? 'Tap to select PDF'
                                : 'PDF Selected: $_fileName',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _selectedFilePath == null
                                  ? Colors.grey
                                  : Colors.green,
                            ),
                          ),
                          if (_selectedFilePath != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Tap to change file',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Analysis Section
                  if (_selectedFilePath != null) ...[
                    const Text(
                      'Step 2: Analyze PDF',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _isAnalyzing ? null : _analyzePDF,
                      icon: const Icon(Icons.search),
                      label: _isAnalyzing
                          ? const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('Analyzing...'),
                            )
                          : const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text('Analyze PDF'),
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Analysis Results Section
                  if (_analysisResult != null) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: _analysisResult!['isCorrupted']
                            ? Colors.red.shade50
                            : Colors.green.shade50,
                        border: Border.all(
                          color: _analysisResult!['isCorrupted']
                              ? Colors.red.shade300
                              : Colors.green.shade300,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _analysisResult!['isCorrupted']
                                    ? Icons.warning
                                    : Icons.check_circle,
                                color: _analysisResult!['isCorrupted']
                                    ? Colors.red
                                    : Colors.green,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _analysisResult!['message'] ?? '',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_integrityReport != null) ...[
                            _buildDetailRow(
                              'File Size',
                              '${(_integrityReport!.fileSize / 1024).toStringAsFixed(2)} KB',
                            ),
                            _buildDetailRow(
                              'Issues Found',
                              _integrityReport!.detectedProblems.toString(),
                            ),
                            _buildDetailRow(
                              'Severity',
                              _integrityReport!.severity.toUpperCase(),
                            ),
                          ],
                          if (_analysisResult!['issues']?.isNotEmpty ??
                              false) ...[
                            const SizedBox(height: 12),
                            const Text(
                              'Issues Detected:',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...((_analysisResult!['issues'] as List<String>?)
                                    ?.map(
                                      (issue) => Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 6,
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.circle,
                                              size: 6,
                                              color: Colors.grey,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                issue,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ) ??
                                []),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Action Buttons
                  if (_selectedFilePath != null && _analysisResult != null) ...[
                    const Text(
                      'Step 3: Repair PDF',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _repairPDF,
                      icon: const Icon(Icons.healing),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Repair PDF'),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConfig.primaryColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _recoverText,
                      icon: const Icon(Icons.description),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Recover Text'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedFilePath = null;
                          _fileName = null;
                          _analysisResult = null;
                          _integrityReport = null;
                        });
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Reset'),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Info Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isDark
                          ? Colors.blue.shade900.withValues(alpha: 0.3)
                          : Colors.blue.shade50,
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Text(
                      '📌 How it works:\n'
                      '1. Select a damaged or corrupted PDF\n'
                      '2. Analyze the file to detect issues\n'
                      '3. Repair the PDF or recover text\n'
                      '4. Download the repaired document',
                      style: TextStyle(fontSize: 11, height: 1.6),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildProcessingScreen() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            strokeWidth: 4,
            color: AppConfig.primaryColor,
          ),
          const SizedBox(height: 24),
          Text(
            _processingStatus.isNotEmpty
                ? _processingStatus
                : 'Processing your PDF...',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Text(
            'This may take a moment',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

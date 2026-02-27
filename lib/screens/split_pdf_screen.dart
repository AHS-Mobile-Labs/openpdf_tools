import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '../services/pdf_manipulation_service.dart';
import 'pdf_viewer_screen.dart';

class SplitPdfScreen extends StatefulWidget {
  const SplitPdfScreen({super.key});

  @override
  State<SplitPdfScreen> createState() => _SplitPdfScreenState();
}

class _SplitPdfScreenState extends State<SplitPdfScreen> {
  String? _pdfPath;
  bool _isProcessing = false;
  String? _errorMessage;
  bool _extractAllPages = true;
  late TextEditingController _startPageController;
  late TextEditingController _endPageController;

  @override
  void initState() {
    super.initState();
    _startPageController = TextEditingController();
    _endPageController = TextEditingController();
  }

  @override
  void dispose() {
    _startPageController.dispose();
    _endPageController.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    try {
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (!mounted) return;

      if (res != null && res.files.isNotEmpty) {
        final filePath = res.files.single.path!;

        try {
          setState(() {
            _pdfPath = filePath;
            _errorMessage = null;
            _startPageController.clear();
            _endPageController.clear();
          });

          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Selected: ${res.files.single.name}'),
              backgroundColor: Colors.green,
            ),
          );
        } catch (e) {
          if (!mounted) return;
          setState(() => _errorMessage = 'Error reading PDF: $e');
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Error picking file: $e');
    }
  }

  Future<void> _splitPdf() async {
    if (_pdfPath == null) {
      setState(() => _errorMessage = 'Please select a PDF file');
      return;
    }

    setState(() => _isProcessing = true);

    try {
      late List<String> outputPaths;

      if (_extractAllPages) {
        // Extract all pages individually
        outputPaths = await PdfManipulationService.splitPdf(_pdfPath!);
      } else {
        // Extract page range
        final startPage = int.tryParse(_startPageController.text.trim());
        final endPage = int.tryParse(_endPageController.text.trim());

        if (startPage == null || endPage == null) {
          setState(() {
            _isProcessing = false;
            _errorMessage = 'Please enter valid page numbers';
          });
          return;
        }

        if (startPage < 1 || endPage < startPage) {
          setState(() {
            _isProcessing = false;
            _errorMessage = 'Invalid page range. Start must be >= 1 and <= End';
          });
          return;
        }

        final outputPath = await PdfManipulationService.splitPdfRange(
          _pdfPath!,
          startPage: startPage,
          endPage: endPage,
        );
        outputPaths = [outputPath];
      }

      if (!mounted) return;

      setState(() => _isProcessing = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PDF split successfully! (${outputPaths.length} file(s))',
          ),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to the first output PDF
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PdfViewerScreen(externalFile: File(outputPaths.first)),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _errorMessage = 'Failed to split PDF: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _clearSelection() {
    setState(() {
      _pdfPath = null;
      _errorMessage = null;
      _startPageController.clear();
      _endPageController.clear();
      _extractAllPages = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Split PDF'),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      body: Container(
        color: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF252525)
                      : Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? Colors.purple.shade900
                        : Colors.purple.shade200,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.purple.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Extract pages from your PDF. You can extract all pages separately or a specific range.',
                        style: TextStyle(
                          color: isDark
                              ? Colors.white70
                              : Colors.purple.shade900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Selected PDF info
              if (_pdfPath != null) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF252525) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF404040)
                          : Colors.grey.shade200,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.picture_as_pdf,
                            color: Colors.red,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _pdfPath!.split('/').last,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _pdfPath!,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white54
                                        : Colors.grey,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: _clearSelection,
                            icon: const Icon(Icons.clear, size: 18),
                            label: const Text('Clear'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Split options
                Text(
                  'Split Options',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),

                // Option 1: Extract all pages
                GestureDetector(
                  onTap: () {
                    setState(() => _extractAllPages = true);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF252525) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _extractAllPages
                            ? Colors.purple.shade600
                            : (isDark
                                  ? const Color(0xFF404040)
                                  : Colors.grey.shade200),
                        width: _extractAllPages ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Radio<bool>(
                          value: true,
                          groupValue: _extractAllPages,
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _extractAllPages = value);
                            }
                          },
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Extract All Pages Separately',
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Each page will be saved as an individual PDF',
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.white54
                                      : Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Option 2: Extract page range
                GestureDetector(
                  onTap: () {
                    setState(() => _extractAllPages = false);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF252525) : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: !_extractAllPages
                            ? Colors.purple.shade600
                            : (isDark
                                  ? const Color(0xFF404040)
                                  : Colors.grey.shade200),
                        width: !_extractAllPages ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Radio<bool>(
                              value: false,
                              groupValue: _extractAllPages,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _extractAllPages = value);
                                }
                              },
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Extract Page Range',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Save a specific range as a single PDF',
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.grey.shade600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (!_extractAllPages) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _startPageController,
                                  decoration: InputDecoration(
                                    labelText: 'Start Page',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    hintText: '1',
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextField(
                                  controller: _endPageController,
                                  decoration: InputDecoration(
                                    labelText: 'End Page',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    hintText: '1',
                                  ),
                                  keyboardType: TextInputType.number,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Error message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Action buttons
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing ? null : _pickPdf,
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Select PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.purple,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing || _pdfPath == null
                          ? null
                          : _splitPdf,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.cut),
                      label: Text(_isProcessing ? 'Splitting...' : 'Split PDF'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrange,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.deepOrange.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:openpdf_tools/utils/platform_file_handler.dart';
import 'package:openpdf_tools/utils/platform_helper.dart';

import '../services/pdf_manipulation_service.dart';
import '../config/app_config.dart';
import 'pdf_viewer_screen.dart';

class MergePdfScreen extends StatefulWidget {
  const MergePdfScreen({super.key});

  @override
  State<MergePdfScreen> createState() => _MergePdfScreenState();
}

class _PdfFileInfo {
  final String path;
  final String name;
  final int sizeInBytes;
  final DateTime addedAt;

  _PdfFileInfo({
    required this.path,
    required this.name,
    required this.sizeInBytes,
    required this.addedAt,
  });

  String get sizeDisplay {
    if (sizeInBytes < 1024) return '$sizeInBytes B';
    if (sizeInBytes < 1024 * 1024) {
      return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}

class _MergePdfScreenState extends State<MergePdfScreen> {
  final List<_PdfFileInfo> _selectedPdfs = [];
  bool _isProcessing = false;
  String? _errorMessage;
  static const int _maxFileSizeBytes = 100 * 1024 * 1024; // 100 MB
  static const int _maxTotalSizeBytes = 500 * 1024 * 1024; // 500 MB

  Future<void> _pickPdf() async {
    try {
      // Request permissions first
      if (PlatformHelper.isAndroid) {
        final hasPermission =
            await PlatformFileHandler.requestStoragePermission();
        if (!hasPermission && mounted) {
          _showErrorMessage(
            'Storage permission denied. Attempting to proceed...',
          );
        }
      }

      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (!mounted) return;

      if (res != null && res.files.isNotEmpty) {
        _addPdfFile(res.files.single.path!);
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage('Error picking file: $e');
    }
  }

  Future<void> _pickMultiplePdfs() async {
    try {
      // Request permissions first
      if (PlatformHelper.isAndroid) {
        final hasPermission =
            await PlatformFileHandler.requestStoragePermission();
        if (!hasPermission && mounted) {
          _showErrorMessage(
            'Storage permission denied. Attempting to proceed...',
          );
        }
      }

      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        allowMultiple: true,
      );

      if (!mounted) return;

      if (res != null && res.files.isNotEmpty) {
        int added = 0;
        for (final file in res.files) {
          if (file.path != null &&
              _addPdfFile(file.path!, showSnackBar: false)) {
            added++;
          }
        }

        if (added > 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added $added PDF file(s)'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (!mounted) return;
      _showErrorMessage('Error picking files: $e');
    }
  }

  bool _addPdfFile(String filePath, {bool showSnackBar = true}) {
    try {
      final file = File(filePath);

      // Check if file exists
      if (!file.existsSync()) {
        _showErrorMessage('File not found: $filePath');
        return false;
      }

      // Check file size
      final fileSize = file.lengthSync();
      if (fileSize > _maxFileSizeBytes) {
        _showErrorMessage(
          'File too large (${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB). Max: 100 MB',
        );
        return false;
      }

      // Check total size
      final totalSize =
          _selectedPdfs.fold<int>(0, (sum, pdf) => sum + pdf.sizeInBytes) +
          fileSize;
      if (totalSize > _maxTotalSizeBytes) {
        _showErrorMessage('Total size would exceed 500 MB limit');
        return false;
      }

      // Check for duplicates
      final fileName = file.path.split('/').last;
      if (_selectedPdfs.any((pdf) => pdf.path == file.path)) {
        _showErrorMessage('File already added: $fileName');
        return false;
      }

      setState(() {
        _selectedPdfs.add(
          _PdfFileInfo(
            path: file.path,
            name: fileName,
            sizeInBytes: fileSize,
            addedAt: DateTime.now(),
          ),
        );
        _errorMessage = null;
      });

      if (showSnackBar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added: $fileName'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      return true;
    } catch (e) {
      _showErrorMessage('Error adding file: $e');
      return false;
    }
  }

  void _showErrorMessage(String message) {
    setState(() => _errorMessage = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _mergePdfs() async {
    if (_selectedPdfs.length < 2) {
      _showErrorMessage('Please select at least 2 PDF files');
      return;
    }

    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      final pdfPaths = <String>[for (final pdf in _selectedPdfs) pdf.path];

      final outputPath = await PdfManipulationService.mergePdfs(pdfPaths);

      if (!mounted) return;

      setState(() {
        _isProcessing = false;
      });

      // Show success dialog
      _showSuccessDialog(outputPath);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isProcessing = false;
        _errorMessage = 'Failed to merge PDFs: $e';
      });

      _showErrorMessage('Failed to merge PDFs: $e');
    }
  }

  void _showSuccessDialog(String outputPath) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Merge Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Successfully merged ${_selectedPdfs.length} PDFs',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Total size: ${_getTotalSizeDisplay()}',
                style: TextStyle(color: Colors.blue.shade900, fontSize: 12),
              ),
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
              _openMergedPdf(outputPath);
            },
            icon: const Icon(Icons.visibility),
            label: const Text('View'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          ),
        ],
      ),
    );
  }

  void _openMergedPdf(String outputPath) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(externalFile: File(outputPath)),
      ),
    );
  }

  String _getTotalSizeDisplay() {
    final totalBytes = _selectedPdfs.fold<int>(
      0,
      (sum, pdf) => sum + pdf.sizeInBytes,
    );
    return _PdfFileInfo(
      path: '',
      name: '',
      sizeInBytes: totalBytes,
      addedAt: DateTime.now(),
    ).sizeDisplay;
  }

  void _removePdf(int index) {
    setState(() {
      _selectedPdfs.removeAt(index);
      _errorMessage = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('File removed'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _reorderPdfs(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _selectedPdfs.removeAt(oldIndex);
      _selectedPdfs.insert(newIndex, item);
    });
  }

  void _clearAll() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Files?'),
        content: const Text(
          'This will remove all selected PDFs. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedPdfs.clear();
                _errorMessage = null;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('All files cleared'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Clear All'),
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
        title: const Text('Merge PDFs'),
        elevation: 0,
        backgroundColor: AppConfig.primaryColor,
        centerTitle: true,
      ),
      body: Container(
        color: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA),
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF252525) : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppConfig.primaryColor.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.merge_type,
                      color: AppConfig.primaryColor,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Combine multiple PDFs into one',
                        style: TextStyle(
                          color: isDark ? Colors.white70 : Colors.blue.shade900,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Selected PDFs list with metadata
              if (_selectedPdfs.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Selected PDFs (${_selectedPdfs.length})',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total: ${_getTotalSizeDisplay()}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white54 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    TextButton.icon(
                      onPressed: _clearAll,
                      icon: const Icon(Icons.clear_all, size: 18),
                      label: const Text('Clear All'),
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ReorderableListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  onReorder: _reorderPdfs,
                  children: List.generate(_selectedPdfs.length, (index) {
                    final pdf = _selectedPdfs[index];

                    return Container(
                      key: ValueKey(pdf.path),
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF252525) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF404040)
                              : Colors.grey.shade200,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.3 : 0.05,
                            ),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppConfig.primaryColor.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.drag_handle,
                            color: AppConfig.primaryColor,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          pdf.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isDark ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Row(
                          children: [
                            Text(
                              'Page ${index + 1}',
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Text(
                              pdf.sizeDisplay,
                              style: TextStyle(
                                color: isDark ? Colors.white54 : Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.remove_circle_outline,
                            size: 22,
                          ),
                          color: Colors.red.shade400,
                          onPressed: () => _removePdf(index),
                          tooltip: 'Remove',
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 24),
              ] else
                // Empty State
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppConfig.primaryColor.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: Icon(
                            Icons.description_outlined,
                            size: 48,
                            color: AppConfig.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No PDFs Selected',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Select 2 or more PDF files to merge',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.white54 : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

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
                      Icon(Icons.error_outline, color: Colors.red.shade600),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Progress indicator
              if (_isProcessing) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.blue),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Merging PDFs...',
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontWeight: FontWeight.w500,
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
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _isProcessing ? null : _pickPdf,
                            icon: const Icon(Icons.add),
                            label: const Text('Add PDF'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppConfig.primaryColor,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade400,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _isProcessing ? null : _pickMultiplePdfs,
                            icon: const Icon(Icons.add_a_photo),
                            label: const Text('Add Multiple'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppConfig.primaryColor,
                              disabledForegroundColor: Colors.grey.shade400,
                              side: BorderSide(
                                color: _isProcessing
                                    ? Colors.grey.shade400
                                    : AppConfig.primaryColor,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isProcessing || _selectedPdfs.length < 2
                          ? null
                          : _mergePdfs,
                      icon: _isProcessing
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.merge_type),
                      label: Text(
                        _isProcessing
                            ? 'Merging...'
                            : _selectedPdfs.length < 2
                            ? 'Select at least 2 PDFs'
                            : 'Merge PDFs',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: Colors.grey.shade400,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
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

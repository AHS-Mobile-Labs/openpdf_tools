import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:openpdf_tools/config/premium_theme.dart';
import 'package:openpdf_tools/utils/platform_file_handler.dart';
import 'package:openpdf_tools/utils/output_path_helper.dart';
import 'package:path/path.dart' as p;
import '../services/pdf_manipulation_service.dart';
import 'package:openpdf_tools/widgets/theme_switcher.dart';
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
  static const int _maxFileSizeBytes = 100 * 1024 * 1024;
  static const int _maxTotalSizeBytes = 500 * 1024 * 1024;

  Future<void> _pickMultiplePdfs() async {
    try {
      final files = await PlatformFileHandler.pickMultipleFiles(
        dialogTitle: 'Choose PDFs to merge',
      );
      if (!mounted) return;
      if (files.isNotEmpty) {
        int added = 0;
        for (final file in files) {
          if (!mounted) return;
          if (_addPdfFile(file.path, showSnackBar: false)) {
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
      if (!file.existsSync()) {
        _showErrorMessage('File not found: $filePath');
        return false;
      }
      final fileSize = file.lengthSync();
      if (fileSize > _maxFileSizeBytes) {
        _showErrorMessage(
          'File too large (${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB). Max: 100 MB',
        );
        return false;
      }
      final totalSize =
          _selectedPdfs.fold<int>(0, (sum, pdf) => sum + pdf.sizeInBytes) +
          fileSize;
      if (totalSize > _maxTotalSizeBytes) {
        _showErrorMessage('Total size would exceed 500 MB limit');
        return false;
      }
      final fileName = p.basename(file.path);
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
    if (kIsWeb) {
      _showErrorMessage(
        'PDF merging is not available on web. Please use the desktop or mobile app.',
      );
      return;
    }
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });
    try {
      final pdfPaths = <String>[for (final pdf in _selectedPdfs) pdf.path];
      final outputPath = await PdfManipulationService.mergePdfs(pdfPaths);
      final savedFile = await OutputPathHelper.exportGeneratedFile(
        sourcePath: outputPath,
        fileName: outputPath.split(Platform.pathSeparator).last,
        category: OutputCategory.exports,
      );
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
      _showSuccessDialog(savedFile);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isProcessing = false;
      });
      String errorMessage = 'Failed to merge PDFs: $e';
      if (e.toString().contains('MissingPluginException')) {
        errorMessage =
            'PDF merge feature not available on this device. Please try a different method or update the app.';
      } else if (e.toString().contains('Permission denied')) {
        errorMessage =
            'Permission denied: Unable to access PDF files. Please check storage permissions.';
      } else if (e.toString().contains('File not found')) {
        errorMessage =
            'One or more PDF files could not be accessed. Please select the files again.';
      }
      setState(() => _errorMessage = errorMessage);
      _showErrorMessage(errorMessage);
    }
  }

  void _showSuccessDialog(ExportedFile savedFile) {
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
                'Saved to: ${savedFile.displayPath}\nTotal size: ${_getTotalSizeDisplay()}',
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
              _openMergedPdf(savedFile.workingPath);
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
    if (kIsWeb) return;
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

  Widget _buildStatusChip({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark
            ? PremiumColors.darkSurfaceSecondary
            : PremiumColors.lightSurfaceSecondary,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark
              ? PremiumColors.darkDivider
              : PremiumColors.lightDivider,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: PremiumColors.luxuryRed),
          const SizedBox(width: 6),
          Text(
            label,
            style: PremiumTypography.labelSmall.copyWith(
              color: isDark ? PremiumColors.darkText : PremiumColors.lightText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner(bool isDark) {
    if (_errorMessage == null) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: PremiumColors.error.withValues(alpha: isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PremiumColors.error.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: PremiumColors.error),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: PremiumTypography.bodySmall.copyWith(
                color: isDark
                    ? PremiumColors.darkText
                    : PremiumColors.lightText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedList(bool isDark) {
    if (_selectedPdfs.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 34),
        decoration: BoxDecoration(
          color: isDark
              ? PremiumColors.darkSurfacePrimary
              : PremiumColors.lightSurfacePrimary,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isDark
                ? PremiumColors.darkDivider
                : PremiumColors.lightDivider,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: PremiumColors.luxuryRed.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.picture_as_pdf_outlined,
                color: PremiumColors.luxuryRed,
                size: 34,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Add at least 2 PDFs',
              style: PremiumTypography.headlineSmall.copyWith(
                color: isDark
                    ? PremiumColors.darkText
                    : PremiumColors.lightText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Files stay in the order shown here. Drag to reorder before merging.',
              textAlign: TextAlign.center,
              style: PremiumTypography.bodySmall.copyWith(
                color: isDark
                    ? PremiumColors.darkTextSecondary
                    : PremiumColors.lightTextSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _selectedPdfs.length,
      onReorder: _reorderPdfs,
      itemBuilder: (context, index) {
        final pdf = _selectedPdfs[index];
        return Container(
          key: ValueKey(pdf.path),
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark
                ? PremiumColors.darkSurfacePrimary
                : PremiumColors.lightSurfacePrimary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark
                  ? PremiumColors.darkDivider
                  : PremiumColors.lightDivider,
            ),
          ),
          child: Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: PremiumColors.luxuryRed.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: PremiumTypography.labelLarge.copyWith(
                        color: PremiumColors.luxuryRed,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pdf.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PremiumTypography.labelLarge.copyWith(
                        color: isDark
                            ? PremiumColors.darkText
                            : PremiumColors.lightText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      pdf.sizeDisplay,
                      style: PremiumTypography.bodySmall.copyWith(
                        color: isDark
                            ? PremiumColors.darkTextSecondary
                            : PremiumColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Remove',
                onPressed: () => _removePdf(index),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(bool isDark) {
    final canMerge = !_isProcessing && _selectedPdfs.length >= 2;
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: isDark
              ? PremiumColors.darkSurfacePrimary
              : PremiumColors.lightSurfacePrimary,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? PremiumColors.darkDivider
                  : PremiumColors.lightDivider,
            ),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isProcessing ? null : _pickMultiplePdfs,
                icon: const Icon(Icons.add),
                label: const Text('Add PDFs'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: canMerge ? _mergePdfs : null,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.merge_type),
                label: Text(
                  _isProcessing
                      ? 'Merging...'
                      : _selectedPdfs.length < 2
                      ? 'Select 2 PDFs'
                      : 'Merge ${_selectedPdfs.length} PDFs',
                ),
              ),
            ),
          ],
        ),
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
        actions: [ThemeSwitcher(compact: true), const SizedBox(width: 8)],
      ),
      bottomNavigationBar: _buildBottomBar(isDark),
      body: Container(
        color: isDark ? PremiumColors.darkBg : PremiumColors.lightBg,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            isMobile ? 16 : 24,
            16,
            isMobile ? 16 : 24,
            24,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 760),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Combine PDFs',
                    style: PremiumTypography.headlineLarge.copyWith(
                      color: isDark
                          ? PremiumColors.darkText
                          : PremiumColors.lightText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Add files, arrange their order, then create one clean PDF.',
                    style: PremiumTypography.bodyMedium.copyWith(
                      color: isDark
                          ? PremiumColors.darkTextSecondary
                          : PremiumColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildStatusChip(
                        icon: Icons.picture_as_pdf,
                        label: '${_selectedPdfs.length} selected',
                        isDark: isDark,
                      ),
                      _buildStatusChip(
                        icon: Icons.storage,
                        label: _getTotalSizeDisplay(),
                        isDark: isDark,
                      ),
                    ],
                  ),
                  if (_isProcessing) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                  ],
                  _buildErrorBanner(isDark),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Merge Order',
                          style: PremiumTypography.headlineSmall.copyWith(
                            color: isDark
                                ? PremiumColors.darkText
                                : PremiumColors.lightText,
                          ),
                        ),
                      ),
                      if (_selectedPdfs.isNotEmpty)
                        TextButton.icon(
                          onPressed: _isProcessing ? null : _clearAll,
                          icon: const Icon(Icons.clear_all, size: 18),
                          label: const Text('Clear'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _buildSelectedList(isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

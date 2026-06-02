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

class SplitPdfScreen extends StatefulWidget {
  const SplitPdfScreen({super.key});
  @override
  State<SplitPdfScreen> createState() => _SplitPdfScreenState();
}

class _SplitPdfScreenState extends State<SplitPdfScreen> {
  String? _pdfPath;
  String? _pdfName;
  int? _pdfSizeInBytes;
  int? _pageCount;
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
      final file = await PlatformFileHandler.pickFile(
        dialogTitle: 'Choose a PDF to split',
      );
      if (!mounted) return;
      if (file == null) return;
      final pageCount = await PdfManipulationService.getPageCount(file.path);
      if (!mounted) return;
      if (pageCount <= 0) {
        setState(() {
          _errorMessage =
              'Could not read the PDF page count. Try another file.';
        });
        return;
      }
      setState(() {
        _pdfPath = file.path;
        _pdfName = p.basename(file.path);
        _pdfSizeInBytes = file.lengthSync();
        _pageCount = pageCount;
        _errorMessage = null;
        _startPageController.text = '1';
        _endPageController.text = pageCount.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected: ${p.basename(file.path)}'),
          backgroundColor: PremiumColors.success,
        ),
      );
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
    if (kIsWeb) {
      setState(
        () => _errorMessage =
            'PDF splitting is not available on web. Please use the desktop or mobile app.',
      );
      return;
    }
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });
    try {
      late List<String> outputPaths;
      if (_extractAllPages) {
        outputPaths = await PdfManipulationService.splitPdf(_pdfPath!);
      } else {
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
        if (_pageCount != null && endPage > _pageCount!) {
          setState(() {
            _isProcessing = false;
            _errorMessage = 'End page must be ${_pageCount!} or less';
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
      final savedFiles = <ExportedFile>[];
      for (final outputPath in outputPaths) {
        savedFiles.add(
          await OutputPathHelper.exportGeneratedFile(
            sourcePath: outputPath,
            fileName: outputPath.split(Platform.pathSeparator).last,
            category: OutputCategory.exports,
          ),
        );
      }
      if (!mounted) return;
      setState(() => _isProcessing = false);
      _showSuccessDialog(savedFiles);
    } catch (e) {
      if (!mounted) return;
      String errorMessage = 'Failed to split PDF: $e';
      if (e.toString().contains('MissingPluginException')) {
        errorMessage =
            'PDF split feature not available on this device. Please try a different method or update the app.';
      } else if (e.toString().contains('Permission denied')) {
        errorMessage =
            'Permission denied: Unable to access PDF files. Please check storage permissions.';
      } else if (e.toString().contains('File not found')) {
        errorMessage =
            'The PDF file could not be accessed. Please select the file again.';
      }
      setState(() {
        _isProcessing = false;
        _errorMessage = errorMessage;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
      );
    }
  }

  void _clearSelection() {
    setState(() {
      _pdfPath = null;
      _pdfName = null;
      _pdfSizeInBytes = null;
      _pageCount = null;
      _errorMessage = null;
      _startPageController.clear();
      _endPageController.clear();
      _extractAllPages = true;
    });
  }

  void _showSuccessDialog(List<ExportedFile> savedFiles) {
    final firstFile = savedFiles.first;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Split Complete'),
        content: Text(
          'Created ${savedFiles.length} PDF file(s).\nSaved to: ${firstFile.displayPath}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: kIsWeb
                ? null
                : () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PdfViewerScreen(
                          externalFile: File(firstFile.workingPath),
                        ),
                      ),
                    );
                  },
            icon: const Icon(Icons.visibility),
            label: const Text('View First'),
          ),
        ],
      ),
    );
  }

  String _sizeDisplay(int? bytes) {
    if (bytes == null) return 'Unknown size';
    return PlatformFileHandler.getHumanReadableFileSize(bytes);
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

  Widget _buildFileCard(bool isDark) {
    final hasFile = _pdfPath != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: PremiumColors.luxuryRed.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              hasFile ? Icons.picture_as_pdf : Icons.upload_file,
              color: PremiumColors.luxuryRed,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  hasFile ? _pdfName! : 'No PDF selected',
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
                  hasFile
                      ? '${_pageCount ?? 0} pages - ${_sizeDisplay(_pdfSizeInBytes)}'
                      : 'Choose one PDF, then split all pages or a page range.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: PremiumTypography.bodySmall.copyWith(
                    color: isDark
                        ? PremiumColors.darkTextSecondary
                        : PremiumColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (hasFile)
            IconButton(
              onPressed: _isProcessing ? null : _clearSelection,
              icon: const Icon(Icons.close),
              tooltip: 'Clear',
            ),
        ],
      ),
    );
  }

  Widget _buildModeCard({
    required bool isDark,
    required bool selected,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: _isProcessing ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? PremiumColors.luxuryRed.withValues(alpha: 0.10)
              : (isDark
                    ? PremiumColors.darkSurfacePrimary
                    : PremiumColors.lightSurfacePrimary),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: selected
                ? PremiumColors.luxuryRed
                : (isDark
                      ? PremiumColors.darkDivider
                      : PremiumColors.lightDivider),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: PremiumColors.luxuryRed),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: PremiumTypography.labelLarge.copyWith(
                      color: isDark
                          ? PremiumColors.darkText
                          : PremiumColors.lightText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: PremiumTypography.bodySmall.copyWith(
                      color: isDark
                          ? PremiumColors.darkTextSecondary
                          : PremiumColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected ? Icons.check_circle : Icons.radio_button_unchecked,
              color: selected ? PremiumColors.luxuryRed : Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isDark) {
    final canSplit = !_isProcessing && _pdfPath != null;
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
                onPressed: _isProcessing ? null : _pickPdf,
                icon: const Icon(Icons.upload_file),
                label: Text(_pdfPath == null ? 'Select PDF' : 'Change'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: canSplit ? _splitPdf : null,
                icon: _isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white),
                        ),
                      )
                    : const Icon(Icons.call_split),
                label: Text(_isProcessing ? 'Splitting...' : 'Split PDF'),
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
        title: const Text('Split PDF'),
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
                    'Split PDF',
                    style: PremiumTypography.headlineLarge.copyWith(
                      color: isDark
                          ? PremiumColors.darkText
                          : PremiumColors.lightText,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Extract every page into separate PDFs, or keep one page range as a new PDF.',
                    style: PremiumTypography.bodyMedium.copyWith(
                      color: isDark
                          ? PremiumColors.darkTextSecondary
                          : PremiumColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildFileCard(isDark),
                  _buildErrorBanner(isDark),
                  if (_isProcessing) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(),
                  ],
                  const SizedBox(height: 22),
                  Text(
                    'Split Mode',
                    style: PremiumTypography.headlineSmall.copyWith(
                      color: isDark
                          ? PremiumColors.darkText
                          : PremiumColors.lightText,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildModeCard(
                    isDark: isDark,
                    selected: _extractAllPages,
                    icon: Icons.dashboard_outlined,
                    title: 'All Pages',
                    subtitle: _pageCount == null
                        ? 'Create one PDF per page.'
                        : 'Create ${_pageCount!} separate PDF file(s).',
                    onTap: () => setState(() => _extractAllPages = true),
                  ),
                  const SizedBox(height: 10),
                  _buildModeCard(
                    isDark: isDark,
                    selected: !_extractAllPages,
                    icon: Icons.view_agenda_outlined,
                    title: 'Page Range',
                    subtitle: 'Create one PDF from a selected range.',
                    onTap: () => setState(() => _extractAllPages = false),
                  ),
                  if (!_extractAllPages) ...[
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _startPageController,
                            decoration: InputDecoration(
                              labelText: 'Start Page',
                              helperText: _pageCount == null
                                  ? null
                                  : '1-${_pageCount!}',
                              border: const OutlineInputBorder(),
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
                              helperText: _pageCount == null
                                  ? null
                                  : '1-${_pageCount!}',
                              border: const OutlineInputBorder(),
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
        ),
      ),
    );
  }
}

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:openpdf_tools/config/premium_theme.dart';
import 'package:openpdf_tools/utils/platform_file_handler.dart';
import 'package:openpdf_tools/utils/output_path_helper.dart';
import 'package:openpdf_tools/utils/web_file_saver.dart';
import 'package:path/path.dart' as p;
import '../services/pdf_manipulation_service.dart';
import 'pdf_viewer_screen.dart';

class SplitPdfScreen extends StatefulWidget {
  const SplitPdfScreen({super.key});
  @override
  State<SplitPdfScreen> createState() => _SplitPdfScreenState();
}

class _SplitPdfScreenState extends State<SplitPdfScreen> {
  String? _pdfPath;
  String? _pdfName;
  Uint8List? _pdfBytes;
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
      final picked = await PlatformFileHandler.pickPlatformFile(
        dialogTitle: 'Choose a PDF to split',
      );
      if (!mounted || picked == null) return;
      int pageCount = 0;
      if (kIsWeb) {
        if (picked.bytes == null) return;
        pageCount = PdfManipulationService.getPageCountFromBytes(picked.bytes!);
      } else if (picked.path != null) {
        pageCount = await PdfManipulationService.getPageCount(picked.path!);
      }
      if (!mounted) return;
      if (pageCount <= 0) {
        setState(() {
          _errorMessage =
              'Could not read the PDF page count. Try another file.';
        });
        return;
      }
      setState(() {
        _pdfPath = picked.path ?? picked.name;
        _pdfName = picked.name;
        _pdfBytes = picked.bytes;
        _pdfSizeInBytes = picked.size;
        _pageCount = pageCount;
        _errorMessage = null;
        _startPageController.text = '1';
        _endPageController.text = pageCount.toString();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Selected: ${picked.name}'),
          backgroundColor: PremiumColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _errorMessage = 'Error picking file: $e');
    }
  }

  Future<void> _splitPdf() async {
    if (_pdfPath == null && _pdfBytes == null) {
      setState(() => _errorMessage = 'Please select a PDF file');
      return;
    }
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });
    try {
      if (kIsWeb) {
        if (_pdfBytes == null) {
          setState(() {
            _isProcessing = false;
            _errorMessage = 'No PDF data found. Please select file again.';
          });
          return;
        }
        final baseName = (_pdfName ?? 'document').replaceAll(
          RegExp(r'\.pdf$', caseSensitive: false),
          '',
        );
        final savedFiles = <ExportedFile>[];
        final webBytesList = <Uint8List>[];

        if (_extractAllPages) {
          final pagesBytes = await PdfManipulationService.splitPdfBytes(
            _pdfBytes!,
          );
          for (var i = 0; i < pagesBytes.length; i++) {
            final outName = '${baseName}_page_${i + 1}.pdf';
            await WebFileSaver.saveFile(bytes: pagesBytes[i], fileName: outName);
            savedFiles.add(
              ExportedFile(
                workingPath: outName,
                displayPath: outName,
                fileName: outName,
                isUserVisible: true,
              ),
            );
            webBytesList.add(pagesBytes[i]);
          }
        } else {
          final startPage = int.tryParse(_startPageController.text.trim());
          final endPage = int.tryParse(_endPageController.text.trim());
          if (startPage == null ||
              endPage == null ||
              startPage < 1 ||
              endPage < startPage) {
            setState(() {
              _isProcessing = false;
              _errorMessage =
                  'Invalid page range. Start must be >= 1 and <= End';
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
          final rangeBytes = await PdfManipulationService.splitPdfRangeBytes(
            _pdfBytes!,
            startPage: startPage,
            endPage: endPage,
          );
          final outName = '${baseName}_pages_${startPage}_$endPage.pdf';
          await WebFileSaver.saveFile(bytes: rangeBytes, fileName: outName);
          savedFiles.add(
            ExportedFile(
              workingPath: outName,
              displayPath: outName,
              fileName: outName,
              isUserVisible: true,
            ),
          );
          webBytesList.add(rangeBytes);
        }
        if (!mounted) return;
        setState(() => _isProcessing = false);
        _showSuccessDialog(savedFiles, webBytesList: webBytesList);
        return;
      }

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
            fileName: p.basename(outputPath),
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
      _pdfBytes = null;
      _pdfSizeInBytes = null;
      _pageCount = null;
      _errorMessage = null;
      _startPageController.clear();
      _endPageController.clear();
      _extractAllPages = true;
    });
  }

  void _showSuccessDialog(
    List<ExportedFile> savedFiles, {
    List<Uint8List>? webBytesList,
  }) {
    final firstFile = savedFiles.first;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    int totalBytes = 0;
    if (webBytesList != null) {
      for (final b in webBytesList) {
        totalBytes += b.length;
      }
    } else {
      for (final f in savedFiles) {
        try {
          final file = File(f.workingPath);
          if (file.existsSync()) {
            totalBytes += file.lengthSync();
          }
        } catch (_) {}
      }
    }
    final sizeDisplay = totalBytes > 0
        ? PlatformFileHandler.getHumanReadableFileSize(totalBytes)
        : _sizeDisplay(_pdfSizeInBytes);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Split Complete'),
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
                    'Created ${savedFiles.length} PDF file(s)',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? PremiumColors.darkSurfaceSecondary
                    : Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? PremiumColors.darkDivider
                      : Colors.blue.shade100,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Total Output Size: $sizeDisplay',
                    style: TextStyle(
                      color: isDark
                          ? PremiumColors.darkText
                          : Colors.blue.shade900,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    kIsWeb ? 'Downloaded to browser' : 'Saved to: ${firstFile.displayPath}',
                    style: TextStyle(
                      color: isDark
                          ? PremiumColors.darkTextSecondary
                          : Colors.blue.shade800,
                      fontSize: 12,
                    ),
                  ),
                ],
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
              if (kIsWeb) {
                if (webBytesList != null && webBytesList.isNotEmpty) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PdfViewerScreen(
                        externalBytes: webBytesList.first,
                        externalFileName: firstFile.fileName,
                      ),
                    ),
                  );
                }
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PdfViewerScreen(
                      externalFile: File(firstFile.workingPath),
                    ),
                  ),
                );
              }
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
                      ? '${_pageCount ?? 0} ${_pageCount == 1 ? 'page' : 'pages'} • ${_sizeDisplay(_pdfSizeInBytes)}'
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

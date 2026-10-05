import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:path/path.dart' as path;
import 'package:openpdf_tools/widgets/in_app_file_picker.dart';
import 'package:openpdf_tools/utils/platform_helper.dart';
import 'package:openpdf_tools/utils/platform_file_handler.dart';
import 'package:openpdf_tools/utils/output_path_helper.dart';
import 'package:openpdf_tools/utils/uri_to_file.dart';
import 'package:openpdf_tools/config/app_config.dart';
import 'package:openpdf_tools/services/format_conversion_service.dart';
import 'pdf_viewer_screen.dart';

class ConvertToPdfScreen extends StatefulWidget {
  const ConvertToPdfScreen({super.key});
  @override
  State<ConvertToPdfScreen> createState() => _ConvertToPdfScreenState();
}

class _ConvertToPdfScreenState extends State<ConvertToPdfScreen> {
  bool _isProcessing = false;
  String? _selectedFormat;
  File? _selectedFile;
  Map<String, String> _getSupportedFormats() {
    return {
      'Word to PDF': 'docx,doc',
      'PowerPoint to PDF': 'pptx,ppt',
      'Excel to PDF': 'xlsx,xls',
      'Images to PDF': 'jpg,jpeg,png,webp,heic,gif,bmp',
      'HTML to PDF': 'html,htm',
      'Markdown to PDF': 'md,markdown',
      'CSV to PDF': 'csv',
      'JSON/XML/Log to PDF': 'json,xml,log',
      'SVG to PDF': 'svg',
      'TIFF to PDF': 'tiff,tif',
      'Text to PDF': 'txt',
      'RTF to PDF': 'rtf',
      'EPUB to PDF': 'epub',
      'ODT to PDF': 'odt',
      'ODP to PDF': 'odp',
      'ODS to PDF': 'ods',
      'ODG to PDF': 'odg',
    };
  }

  Future<void> pickFile(String format) async {
    try {
      if (PlatformHelper.isAndroid) {
        final hasPermission =
            await PlatformFileHandler.requestStoragePermission();
        if (!hasPermission && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Storage permission denied. Attempting to proceed...',
              ),
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
      final supportedFormats = _getSupportedFormats();
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: supportedFormats[format]!.split(','),
        withData: kIsWeb,
      );
      if (result != null && result.files.isNotEmpty) {
        if (kIsWeb) {
          final fileBytes = result.files.first.bytes;
          final fileName = result.files.first.name;
          if (fileBytes != null) {
            setState(() {
              _selectedFormat = format;
              _selectedFile = null;
            });
            await _convertToPdfFromBytes(fileBytes, fileName);
          }
        } else {
          final pickedPath = result.files.first.path;
          if (pickedPath == null || pickedPath.isEmpty) return;
          final realPath = await resolveToRealPath(pickedPath);
          if (!mounted) return;
          setState(() {
            _selectedFormat = format;
            _selectedFile = File(realPath);
          });
          await _convertToPdf();
        }
      }
    } catch (e) {
      if (!mounted) return;
      final choice = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('File picker failed'),
          content: Text('File picker failed: $e\n\nChoose an option:'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('inapp'),
              child: const Text('Use in-app picker'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('enter'),
              child: const Text('Enter path'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('cancel'),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );
      if (choice == 'inapp') {
        final supportedFormats = _getSupportedFormats();
        if (!mounted) return;
        final selected = await showInAppFilePicker(
          context,
          initialDirectory: Directory.current.path,
          allowedExtensions: supportedFormats[format]!.split(','),
        );
        if (selected != null) {
          setState(() {
            _selectedFormat = format;
            _selectedFile = File(selected);
          });
          await _convertToPdf();
        }
      } else if (choice == 'enter') {
        _showPathDialog(format);
      }
    }
  }

  void _showPathDialog(String format) async {
    final controller = TextEditingController();
    final submit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter file path'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '/path/to/file'),
          keyboardType: TextInputType.text,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    if (submit == true) {
      final path = controller.text.trim();
      if (path.isEmpty) return;
      final file = File(path);
      if (await file.exists()) {
        setState(() {
          _selectedFormat = format;
          _selectedFile = file;
        });
        await _convertToPdf();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('File not found')));
        }
      }
    }
  }

  Future<void> _convertToPdfFromBytes(
    Uint8List fileBytes,
    String fileName,
  ) async {
    setState(() => _isProcessing = true);
    try {
      final pdfBytes = await FormatConversionService.convertToPdf(
        bytes: fileBytes,
        fileName: fileName,
      );
      await Printing.sharePdf(
        bytes: pdfBytes,
        filename: '${fileName.replaceAll(RegExp(r'\.[^.]*$'), '')}.pdf',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _convertToPdf() async {
    if (_selectedFile == null || _selectedFormat == null) return;
    setState(() => _isProcessing = true);
    try {
      final fileName = path.basename(_selectedFile!.path);
      final fileBytes = await _selectedFile!.readAsBytes();
      final pdfBytes = await FormatConversionService.convertToPdf(
        bytes: fileBytes,
        fileName: fileName,
      );
      final outputPath = await OutputPathHelper.createWorkingOutputPath(
        fileName: OutputPathHelper.outputFileName(
          sourcePath: _selectedFile!.path,
          suffix: 'converted',
          extension: 'pdf',
        ),
        category: OutputCategory.exports,
      );
      await File(outputPath).writeAsBytes(pdfBytes);
      if (await File(outputPath).exists()) {
        await _showSuccessDialog(outputPath);
      } else {
        throw Exception('PDF conversion failed to create output file');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showSuccessDialog(String filePath) async {
    final savedFile = await OutputPathHelper.exportGeneratedFile(
      sourcePath: filePath,
      fileName: path.basename(filePath),
      category: OutputCategory.exports,
    );
    final fileSize = await File(savedFile.workingPath).length();
    final sizeInMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${savedFile.fileName} ($sizeInMB MB) saved to ${savedFile.displayPath}',
        ),
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PdfViewerScreen(externalFile: File(savedFile.workingPath)),
      ),
    );
  }


  Color _getCardColor(String format) {
    if (format.contains('Word')) return const Color(0xFF2B7BB9);
    if (format.contains('PowerPoint')) return const Color(0xFFD04423);
    if (format.contains('Excel')) return const Color(0xFF1E7145);
    if (format.contains('Image')) return const Color(0xFF9B59B6);
    if (format.contains('SVG')) return const Color(0xFF16A085);
    if (format.contains('TIFF')) return const Color(0xFF8E44AD);
    if (format.contains('Text')) return const Color(0xFF7F8C8D);
    if (format.contains('RTF')) return const Color(0xFF2980B9);
    if (format.contains('EPUB')) return const Color(0xFFE67E22);
    if (format.contains('OD')) return const Color(0xFF27AE60);
    return const Color(0xFFC6302C);
  }

  IconData _getIconForFormat(String format) {
    if (format.contains('Word')) return Icons.description;
    if (format.contains('PowerPoint')) return Icons.slideshow;
    if (format.contains('Excel')) return Icons.table_chart;
    if (format.contains('Image')) return Icons.image;
    if (format.contains('SVG')) return Icons.graphic_eq;
    if (format.contains('TIFF')) return Icons.photo;
    if (format.contains('Text')) return Icons.text_fields;
    if (format.contains('RTF')) return Icons.article;
    if (format.contains('EPUB')) return Icons.menu_book;
    if (format.contains('OD')) return Icons.file_present;
    return Icons.insert_drive_file;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F0F)
          : const Color(0xFFFAFAFA),
      body: SafeArea(
        child: _isProcessing
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Converting file to PDF...'),
                  ],
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          _buildSectionLabel('Choose a Format', isDark),
                          const SizedBox(height: 8),
                          _buildFormatList(isDark, width),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: _buildTip(isDark),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildFormatList(bool isDark, double width) {
    final supportedFormats = _getSupportedFormats();
    final entries = supportedFormats.entries.toList();
    final cols = width < 400
        ? 2
        : width < 600
        ? 3
        : width < 800
        ? 4
        : width < 1100
        ? 5
        : 6;
    final aspectRatio = width < 600 ? 0.95 : 1.1;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        childAspectRatio: aspectRatio,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: entries.length,
      itemBuilder: (_, index) =>
          _formatCard(entries[index].key, entries[index].value, isDark),
    );
  }

  Widget _buildSectionLabel(String text, bool isDark) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppConfig.primaryColor,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 7),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
            letterSpacing: 0.1,
          ),
        ),
      ],
    );
  }

  Widget _buildTip(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppConfig.primaryColor.withValues(alpha: 0.07),
        border: Border.all(
          color: AppConfig.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            size: 16,
            color: AppConfig.primaryColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'All formats (Word, Excel, PowerPoint, Text, Images & eBooks) convert directly on your Android device with complete offline privacy.',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formatCard(String formatName, String extensions, bool isDark) {
    final cardColor = _getCardColor(formatName);
    final displayExts = extensions
        .split(',')
        .take(2)
        .map((e) => e.trim().toUpperCase())
        .join(', ');
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: () => pickFile(formatName),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
            border: Border.all(
              color: isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade200,
            ),
          ),
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getIconForFormat(formatName),
                  size: 22,
                  color: cardColor,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                formatName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                displayExts,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

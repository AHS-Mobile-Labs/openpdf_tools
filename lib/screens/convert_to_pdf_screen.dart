import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:openpdf_tools/widgets/in_app_file_picker.dart';
import 'package:openpdf_tools/utils/platform_helper.dart';
import 'package:openpdf_tools/utils/platform_file_handler.dart';
import 'package:openpdf_tools/config/app_config.dart';
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
    if (kIsWeb || PlatformHelper.isMobile) {
      return {
        'Images to PDF': 'jpg,jpeg,png,webp,heic,gif,bmp',
        'TIFF to PDF': 'tiff,tif',
        'Text to PDF': 'txt',
      };
    }
    return {
      'Word to PDF': 'docx,doc',
      'PowerPoint to PDF': 'pptx,ppt',
      'Excel to PDF': 'xlsx,xls',
      'Images to PDF': 'jpg,jpeg,png,webp,heic,gif,bmp',
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
      if (format.contains('Images') && PlatformHelper.isAndroid) {
        await PlatformFileHandler.requestCameraPermission();
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
          setState(() {
            _selectedFormat = format;
            _selectedFile = File(result.files.first.path!);
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
      final ext = fileName.split('.').last.toLowerCase();
      if (['jpg', 'jpeg', 'png', 'webp', 'heic', 'gif', 'bmp'].contains(ext)) {
        final image = img.decodeImage(fileBytes);
        if (image == null) throw Exception('Failed to decode image');
        final pdf = pw.Document();
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat(
              image.width.toDouble(),
              image.height.toDouble(),
            ),
            build: (pw.Context context) => pw.Image(pw.MemoryImage(fileBytes)),
          ),
        );
        final pdfBytes = await pdf.save();
        await Printing.sharePdf(
          bytes: Uint8List.fromList(pdfBytes),
          filename: '${fileName.replaceAll(RegExp(r'\.[^.]*$'), '')}.pdf',
        );
      } else if (ext == 'txt') {
        final content = String.fromCharCodes(fileBytes);
        final pdf = pw.Document();
        final lines = content.split('\n');
        const linesPerPage = 50;
        for (int i = 0; i < lines.length; i += linesPerPage) {
          final pageLines = lines
              .sublist(i, (i + linesPerPage).clamp(0, lines.length))
              .join('\n');
          pdf.addPage(
            pw.Page(
              build: (pw.Context context) => pw.Padding(
                padding: const pw.EdgeInsets.all(20),
                child: pw.Text(
                  pageLines,
                  style: const pw.TextStyle(fontSize: 12),
                ),
              ),
            ),
          );
        }
        final pdfBytes = await pdf.save();
        await Printing.sharePdf(
          bytes: Uint8List.fromList(pdfBytes),
          filename: '${fileName.replaceAll(RegExp(r'\.[^.]*$'), '')}.pdf',
        );
      } else {
        throw Exception(
          'This format is not supported for web conversion.\n'
          'Please use the desktop app or an online converter.',
        );
      }
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
      final fileExtension = path
          .extension(_selectedFile!.path)
          .replaceFirst('.', '')
          .toLowerCase();
      String? outputPath;
      if ([
        'jpg',
        'jpeg',
        'png',
        'webp',
        'heic',
        'gif',
        'bmp',
      ].contains(fileExtension)) {
        outputPath = await _convertImageToPdf(_selectedFile!);
      } else if (fileExtension == 'txt') {
        outputPath = await _convertTextToPdf(_selectedFile!);
      } else if (fileExtension == 'svg') {
        outputPath = await _convertSvgToPdf(_selectedFile!);
      } else if (['tiff', 'tif'].contains(fileExtension)) {
        outputPath = await _convertTiffToPdf(_selectedFile!);
      } else if (fileExtension == 'rtf') {
        outputPath = await _convertRtfToPdf(_selectedFile!);
      } else if (fileExtension == 'epub') {
        outputPath = await _convertEpubToPdf(_selectedFile!);
      } else if (fileExtension == 'odg') {
        outputPath = await _convertOdgToPdf(_selectedFile!);
      } else if ([
        'docx',
        'doc',
        'xlsx',
        'xls',
        'pptx',
        'ppt',
        'odt',
        'ods',
        'odp',
      ].contains(fileExtension)) {
        outputPath = await _convertOfficeFormatToPdf(_selectedFile!);
      } else {
        throw Exception(
          'Unsupported format: $fileExtension\n\nFor complex formats like '
          '$fileExtension, you may need to use an external service or install LibreOffice.',
        );
      }
      if (outputPath != null && await File(outputPath).exists()) {
        await _showSuccessDialog(outputPath);
      } else {
        throw Exception('PDF conversion failed');
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

  Future<String?> _convertImageToPdf(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) throw Exception('Failed to decode image');
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(
            image.width.toDouble(),
            image.height.toDouble(),
          ),
          build: (pw.Context context) => pw.Image(pw.MemoryImage(imageBytes)),
        ),
      );
      final tempDir = await getTemporaryDirectory();
      final outputPath = path.join(
        tempDir.path,
        'converted_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await File(outputPath).writeAsBytes(await pdf.save());
      return outputPath;
    } catch (e) {
      throw Exception('Image to PDF conversion failed: $e');
    }
  }

  Future<String?> _convertTextToPdf(File textFile) async {
    try {
      final content = await textFile.readAsString();
      final pdf = pw.Document();
      final lines = content.split('\n');
      const linesPerPage = 50;
      for (int i = 0; i < lines.length; i += linesPerPage) {
        final pageLines = lines
            .sublist(i, (i + linesPerPage).clamp(0, lines.length))
            .join('\n');
        pdf.addPage(
          pw.Page(
            build: (pw.Context context) => pw.Padding(
              padding: const pw.EdgeInsets.all(20),
              child: pw.Text(
                pageLines,
                style: const pw.TextStyle(fontSize: 12),
              ),
            ),
          ),
        );
      }
      final tempDir = await getTemporaryDirectory();
      final outputPath = path.join(
        tempDir.path,
        'converted_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await File(outputPath).writeAsBytes(await pdf.save());
      return outputPath;
    } catch (e) {
      throw Exception('Text to PDF conversion failed: $e');
    }
  }

  Future<String?> _convertOfficeFormatToPdf(File sourceFile) async {
    if (kIsWeb || PlatformHelper.isMobile) {
      throw Exception(
        'Office format conversion is not supported on this platform.\n\n'
        'Use an online converter:\n'
        '• CloudConvert.com\n'
        '• Zamzar.com\n'
        '• AnyConv.com\n\n'
        'Or convert on desktop (Windows/macOS/Linux) first.',
      );
    }
    final tempDir = await getTemporaryDirectory();
    final filename = path.basenameWithoutExtension(sourceFile.path);
    final command = PlatformHelper.isWindows ? 'soffice' : 'libreoffice';
    try {
      final result = await Process.run(command, [
        '--headless',
        '--convert-to',
        'pdf',
        '--outdir',
        tempDir.path,
        sourceFile.path,
      ]);
      if (result.exitCode == 0) {
        final convertedFile = File(path.join(tempDir.path, '$filename.pdf'));
        if (await convertedFile.exists()) return convertedFile.path;
      }
      throw Exception(
        'LibreOffice conversion failed.\n\n'
        'For Office formats (DOCX, XLSX, PPTX, etc.), install LibreOffice:\n'
        'Linux: sudo apt-get install libreoffice\n'
        'macOS: brew install libreoffice\n'
        'Windows: Download from https://www.libreoffice.org/\n\n'
        'Error: ${result.stderr}',
      );
    } catch (e) {
      if (e.toString().contains('No such file')) {
        throw Exception(
          'LibreOffice not found on this system.\n\n'
          'For Office formats (DOCX, XLSX, PPTX, etc.), install LibreOffice:\n'
          'Linux: sudo apt-get install libreoffice\n'
          'macOS: brew install libreoffice\n'
          'Windows: Download from https://www.libreoffice.org/',
        );
      }
      rethrow;
    }
  }

  Future<String?> _convertSvgToPdf(File svgFile) async {
    if (kIsWeb || PlatformHelper.isMobile) {
      throw Exception(
        'SVG to PDF conversion is not supported on mobile devices.\n\n'
        'Please use a desktop application or online converter.\n'
        'Recommended online converters:\n'
        '• CloudConvert.com\n'
        '• Zamzar.com\n'
        '• AnyConv.com',
      );
    }
    return _convertOfficeFormatToPdf(svgFile);
  }

  Future<String?> _convertTiffToPdf(File tiffFile) async {
    try {
      final imageBytes = await tiffFile.readAsBytes();
      final image = img.decodeImage(imageBytes);
      if (image == null) throw Exception('Failed to decode TIFF image');
      final pdf = pw.Document();
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat(
            image.width.toDouble(),
            image.height.toDouble(),
          ),
          build: (pw.Context context) => pw.Image(pw.MemoryImage(imageBytes)),
        ),
      );
      final tempDir = await getTemporaryDirectory();
      final outputPath = path.join(
        tempDir.path,
        'converted_${DateTime.now().millisecondsSinceEpoch}.pdf',
      );
      await File(outputPath).writeAsBytes(await pdf.save());
      return outputPath;
    } catch (e) {
      throw Exception('TIFF to PDF conversion failed: $e');
    }
  }

  Future<String?> _convertRtfToPdf(File rtfFile) async {
    if (kIsWeb || PlatformHelper.isMobile) {
      throw Exception(
        'RTF to PDF conversion is not supported on mobile devices.\n\n'
        'Please use a desktop application or online converter.\n'
        'Recommended online converters:\n'
        '• CloudConvert.com\n'
        '• Zamzar.com\n'
        '• AnyConv.com',
      );
    }
    return _convertOfficeFormatToPdf(rtfFile);
  }

  Future<String?> _convertEpubToPdf(File epubFile) async {
    if (kIsWeb || PlatformHelper.isMobile) {
      throw Exception(
        'EPUB to PDF conversion is not supported on mobile devices.\n\n'
        'Please use a desktop application or online converter.\n'
        'Recommended online converters:\n'
        '• CloudConvert.com\n'
        '• Zamzar.com\n'
        '• AnyConv.com',
      );
    }
    return _convertOfficeFormatToPdf(epubFile);
  }

  Future<String?> _convertOdgToPdf(File odgFile) async {
    if (kIsWeb || PlatformHelper.isMobile) {
      throw Exception(
        'ODG (Drawing) to PDF conversion is not supported on mobile devices.\n\n'
        'Please use a desktop application or online converter.\n'
        'Recommended online converters:\n'
        '• CloudConvert.com\n'
        '• Zamzar.com\n'
        '• AnyConv.com',
      );
    }
    return _convertOfficeFormatToPdf(odgFile);
  }

  Future<void> _showSuccessDialog(String filePath) async {
    final fileSize = await File(filePath).length();
    final sizeInMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ ${path.basename(filePath)} ($sizeInMB MB)'),
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(externalFile: File(filePath)),
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
              'Office formats (DOCX, XLSX, PPTX) require LibreOffice installed on your system.',
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

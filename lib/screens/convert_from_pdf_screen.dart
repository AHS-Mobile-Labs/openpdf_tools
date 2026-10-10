import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:openpdf_tools/utils/platform_file_handler.dart';
import 'package:openpdf_tools/utils/platform_helper.dart';
import 'package:openpdf_tools/utils/output_path_helper.dart';
import 'package:openpdf_tools/utils/uri_to_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path_lib;
import 'package:openpdf_tools/widgets/in_app_file_picker.dart';
import 'package:openpdf_tools/services/format_conversion_service.dart';
import 'package:archive/archive.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import 'pdf_viewer_screen.dart';

class ConvertFromPdfScreen extends StatefulWidget {
  const ConvertFromPdfScreen({super.key});
  @override
  State<ConvertFromPdfScreen> createState() => _ConvertFromPdfScreenState();
}

class _ConvertFromPdfScreenState extends State<ConvertFromPdfScreen> {
  bool _isProcessing = false;
  String? _selectedPdfPath;
  String? _selectedFormat;
  static const List<ConversionFormat> conversionFormats = [
    ConversionFormat(
      name: 'PDF to Word',
      format: 'Word',
      fileExtension: 'docx',
      icon: Icons.description,
      color: Color(0xFF2E5090),
    ),
    ConversionFormat(
      name: 'PDF to PowerPoint',
      format: 'PowerPoint',
      fileExtension: 'pptx',
      icon: Icons.slideshow,
      color: Color(0xFFD24726),
    ),
    ConversionFormat(
      name: 'PDF to Excel',
      format: 'Excel',
      fileExtension: 'xlsx',
      icon: Icons.table_chart,
      color: Color(0xFF107C10),
    ),
    ConversionFormat(
      name: 'PDF to Images',
      format: 'Images',
      fileExtension: 'zip',
      icon: Icons.collections,
      color: Color(0xFF9C27B0),
    ),
    ConversionFormat(
      name: 'PDF to JPG',
      format: 'JPG',
      fileExtension: 'jpg',
      icon: Icons.image,
      color: Color(0xFFFF9800),
    ),
    ConversionFormat(
      name: 'PDF to PNG',
      format: 'PNG',
      fileExtension: 'png',
      icon: Icons.image,
      color: Color(0xFF2196F3),
    ),
    ConversionFormat(
      name: 'PDF to SVG',
      format: 'SVG',
      fileExtension: 'svg',
      icon: Icons.image,
      color: Color(0xFFFFB81C),
    ),
    ConversionFormat(
      name: 'PDF to DOCX',
      format: 'DOCX',
      fileExtension: 'docx',
      icon: Icons.file_present,
      color: Color(0xFF4472C4),
    ),
    ConversionFormat(
      name: 'PDF to PPTX',
      format: 'PPTX',
      fileExtension: 'pptx',
      icon: Icons.file_present,
      color: Color(0xFFED7D31),
    ),
    ConversionFormat(
      name: 'PDF to XLSX',
      format: 'XLSX',
      fileExtension: 'xlsx',
      icon: Icons.file_present,
      color: Color(0xFF70AD47),
    ),
    ConversionFormat(
      name: 'PDF to ODT',
      format: 'ODT',
      fileExtension: 'odt',
      icon: Icons.file_present,
      color: Color(0xFF1F497D),
    ),
    ConversionFormat(
      name: 'PDF to ODS',
      format: 'ODS',
      fileExtension: 'ods',
      icon: Icons.file_present,
      color: Color(0xFF6AA84F),
    ),
    ConversionFormat(
      name: 'PDF to ODP',
      format: 'ODP',
      fileExtension: 'odp',
      icon: Icons.file_present,
      color: Color(0xFFFF6B6B),
    ),
    ConversionFormat(
      name: 'PDF to Text',
      format: 'Text',
      fileExtension: 'txt',
      icon: Icons.description,
      color: Color(0xFF424242),
    ),
    ConversionFormat(
      name: 'PDF to RTF',
      format: 'RTF',
      fileExtension: 'rtf',
      icon: Icons.description,
      color: Color(0xFF666666),
    ),
    ConversionFormat(
      name: 'PDF to EPUB',
      format: 'EPUB',
      fileExtension: 'epub',
      icon: Icons.book,
      color: Color(0xFF8B4513),
    ),
    ConversionFormat(
      name: 'PDF to HTML',
      format: 'HTML',
      fileExtension: 'html',
      icon: Icons.code,
      color: Color(0xFFE34C26),
    ),
    ConversionFormat(
      name: 'PDF to Secure PDF',
      format: 'SecurePDF',
      fileExtension: 'pdf',
      icon: Icons.lock,
      color: Color(0xFF9C27B0),
    ),
    ConversionFormat(
      name: 'PDF to PDF/A',
      format: 'PDF/A',
      fileExtension: 'pdf',
      icon: Icons.archive,
      color: Color(0xFF1976D2),
    ),
  ];
  Future<String> _getInitialDirectory() async {
    if (kIsWeb) return '';
    try {
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null && await downloadsDir.exists()) {
        return downloadsDir.path;
      }
    } catch (_) {}
    try {
      if (!kIsWeb && (PlatformHelper.isLinux || PlatformHelper.isMacOS)) {
        final homeDir = Platform.environment['HOME'];
        if (homeDir != null && await Directory(homeDir).exists()) {
          return homeDir;
        }
      }
    } catch (_) {}
    try {
      return Directory.current.path;
    } catch (_) {
      return '';
    }
  }

  Future<void> _pickPdf() async {
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
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (result != null && result.files.isNotEmpty) {
        final pickedPath = result.files.first.path;
        if (pickedPath == null || pickedPath.isEmpty) return;
        final realPath = await resolveToRealPath(pickedPath);
        if (!mounted) return;
        setState(() => _selectedPdfPath = realPath);
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
        final initialDir = await _getInitialDirectory();
        if (!mounted) return;
        final selected = await showInAppFilePicker(
          context,
          initialDirectory: initialDir,
          allowedExtensions: ['pdf'],
        );
        if (selected != null) {
          setState(() => _selectedPdfPath = selected);
        }
      } else if (choice == 'enter') {
        _showPathDialog();
      }
    }
  }

  void _showPathDialog() async {
    final controller = TextEditingController();
    final submit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Enter PDF path'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '/path/to/file.pdf'),
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
        setState(() => _selectedPdfPath = path);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('File not found')));
      }
    }
  }

  Future<void> _convertPdf(ConversionFormat format) async {
    if (_selectedPdfPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF file first')),
      );
      return;
    }
    setState(() {
      _isProcessing = true;
      _selectedFormat = format.format;
    });
    try {
      final fileName = OutputPathHelper.outputFileName(
        sourcePath: _selectedPdfPath!,
        suffix: 'converted',
        extension: format.fileExtension,
      );
      final outputPath = await OutputPathHelper.createWorkingOutputPath(
        fileName: fileName,
        category: OutputCategory.exports,
      );
      await _performConversion(format, outputPath);
      if (!mounted) return;
      if (!await File(outputPath).exists()) {
        throw Exception('Conversion did not create an output file.');
      }
      final savedFile = await OutputPathHelper.exportGeneratedFile(
        sourcePath: outputPath,
        fileName: fileName,
        category: OutputCategory.exports,
      );
      if (!mounted) return;
      final isPdfOutput = format.fileExtension == 'pdf';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved: ${savedFile.displayPath}'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () {
              if (isPdfOutput) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PdfViewerScreen(
                      externalFile: File(savedFile.workingPath),
                    ),
                  ),
                );
              } else if (PlatformHelper.isMobile) {
                share_plus.SharePlus.instance.share(
                  share_plus.ShareParams(
                    files: [share_plus.XFile(savedFile.workingPath)],
                  ),
                );
              } else if (PlatformHelper.isMacOS) {
                Process.run('open', [savedFile.workingPath]);
              } else if (PlatformHelper.isWindows) {
                Process.run('explorer', [savedFile.workingPath]);
              } else if (PlatformHelper.isLinux) {
                Process.run('xdg-open', [savedFile.workingPath]);
              }
            },
          ),
        ),
      );
      if (isPdfOutput) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                PdfViewerScreen(externalFile: File(savedFile.workingPath)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Conversion failed: $e')));
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _performConversion(
    ConversionFormat format,
    String outputPath,
  ) async {
    final pdfBytes = await File(_selectedPdfPath!).readAsBytes();
    final outFile = File(outputPath);
    final outDir = outFile.parent;
    if (!await outDir.exists()) await outDir.create(recursive: true);

    switch (format.format) {
      case 'Text':
        final text = FormatConversionService.extractFullText(pdfBytes);
        await outFile.writeAsString(text.isNotEmpty ? text : 'No text content found in PDF.');
        break;

      case 'Word':
      case 'DOCX':
        final docxBytes = FormatConversionService.pdfToDocx(pdfBytes);
        await outFile.writeAsBytes(docxBytes);
        break;

      case 'PowerPoint':
      case 'PPTX':
        final pptxBytes = FormatConversionService.pdfToPptx(pdfBytes);
        await outFile.writeAsBytes(pptxBytes);
        break;

      case 'Excel':
      case 'XLSX':
        final xlsxBytes = FormatConversionService.pdfToXlsx(pdfBytes);
        await outFile.writeAsBytes(xlsxBytes);
        break;

      case 'ODT':
        final odtBytes = FormatConversionService.pdfToOdt(pdfBytes);
        await outFile.writeAsBytes(odtBytes);
        break;

      case 'ODS':
        final odsBytes = FormatConversionService.pdfToOds(pdfBytes);
        await outFile.writeAsBytes(odsBytes);
        break;

      case 'ODP':
        final odpBytes = FormatConversionService.pdfToOdp(pdfBytes);
        await outFile.writeAsBytes(odpBytes);
        break;

      case 'HTML':
        final html = FormatConversionService.pdfToHtml(
          pdfBytes,
          title: path_lib.basenameWithoutExtension(_selectedPdfPath!),
        );
        await outFile.writeAsString(html);
        break;

      case 'RTF':
        final rtf = FormatConversionService.pdfToRtf(pdfBytes);
        await outFile.writeAsString(rtf);
        break;

      case 'EPUB':
        final epubBytes = FormatConversionService.pdfToEpub(
          pdfBytes,
          title: path_lib.basenameWithoutExtension(_selectedPdfPath!),
        );
        await outFile.writeAsBytes(epubBytes);
        break;

      case 'SVG':
        final svg = FormatConversionService.pdfToSvg(pdfBytes);
        await outFile.writeAsString(svg);
        break;

      case 'Images':
        final images = await FormatConversionService.renderPdfToImages(pdfBytes, format: 'png');
        if (images.isEmpty) throw Exception('No images could be extracted from PDF');
        final archive = Archive();
        for (int i = 0; i < images.length; i++) {
          archive.addFile(ArchiveFile('page_${i + 1}.png', images[i].length, images[i]));
        }
        final zipBytes = ZipEncoder().encode(archive);
        await outFile.writeAsBytes(zipBytes);
        break;

      case 'JPG':
      case 'PNG':
        final images = await FormatConversionService.renderPdfToImages(
          pdfBytes,
          format: format.format.toLowerCase(),
        );
        if (images.isEmpty) throw Exception('No images could be generated from PDF');
        await outFile.writeAsBytes(images.first);
        break;

      case 'SecurePDF':
        final secBytes = FormatConversionService.encryptPdf(pdfBytes);
        await outFile.writeAsBytes(secBytes);
        break;

      case 'PDF/A':
        final pdfABytes = FormatConversionService.createPdfA(pdfBytes);
        await outFile.writeAsBytes(pdfABytes);
        break;

      default:
        throw Exception('Unsupported format: ${format.format}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F0F)
          : const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Convert from PDF'),
        backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
      ),
      body: Column(
        children: [
          if (_selectedPdfPath != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: isDark
                  ? Colors.green.shade900.withValues(alpha: 0.4)
                  : Colors.green.shade100,
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: isDark
                        ? Colors.green.shade300
                        : Colors.green.shade700,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'PDF Selected',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          path_lib.basename(_selectedPdfPath!),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() => _selectedPdfPath = null),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
          Expanded(
            child: _selectedPdfPath == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.file_upload,
                          size: 64,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Select a PDF to convert',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _pickPdf,
                          icon: const Icon(Icons.folder_open),
                          label: const Text('Choose PDF'),
                        ),
                      ],
                    ),
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          childAspectRatio: 1.0,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: conversionFormats.length,
                    itemBuilder: (context, index) {
                      final format = conversionFormats[index];
                      final isSelected = _selectedFormat == format.format;
                      final isProcessing = _isProcessing && isSelected;
                      return _ConversionFormatCard(
                        format: format,
                        isDark: isDark,
                        isProcessing: isProcessing,
                        isDisabled: _isProcessing && !isSelected,
                        onTap: _isProcessing ? null : () => _convertPdf(format),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class ConversionFormat {
  final String name;
  final String format;
  final String fileExtension;
  final IconData icon;
  final Color color;
  const ConversionFormat({
    required this.name,
    required this.format,
    required this.fileExtension,
    required this.icon,
    required this.color,
  });
}

class _ConversionFormatCard extends StatefulWidget {
  final ConversionFormat format;
  final bool isDark;
  final bool isProcessing;
  final bool isDisabled;
  final VoidCallback? onTap;
  const _ConversionFormatCard({
    required this.format,
    required this.isDark,
    required this.isProcessing,
    required this.isDisabled,
    required this.onTap,
  });
  @override
  State<_ConversionFormatCard> createState() => _ConversionFormatCardState();
}

class _ConversionFormatCardState extends State<_ConversionFormatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        if (!widget.isDisabled && !widget.isProcessing) {
          _controller.forward();
        }
      },
      onExit: (_) {
        if (!widget.isDisabled && !widget.isProcessing) {
          _controller.reverse();
        }
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: GestureDetector(
          onTap: widget.isDisabled ? null : widget.onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: widget.format.color.withValues(alpha: 0.3),
                width: 1.5,
              ),
              color: widget.isDark ? const Color(0xFF1C1C1C) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Stack(
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: widget.format.color.withValues(alpha: 0.1),
                            ),
                            child: Icon(
                              widget.format.icon,
                              size: 20,
                              color: widget.format.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Flexible(
                            child: Text(
                              widget.format.name,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.fade,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                                height: 1.0,
                                color: widget.isDisabled
                                    ? Colors.grey
                                    : widget.isDark
                                    ? Colors.white
                                    : Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (widget.isProcessing)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                          strokeWidth: 2,
                        ),
                      ),
                    ),
                  ),
                if (widget.isDisabled && !widget.isProcessing)
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey.withValues(alpha: 0.3),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

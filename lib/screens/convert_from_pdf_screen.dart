import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:openpdf_tools/utils/platform_file_handler.dart';
import 'package:openpdf_tools/utils/platform_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path_lib;
import 'package:openpdf_tools/widgets/in_app_file_picker.dart';
import 'package:openpdf_tools/widgets/theme_switcher.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import 'pdf_viewer_screen.dart';

// ignore: use_build_context_synchronously

class ConvertFromPdfScreen extends StatefulWidget {
  const ConvertFromPdfScreen({super.key});

  @override
  State<ConvertFromPdfScreen> createState() => _ConvertFromPdfScreenState();
}

class _ConvertFromPdfScreenState extends State<ConvertFromPdfScreen> {
  bool _isProcessing = false;
  String? _selectedPdfPath;
  String? _selectedFormat;

  static const platform = MethodChannel('com.openpdf.tools/pdfManipulation');
  // All conversion formats
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
      // Try to use the Downloads directory first
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null && await downloadsDir.exists()) {
        return downloadsDir.path;
      }
    } catch (_) {}

    try {
      // Fallback to home directory on Linux
      if (PlatformHelper.isLinux || PlatformHelper.isMacOS) {
        final homeDir = Platform.environment['HOME'];
        if (homeDir != null && await Directory(homeDir).exists()) {
          return homeDir;
        }
      }
    } catch (_) {}

    // Final fallback to current working directory
    try {
      return Directory.current.path;
    } catch (_) {
      return '';
    }
  }

  Future<void> _pickPdf() async {
    try {
      // Request permissions first
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
        setState(() => _selectedPdfPath = result.files.first.path!);
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
        final selected = await showInAppFilePicker(
          // ignore: use_build_context_synchronously
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

        ScaffoldMessenger.of(context).showSnackBar(
          // ignore: use_build_context_synchronously
          const SnackBar(content: Text('File not found')),
        );
      }
    }
  }

  Future<void> _convertPdf(ConversionFormat format) async {
    if (_selectedPdfPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        // ignore: use_build_context_synchronously
        const SnackBar(content: Text('Please select a PDF file first')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
      _selectedFormat = format.format;
    });

    if (kIsWeb) {
      _showWebConversionDialog(format);
      setState(() => _isProcessing = false);
      return;
    }

    try {
      // Get Downloads directory or fallback to home directory
      Directory outputDir;
      final downloadsDir = await getDownloadsDirectory();
      if (downloadsDir != null) {
        outputDir = downloadsDir;
      } else {
        // Fallback to home directory on Linux
        final homeDir = PlatformHelper.isLinux || PlatformHelper.isMacOS
            ? Platform.environment['HOME']
            : null;
        if (homeDir != null) {
          outputDir = Directory(homeDir);
        } else {
          outputDir = await getApplicationDocumentsDirectory();
        }
      }

      // Ensure directory exists
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
      }

      final fileName =
          '${path_lib.basename(_selectedPdfPath!).replaceAll('.pdf', '')}_converted.${format.fileExtension}';
      final outputPath = '${outputDir.path}/$fileName';

      // Call conversion based on format
      await _performConversion(format, outputPath);

      if (!mounted) return;

      // Check if the output file was actually created
      if (!await File(outputPath).exists()) return;

      // Check if output is a PDF file
      final isPdfOutput = format.fileExtension == 'pdf';

      ScaffoldMessenger.of(context).showSnackBar(
        // ignore: use_build_context_synchronously

        // ignore: use_build_context_synchronously
        SnackBar(
          content: Text('✓ Saved: $fileName'),
          duration: const Duration(seconds: 3),
          action: SnackBarAction(
            label: 'Open',
            onPressed: () {
              if (isPdfOutput) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        PdfViewerScreen(externalFile: File(outputPath)),
                  ),
                );
              } else if (PlatformHelper.isMobile) {
                // Mobile: share the file
                share_plus.SharePlus.instance.share(
                  share_plus.ShareParams(files: [share_plus.XFile(outputPath)]),
                );
              } else {
                // Desktop: open file in default application
                Process.run('xdg-open', [outputPath]);
              }
            },
          ),
        ),
      );

      if (isPdfOutput) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfViewerScreen(externalFile: File(outputPath)),
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
        // ignore: use_build_context_synchronously
      }
    }
  }

  Future<void> _performConversion(
    ConversionFormat format,
    String outputPath,
  ) async {
    switch (format.format) {
      case 'Text':
        await _convertToText(outputPath);
        break;
      case 'Images':
      case 'JPG':
      case 'PNG':
      case 'SVG':
        await _convertToImages(format, outputPath);
        break;
      case 'Word':
      case 'DOCX':
      case 'PowerPoint':
      case 'PPTX':
      case 'Excel':
      case 'XLSX':
      case 'ODT':
      case 'ODS':
      case 'ODP':
      case 'HTML':
      case 'RTF':
      case 'EPUB':
        await _convertUsingLibreOffice(format, outputPath);
        break;
      case 'SecurePDF':
        await _convertToSecurePdf(outputPath);
        break;
      case 'PDF/A':
        await _convertToPdfA(outputPath);
        break;
      default:
        throw Exception('Unsupported format: ${format.format}');
    }
  }

  Future<void> _convertToText(String outputPath) async {
    // Ensure output directory exists
    final outDir = File(outputPath).parent;
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    }

    if (Platform.isAndroid) {
      // Android: Use method channel to extract text via PDFBox
      try {
        final result = await platform.invokeMethod<String>('extractText', {
          'inputPath': _selectedPdfPath!,
          'outputPath': outputPath,
        });
        if (result == null || result.isEmpty) {
          throw Exception('Failed to extract text from PDF');
        }
      } catch (e) {
        throw Exception('Text extraction failed: $e');
      }
    } else {
      // Desktop: Use command-line tool
      final result = await Process.run('pdftotext', [
        _selectedPdfPath!,
        outputPath,
      ]);

      if (result.exitCode != 0) {
        throw Exception('Text conversion failed: ${result.stderr}');
      }
    }
  }

  Future<void> _convertToImages(
    ConversionFormat format,
    String outputPath,
  ) async {
    final tempDir = await getTemporaryDirectory();
    final imageDir =
        '${tempDir.path}/pdf_images_${DateTime.now().millisecondsSinceEpoch}';
    await Directory(imageDir).create(recursive: true);

    try {
      String imageFormat = '';
      switch (format.format) {
        case 'JPG':
          imageFormat = 'jpg';
          break;
        case 'PNG':
          imageFormat = 'png';
          break;
        case 'SVG':
          imageFormat = 'svg';
          break;
        default:
          imageFormat = 'png';
      }

      if (Platform.isAndroid) {
        // Android: Use method channel to render PDF pages as images
        try {
          final result = await platform
              .invokeMethod<List<dynamic>>('pdfToImages', {
                'inputPath': _selectedPdfPath!,
                'outputDir': imageDir,
                'format': imageFormat,
                'quality': 150,
              });
          if (result == null || result.isEmpty) {
            throw Exception('Failed to convert PDF to images');
          }
        } catch (e) {
          throw Exception('Image conversion failed: $e');
        }
      } else {
        // Desktop: Use pdftoppm command
        final result = await Process.run('pdftoppm', [
          '-$imageFormat',
          '-r',
          '150',
          _selectedPdfPath!,
          '$imageDir/page',
        ]);

        if (result.exitCode != 0) {
          throw Exception('Image conversion failed: ${result.stderr}');
        }
      }

      // If format is Images, zip all images
      if (format.format == 'Images') {
        if (Platform.isAndroid) {
          // Android: use method channel for zipping
          try {
            await platform.invokeMethod<String>('zipDirectory', {
              'inputDir': imageDir,
              'outputPath': outputPath,
            });
          } catch (e) {
            throw Exception('Zip creation failed: $e');
          }
        } else {
          // Desktop: use zip command
          final zipResult = await Process.run('zip', [
            '-r',
            outputPath,
            imageDir,
          ]);

          if (zipResult.exitCode != 0) {
            throw Exception('Zip creation failed: ${zipResult.stderr}');
          }
        }
      } else {
        // Single image format (JPG/PNG/SVG): copy the first generated image to outputPath
        final imageFiles =
            Directory(imageDir).listSync().whereType<File>().toList()
              ..sort((a, b) => a.path.compareTo(b.path));
        if (imageFiles.isNotEmpty) {
          await imageFiles.first.copy(outputPath);
        } else {
          throw Exception('No images were generated from the PDF');
        }
      }
    } finally {
      // Clean up temporary image directory
      try {
        if (await Directory(imageDir).exists()) {
          await Directory(imageDir).delete(recursive: true);
        }
      } catch (_) {}
    }
  }

  Future<void> _convertUsingLibreOffice(
    ConversionFormat format,
    String outputPath,
  ) async {
    if (Platform.isAndroid) {
      // Android: Office formats not directly supported - offer web alternative
      _showWebConversionDialog(format);
      return;
    }

    final outDir = Directory(outputPath).parent.path;

    // Ensure output directory exists before LibreOffice tries to use it
    if (!await Directory(outDir).exists()) {
      await Directory(outDir).create(recursive: true);
    }

    final outFileName = path_lib
        .basename(_selectedPdfPath!)
        .replaceAll(RegExp(r'\.[^.]*$'), '');

    final formatMap = {
      'Word': 'docx',
      'DOCX': 'docx',
      'PowerPoint': 'pptx',
      'PPTX': 'pptx',
      'Excel': 'xlsx',
      'XLSX': 'xlsx',
      'ODT': 'odt',
      'ODS': 'ods',
      'ODP': 'odp',
      'HTML': 'html',
      'RTF': 'rtf',
      'EPUB': 'epub',
    };

    final outFormat = formatMap[format.format] ?? format.fileExtension;

    try {
      final result = await Process.run('libreoffice', [
        '--headless',
        '--convert-to',
        outFormat,
        '--outdir',
        outDir,
        _selectedPdfPath!,
      ]);

      if (result.exitCode != 0) {
        throw Exception('LibreOffice conversion failed: ${result.stderr}');
      }

      // LibreOffice generates files with its own naming, rename to desired output
      final generatedFile = File('$outDir/$outFileName.$outFormat');
      if (await generatedFile.exists()) {
        await generatedFile.rename(outputPath);
      }
    } catch (e) {
      // Clean up any partially generated files
      try {
        if (await File(outputPath).exists()) {
          await File(outputPath).delete();
        }
      } catch (_) {}
      rethrow;
    }
  }

  Future<void> _convertToSecurePdf(String outputPath) async {
    final outDir = File(outputPath).parent;
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    }

    if (Platform.isAndroid) {
      // Android: Use method channel to encrypt PDF using PDFBox
      try {
        final result = await platform.invokeMethod<String>('encryptPdf', {
          'inputPath': _selectedPdfPath!,
          'outputPath': outputPath,
          'userPassword': 'user',
          'ownerPassword': 'owner',
        });
        if (result == null || result.isEmpty) {
          throw Exception('Failed to create secure PDF');
        }
      } catch (e) {
        throw Exception('Secure PDF creation failed: $e');
      }
    } else {
      // Desktop: Use qpdf command
      final result = await Process.run('qpdf', [
        '--encrypt',
        'userpassword',
        'ownerpassword',
        '256',
        '--',
        _selectedPdfPath!,
        outputPath,
      ]);

      if (result.exitCode != 0) {
        throw Exception('Secure PDF creation failed: ${result.stderr}');
      }
    }
  }

  Future<void> _convertToPdfA(String outputPath) async {
    final outDir = File(outputPath).parent;
    if (!await outDir.exists()) {
      await outDir.create(recursive: true);
    }

    if (Platform.isAndroid) {
      // Android: Create PDF/A compliant PDF using method channel
      try {
        final result = await platform.invokeMethod<String>('createPdfA', {
          'inputPath': _selectedPdfPath!,
          'outputPath': outputPath,
        });
        if (result == null || result.isEmpty) {
          throw Exception('Failed to create PDF/A');
        }
      } catch (e) {
        throw Exception('PDF/A conversion failed: $e');
      }
    } else {
      // Desktop: PDF/A conversion using ghostscript
      final result = await Process.run('gs', [
        '-sDEVICE=pdfwrite',
        '-dPDFA=1',
        '-sOutputFile=$outputPath',
        '-f',
        _selectedPdfPath!,
      ]);

      if (result.exitCode != 0) {
        throw Exception('PDF/A conversion failed: ${result.stderr}');
      }
    }
  }

  void _showWebConversionDialog(ConversionFormat format) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${format.format} Conversion'),
        content: Text(
          'PDF to ${format.format} conversion requires a desktop application or online service.\n\n'
          'Recommended online converters:\n'
          '• CloudConvert.com\n'
          '• Zamzar.com\n'
          '• AnyConv.com\n\n'
          'Or use LibreOffice on Windows/macOS/Linux.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
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
        actions: [ThemeSwitcher(compact: true), const SizedBox(width: 8)],
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

class Path {
  static String basename(String path) {
    return path.split(Platform.pathSeparator).last;
  }
}

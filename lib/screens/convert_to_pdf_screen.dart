import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:openpdf_tools/widgets/in_app_file_picker.dart';
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

  // Supported formats
  static const Map<String, String> supportedFormats = {
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

  Future<void> pickFile(String format) async {
    try {
      final extensions = supportedFormats[format]!.split(',');
      
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: extensions,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFormat = format;
          _selectedFile = File(result.files.first.path!);
        });
        await _convertToPdf();
      }
    } catch (e) {
      // Fallback to in-app picker on Linux
      // ignore: use_build_context_synchronously
      final choice = await showDialog<String>(
        // ignore: use_build_context_synchronously
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
      // ignore: use_build_context_synchronously
        // ignore: use_build_context_synchronously

        final selected = await showInAppFilePicker(
          // ignore: use_build_context_synchronously
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
          ScaffoldMessenger.of(context).showSnackBar(
            // ignore: use_build_context_synchronously

            const SnackBar(content: Text('File not found')),
          );
        }
      }
    }
  }

  Future<void> _convertToPdf() async {
    if (_selectedFile == null || _selectedFormat == null) return;

    setState(() => _isProcessing = true);

    try {
      final fileExtension = _selectedFile!.path.split('.').last.toLowerCase();
      String? outputPath;

      // Image formats
      if (['jpg', 'jpeg', 'png', 'webp', 'heic', 'gif', 'bmp'].contains(fileExtension)) {
        outputPath = await _convertImageToPdf(_selectedFile!);
      } 
      // Text files
      else if (fileExtension == 'txt') {
        outputPath = await _convertTextToPdf(_selectedFile!);
      }
      // Office formats using LibreOffice
      else if (['docx', 'doc', 'xlsx', 'xls', 'pptx', 'ppt', 'odt', 'ods', 'odp'].contains(fileExtension)) {
        outputPath = await _convertOfficeFormatToPdf(_selectedFile!);
      }
      // Other formats
      else {
        throw Exception('Unsupported format: $fileExtension\n\nFor complex formats like $fileExtension, you may need to use an external service or install LibreOffice.');
      }

      if (outputPath != null && await File(outputPath).exists()) {
        await _showSuccessDialog(outputPath);
      } else {
        throw Exception('PDF conversion failed');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          // ignore: use_build_context_synchronously

          // ignore: use_build_context_synchronously


          // ignore: use_build_context_synchronously



          SnackBar(content: Text('Error: $e')),
        );
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
          build: (pw.Context context) {
            return pw.Image(pw.MemoryImage(imageBytes));
          },
        ),
      );

      final tempDir = await getTemporaryDirectory();
      final outputPath = '${tempDir.path}/converted_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(outputPath);
      await file.writeAsBytes(await pdf.save());

      return outputPath;
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> _convertTextToPdf(File textFile) async {
    try {
      final content = await textFile.readAsString();
      
      final pdf = pw.Document();
      
      // Split content into multiple pages if needed
      final lines = content.split('\n');
      int linesPerPage = 50;
      
      for (int i = 0; i < lines.length; i += linesPerPage) {
        final pageLines = lines.sublist(
          i,
          i + linesPerPage > lines.length ? lines.length : i + linesPerPage,
        ).join('\n');
        
        pdf.addPage(
          pw.Page(
            build: (pw.Context context) {
              return pw.Padding(
                padding: const pw.EdgeInsets.all(20),
                child: pw.Text(
                  pageLines,
                  style: const pw.TextStyle(fontSize: 12),
                ),
              );
            },
          ),
        );
      }

      final tempDir = await getTemporaryDirectory();
      final outputPath = '${tempDir.path}/converted_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File(outputPath);
      await file.writeAsBytes(await pdf.save());

      return outputPath;
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> _convertOfficeFormatToPdf(File sourceFile) async {
    try {
      final tempDir = await getTemporaryDirectory();

      // Try using LibreOffice command line tool
      final result = await Process.run(
        'libreoffice',
        [
          '--headless',
          '--convert-to',
          'pdf',
          '--outdir',
          tempDir.path,
          sourceFile.path,
        ],
      );

      if (result.exitCode == 0) {
        // Find the converted file
        final filename = sourceFile.path.split('/').last.split('.').first;
        final convertedFile = File('${tempDir.path}/$filename.pdf');
        
        if (await convertedFile.exists()) {
          return convertedFile.path;
        }
      }

      throw Exception(
        'LibreOffice not found or conversion failed.\n\n'
        'For Office formats (DOCX, XLSX, PPTX, etc.), install LibreOffice:\n'
        'Linux: sudo apt-get install libreoffice\n'
        'macOS: brew install libreoffice\n'
        'Windows: Download from https://www.libreoffice.org/\n\n'
        'Error: ${result.stderr}',
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _showSuccessDialog(String filePath) async {
    final fileSize = await File(filePath).length();
    final sizeInMB = (fileSize / (1024 * 1024)).toStringAsFixed(2);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✓ ${filePath.split('/').last} ($sizeInMB MB)'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Convert to PDF')),
      body: _isProcessing
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Converting file to PDF...'),
                ],
              ),
            )
          : GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              padding: const EdgeInsets.all(12),
              children: supportedFormats.entries.map((entry) {
                return _formatCard(entry.key, entry.value);
              }).toList(),
            ),
    );
  }

  Widget _formatCard(String formatName, String extensions) {
    return InkWell(
      onTap: () => pickFile(formatName),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
          color: Colors.grey.shade50,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForFormat(formatName),
              size: 40,
              color: const Color(0xFFC6302C),
            ),
            const SizedBox(height: 12),
            Text(
              formatName,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              extensions.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForFormat(String format) {
    if (format.contains('Word') || format.contains('DOC')) return Icons.description;
    if (format.contains('PowerPoint') || format.contains('PPT')) return Icons.slideshow;
    if (format.contains('Excel') || format.contains('XLS')) return Icons.table_chart;
    if (format.contains('Image') || format.contains('JPG') || format.contains('PNG') || format.contains('WEBP') || format.contains('HEIC')) return Icons.image;
    if (format.contains('SVG')) return Icons.graphic_eq;
    if (format.contains('TIFF')) return Icons.photo;
    if (format.contains('Text') || format.contains('TXT')) return Icons.text_fields;
    if (format.contains('RTF')) return Icons.article;
    if (format.contains('EPUB')) return Icons.menu_book;
    if (format.contains('OD')) return Icons.file_present;
    return Icons.insert_drive_file;
  }
}

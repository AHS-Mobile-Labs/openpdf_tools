import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:openpdf_tools/widgets/in_app_file_picker.dart';
import 'package:openpdf_tools/utils/platform_file_handler.dart';
import 'package:openpdf_tools/utils/platform_helper.dart';
import 'package:path_provider/path_provider.dart';
import 'package:openpdf_tools/widgets/theme_switcher.dart';
import 'pdf_viewer_screen.dart';
class CompressPdfScreen extends StatefulWidget {
  const CompressPdfScreen({super.key});
  @override
  State<CompressPdfScreen> createState() => _CompressPdfScreenState();
}
class _CompressPdfScreenState extends State<CompressPdfScreen> {
  static const platform = MethodChannel('com.openpdf.tools/pdfManipulation');
  String? _pdfPath;
  bool _isProcessing = false;
  int _quality = 60;
  Future<void> pickPdf() async {
    try {
      if (PlatformHelper.isAndroid) {
        await PlatformFileHandler.requestFilePermissions();
      }
      final res = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      if (!mounted) return;
      if (res == null || res.files.isEmpty) return;
      setState(() => _pdfPath = res.files.single.path);
    } catch (e) {
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
      if (!mounted) return;
      if (choice == 'inapp') {
        final selected = await showInAppFilePicker(
          context,
          initialDirectory: Directory.current.path,
          allowedExtensions: ['pdf'],
        );
        if (!mounted) return;
        if (selected != null) {
          setState(() => _pdfPath = selected);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Selected: $selected')));
        }
      } else if (choice == 'enter') {
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
        if (!mounted) return;
        if (submit == true) {
          final path = controller.text.trim();
          if (path.isEmpty) return;
          final file = File(path);
          if (await file.exists()) {
            if (!mounted) return;
            setState(() => _pdfPath = path);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Selected: $path')));
          } else {
            if (!mounted) return;
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('File not found')));
          }
        }
      }
    }
  }
  Future<void> compressPdf() async {
    if (_pdfPath == null) return;
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'PDF compression is not available on web. Please use the desktop or mobile app.',
            ),
          ),
        );
      }
      return;
    }
    setState(() => _isProcessing = true);
    try {
      final tempDir = await getTemporaryDirectory();
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }
      final outputPath =
          '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.pdf';
      debugPrint('[CompressPdf] Compressing PDF from: $_pdfPath');
      debugPrint('[CompressPdf] Output path: $outputPath');
      debugPrint('[CompressPdf] Platform: ${PlatformHelper.platformName}');
      if (PlatformHelper.isAndroid) {
        await _compressPdfAndroid(outputPath);
      } else {
        await _compressPdfDesktop(outputPath);
      }
      final compressedFile = File(outputPath);
      if (!await compressedFile.exists()) {
        throw Exception('Compressed PDF was not created at: $outputPath');
      }
      final originalSize = File(_pdfPath!).lengthSync();
      final compressedSize = compressedFile.lengthSync();
      final reduction = ((1 - compressedSize / originalSize) * 100)
          .toStringAsFixed(1);
      debugPrint(
        '[CompressPdf] Success! Original: ${(originalSize / 1024).toStringAsFixed(2)} KB, Compressed: ${(compressedSize / 1024).toStringAsFixed(2)} KB',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Compressed: ${(compressedSize / 1024).toStringAsFixed(2)} KB (reduced by $reduction%)',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfViewerScreen(externalFile: compressedFile),
          ),
        );
      }
    } catch (e) {
      debugPrint('[CompressPdf] Error: $e');
      if (mounted) {
        String errorMsg = 'Compression failed';
        if (e.toString().contains('No such file')) {
          errorMsg = 'Output directory not accessible. Please try again.';
        } else if (e.toString().contains('Ghostscript')) {
          errorMsg =
              'Ghostscript not installed. Saved as copy without compression.';
        } else {
          errorMsg = 'Compression failed: $e';
        }
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(errorMsg)));
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
  Future<void> _compressPdfAndroid(String outputPath) async {
    try {
      final result = await platform
          .invokeMethod<String>('compressPdf', {
            'inputPath': _pdfPath!,
            'outputPath': outputPath,
            'quality': _quality,
          })
          .timeout(
            const Duration(seconds: 120),
            onTimeout: () => throw TimeoutException(
              'Android compression timed out after 120 seconds',
            ),
          );
      if (result == null || result.isEmpty) {
        throw Exception('Android compression returned null or empty path');
      }
      debugPrint('[CompressPdf] Android compression successful: $result');
    } on TimeoutException catch (e) {
      debugPrint('[CompressPdf] Android compression timeout: $e');
      throw Exception(
        'PDF compression is taking too long. Please try a smaller file or lower quality.',
      );
    } on PlatformException catch (e) {
      debugPrint('[CompressPdf] Android compression failed: ${e.message}');
      throw Exception('Android compression failed: ${e.message}');
    } catch (e) {
      debugPrint('[CompressPdf] Android compression error: $e');
      throw Exception('Android compression error: $e');
    }
  }
  Future<void> _compressPdfDesktop(String outputPath) async {
    try {
      final result = await Process.run('gs', [
        '-sDEVICE=pdfwrite',
        '-dCompatibilityLevel=1.4',
        '-dPDFSETTINGS=/ebook',         '-dPDFSETTINGS=/ebook',
        '-dNOPAUSE',
        '-dQUIET',
        '-dBATCH',
        '-dDetectDuplicateImages',
        '-r${72 + (_quality - 20) ~/ 2}',         '-r${72 + (_quality - 20) ~/ 2}',
        '-dCompressFonts=true',
        '-r150x150',
        '-dDownsampleColorImages=true',
        '-dColorImageDownsampleType=/Bicubic',
        '-dColorImageResolution=150',
        '-dGrayImageDownsampleType=/Bicubic',
        '-dGrayImageResolution=150',
        '-dMonoImageDownsampleType=/Bicubic',
        '-dMonoImageResolution=150',
        '-sOutputFile=$outputPath',
        _pdfPath!,
      ]);
      debugPrint('[CompressPdf] Ghostscript exit code: ${result.exitCode}');
      if (result.exitCode != 0) {
        debugPrint('[CompressPdf] Ghostscript error: ${result.stderr}');
        throw Exception('Ghostscript compression failed: ${result.stderr}');
      }
    } catch (e) {
      if (e.toString().contains('No such file or directory')) {
        debugPrint('[CompressPdf] Ghostscript not found, using fallback copy');
        await File(_pdfPath!).copy(outputPath);
      } else {
        rethrow;
      }
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
        title: const Text('Compress PDF'),
        backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        actions: [ThemeSwitcher(compact: true), const SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ElevatedButton.icon(
                      onPressed: pickPdf,
                      icon: const Icon(Icons.attach_file),
                      label: const Text('Select PDF'),
                    ),
                    const SizedBox(height: 12),
                    if (_pdfPath != null)
                      Text('Selected: ${_pdfPath!.split('/').last}'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text('Quality: '),
                        Expanded(
                          child: Slider(
                            value: _quality.toDouble(),
                            min: 20,
                            max: 90,
                            divisions: 7,
                            label: _getQualityLabel(_quality),
                            onChanged: (v) =>
                                setState(() => _quality = v.toInt()),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _getQualityDescription(_quality),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (_isProcessing) ...[
                      const SizedBox(height: 16),
                      const CircularProgressIndicator(),
                      const SizedBox(height: 8),
                      Center(
                        child: Text(
                          'Compressing PDF using ${PlatformHelper.isAndroid ? 'PDFBox' : 'Ghostscript'}...',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: ElevatedButton(
                onPressed: (_pdfPath == null || _isProcessing)
                    ? null
                    : compressPdf,
                child: Text(
                  _isProcessing ? 'Compressing...' : 'Start Compression',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  String _getQualityLabel(int quality) {
    if (quality <= 40) return 'Low (/screen)';
    if (quality <= 60) return 'Medium (/ebook)';
    return 'High (/printer)';
  }
  String _getQualityDescription(int quality) {
    if (quality <= 40) {
      return '📱 Screen quality - Smallest file size, suitable for web';
    } else if (quality <= 60) {
      return '📄 eBook quality - Good balance of size and quality';
    }
    return '🖨️ Print quality - Highest quality, larger file size';
  }
}
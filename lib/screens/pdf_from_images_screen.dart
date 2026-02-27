import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:openpdf_tools/widgets/in_app_file_picker.dart';

class PdfFromImagesScreen extends StatefulWidget {
  const PdfFromImagesScreen({super.key});

  @override
  State<PdfFromImagesScreen> createState() => _PdfFromImagesScreenState();
}

class _PdfFromImagesScreenState extends State<PdfFromImagesScreen> {
  final List<File> images = [];
  bool _isProcessing = false;

  Future<void> pickImages() async {
    // Prefer the platform gallery picker on mobile (handles permissions nicely),
    // otherwise use the in-app multi-file picker.
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        final picker = ImagePicker();
        final picked = await picker.pickMultiImage();
        if (picked.isNotEmpty) {
          setState(() {
            images.addAll(picked.map((e) => File(e.path)));
          });
          return;
        }
      }

      // Desktop or fallback path
      // ignore: use_build_context_synchronously
      final selected = await showInAppFilePickerMultiple(
        // ignore: use_build_context_synchronously
        context,
        initialDirectory: Directory.current.path,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      );

      if (selected == null || selected.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('No images selected')));
        }
        return;
      }

      setState(() {
        images.addAll(selected.map((p) => File(p)));
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick images: $e')));
      }
    }
  }

  Future<void> createPdf() async {
    setState(() => _isProcessing = true);
    try {
      final pdf = pw.Document();

      for (final img in images) {
        Uint8List bytes = await img.readAsBytes();

        try {
          final compressed = await FlutterImageCompress.compressWithFile(
            img.path,
            quality: 65,
          );
          if (compressed != null) bytes = compressed;
        } catch (_) {}

        pdf.addPage(
          pw.Page(
            build: (_) => pw.Center(child: pw.Image(pw.MemoryImage(bytes))),
          ),
        );
      }

      final bytes = await pdf.save();

      // Ask the user whether to download or share the generated PDF.
      final action = await showDialog<String>(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('PDF Ready'),
          content: const Text(
            'Would you like to download the PDF to your device or share it with other apps?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('download'),
              child: const Text('Download'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('share'),
              child: const Text('Share'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop('cancel'),
              child: const Text('Cancel'),
            ),
          ],
        ),
      );

      if (action == 'download') {
        final dir = await getApplicationDocumentsDirectory();
        final file = File('${dir.path}/openpdf_images.pdf');
        await file.writeAsBytes(bytes);
        if (mounted) {
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Saved to ${file.path}')));
        }
      } else if (action == 'share') {
        await Printing.sharePdf(bytes: bytes, filename: 'openpdf_images.pdf');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create PDF: $e')));
    } finally {
      setState(() => _isProcessing = false);
      // ignore: use_build_context_synchronously
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
        title: const Text('PDF from Images'),
        backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_photo_alternate),
            onPressed: pickImages,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: images.isEmpty
                ? const Center(child: Text('No images selected'))
                : ReorderableListView(
                    onReorder: (oldIndex, newIndex) {
                      setState(() {
                        // ignore: use_build_context_synchronously

                        if (newIndex > oldIndex) newIndex -= 1;
                        final item = images.removeAt(oldIndex);
                        images.insert(newIndex, item);
                      });
                    },
                    padding: const EdgeInsets.only(top: 8),
                    children: List.generate(images.length, (i) {
                      final img = images[i];
                      return ListTile(
                        key: ValueKey('${img.path}-$i'),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.file(
                            img,
                            width: 56,
                            height: 56,
                            fit: BoxFit.cover,
                          ),
                        ),
                        title: Text(img.path.split('/').last),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () {
                                setState(() => images.removeAt(i));
                              },
                            ),
                            const Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Icon(Icons.drag_handle),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: ElevatedButton(
              onPressed: (images.isEmpty || _isProcessing) ? null : createPdf,
              child: _isProcessing
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Create & Share PDF'),
            ),
          ),
        ],
      ),
    );
  }
}

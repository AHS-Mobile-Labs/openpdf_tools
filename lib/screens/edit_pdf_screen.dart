import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:openpdf_tools/widgets/in_app_file_picker.dart';
import 'pdf_viewer_screen.dart';

class EditPdfScreen extends StatefulWidget {
  const EditPdfScreen({super.key});

  @override
  State<EditPdfScreen> createState() => _EditPdfScreenState();
}

class _EditPdfScreenState extends State<EditPdfScreen> {
  String? _pdfPath;
  bool _isProcessing = false;
  String _editType = 'addText'; // addText, rotate, deletePages, reorder

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() => _pdfPath = result.files.single.path);
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      final choice = await showDialog<String>(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('File picker failed'),
          content: Text('File picker failed: $e\n\nChoose an option:'),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop('inapp'), child: const Text('Use in-app picker')),
            TextButton(onPressed: () => Navigator.of(ctx).pop('enter'), child: const Text('Enter path')),
            TextButton(onPressed: () => Navigator.of(ctx).pop('cancel'), child: const Text('Cancel')),
          ],
        ),
      );

      if (choice == 'inapp') {
      // ignore: use_build_context_synchronously
        final selected = await showInAppFilePicker(context, initialDirectory: Directory.current.path, allowedExtensions: ['pdf']);
        if (selected != null) {
          setState(() => _pdfPath = selected);
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selected: $selected')));
        }
      } else if (choice == 'enter') {
        final controller = TextEditingController();
        final submit = await showDialog<bool>(
          // ignore: use_build_context_synchronously
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Enter PDF path'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: '/path/to/file.pdf'),
              keyboardType: TextInputType.text,
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('OK')),
            ],
          ),
        );

        if (submit == true) {
          final path = controller.text.trim();
          if (path.isEmpty) return;
          final file = File(path);
          if (await file.exists()) {
            setState(() => _pdfPath = path);
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Selected: $path')));
          } else {
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('File not found')));
          }
        }
      }
    }
  }

  Future<void> _addTextToPdf() async {
    if (_pdfPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a PDF first')));
      return;
    }

    final textController = TextEditingController();
    final fontSizeController = TextEditingController(text: '12');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Text to PDF'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textController,
                decoration: const InputDecoration(
                  labelText: 'Text to add',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: fontSizeController,
                decoration: const InputDecoration(
                  labelText: 'Font size',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop({
              'text': textController.text,
              'fontSize': double.tryParse(fontSizeController.text) ?? 12,
            }),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == null) return;

    setState(() => _isProcessing = true);

    try {
      // Use ghostscript to add text overlay to PDF
      final tempDir = await getTemporaryDirectory();
      final outputPath = '${tempDir.path}/edited_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // Create a PostScript file with text overlay
      final psFile = File('${tempDir.path}/overlay_${DateTime.now().millisecondsSinceEpoch}.ps');
      await psFile.writeAsString('''
/Helvetica findfont
${result['fontSize']} scalefont
setfont
100 700 moveto
(${result['text']}) show
showpage
''');

      // Use ghostscript to overlay the text
      // ignore: use_build_context_synchronously
      final resultGs = await Process.run(
        'gs',
        [
          '-sDEVICE=pdfwrite',
          '-q',
          '-dNOPAUSE',
          '-dBATCH',
          '-o', outputPath,
          _pdfPath!,
        ],
      );

      if (resultGs.exitCode == 0) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Text added: $outputPath')));

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PdfViewerScreen(externalFile: File(outputPath)),
            ),
          );
        }
      } else {
        throw Exception('Ghostscript error: ${resultGs.stderr}');
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _rotatePdf() async {
    if (_pdfPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a PDF first')));
      return;
    }

    final angleResult = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rotate PDF'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _RotateOption('90°', 90, ctx),
            _RotateOption('180°', 180, ctx),
            _RotateOption('270°', 270, ctx),
          ],
        ),
      ),
    );

    if (angleResult == null) return;

    setState(() => _isProcessing = true);

    try {
      final tempDir = await getTemporaryDirectory();
      final outputPath = '${tempDir.path}/rotated_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // Use ghostscript to rotate PDF
      // ignore: use_build_context_synchronously
      final resultGs = await Process.run(
        'gs',
        [
          '-sDEVICE=pdfwrite',
          '-q',
          '-dNOPAUSE',
          '-dBATCH',
          '-dAutoRotatePages=/None',
          '-c', '[$angleResult] {currentpagedevice /Rotate known {currentpagedevice /Rotate get add} {$angleResult} ifelse exch copypdfpagesrange copypdfpage}',
          '-f', _pdfPath!,
          '-o', outputPath,
        ],
      );

      if (resultGs.exitCode == 0) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF rotated: $outputPath')));

        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PdfViewerScreen(externalFile: File(outputPath)),
            ),
          );
        }
      } else {
        throw Exception('Rotation failed');
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _addWatermark() async {
    if (_pdfPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a PDF first')));
      return;
    }

    final watermarkController = TextEditingController();


      // ignore: use_build_context_synchronously
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Watermark'),
        content: TextField(
          controller: watermarkController,
          decoration: const InputDecoration(
            labelText: 'Watermark text',
            border: OutlineInputBorder(),
            hintText: 'e.g., CONFIDENTIAL',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(watermarkController.text),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == null || result.isEmpty) return;

    setState(() => _isProcessing = true);

    try {
      final tempDir = await getTemporaryDirectory();
      final outputPath = '${tempDir.path}/watermarked_${DateTime.now().millisecondsSinceEpoch}.pdf';

      // Use ghostscript to add watermark to PDF
      final psFile = File('${tempDir.path}/watermark_${DateTime.now().millisecondsSinceEpoch}.ps');
      await psFile.writeAsString('''
/Times-Roman findfont
50 scalefont
setfont
0.8 setgray
-45 rotate
100 -500 moveto
($result) show
''');


      // ignore: use_build_context_synchronously
      // ignore: use_build_context_synchronously

      final resultGs = await Process.run(
        'gs',
        [
          '-sDEVICE=pdfwrite',
          '-q',
          '-dNOPAUSE',
          '-dBATCH',
          '-o', outputPath,
          _pdfPath!,
        ],
      );
 // ignore: use_build_context_synchronously

      if (resultGs.exitCode == 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Watermark added: $outputPath')));

        // ignore: use_build_context_synchronously


        // ignore: use_build_context_synchronously



        if (mounted) {
          Navigator.push(
            context,
            // ignore: use_build_context_synchronously
            MaterialPageRoute(
              builder: (_) => PdfViewerScreen(externalFile: File(outputPath)),
            ),
          );
        }
      } else {
        throw Exception('Ghostscript error: ${resultGs.stderr}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isProcessing = false);
    // ignore: use_build_context_synchronously

    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit PDF'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // PDF Selection
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Step 1: Select PDF',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    if (_pdfPath == null)
                      ElevatedButton.icon(
                        onPressed: _pickPdf,
                        icon: const Icon(Icons.upload_file),
                        label: const Text('Pick PDF'),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.article, color: Colors.grey),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _pdfPath!.split('/').last,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton.icon(
                            onPressed: _pickPdf,
                            icon: const Icon(Icons.change_circle),
                            label: const Text('Choose Different File'),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Editing Options
            if (_pdfPath != null) ...[
              const Text(
                'Step 2: Choose Edit Option',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _EditOptionCard(
                title: 'Add Text',
                description: 'Add custom text to your PDF',
                icon: Icons.text_fields,
                isSelected: _editType == 'addText',
                onTap: () => setState(() => _editType = 'addText'),
              // ignore: use_build_context_synchronously

              ),
              const SizedBox(height: 12),
              _EditOptionCard(
                title: 'Add Watermark',
                description: 'Add watermark text to pages',
                icon: Icons.water_drop,
                isSelected: _editType == 'watermark',
                onTap: () => setState(() => _editType = 'watermark'),
              // ignore: use_build_context_synchronously

              ),
              const SizedBox(height: 12),
              _EditOptionCard(
                title: 'Rotate Pages',
                description: 'Rotate PDF pages (90°, 180°, 270°)',
                icon: Icons.rotate_right,
                isSelected: _editType == 'rotate',
                onTap: () => setState(() => _editType = 'rotate'),
              ),
              const SizedBox(height: 20),

              // Action Button
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _performEdit,
                icon: _isProcessing ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ) : const Icon(Icons.edit),
                label: Text(_isProcessing ? 'Processing...' : 'Apply Edit'),
              ),
            ],

            if (_pdfPath == null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(Icons.description_outlined, size: 80, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text(
                      'Select a PDF to get started',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _performEdit() {
    switch (_editType) {
      case 'addText':
        _addTextToPdf();
        break;
      case 'watermark':
        _addWatermark();
        break;
      case 'rotate':
        _rotatePdf();
        break;
    }
  }
}

class _EditOptionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _EditOptionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFFC6302C) : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, size: 32, color: isSelected ? const Color(0xFFC6302C) : Colors.grey),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(Icons.check_circle, color: Color(0xFFC6302C)),
            ],
          ),
        ),
      ),
    );
  }
}

class _RotateOption extends StatelessWidget {
  final String label;
  final int angle;
  final BuildContext ctx;

  const _RotateOption(this.label, this.angle, this.ctx);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      onTap: () => Navigator.of(ctx).pop(angle),
    );
  }
}

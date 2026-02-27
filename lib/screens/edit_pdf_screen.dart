import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:openpdf_tools/services/pdf_editing_service.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'pdf_viewer_screen.dart';

class EditPdfScreen extends StatefulWidget {
  const EditPdfScreen({super.key});

  @override
  State<EditPdfScreen> createState() => _EditPdfScreenState();
}

class _EditPdfScreenState extends State<EditPdfScreen>
    with TickerProviderStateMixin {
  String? _pdfPath;
  bool _isProcessing = false;
  String _editType = 'addText';
  late AnimationController _backgroundColorAnimationController;
  late Animation<Color?> _backgroundColorAnimation;
  Color _selectedBackgroundColor = Colors.white;
  String? _previewPath;
  bool _showPreviewModal = false;

  @override
  void initState() {
    super.initState();
    _backgroundColorAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _backgroundColorAnimation =
        ColorTween(begin: Colors.white, end: Colors.white).animate(
          CurvedAnimation(
            parent: _backgroundColorAnimationController,
            curve: Curves.easeInOut,
          ),
        );
  }

  @override
  void dispose() {
    _backgroundColorAnimationController.dispose();
    super.dispose();
  }

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

      if (choice == 'enter') {
        final controller = TextEditingController();
        if (!mounted) return;
        final custom = await showDialog<String>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Enter PDF path'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: '/path/to/file.pdf'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(controller.text),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (custom != null && custom.isNotEmpty) {
          setState(() => _pdfPath = custom);
        }
      }
    }
  }

  Future<void> _updatePreview() async {
    if (_pdfPath == null) return;
    try {
      String? preview;
      switch (_editType) {
        case 'addText':
          preview = await PdfEditingService.addTextToPdf(
            inputPath: _pdfPath!,
            text: 'Preview Text',
            fontSize: 16,
          );
          break;
        case 'watermark':
          preview = await PdfEditingService.addWatermarkWithPlacement(
            inputPath: _pdfPath!,
            text: 'Preview',
            placement: 'center',
            opacity: 0.2,
            fontSize: 16,
          );
          break;
        case 'rotate':
          preview = await PdfEditingService.rotatePdf(
            inputPath: _pdfPath!,
            angle: 90,
          );
          break;
        case 'crop':
          preview = await PdfEditingService.cropPdf(
            inputPath: _pdfPath!,
            cropBox: [0, 0, 612, 792],
          );
          break;
        case 'bgColor':
          final r = ((_selectedBackgroundColor.r * 255.0).round().clamp(
            0,
            255,
          ));
          final g = ((_selectedBackgroundColor.g * 255.0).round().clamp(
            0,
            255,
          ));
          final b = ((_selectedBackgroundColor.b * 255.0).round().clamp(
            0,
            255,
          ));
          final colorHex =
              '#${((r << 16) | (g << 8) | b).toRadixString(16).toUpperCase().padLeft(6, '0')}';
          preview = await PdfEditingService.changeBackgroundColor(
            inputPath: _pdfPath!,
            hexColor: colorHex,
          );
          break;
        case 'compress':
          preview = await PdfEditingService.compressPdf(inputPath: _pdfPath!);
          break;
      }
      if (mounted) {
        setState(() => _previewPath = preview);
      }
    } catch (e) {
      // Preview generation failed, ignore silently
    }
  }

  Future<void> _addTextToPdf() async {
    if (_pdfPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF first')),
      );
      return;
    }

    final textController = TextEditingController(text: 'Sample Text');
    final fontSizeController = TextEditingController(text: '20');

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
                  labelText: 'Text',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: fontSizeController,
                decoration: const InputDecoration(
                  labelText: 'Font Size',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop({
              'text': textController.text,
              'fontSize': double.parse(fontSizeController.text),
            }),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == null) return;

    setState(() => _isProcessing = true);
    try {
      final outputPath = await PdfEditingService.addTextToPdf(
        inputPath: _pdfPath!,
        text: result['text'],
        fontSize: result['fontSize'],
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Text added: ${File(outputPath).path.split('/').last}'),
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(externalFile: File(outputPath)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _rotatePdf() async {
    if (_pdfPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF first')),
      );
      return;
    }

    final angle = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Rotation Angle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('90°'),
              onTap: () => Navigator.of(context).pop(90),
            ),
            ListTile(
              title: const Text('180°'),
              onTap: () => Navigator.of(context).pop(180),
            ),
            ListTile(
              title: const Text('270°'),
              onTap: () => Navigator.of(context).pop(270),
            ),
          ],
        ),
      ),
    );

    if (angle == null) return;

    setState(() => _isProcessing = true);
    try {
      final outputPath = await PdfEditingService.rotatePdf(
        inputPath: _pdfPath!,
        angle: angle,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Rotated by $angle°: ${File(outputPath).path.split('/').last}',
          ),
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(externalFile: File(outputPath)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _addWatermarkWithPlacement() async {
    if (_pdfPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF first')),
      );
      return;
    }

    final watermarkController = TextEditingController(text: 'WATERMARK');
    final opacityController = TextEditingController(text: '0.5');

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Watermark'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: watermarkController,
                decoration: const InputDecoration(
                  labelText: 'Watermark Text',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButton<String>(
                isExpanded: true,
                value: 'center',
                items:
                    [
                          'top-left',
                          'top-center',
                          'top-right',
                          'center',
                          'bottom-left',
                          'bottom-center',
                          'bottom-right',
                        ]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                onChanged: (v) {},
              ),
              const SizedBox(height: 12),
              TextField(
                controller: opacityController,
                decoration: const InputDecoration(
                  labelText: 'Opacity (0.0 - 1.0)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop({
              'watermark': watermarkController.text,
              'placement': 'center',
              'opacity': double.parse(opacityController.text),
            }),
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result == null) return;

    setState(() => _isProcessing = true);
    try {
      final outputPath = await PdfEditingService.addWatermarkWithPlacement(
        inputPath: _pdfPath!,
        text: result['watermark'],
        placement: result['placement'],
        opacity: result['opacity'],
        fontSize: 20,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Watermark added: ${File(outputPath).path.split('/').last}',
          ),
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(externalFile: File(outputPath)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _cropPdf() async {
    if (_pdfPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF first')),
      );
      return;
    }

    final leftController = TextEditingController(text: '0');
    final bottomController = TextEditingController(text: '0');
    final rightController = TextEditingController(text: '612');
    final topController = TextEditingController(text: '792');

    final result = await showDialog<List<double>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Crop PDF'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Crop dimensions (in points, 1 inch = 72 points):'),
              const SizedBox(height: 12),
              TextField(
                controller: leftController,
                decoration: const InputDecoration(
                  labelText: 'Left',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: bottomController,
                decoration: const InputDecoration(
                  labelText: 'Bottom',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: rightController,
                decoration: const InputDecoration(
                  labelText: 'Right',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: topController,
                decoration: const InputDecoration(
                  labelText: 'Top',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop([
              double.parse(leftController.text),
              double.parse(bottomController.text),
              double.parse(rightController.text),
              double.parse(topController.text),
            ]),
            child: const Text('Crop'),
          ),
        ],
      ),
    );

    if (result == null) return;

    setState(() => _isProcessing = true);
    try {
      final outputPath = await PdfEditingService.cropPdf(
        inputPath: _pdfPath!,
        cropBox: result,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PDF cropped: ${File(outputPath).path.split('/').last}',
          ),
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(externalFile: File(outputPath)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _changeBackgroundColor() async {
    if (_pdfPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF first')),
      );
      return;
    }

    Color pickedColor = _selectedBackgroundColor;

    // ignore: use_build_context_synchronously
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pick Background Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickedColor,
            onColorChanged: (color) => pickedColor = color,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    setState(() => _isProcessing = true);
    try {
      _backgroundColorAnimation =
          ColorTween(begin: _selectedBackgroundColor, end: pickedColor).animate(
            CurvedAnimation(
              parent: _backgroundColorAnimationController,
              curve: Curves.easeInOut,
            ),
          );
      _backgroundColorAnimationController.forward(from: 0);

      final r = ((pickedColor.r * 255.0).round().clamp(0, 255));
      final g = ((pickedColor.g * 255.0).round().clamp(0, 255));
      final b = ((pickedColor.b * 255.0).round().clamp(0, 255));
      final colorHex =
          '#${((r << 16) | (g << 8) | b).toRadixString(16).toUpperCase().padLeft(6, '0')}';

      final outputPath = await PdfEditingService.changeBackgroundColor(
        inputPath: _pdfPath!,
        hexColor: colorHex,
      );

      setState(() => _selectedBackgroundColor = pickedColor);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Background color changed: ${File(outputPath).path.split('/').last}',
          ),
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(externalFile: File(outputPath)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _compressPdf() async {
    if (_pdfPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF first')),
      );
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final outputPath = await PdfEditingService.compressPdf(
        inputPath: _pdfPath!,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'PDF compressed: ${File(outputPath).path.split('/').last}',
          ),
        ),
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerScreen(externalFile: File(outputPath)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  void _performEdit() {
    switch (_editType) {
      case 'addText':
        _addTextToPdf();
        break;
      case 'watermark':
        _addWatermarkWithPlacement();
        break;
      case 'rotate':
        _rotatePdf();
        break;
      case 'crop':
        _cropPdf();
        break;
      case 'bgColor':
        _changeBackgroundColor();
        break;
      case 'compress':
        _compressPdf();
        break;
    }
    _updatePreview();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width > 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F0F)
          : const Color(0xFFFAFAFA),
      appBar: AppBar(
        title: const Text('Edit PDF'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
      ),
      body: AnimatedBuilder(
        animation: _backgroundColorAnimation,
        builder: (context, child) {
          return Container(
            color: isDark
                ? const Color(0xFF0F0F0F)
                : (_backgroundColorAnimation.value ?? const Color(0xFFFAFAFA)),
            child: child,
          );
        },
        child: isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _buildEditPanel()),
                  Expanded(
                    flex: 3,
                    child: Container(
                      color: isDark
                          ? const Color(0xFF1C1C1C)
                          : Colors.grey.shade100,
                      padding: const EdgeInsets.all(16),
                      child: _previewPath != null
                          ? SfPdfViewer.file(File(_previewPath!))
                          : Center(
                              child: Text(
                                'Live Preview will appear here',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ),
                    ),
                  ),
                ],
              )
            : Stack(
                children: [
                  _buildEditPanel(),
                  if (_showPreviewModal && _previewPath != null)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black.withValues(alpha: 0.7),
                        child: Center(
                          child: Material(
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              width: MediaQuery.of(context).size.width * 0.9,
                              height: MediaQuery.of(context).size.height * 0.7,
                              padding: const EdgeInsets.all(16),
                              child: Stack(
                                children: [
                                  SfPdfViewer.file(File(_previewPath!)),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: IconButton(
                                      icon: const Icon(Icons.close),
                                      onPressed: () => setState(
                                        () => _showPreviewModal = false,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
      ),
    );
  }

  Widget _buildEditPanel() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
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
                            color: isDark
                                ? const Color(0xFF1C1C1C)
                                : Colors.grey.shade100,
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
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _EditOptionCard(
              title: 'Add Watermark',
              description: 'Add watermark with placement control',
              icon: Icons.water_drop,
              isSelected: _editType == 'watermark',
              onTap: () => setState(() => _editType = 'watermark'),
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _EditOptionCard(
              title: 'Rotate Pages',
              description: 'Rotate PDF pages (90°, 180°, 270°)',
              icon: Icons.rotate_right,
              isSelected: _editType == 'rotate',
              onTap: () => setState(() => _editType = 'rotate'),
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _EditOptionCard(
              title: 'Crop PDF',
              description: 'Crop PDF to custom dimensions',
              icon: Icons.crop,
              isSelected: _editType == 'crop',
              onTap: () => setState(() => _editType = 'crop'),
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _EditOptionCard(
              title: 'Background Color',
              description: 'Change background color with animation',
              icon: Icons.palette,
              isSelected: _editType == 'bgColor',
              onTap: () => setState(() => _editType = 'bgColor'),
              isDark: isDark,
            ),
            const SizedBox(height: 12),
            _EditOptionCard(
              title: 'Compress',
              description: 'Compress PDF to reduce file size',
              icon: Icons.compress,
              isSelected: _editType == 'compress',
              onTap: () => setState(() => _editType = 'compress'),
              isDark: isDark,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _performEdit,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.edit),
              label: Text(_isProcessing ? 'Processing...' : 'Apply Edit'),
            ),
            if (_previewPath != null &&
                MediaQuery.of(context).size.width <= 900)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.visibility),
                  label: const Text('Show Live Preview'),
                  onPressed: () => setState(() => _showPreviewModal = true),
                ),
              ),
          ],
          if (_pdfPath == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(
                    Icons.description_outlined,
                    size: 80,
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Select a PDF to get started',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _EditOptionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;

  const _EditOptionCard({
    required this.title,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: isSelected ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected
              ? const Color(0xFFC6302C)
              : (isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade300),
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
              Icon(
                icon,
                size: 32,
                color: isSelected
                    ? const Color(0xFFC6302C)
                    : (isDark ? Colors.grey.shade400 : Colors.grey),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                      ),
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

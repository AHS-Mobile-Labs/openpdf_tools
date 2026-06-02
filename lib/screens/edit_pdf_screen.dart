import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:openpdf_tools/config/premium_theme.dart';
import 'package:openpdf_tools/utils/platform_file_handler.dart';
import 'package:openpdf_tools/utils/platform_helper.dart';
import 'package:openpdf_tools/utils/output_path_helper.dart';
import 'package:openpdf_tools/utils/uri_to_file.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:openpdf_tools/services/pdf_editing_service.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:openpdf_tools/widgets/theme_switcher.dart';
import 'package:path/path.dart' as p;
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
  String _watermarkPlacement = 'center';
  late TextEditingController _cropLeftController;
  late TextEditingController _cropBottomController;
  late TextEditingController _cropRightController;
  late TextEditingController _cropTopController;
  @override
  void initState() {
    super.initState();
    _cropLeftController = TextEditingController(text: '0');
    _cropBottomController = TextEditingController(text: '0');
    _cropRightController = TextEditingController(text: '612');
    _cropTopController = TextEditingController(text: '792');
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
    _cropLeftController.dispose();
    _cropBottomController.dispose();
    _cropRightController.dispose();
    _cropTopController.dispose();
    _backgroundColorAnimationController.dispose();
    super.dispose();
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
      if (result != null && result.files.single.path != null) {
        final realPath = await resolveToRealPath(result.files.single.path!);
        if (!mounted) return;
        setState(() => _pdfPath = realPath);
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

  Future<void> _showEditResult(String message, String outputPath) async {
    final savedFile = await OutputPathHelper.exportGeneratedFile(
      sourcePath: outputPath,
      fileName: outputPath.split(Platform.pathSeparator).last,
      category: OutputCategory.exports,
    );
    if (!mounted) return;
    setState(() => _previewPath = savedFile.workingPath);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$message Saved to ${savedFile.displayPath}'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            if (!mounted) return;
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    PdfViewerScreen(externalFile: File(savedFile.workingPath)),
              ),
            );
          },
        ),
      ),
    );
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
            onPressed: () {
              final fontSize = double.tryParse(fontSizeController.text);
              if (fontSize == null || fontSize <= 0) return;
              Navigator.of(
                ctx,
              ).pop({'text': textController.text, 'fontSize': fontSize});
            },
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
      await _showEditResult(
        'Text added: ${File(outputPath).path.split('/').last}',
        outputPath,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
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
      await _showEditResult(
        'Rotated by $angle°: ${File(outputPath).path.split('/').last}',
        outputPath,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
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
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
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
                  value: _watermarkPlacement,
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
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (v) {
                    final placement = v ?? 'center';
                    setState(() => _watermarkPlacement = placement);
                    setDialogState(() {});
                  },
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
              onPressed: () {
                final opacity = double.tryParse(opacityController.text);
                if (opacity == null || opacity < 0 || opacity > 1) return;
                Navigator.of(ctx).pop({
                  'watermark': watermarkController.text,
                  'placement': _watermarkPlacement,
                  'opacity': opacity,
                });
              },
              child: const Text('Add'),
            ),
          ],
        ),
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
      await _showEditResult(
        'Watermark added: ${File(outputPath).path.split('/').last}',
        outputPath,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _cropPdf() async {
    if (_pdfPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF first')),
      );
      return;
    }
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
                controller: _cropLeftController,
                decoration: const InputDecoration(
                  labelText: 'Left',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _cropBottomController,
                decoration: const InputDecoration(
                  labelText: 'Bottom',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _cropRightController,
                decoration: const InputDecoration(
                  labelText: 'Right',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _cropTopController,
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
            onPressed: () {
              final left = double.tryParse(_cropLeftController.text);
              final bottom = double.tryParse(_cropBottomController.text);
              final right = double.tryParse(_cropRightController.text);
              final top = double.tryParse(_cropTopController.text);
              if (left == null ||
                  bottom == null ||
                  right == null ||
                  top == null ||
                  right <= left ||
                  top <= bottom) {
                return;
              }
              Navigator.of(ctx).pop([left, bottom, right, top]);
            },
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
      await _showEditResult(
        'PDF cropped: ${File(outputPath).path.split('/').last}',
        outputPath,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _changeBackgroundColor() async {
    if (_pdfPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a PDF first')),
      );
      return;
    }
    final pickedColor = await showDialog<Color>(
      context: context,
      builder: (ctx) {
        Color dialogColor = _selectedBackgroundColor;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('Pick Background Color'),
            content: SingleChildScrollView(
              child: ColorPicker(
                pickerColor: dialogColor,
                onColorChanged: (color) =>
                    setDialogState(() => dialogColor = color),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(dialogColor),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      },
    );
    if (pickedColor == null) return;
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
      if (!mounted) return;
      setState(() => _selectedBackgroundColor = pickedColor);
      await _showEditResult(
        'Background color changed: ${File(outputPath).path.split('/').last}',
        outputPath,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
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
      await _showEditResult(
        'PDF compressed: ${File(outputPath).path.split('/').last}',
        outputPath,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
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
  }

  _EditOperation get _selectedOperation =>
      _editOperations.firstWhere((operation) => operation.id == _editType);

  String get _selectedFileName =>
      _pdfPath == null ? 'No PDF selected' : p.basename(_pdfPath!);

  String get _selectedFileSize {
    if (_pdfPath == null) return '';
    try {
      final file = File(_pdfPath!);
      if (!file.existsSync()) return 'File path ready';
      return _formatBytes(file.lengthSync());
    } catch (_) {
      return 'File path ready';
    }
  }

  String get _previewFileName =>
      _previewPath == null ? '' : p.basename(_previewPath!);

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(2)} MB';
  }

  void _openPreviewFile() {
    if (_previewPath == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(externalFile: File(_previewPath!)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 900;
    final panelWidth = size.width > 1200 ? 480.0 : 420.0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? PremiumColors.darkBg : PremiumColors.lightBg,
      appBar: AppBar(
        title: const Text('Edit PDF Studio'),
        elevation: 0,
        backgroundColor: isDark
            ? PremiumColors.darkSurfacePrimary
            : PremiumColors.lightSurfacePrimary,
        foregroundColor: isDark
            ? PremiumColors.darkText
            : PremiumColors.lightText,
        actions: [
          if (_previewPath != null)
            IconButton(
              icon: const Icon(Icons.visibility_outlined),
              tooltip: 'View output',
              onPressed: _openPreviewFile,
            ),
          ThemeSwitcher(compact: true),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedBuilder(
        animation: _backgroundColorAnimation,
        builder: (context, child) {
          final baseColor = isDark
              ? PremiumColors.darkBg
              : PremiumColors.lightBg;
          final animatedColor = _backgroundColorAnimation.value;
          final canvasColor = animatedColor == null || isDark
              ? baseColor
              : Color.alphaBlend(
                  animatedColor.withValues(alpha: 0.08),
                  baseColor,
                );
          return Container(color: canvasColor, child: child);
        },
        child: SafeArea(
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(width: panelWidth, child: _buildEditPanel()),
                    Container(
                      width: 1,
                      color: isDark
                          ? PremiumColors.darkDivider
                          : PremiumColors.lightDivider,
                    ),
                    Expanded(child: _buildPreviewWorkspace(isWide: true)),
                  ],
                )
              : Stack(
                  children: [
                    _buildEditPanel(),
                    if (_showPreviewModal && _previewPath != null)
                      _buildMobilePreviewOverlay(),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildEditPanel() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        24 + MediaQuery.of(context).padding.bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildEditorHero(isDark),
          const SizedBox(height: 16),
          _buildFilePickerCard(isDark),
          if (_pdfPath != null) ...[
            const SizedBox(height: 16),
            _buildOperationSection(isDark),
            const SizedBox(height: 16),
            _buildSelectedActionCard(isDark),
            if (_previewPath != null) ...[
              const SizedBox(height: 16),
              _buildPreviewReadyCard(isDark),
            ],
          ] else ...[
            const SizedBox(height: 16),
            _buildGettingStartedPanel(isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildEditorHero(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? PremiumColors.darkSurfaceSecondary
            : PremiumColors.lightSurfacePrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? PremiumColors.darkDivider
              : PremiumColors.lightDivider,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.22 : 0.06),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: PremiumColors.luxuryRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.edit_document,
                  color: PremiumColors.luxuryRed,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Edit, polish, export',
                      style: PremiumTypography.headlineLarge.copyWith(
                        color: isDark
                            ? PremiumColors.darkText
                            : PremiumColors.lightText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Choose one focused PDF action and preview the output.',
                      style: PremiumTypography.bodyMedium.copyWith(
                        color: isDark
                            ? PremiumColors.darkTextSecondary
                            : PremiumColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _FeatureBullet(icon: Icons.text_fields, label: 'Text'),
              _FeatureBullet(
                icon: Icons.water_drop_outlined,
                label: 'Watermark',
              ),
              _FeatureBullet(icon: Icons.crop_rotate, label: 'Rotate & crop'),
              _FeatureBullet(icon: Icons.compress, label: 'Compress'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilePickerCard(bool isDark) {
    final surfaceColor = isDark
        ? PremiumColors.darkSurfaceSecondary
        : PremiumColors.lightSurfacePrimary;
    final mutedColor = isDark
        ? PremiumColors.darkTextSecondary
        : PremiumColors.lightTextSecondary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _pdfPath == null
              ? PremiumColors.luxuryRed.withValues(alpha: 0.28)
              : (isDark
                    ? PremiumColors.darkDivider
                    : PremiumColors.lightDivider),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Document',
                style: PremiumTypography.headlineSmall.copyWith(
                  color: isDark
                      ? PremiumColors.darkText
                      : PremiumColors.lightText,
                ),
              ),
              const Spacer(),
              if (_pdfPath != null)
                TextButton.icon(
                  onPressed: _pickPdf,
                  icon: const Icon(Icons.swap_horiz, size: 18),
                  label: const Text('Change'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_pdfPath == null)
            InkWell(
              onTap: _pickPdf,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 22,
                ),
                decoration: BoxDecoration(
                  color: PremiumColors.luxuryRed.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: PremiumColors.luxuryRed.withValues(alpha: 0.22),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.upload_file,
                      color: PremiumColors.luxuryRed,
                      size: 42,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Select a PDF to start editing',
                      style: PremiumTypography.labelLarge.copyWith(
                        color: isDark
                            ? PremiumColors.darkText
                            : PremiumColors.lightText,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your original file stays untouched; exports are saved as new files.',
                      textAlign: TextAlign.center,
                      style: PremiumTypography.bodySmall.copyWith(
                        color: mutedColor,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _pickPdf,
                      icon: const Icon(Icons.folder_open),
                      label: const Text('Pick PDF'),
                    ),
                  ],
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark
                    ? PremiumColors.darkSurfacePrimary
                    : PremiumColors.lightSurfaceSecondary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: PremiumColors.luxuryRed.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf,
                      color: PremiumColors.luxuryRed,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _selectedFileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: PremiumTypography.labelLarge.copyWith(
                            color: isDark
                                ? PremiumColors.darkText
                                : PremiumColors.lightText,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _selectedFileSize,
                          style: PremiumTypography.bodySmall.copyWith(
                            color: mutedColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.check_circle,
                    color: PremiumColors.success.withValues(alpha: 0.9),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOperationSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? PremiumColors.darkSurfaceSecondary
            : PremiumColors.lightSurfacePrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? PremiumColors.darkDivider
              : PremiumColors.lightDivider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Editing tools',
                style: PremiumTypography.headlineSmall.copyWith(
                  color: isDark
                      ? PremiumColors.darkText
                      : PremiumColors.lightText,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: PremiumColors.luxuryBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${_editOperations.length} tools',
                  style: PremiumTypography.labelSmall.copyWith(
                    color: PremiumColors.luxuryBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Pick an action. Each one opens the right settings only when needed.',
            style: PremiumTypography.bodySmall.copyWith(
              color: isDark
                  ? PremiumColors.darkTextSecondary
                  : PremiumColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 620 ? 2 : 1;
              final gap = 12.0;
              final itemWidth =
                  (constraints.maxWidth - (gap * (columns - 1))) / columns;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: _editOperations
                    .map(
                      (operation) => SizedBox(
                        width: itemWidth,
                        child: _EditOptionCard(
                          operation: operation,
                          isSelected: _editType == operation.id,
                          isDark: isDark,
                          onTap: () => setState(() => _editType = operation.id),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedActionCard(bool isDark) {
    final operation = _selectedOperation;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: operation.accent.withValues(alpha: isDark ? 0.18 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: operation.accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: operation.accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(operation.icon, color: operation.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      operation.title,
                      style: PremiumTypography.headlineSmall.copyWith(
                        color: isDark
                            ? PremiumColors.darkText
                            : PremiumColors.lightText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      operation.detail,
                      style: PremiumTypography.bodySmall.copyWith(
                        color: isDark
                            ? PremiumColors.darkTextSecondary
                            : PremiumColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniSpecChip(label: 'Offline', isDark: isDark),
              _MiniSpecChip(label: 'Creates a copy', isDark: isDark),
              _MiniSpecChip(label: operation.outcome, isDark: isDark),
            ],
          ),
          if (_isProcessing) ...[
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 6,
                color: operation.accent,
                backgroundColor: operation.accent.withValues(alpha: 0.18),
              ),
            ),
          ],
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: _isProcessing ? null : _performEdit,
            icon: _isProcessing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(operation.icon),
            label: Text(_isProcessing ? 'Processing...' : operation.ctaLabel),
            style: ElevatedButton.styleFrom(
              backgroundColor: operation.accent,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewReadyCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? PremiumColors.darkSurfaceSecondary
            : PremiumColors.lightSurfacePrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: PremiumColors.success.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: PremiumColors.success.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.done, color: PremiumColors.success),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Output ready',
                  style: PremiumTypography.labelLarge.copyWith(
                    color: isDark
                        ? PremiumColors.darkText
                        : PremiumColors.lightText,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _previewFileName,
                  maxLines: 1,
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
          if (MediaQuery.of(context).size.width <= 900)
            IconButton(
              icon: const Icon(Icons.preview),
              tooltip: 'Preview',
              onPressed: () => setState(() => _showPreviewModal = true),
            )
          else
            TextButton.icon(
              onPressed: _openPreviewFile,
              icon: const Icon(Icons.open_in_new, size: 18),
              label: const Text('Open'),
            ),
        ],
      ),
    );
  }

  Widget _buildGettingStartedPanel(bool isDark) {
    final textColor = isDark ? PremiumColors.darkText : PremiumColors.lightText;
    final mutedColor = isDark
        ? PremiumColors.darkTextSecondary
        : PremiumColors.lightTextSecondary;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? PremiumColors.darkSurfaceSecondary
            : PremiumColors.lightSurfacePrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? PremiumColors.darkDivider
              : PremiumColors.lightDivider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'A cleaner editing flow',
            style: PremiumTypography.headlineSmall.copyWith(color: textColor),
          ),
          const SizedBox(height: 12),
          _WorkflowRow(
            number: '1',
            title: 'Open a PDF',
            description: 'Select a file from device storage.',
            isDark: isDark,
          ),
          _WorkflowRow(
            number: '2',
            title: 'Pick one tool',
            description:
                'Use text, watermark, rotation, crop, color, or compression.',
            isDark: isDark,
          ),
          _WorkflowRow(
            number: '3',
            title: 'Preview and export',
            description: 'Review the generated copy before sharing or saving.',
            isDark: isDark,
            isLast: true,
          ),
          const SizedBox(height: 12),
          Text(
            'Tip: edits are exported as new files, so the source PDF remains available.',
            style: PremiumTypography.bodySmall.copyWith(color: mutedColor),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewWorkspace({required bool isWide}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final background = isDark
        ? PremiumColors.darkSurfacePrimary
        : PremiumColors.lightSurfaceSecondary;
    return Container(
      color: background,
      padding: EdgeInsets.all(isWide ? 18 : 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark
                  ? PremiumColors.darkSurfaceSecondary
                  : PremiumColors.lightSurfacePrimary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? PremiumColors.darkDivider
                    : PremiumColors.lightDivider,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: PremiumColors.luxuryBlue.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.visibility_outlined,
                    color: PremiumColors.luxuryBlue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Live preview',
                        style: PremiumTypography.labelLarge.copyWith(
                          color: isDark
                              ? PremiumColors.darkText
                              : PremiumColors.lightText,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _previewPath == null
                            ? 'Apply an edit to generate a preview.'
                            : _previewFileName,
                        maxLines: 1,
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
                if (_previewPath != null)
                  TextButton.icon(
                    onPressed: _openPreviewFile,
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Full view'),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111111) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? PremiumColors.darkDivider
                      : PremiumColors.lightDivider,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.28 : 0.06),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: _previewPath != null
                  ? SfPdfViewer.file(File(_previewPath!))
                  : _PreviewEmptyState(
                      hasPdf: _pdfPath != null,
                      operation: _selectedOperation,
                      isDark: isDark,
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobilePreviewOverlay() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.72),
        padding: const EdgeInsets.all(16),
        child: Center(
          child: Material(
            color: isDark
                ? PremiumColors.darkSurfacePrimary
                : PremiumColors.lightSurfacePrimary,
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: double.infinity,
              height: MediaQuery.of(context).size.height * 0.74,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _previewFileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: PremiumTypography.labelLarge.copyWith(
                              color: isDark
                                  ? PremiumColors.darkText
                                  : PremiumColors.lightText,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.open_in_new),
                          tooltip: 'Full view',
                          onPressed: _openPreviewFile,
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          tooltip: 'Close',
                          onPressed: () =>
                              setState(() => _showPreviewModal = false),
                        ),
                      ],
                    ),
                  ),
                  Divider(
                    height: 1,
                    color: isDark
                        ? PremiumColors.darkDivider
                        : PremiumColors.lightDivider,
                  ),
                  Expanded(child: SfPdfViewer.file(File(_previewPath!))),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

const List<_EditOperation> _editOperations = [
  _EditOperation(
    id: 'addText',
    title: 'Add Text',
    description: 'Place custom text on the document.',
    detail:
        'Add labels, notes, or quick corrections using your chosen text size.',
    outcome: 'Text layer',
    ctaLabel: 'Add Text',
    icon: Icons.text_fields,
    accent: PremiumColors.luxuryRed,
  ),
  _EditOperation(
    id: 'watermark',
    title: 'Watermark',
    description: 'Add branded or confidential marks.',
    detail: 'Control placement and opacity for subtle stamps across the PDF.',
    outcome: 'Placement',
    ctaLabel: 'Add Watermark',
    icon: Icons.water_drop_outlined,
    accent: PremiumColors.luxuryBlue,
  ),
  _EditOperation(
    id: 'rotate',
    title: 'Rotate Pages',
    description: 'Fix page orientation quickly.',
    detail:
        'Rotate pages by 90, 180, or 270 degrees and export a corrected copy.',
    outcome: 'Orientation',
    ctaLabel: 'Rotate Pages',
    icon: Icons.rotate_right,
    accent: PremiumColors.warning,
  ),
  _EditOperation(
    id: 'crop',
    title: 'Crop PDF',
    description: 'Trim page bounds with point values.',
    detail:
        'Enter page crop dimensions when you need precise printable margins.',
    outcome: 'Margins',
    ctaLabel: 'Crop PDF',
    icon: Icons.crop,
    accent: PremiumColors.luxuryGreen,
  ),
  _EditOperation(
    id: 'bgColor',
    title: 'Background Color',
    description: 'Apply a new PDF background color.',
    detail: 'Pick a color visually and generate a fresh document background.',
    outcome: 'Color',
    ctaLabel: 'Change Color',
    icon: Icons.palette_outlined,
    accent: PremiumColors.info,
  ),
  _EditOperation(
    id: 'compress',
    title: 'Compress',
    description: 'Reduce file size for sharing.',
    detail: 'Create a smaller copy that is easier to send or store.',
    outcome: 'Smaller file',
    ctaLabel: 'Compress PDF',
    icon: Icons.compress,
    accent: PremiumColors.luxuryRed,
  ),
];

class _EditOperation {
  final String id;
  final String title;
  final String description;
  final String detail;
  final String outcome;
  final String ctaLabel;
  final IconData icon;
  final Color accent;
  const _EditOperation({
    required this.id,
    required this.title,
    required this.description,
    required this.detail,
    required this.outcome,
    required this.ctaLabel,
    required this.icon,
    required this.accent,
  });
}

class _EditOptionCard extends StatelessWidget {
  final _EditOperation operation;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isDark;
  const _EditOptionCard({
    required this.operation,
    required this.isSelected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? PremiumColors.darkText : PremiumColors.lightText;
    final mutedColor = isDark
        ? PremiumColors.darkTextSecondary
        : PremiumColors.lightTextSecondary;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: isSelected
            ? operation.accent.withValues(alpha: isDark ? 0.18 : 0.08)
            : (isDark
                  ? PremiumColors.darkSurfacePrimary
                  : PremiumColors.lightSurfaceSecondary),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? operation.accent.withValues(alpha: 0.62)
              : (isDark
                    ? PremiumColors.darkDivider
                    : PremiumColors.lightDivider),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: operation.accent.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(operation.icon, size: 21, color: operation.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      operation.title,
                      style: PremiumTypography.labelLarge.copyWith(
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      operation.description,
                      style: PremiumTypography.bodySmall.copyWith(
                        color: mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(Icons.check_circle, color: operation.accent, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeatureBullet extends StatelessWidget {
  final IconData icon;
  final String label;
  const _FeatureBullet({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: isDark
            ? PremiumColors.darkSurfacePrimary
            : PremiumColors.lightSurfaceSecondary,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isDark
              ? PremiumColors.darkDivider
              : PremiumColors.lightDivider,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: PremiumColors.luxuryRed),
          const SizedBox(width: 6),
          Text(
            label,
            style: PremiumTypography.labelSmall.copyWith(
              color: isDark ? PremiumColors.darkText : PremiumColors.lightText,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniSpecChip extends StatelessWidget {
  final String label;
  final bool isDark;
  const _MiniSpecChip({required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.08)
            : Colors.white.withValues(alpha: 0.76),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: PremiumTypography.labelSmall.copyWith(
          color: isDark ? PremiumColors.darkText : PremiumColors.lightText,
        ),
      ),
    );
  }
}

class _WorkflowRow extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  final bool isDark;
  final bool isLast;
  const _WorkflowRow({
    required this.number,
    required this.title,
    required this.description,
    required this.isDark,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? PremiumColors.darkText : PremiumColors.lightText;
    final mutedColor = isDark
        ? PremiumColors.darkTextSecondary
        : PremiumColors.lightTextSecondary;
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: PremiumColors.luxuryRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  number,
                  style: PremiumTypography.labelSmall.copyWith(
                    color: PremiumColors.luxuryRed,
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 1,
                  height: 26,
                  color: isDark
                      ? PremiumColors.darkDivider
                      : PremiumColors.lightDivider,
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: PremiumTypography.labelLarge.copyWith(
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: PremiumTypography.bodySmall.copyWith(
                    color: mutedColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PreviewEmptyState extends StatelessWidget {
  final bool hasPdf;
  final _EditOperation operation;
  final bool isDark;
  const _PreviewEmptyState({
    required this.hasPdf,
    required this.operation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? PremiumColors.darkText : PremiumColors.lightText;
    final mutedColor = isDark
        ? PremiumColors.darkTextSecondary
        : PremiumColors.lightTextSecondary;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 74,
                height: 74,
                decoration: BoxDecoration(
                  color: operation.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Icon(
                  hasPdf ? operation.icon : Icons.picture_as_pdf_outlined,
                  color: operation.accent,
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                hasPdf ? 'Preview after ${operation.title}' : 'No preview yet',
                textAlign: TextAlign.center,
                style: PremiumTypography.headlineSmall.copyWith(
                  color: textColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hasPdf
                    ? 'Apply the selected edit to generate a reviewable output file.'
                    : 'Choose a PDF, pick an editing tool, and the generated file appears here.',
                textAlign: TextAlign.center,
                style: PremiumTypography.bodyMedium.copyWith(color: mutedColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

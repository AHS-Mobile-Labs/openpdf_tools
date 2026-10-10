import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:openpdf_tools/utils/platform_file_handler.dart';
import 'package:openpdf_tools/utils/platform_helper.dart';
import 'package:openpdf_tools/utils/output_path_helper.dart';
import 'package:openpdf_tools/utils/uri_to_file.dart';
import 'package:printing/printing.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import 'package:path/path.dart' as p;
import 'pdf_viewer_screen.dart';

enum EditorTool {
  select,
  pen,
  highlighter,
  text,
  signature,
  stamp,
  image,
  redact,
}

class DrawingStroke {
  final List<Offset> points;
  final Color color;
  final double strokeWidth;
  final bool isHighlighter;

  DrawingStroke({
    required this.points,
    required this.color,
    required this.strokeWidth,
    this.isHighlighter = false,
  });
}

class TextElement {
  final String id;
  String text;
  Offset position; // Normalized [0..1]
  double fontSize;
  Color color;
  bool isBold;
  Color? backgroundColor;

  TextElement({
    required this.id,
    required this.text,
    required this.position,
    this.fontSize = 18.0,
    this.color = Colors.black,
    this.isBold = false,
    this.backgroundColor,
  });
}

class ImageStampElement {
  final String id;
  final Uint8List imageBytes;
  Offset position; // Normalized [0..1]
  Size size; // Normalized [0..1]
  final bool isSignature;

  ImageStampElement({
    required this.id,
    required this.imageBytes,
    required this.position,
    required this.size,
    this.isSignature = false,
  });
}

class WatermarkElement {
  final String text;
  final Color color;
  final double opacity;
  final double angleDegrees;
  final double fontSize;

  WatermarkElement({
    required this.text,
    this.color = const Color(0xFFE53935),
    this.opacity = 0.35,
    this.angleDegrees = -45,
    this.fontSize = 38,
  });
}

class RedactionElement {
  final String id;
  final Rect rect; // Normalized [0..1]
  final bool isWhiteout;

  RedactionElement({
    required this.id,
    required this.rect,
    this.isWhiteout = false,
  });
}

class PageEdits {
  int rotationDegrees = 0;
  List<DrawingStroke> strokes = [];
  List<TextElement> texts = [];
  List<ImageStampElement> images = [];
  List<RedactionElement> redactions = [];
  WatermarkElement? watermark;

  bool get isEmpty =>
      rotationDegrees == 0 &&
      strokes.isEmpty &&
      texts.isEmpty &&
      images.isEmpty &&
      redactions.isEmpty &&
      watermark == null;

  void undoLast() {
    if (redactions.isNotEmpty) {
      redactions.removeLast();
    } else if (images.isNotEmpty) {
      images.removeLast();
    } else if (texts.isNotEmpty) {
      texts.removeLast();
    } else if (strokes.isNotEmpty) {
      strokes.removeLast();
    } else if (watermark != null) {
      watermark = null;
    }
  }

  void clear() {
    strokes.clear();
    texts.clear();
    images.clear();
    redactions.clear();
    watermark = null;
    rotationDegrees = 0;
  }
}

class EditPdfScreen extends StatefulWidget {
  final String? initialPdfPath;
  const EditPdfScreen({super.key, this.initialPdfPath});

  @override
  State<EditPdfScreen> createState() => _EditPdfScreenState();
}

class _EditPdfScreenState extends State<EditPdfScreen> {
  String? _pdfPath;
  Uint8List? _pdfBytes;
  int _originalPageCount = 0;
  List<int> _activeOriginalIndices = [];
  List<Size> _originalPageSizes = [];

  int _currentPageIndex = 0;
  bool _isLoadingDoc = false;
  bool _isRenderingPage = false;
  bool _isSaving = false;

  final Map<int, Uint8List> _renderedPageCache = {};
  Uint8List? _currentRasterPng;

  // Active page edits mapped by current page index
  final Map<int, PageEdits> _pageEdits = {};

  // Selected tool & drawing settings
  EditorTool _activeTool = EditorTool.select;
  Color _penColor = Colors.black;
  double _penWidth = 3.0;

  Color _highlighterColor = const Color(0x66FFEB3B); // Translucent yellow
  final double _highlighterWidth = 20.0;

  bool _isWhiteout = false;

  // In-progress drawing gesture state
  List<Offset>? _currentStrokePoints;
  Offset? _redactStart;
  Offset? _redactCurrent;

  // Selection state
  String? _selectedTextId;
  String? _selectedImageId;

  @override
  void initState() {
    super.initState();
    if (widget.initialPdfPath != null) {
      _loadPdfFile(widget.initialPdfPath!);
    }
  }

  PageEdits _getEditsForPage(int pageIndex) {
    return _pageEdits.putIfAbsent(pageIndex, () => PageEdits());
  }

  Future<void> _pickPdf() async {
    try {
      if (PlatformHelper.isAndroid) {
        final hasPermission =
            await PlatformFileHandler.requestStoragePermission();
        if (!hasPermission && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Storage permission not granted. Trying anyway...'),
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
        await _loadPdfFile(realPath);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to open PDF: $e')));
      }
    }
  }

  Future<void> _loadPdfFile(String path) async {
    setState(() {
      _isLoadingDoc = true;
      _pdfPath = path;
      _renderedPageCache.clear();
      _pageEdits.clear();
      _selectedTextId = null;
      _selectedImageId = null;
    });

    try {
      final file = File(path);
      if (!await file.exists()) {
        throw Exception('File does not exist: $path');
      }
      final bytes = await file.readAsBytes();
      final doc = PdfDocument(inputBytes: bytes);
      final count = doc.pages.count;
      final sizes = <Size>[];
      for (var i = 0; i < count; i++) {
        final page = doc.pages[i];
        sizes.add(Size(page.size.width, page.size.height));
      }
      doc.dispose();

      if (count == 0) {
        throw Exception('The selected PDF contains no pages.');
      }

      setState(() {
        _pdfBytes = bytes;
        _originalPageCount = count;
        _activeOriginalIndices = List.generate(count, (i) => i);
        _originalPageSizes = sizes;
        _currentPageIndex = 0;
        _isLoadingDoc = false;
      });

      await _renderCurrentPage();
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingDoc = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error loading PDF: $e')));
      }
    }
  }

  Future<void> _renderCurrentPage() async {
    if (_pdfBytes == null || _activeOriginalIndices.isEmpty) return;
    final currentOriginalIndex = _activeOriginalIndices[_currentPageIndex];

    if (_renderedPageCache.containsKey(currentOriginalIndex)) {
      setState(() {
        _currentRasterPng = _renderedPageCache[currentOriginalIndex];
        _isRenderingPage = false;
      });
      return;
    }

    setState(() => _isRenderingPage = true);
    try {
      await for (final raster in Printing.raster(
        _pdfBytes!,
        pages: [currentOriginalIndex],
        dpi: 140,
      )) {
        final png = await raster.toPng();
        _renderedPageCache[currentOriginalIndex] = png;
        if (mounted) {
          setState(() {
            _currentRasterPng = png;
            _isRenderingPage = false;
          });
        }
        break;
      }
    } catch (e) {
      debugPrint('[EditPdfScreen] Error rendering page raster: $e');
      if (mounted) setState(() => _isRenderingPage = false);
    }
  }

  void _goToPage(int targetIndex) {
    if (targetIndex < 0 || targetIndex >= _activeOriginalIndices.length) return;
    setState(() {
      _currentPageIndex = targetIndex;
      _selectedTextId = null;
      _selectedImageId = null;
      _currentStrokePoints = null;
      _redactStart = null;
      _redactCurrent = null;
    });
    _renderCurrentPage();
  }

  void _rotateCurrentPage() {
    final edits = _getEditsForPage(_currentPageIndex);
    setState(() {
      edits.rotationDegrees = (edits.rotationDegrees + 90) % 360;
    });
  }

  Future<void> _deleteCurrentPage() async {
    if (_activeOriginalIndices.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot delete the only page in the document.'),
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Page?'),
        content: Text(
          'Delete page ${_currentPageIndex + 1} of ${_activeOriginalIndices.length}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _pageEdits.remove(_currentPageIndex);
      _activeOriginalIndices.removeAt(_currentPageIndex);
      if (_currentPageIndex >= _activeOriginalIndices.length) {
        _currentPageIndex = _activeOriginalIndices.length - 1;
      }
      _selectedTextId = null;
      _selectedImageId = null;
    });

    await _renderCurrentPage();
  }

  void _undoOnCurrentPage() {
    final edits = _getEditsForPage(_currentPageIndex);
    setState(() {
      edits.undoLast();
    });
  }

  void _clearCurrentPage() {
    final edits = _getEditsForPage(_currentPageIndex);
    if (edits.isEmpty) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear All Edits?'),
        content: const Text(
          'Remove all drawings, text, and stamps on this page?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                edits.clear();
                _selectedTextId = null;
                _selectedImageId = null;
              });
            },
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // --- ADD TEXT DIALOG ---
  void _openAddTextDialog({TextElement? existing}) {
    final textController = TextEditingController(text: existing?.text ?? '');
    double fontSize = existing?.fontSize ?? 18.0;
    Color textColor = existing?.color ?? Colors.black;
    bool isBold = existing?.isBold ?? false;
    Color? bgColor = existing?.backgroundColor;

    final palette = [
      Colors.black,
      const Color(0xFF1565C0),
      const Color(0xFFC62828),
      const Color(0xFF2E7D32),
      const Color(0xFF6A1B9A),
      const Color(0xFFE65100),
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    existing == null ? 'Add Text' : 'Edit Text',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: textController,
                autofocus: true,
                maxLines: 3,
                minLines: 1,
                decoration: InputDecoration(
                  hintText: 'Enter text here...',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const Text(
                    'Size: ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Expanded(
                    child: Slider(
                      value: fontSize,
                      min: 10,
                      max: 44,
                      divisions: 34,
                      label: fontSize.round().toString(),
                      onChanged: (v) => setSheetState(() => fontSize = v),
                    ),
                  ),
                  Text('${fontSize.round()} pt'),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Color:',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Row(
                    children: palette.map((c) {
                      final isSelected = textColor == c;
                      return GestureDetector(
                        onTap: () => setSheetState(() => textColor = c),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: c,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.blue : Colors.grey,
                              width: isSelected ? 3 : 1,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Bold Style',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Switch(
                    value: isBold,
                    onChanged: (v) => setSheetState(() => isBold = v),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Background Highlight',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Switch(
                    value: bgColor != null,
                    onChanged: (v) => setSheetState(() {
                      bgColor = v ? const Color(0x55FFEB3B) : null;
                    }),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC6302C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  final text = textController.text.trim();
                  if (text.isEmpty) return;
                  Navigator.pop(ctx);
                  final edits = _getEditsForPage(_currentPageIndex);
                  setState(() {
                    if (existing != null) {
                      existing.text = text;
                      existing.fontSize = fontSize;
                      existing.color = textColor;
                      existing.isBold = isBold;
                      existing.backgroundColor = bgColor;
                    } else {
                      final id =
                          'txt_${DateTime.now().millisecondsSinceEpoch}';
                      edits.texts.add(
                        TextElement(
                          id: id,
                          text: text,
                          position: const Offset(0.3, 0.4),
                          fontSize: fontSize,
                          color: textColor,
                          isBold: isBold,
                          backgroundColor: bgColor,
                        ),
                      );
                      _selectedTextId = id;
                      _activeTool = EditorTool.select;
                    }
                  });
                },
                child: Text(
                  existing == null ? 'Add to Page' : 'Save Changes',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- SIGNATURE PAD MODAL ---
  void _openSignaturePad() {
    final strokes = <List<Offset>>[];
    List<Offset>? currentStroke;
    Color inkColor = const Color(0xFF0D47A1);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Draw Your Signature',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Sign with your finger on the pad below:',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade400, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    children: [
                      // Guidelines
                      Positioned(
                        left: 20,
                        right: 20,
                        bottom: 40,
                        child: Container(
                          height: 1,
                          color: Colors.grey.shade300,
                        ),
                      ),
                      Positioned(
                        left: 20,
                        bottom: 44,
                        child: Text(
                          'Sign above line',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onPanStart: (details) {
                          setSheetState(() {
                            currentStroke = [details.localPosition];
                            strokes.add(currentStroke!);
                          });
                        },
                        onPanUpdate: (details) {
                          setSheetState(() {
                            currentStroke?.add(details.localPosition);
                          });
                        },
                        onPanEnd: (_) => currentStroke = null,
                        child: CustomPaint(
                          painter: _SignaturePadPainter(
                            strokes: strokes,
                            color: inkColor,
                          ),
                          size: const Size(double.infinity, 200),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Ink: ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      GestureDetector(
                        onTap: () => setSheetState(
                          () => inkColor = const Color(0xFF0D47A1),
                        ),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D47A1),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: inkColor == const Color(0xFF0D47A1)
                                  ? Colors.blue
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => setSheetState(() => inkColor = Colors.black),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: inkColor == Colors.black
                                  ? Colors.blue
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () => setSheetState(() => strokes.clear()),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Clear Pad'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  if (strokes.isEmpty) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                        content: Text('Please draw your signature first.'),
                      ),
                    );
                    return;
                  }
                  final pngBytes = await _rasterizeSignature(strokes, inkColor);
                  if (pngBytes == null) return;
                  if (!mounted || !ctx.mounted) return;
                  Navigator.pop(ctx);

                  final id = 'sig_${DateTime.now().millisecondsSinceEpoch}';
                  final edits = _getEditsForPage(_currentPageIndex);
                  setState(() {
                    edits.images.add(
                      ImageStampElement(
                        id: id,
                        imageBytes: pngBytes,
                        position: const Offset(0.3, 0.6),
                        size: const Size(0.4, 0.15),
                        isSignature: true,
                      ),
                    );
                    _selectedImageId = id;
                    _activeTool = EditorTool.select;
                  });
                },
                child: const Text(
                  'Stamp Signature to Page',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<Uint8List?> _rasterizeSignature(
    List<List<Offset>> strokes,
    Color color,
  ) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, const Rect.fromLTWH(0, 0, 400, 200));

    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (var i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(400, 200);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  // --- STAMP & WATERMARK MODAL ---
  void _openStampDialog() {
    final quickStamps = [
      {'text': 'APPROVED', 'color': const Color(0xFF2E7D32)},
      {'text': 'CONFIDENTIAL', 'color': const Color(0xFFC62828)},
      {'text': 'DRAFT', 'color': const Color(0xFFEF6C00)},
      {'text': 'PAID', 'color': const Color(0xFF1565C0)},
      {'text': 'URGENT', 'color': const Color(0xFFD84315)},
      {'text': 'FINAL', 'color': const Color(0xFF00695C)},
    ];

    final customController = TextEditingController();
    double opacity = 0.35;
    double angle = -45;
    bool applyToAll = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Watermark & Status Stamps',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Quick Status Stamps:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: quickStamps.map((item) {
                  final text = item['text'] as String;
                  final color = item['color'] as Color;
                  return ActionChip(
                    avatar: Icon(Icons.verified, size: 16, color: color),
                    label: Text(
                      text,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    backgroundColor: color.withValues(alpha: 0.1),
                    side: BorderSide(color: color, width: 1.5),
                    onPressed: () {
                      Navigator.pop(ctx);
                      _applyWatermark(
                        text: text,
                        color: color,
                        opacity: 0.35,
                        angle: -45,
                        applyToAll: false,
                      );
                    },
                  );
                }).toList(),
              ),
              const Divider(height: 28),
              const Text(
                'Custom Watermark Text:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: customController,
                decoration: InputDecoration(
                  hintText: 'e.g. DO NOT COPY / MY COMPANY',
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Text(
                    'Opacity: ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Expanded(
                    child: Slider(
                      value: opacity,
                      min: 0.1,
                      max: 0.8,
                      divisions: 7,
                      label: '${(opacity * 100).round()}%',
                      onChanged: (v) => setSheetState(() => opacity = v),
                    ),
                  ),
                  Text('${(opacity * 100).round()}%'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Angle: ',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SegmentedButton<double>(
                    segments: const [
                      ButtonSegment(value: 0.0, label: Text('Horizontal')),
                      ButtonSegment(value: -45.0, label: Text('Diagonal')),
                    ],
                    selected: {angle},
                    onSelectionChanged: (set) =>
                        setSheetState(() => angle = set.first),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Apply to all pages in PDF',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Switch(
                    value: applyToAll,
                    onChanged: (v) => setSheetState(() => applyToAll = v),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC6302C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  final text = customController.text.trim();
                  if (text.isEmpty) return;
                  Navigator.pop(ctx);
                  _applyWatermark(
                    text: text,
                    color: const Color(0xFFC62828),
                    opacity: opacity,
                    angle: angle,
                    applyToAll: applyToAll,
                  );
                },
                child: const Text(
                  'Apply Watermark',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _applyWatermark({
    required String text,
    required Color color,
    required double opacity,
    required double angle,
    required bool applyToAll,
  }) {
    final wm = WatermarkElement(
      text: text,
      color: color,
      opacity: opacity,
      angleDegrees: angle,
    );

    setState(() {
      if (applyToAll) {
        for (var i = 0; i < _activeOriginalIndices.length; i++) {
          _getEditsForPage(i).watermark = wm;
        }
      } else {
        _getEditsForPage(_currentPageIndex).watermark = wm;
      }
    });
  }

  // --- INSERT IMAGE ---
  Future<void> _insertImage() async {
    try {
      Uint8List? imageBytes;
      try {
        final picker = ImagePicker();
        final picked = await picker.pickImage(source: ImageSource.gallery);
        if (picked != null) {
          imageBytes = await picked.readAsBytes();
        }
      } catch (_) {
        // Fallback to file picker if image_picker fails on desktop
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
        );
        if (result != null && result.files.single.path != null) {
          imageBytes = await File(result.files.single.path!).readAsBytes();
        }
      }

      if (imageBytes == null) return;

      final id = 'img_${DateTime.now().millisecondsSinceEpoch}';
      final edits = _getEditsForPage(_currentPageIndex);
      setState(() {
        edits.images.add(
          ImageStampElement(
            id: id,
            imageBytes: imageBytes!,
            position: const Offset(0.3, 0.35),
            size: const Size(0.35, 0.25),
          ),
        );
        _selectedImageId = id;
        _activeTool = EditorTool.select;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  // --- SAVE / EXPORT PDF ROUTINE ---
  Future<void> _saveAndExportPdf() async {
    if (_pdfBytes == null || _activeOriginalIndices.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final doc = PdfDocument(inputBytes: _pdfBytes!);

      // 1. Remove deleted pages in descending order
      for (var i = _originalPageCount - 1; i >= 0; i--) {
        if (!_activeOriginalIndices.contains(i)) {
          doc.pages.removeAt(i);
        }
      }

      // 2. Apply edits to retained pages
      for (var pageIdx = 0; pageIdx < _activeOriginalIndices.length; pageIdx++) {
        final page = doc.pages[pageIdx];
        final edits = _pageEdits[pageIdx];
        if (edits == null || edits.isEmpty) continue;

        // Rotation
        if (edits.rotationDegrees != 0) {
          int currentDeg = 0;
          switch (page.rotation) {
            case PdfPageRotateAngle.rotateAngle90:
              currentDeg = 90;
              break;
            case PdfPageRotateAngle.rotateAngle180:
              currentDeg = 180;
              break;
            case PdfPageRotateAngle.rotateAngle270:
              currentDeg = 270;
              break;
            case PdfPageRotateAngle.rotateAngle0:
              currentDeg = 0;
              break;
          }
          final newDeg = (currentDeg + edits.rotationDegrees) % 360;
          switch (newDeg) {
            case 90:
              page.rotation = PdfPageRotateAngle.rotateAngle90;
              break;
            case 180:
              page.rotation = PdfPageRotateAngle.rotateAngle180;
              break;
            case 270:
              page.rotation = PdfPageRotateAngle.rotateAngle270;
              break;
            case 0:
            default:
              page.rotation = PdfPageRotateAngle.rotateAngle0;
              break;
          }
        }

        final pw = page.size.width;
        final ph = page.size.height;

        // Redactions / Whiteouts
        for (final redact in edits.redactions) {
          final rx = redact.rect.left * pw;
          final ry = redact.rect.top * ph;
          final rw = redact.rect.width * pw;
          final rh = redact.rect.height * ph;

          final color = redact.isWhiteout
              ? PdfColor(255, 255, 255)
              : PdfColor(0, 0, 0);

          page.graphics.drawRectangle(
            brush: PdfSolidBrush(color),
            bounds: ui.Rect.fromLTWH(rx, ry, rw, rh),
          );
        }

        // Freehand Strokes (Pen & Highlighter)
        for (final stroke in edits.strokes) {
          if (stroke.points.length < 2) continue;
          final r = (stroke.color.r * 255.0).round().clamp(0, 255);
          final g = (stroke.color.g * 255.0).round().clamp(0, 255);
          final b = (stroke.color.b * 255.0).round().clamp(0, 255);
          final a = (stroke.color.a * 255.0).round().clamp(0, 255);

          final pen = PdfPen(
            PdfColor(r, g, b, a),
            width: stroke.strokeWidth,
            lineCap: PdfLineCap.round,
            lineJoin: PdfLineJoin.round,
          );

          for (var i = 0; i < stroke.points.length - 1; i++) {
            final p1 = Offset(
              stroke.points[i].dx * pw,
              stroke.points[i].dy * ph,
            );
            final p2 = Offset(
              stroke.points[i + 1].dx * pw,
              stroke.points[i + 1].dy * ph,
            );
            page.graphics.drawLine(pen, p1, p2);
          }
        }

        // Text elements
        for (final textItem in edits.texts) {
          final font = PdfStandardFont(
            PdfFontFamily.helvetica,
            textItem.fontSize,
            style: textItem.isBold ? PdfFontStyle.bold : PdfFontStyle.regular,
          );
          final tr = (textItem.color.r * 255.0).round().clamp(0, 255);
          final tg = (textItem.color.g * 255.0).round().clamp(0, 255);
          final tb = (textItem.color.b * 255.0).round().clamp(0, 255);
          final brush = PdfSolidBrush(PdfColor(tr, tg, tb));

          final tx = textItem.position.dx * pw;
          final ty = textItem.position.dy * ph;

          if (textItem.backgroundColor != null) {
            final textSize = font.measureString(textItem.text);
            final bgr = (textItem.backgroundColor!.r * 255.0).round().clamp(0, 255);
            final bgg = (textItem.backgroundColor!.g * 255.0).round().clamp(0, 255);
            final bgb = (textItem.backgroundColor!.b * 255.0).round().clamp(0, 255);
            page.graphics.drawRectangle(
              brush: PdfSolidBrush(PdfColor(bgr, bgg, bgb)),
              bounds: ui.Rect.fromLTWH(
                tx - 4,
                ty - 2,
                textSize.width + 8,
                textSize.height + 4,
              ),
            );
          }

          page.graphics.drawString(
            textItem.text,
            font,
            brush: brush,
            bounds: ui.Rect.fromLTWH(tx, ty, pw - tx > 50 ? pw - tx : pw, ph - ty),
          );
        }

        // Signatures and Images
        for (final imgItem in edits.images) {
          final bmp = PdfBitmap(imgItem.imageBytes);
          final ix = imgItem.position.dx * pw;
          final iy = imgItem.position.dy * ph;
          final iw = imgItem.size.width * pw;
          final ih = imgItem.size.height * ph;

          page.graphics.drawImage(bmp, ui.Rect.fromLTWH(ix, iy, iw, ih));
        }

        // Watermark
        if (edits.watermark != null) {
          final wm = edits.watermark!;
          final state = page.graphics.save();
          page.graphics.setTransparency(wm.opacity.clamp(0.05, 1.0));
          page.graphics.translateTransform(pw / 2, ph / 2);
          page.graphics.rotateTransform(wm.angleDegrees);

          final font = PdfStandardFont(
            PdfFontFamily.helvetica,
            wm.fontSize,
            style: PdfFontStyle.bold,
          );
          final textSize = font.measureString(wm.text);
          final wr = (wm.color.r * 255.0).round().clamp(0, 255);
          final wg = (wm.color.g * 255.0).round().clamp(0, 255);
          final wb = (wm.color.b * 255.0).round().clamp(0, 255);

          page.graphics.drawString(
            wm.text,
            font,
            brush: PdfSolidBrush(PdfColor(wr, wg, wb)),
            bounds: ui.Rect.fromLTWH(
              -textSize.width / 2,
              -textSize.height / 2,
              textSize.width,
              textSize.height,
            ),
            format: PdfStringFormat(alignment: PdfTextAlignment.center),
          );
          page.graphics.restore(state);
        }
      }

      final savedBytes = await doc.save();
      doc.dispose();

      // Write to working path and export to public directory
      final baseName = p.basenameWithoutExtension(_pdfPath ?? 'document');
      final fileName = '${baseName}_edited_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final workingPath = await OutputPathHelper.createWorkingOutputPath(
        fileName: fileName,
        category: OutputCategory.exports,
      );
      await File(workingPath).writeAsBytes(savedBytes, flush: true);

      final exportResult = await OutputPathHelper.exportGeneratedFile(
        sourcePath: workingPath,
        fileName: fileName,
        category: OutputCategory.exports,
      );

      setState(() => _isSaving = false);
      if (!mounted) return;
      _showSavedDialog(
        workingPath: exportResult.workingPath,
        displayPath: exportResult.displayPath,
        fileName: fileName,
        byteCount: savedBytes.length,
      );
    } catch (e) {
      setState(() => _isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save PDF: $e')));
      }
    }
  }

  void _showSavedDialog({
    required String workingPath,
    required String displayPath,
    required String fileName,
    required int byteCount,
  }) {
    final sizeKb = (byteCount / 1024).toStringAsFixed(1);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 28),
            SizedBox(width: 10),
            Text('PDF Saved!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fileName,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 6),
            Text('Size: $sizeKb KB • Pages: ${_activeOriginalIndices.length}'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                displayPath,
                style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              share_plus.SharePlus.instance.share(
                share_plus.ShareParams(
                  files: [share_plus.XFile(workingPath)],
                ),
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFC6302C),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PdfViewerScreen(
                    externalFile: File(workingPath),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.picture_as_pdf),
            label: const Text('Open Viewer'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: Text(
          _pdfPath != null ? p.basename(_pdfPath!) : 'Edit PDF Studio',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        elevation: 0,
        backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        actions: [
          if (_pdfBytes != null) ...[
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Undo last edit on page',
              onPressed: _undoOnCurrentPage,
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              tooltip: 'Clear page edits',
              onPressed: _clearCurrentPage,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC6302C),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _isSaving ? null : _saveAndExportPdf,
                icon: _isSaving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save, size: 16),
                label: const Text('Save PDF', style: TextStyle(fontSize: 13)),
              ),
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: _isLoadingDoc
          ? const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading PDF Studio...'),
                ],
              ),
            )
          : _pdfBytes == null
              ? _buildEmptyState(isDark)
              : _buildStudioWorkspace(isDark),
    );
  }

  // --- EMPTY / FILE PICKER STATE ---
  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFC6302C).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.design_services,
                size: 64,
                color: Color(0xFFC6302C),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'PDF Studio Editor',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Annotate, draw, place signatures, add text, stamps, watermark, and redact PDFs 100% locally on Android.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: [
                _featureChip(Icons.edit, 'Draw & Markup', isDark),
                _featureChip(Icons.text_fields, 'Add Text', isDark),
                _featureChip(Icons.gesture, 'Handwritten Signature', isDark),
                _featureChip(Icons.verified, 'Watermark & Stamps', isDark),
                _featureChip(Icons.image, 'Insert Photos', isDark),
                _featureChip(Icons.visibility_off, 'Redact Sensitive Info', isDark),
                _featureChip(Icons.rotate_right, 'Rotate & Delete Pages', isDark),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC6302C),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 16,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
              onPressed: _pickPdf,
              icon: const Icon(Icons.file_open),
              label: const Text(
                'Select PDF to Edit',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _featureChip(IconData icon, String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222222) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.white12 : Colors.grey.shade300,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: const Color(0xFFC6302C)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }

  // --- STUDIO WORKSPACE ---
  Widget _buildStudioWorkspace(bool isDark) {
    final edits = _getEditsForPage(_currentPageIndex);
    final currentOriginalIndex = _activeOriginalIndices[_currentPageIndex];
    final originalPageSize = _originalPageSizes[currentOriginalIndex];

    // Compute display size accounting for rotation
    final rotation = edits.rotationDegrees;
    final isQuarterTurn = rotation == 90 || rotation == 270;
    final displayWidth = isQuarterTurn
        ? originalPageSize.height
        : originalPageSize.width;
    final displayHeight = isQuarterTurn
        ? originalPageSize.width
        : originalPageSize.height;

    return Column(
      children: [
        // Page Navigation Strip
        _buildPageNavBar(isDark),

        // PDF Interactive Canvas
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final containerW = constraints.maxWidth;
              final containerH = constraints.maxHeight;

              // Compute aspect-fit rectangle
              final pageAspect = displayWidth / displayHeight;
              final containerAspect = containerW / containerH;

              double canvasW;
              double canvasH;

              if (containerAspect > pageAspect) {
                canvasH = containerH * 0.95;
                canvasW = canvasH * pageAspect;
              } else {
                canvasW = containerW * 0.95;
                canvasH = canvasW / pageAspect;
              }

              return Center(
                child: Container(
                  width: canvasW,
                  height: canvasH,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Stack(
                      children: [
                        // 1. Rendered PDF Page Raster
                        if (_currentRasterPng != null)
                          Positioned.fill(
                            child: RotatedBox(
                              quarterTurns: rotation ~/ 90,
                              child: Image.memory(
                                _currentRasterPng!,
                                fit: BoxFit.fill,
                              ),
                            ),
                          )
                        else
                          const Center(
                            child: CircularProgressIndicator(),
                          ),

                        // 2. Watermark overlay (if applied)
                        if (edits.watermark != null)
                          Positioned.fill(
                            child: _buildWatermarkWidget(edits.watermark!),
                          ),

                        // 3. Static Custom Paint (Strokes & Redactions)
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _CanvasAnnotationsPainter(
                              strokes: edits.strokes,
                              redactions: edits.redactions,
                            ),
                          ),
                        ),

                        // 4. Interactive Items (Draggable Texts)
                        for (final textItem in edits.texts)
                          _buildDraggableTextWidget(
                            textItem,
                            canvasW,
                            canvasH,
                          ),

                        // 5. Interactive Items (Draggable Images & Signatures)
                        for (final imgItem in edits.images)
                          _buildDraggableImageWidget(
                            imgItem,
                            canvasW,
                            canvasH,
                          ),

                        // 6. Active Drawing / Redacting Gesture Layer
                        if (_activeTool == EditorTool.pen ||
                            _activeTool == EditorTool.highlighter ||
                            _activeTool == EditorTool.redact)
                          Positioned.fill(
                            child: GestureDetector(
                              onPanStart: (details) {
                                final local = details.localPosition;
                                final norm = Offset(
                                  (local.dx / canvasW).clamp(0.0, 1.0),
                                  (local.dy / canvasH).clamp(0.0, 1.0),
                                );

                                if (_activeTool == EditorTool.redact) {
                                  setState(() {
                                    _redactStart = norm;
                                    _redactCurrent = norm;
                                  });
                                } else {
                                  setState(() {
                                    _currentStrokePoints = [norm];
                                  });
                                }
                              },
                              onPanUpdate: (details) {
                                final local = details.localPosition;
                                final norm = Offset(
                                  (local.dx / canvasW).clamp(0.0, 1.0),
                                  (local.dy / canvasH).clamp(0.0, 1.0),
                                );

                                if (_activeTool == EditorTool.redact) {
                                  setState(() {
                                    _redactCurrent = norm;
                                  });
                                } else {
                                  setState(() {
                                    _currentStrokePoints?.add(norm);
                                  });
                                }
                              },
                              onPanEnd: (_) {
                                if (_activeTool == EditorTool.redact) {
                                  if (_redactStart != null &&
                                      _redactCurrent != null) {
                                    final l = _redactStart!.dx < _redactCurrent!.dx
                                        ? _redactStart!.dx
                                        : _redactCurrent!.dx;
                                    final t = _redactStart!.dy < _redactCurrent!.dy
                                        ? _redactStart!.dy
                                        : _redactCurrent!.dy;
                                    final r = _redactStart!.dx > _redactCurrent!.dx
                                        ? _redactStart!.dx
                                        : _redactCurrent!.dx;
                                    final b = _redactStart!.dy > _redactCurrent!.dy
                                        ? _redactStart!.dy
                                        : _redactCurrent!.dy;

                                    if ((r - l) > 0.01 && (b - t) > 0.01) {
                                      final id =
                                          'redact_${DateTime.now().millisecondsSinceEpoch}';
                                      edits.redactions.add(
                                        RedactionElement(
                                          id: id,
                                          rect: Rect.fromLTRB(l, t, r, b),
                                          isWhiteout: _isWhiteout,
                                        ),
                                      );
                                    }
                                  }
                                  setState(() {
                                    _redactStart = null;
                                    _redactCurrent = null;
                                  });
                                } else {
                                  if (_currentStrokePoints != null &&
                                      _currentStrokePoints!.length > 1) {
                                    final isHigh =
                                        _activeTool == EditorTool.highlighter;
                                    edits.strokes.add(
                                      DrawingStroke(
                                        points: List.from(_currentStrokePoints!),
                                        color: isHigh
                                            ? _highlighterColor
                                            : _penColor,
                                        strokeWidth: isHigh
                                            ? _highlighterWidth
                                            : _penWidth,
                                        isHighlighter: isHigh,
                                      ),
                                    );
                                  }
                                  setState(() {
                                    _currentStrokePoints = null;
                                  });
                                }
                              },
                              child: CustomPaint(
                                painter: _ActiveInteractionPainter(
                                  activeStroke: _currentStrokePoints,
                                  strokeColor:
                                      _activeTool == EditorTool.highlighter
                                          ? _highlighterColor
                                          : _penColor,
                                  strokeWidth:
                                      _activeTool == EditorTool.highlighter
                                          ? _highlighterWidth
                                          : _penWidth,
                                  redactStart: _redactStart,
                                  redactCurrent: _redactCurrent,
                                  isWhiteout: _isWhiteout,
                                ),
                              ),
                            ),
                          ),

                        // Loading spinner indicator over page when rendering
                        if (_isRenderingPage)
                          Container(
                            color: Colors.black12,
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Floating Drawer for active subtool options (Pen colors, Highlighter widths, Redact toggles)
        _buildSubtoolOptionBar(isDark),

        // Bottom Tool Selection Bar
        _buildBottomToolDock(isDark),
      ],
    );
  }

  // --- PAGE NAVIGATION BAR ---
  Widget _buildPageNavBar(bool isDark) {
    final total = _activeOriginalIndices.length;
    final current = _currentPageIndex + 1;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios, size: 16),
                tooltip: 'Previous Page',
                onPressed: _currentPageIndex > 0
                    ? () => _goToPage(_currentPageIndex - 1)
                    : null,
              ),
              GestureDetector(
                onTap: _showPageJumpSheet,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC6302C).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Page $current of $total',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFFC6302C),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.arrow_forward_ios, size: 16),
                tooltip: 'Next Page',
                onPressed: _currentPageIndex < total - 1
                    ? () => _goToPage(_currentPageIndex + 1)
                    : null,
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.rotate_90_degrees_cw, size: 20),
                tooltip: 'Rotate 90°',
                onPressed: _rotateCurrentPage,
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 20),
                tooltip: 'Delete Page',
                color: Colors.red.shade400,
                onPressed: total > 1 ? _deleteCurrentPage : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showPageJumpSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select Page',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: _activeOriginalIndices.length,
                itemBuilder: (ctx, i) {
                  final isSelected = i == _currentPageIndex;
                  return InkWell(
                    onTap: () {
                      Navigator.pop(ctx);
                      _goToPage(i);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFFC6302C)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFC6302C)
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : null,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- SUBTOOL BAR (Options for Pen, Highlighter, Redact) ---
  Widget _buildSubtoolOptionBar(bool isDark) {
    if (_activeTool == EditorTool.pen) {
      final penColors = [
        Colors.black,
        const Color(0xFF1565C0),
        const Color(0xFFC62828),
        const Color(0xFF2E7D32),
        const Color(0xFF6A1B9A),
        Colors.white,
      ];
      final widths = [2.0, 4.0, 8.0];

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        color: isDark ? const Color(0xFF181818) : Colors.grey.shade200,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: penColors.map((c) {
                final isSelected = _penColor == c;
                return GestureDetector(
                  onTap: () => setState(() => _penColor = c),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.blue : Colors.grey,
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            Row(
              children: widths.map((w) {
                final isSelected = _penWidth == w;
                return GestureDetector(
                  onTap: () => setState(() => _penWidth = w),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFC6302C)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${w.toInt()}pt',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : null,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      );
    } else if (_activeTool == EditorTool.highlighter) {
      final highColors = [
        const Color(0x66FFEB3B), // Yellow
        const Color(0x6600E676), // Green
        const Color(0x66FF4081), // Pink
        const Color(0x6600B0FF), // Blue
        const Color(0x66FF9100), // Orange
      ];

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        color: isDark ? const Color(0xFF181818) : Colors.grey.shade200,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: highColors.map((c) {
                final isSelected = _highlighterColor == c;
                return GestureDetector(
                  onTap: () => setState(() => _highlighterColor = c),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: c.withValues(alpha: 1.0),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const Text(
              'Highlighter Mode',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    } else if (_activeTool == EditorTool.redact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        color: isDark ? const Color(0xFF181818) : Colors.grey.shade200,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Drag a rectangle to cover info:',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Blackout', style: TextStyle(fontSize: 11)),
                  selected: !_isWhiteout,
                  onSelected: (v) => setState(() => _isWhiteout = false),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Whiteout', style: TextStyle(fontSize: 11)),
                  selected: _isWhiteout,
                  onSelected: (v) => setState(() => _isWhiteout = true),
                ),
              ],
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  // --- BOTTOM DOCK (Primary Tools) ---
  Widget _buildBottomToolDock(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              _dockToolItem(
                icon: Icons.touch_app,
                label: 'Select',
                tool: EditorTool.select,
                onTap: () => setState(() => _activeTool = EditorTool.select),
              ),
              _dockToolItem(
                icon: Icons.edit,
                label: 'Pen',
                tool: EditorTool.pen,
                onTap: () => setState(() => _activeTool = EditorTool.pen),
              ),
              _dockToolItem(
                icon: Icons.brush,
                label: 'Highlight',
                tool: EditorTool.highlighter,
                onTap: () =>
                    setState(() => _activeTool = EditorTool.highlighter),
              ),
              _dockToolItem(
                icon: Icons.text_fields,
                label: 'Add Text',
                tool: EditorTool.text,
                onTap: () => _openAddTextDialog(),
              ),
              _dockToolItem(
                icon: Icons.gesture,
                label: 'Signature',
                tool: EditorTool.signature,
                onTap: _openSignaturePad,
              ),
              _dockToolItem(
                icon: Icons.verified,
                label: 'Stamps',
                tool: EditorTool.stamp,
                onTap: _openStampDialog,
              ),
              _dockToolItem(
                icon: Icons.add_photo_alternate,
                label: 'Image',
                tool: EditorTool.image,
                onTap: _insertImage,
              ),
              _dockToolItem(
                icon: Icons.visibility_off,
                label: 'Redact',
                tool: EditorTool.redact,
                onTap: () => setState(() => _activeTool = EditorTool.redact),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dockToolItem({
    required IconData icon,
    required String label,
    required EditorTool tool,
    required VoidCallback onTap,
  }) {
    final isSelected = _activeTool == tool;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        color: isSelected
            ? const Color(0xFFC6302C).withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? const Color(0xFFC6302C)
                      : Colors.grey.shade600,
                ),
                const SizedBox(height: 3),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? const Color(0xFFC6302C)
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- DRAGGABLE TEXT WIDGET ---
  Widget _buildDraggableTextWidget(
    TextElement textItem,
    double canvasW,
    double canvasH,
  ) {
    final isSelected = _selectedTextId == textItem.id;
    final left = textItem.position.dx * canvasW;
    final top = textItem.position.dy * canvasH;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTextId = textItem.id;
            _selectedImageId = null;
          });
        },
        onDoubleTap: () => _openAddTextDialog(existing: textItem),
        onPanUpdate: (details) {
          setState(() {
            _selectedTextId = textItem.id;
            final newX = (textItem.position.dx + details.delta.dx / canvasW)
                .clamp(0.0, 0.9);
            final newY = (textItem.position.dy + details.delta.dy / canvasH)
                .clamp(0.0, 0.95);
            textItem.position = Offset(newX, newY);
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: textItem.backgroundColor ??
                (isSelected ? Colors.blue.withValues(alpha: 0.1) : null),
            border: isSelected
                ? Border.all(color: Colors.blue, width: 1.5)
                : null,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                textItem.text,
                style: TextStyle(
                  fontSize: textItem.fontSize * (canvasW / 450).clamp(0.7, 1.3),
                  color: textItem.color,
                  fontWeight:
                      textItem.isBold ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    final edits = _getEditsForPage(_currentPageIndex);
                    setState(() {
                      edits.texts.removeWhere((t) => t.id == textItem.id);
                      _selectedTextId = null;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- DRAGGABLE IMAGE & SIGNATURE WIDGET ---
  Widget _buildDraggableImageWidget(
    ImageStampElement imgItem,
    double canvasW,
    double canvasH,
  ) {
    final isSelected = _selectedImageId == imgItem.id;
    final left = imgItem.position.dx * canvasW;
    final top = imgItem.position.dy * canvasH;
    final width = imgItem.size.width * canvasW;
    final height = imgItem.size.height * canvasH;

    return Positioned(
      left: left,
      top: top,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedImageId = imgItem.id;
            _selectedTextId = null;
          });
        },
        onPanUpdate: (details) {
          setState(() {
            _selectedImageId = imgItem.id;
            final newX = (imgItem.position.dx + details.delta.dx / canvasW)
                .clamp(0.0, 1.0 - imgItem.size.width);
            final newY = (imgItem.position.dy + details.delta.dy / canvasH)
                .clamp(0.0, 1.0 - imgItem.size.height);
            imgItem.position = Offset(newX, newY);
          });
        },
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            border: isSelected
                ? Border.all(color: Colors.blue, width: 1.5)
                : null,
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.memory(imgItem.imageBytes, fit: BoxFit.contain),
              ),
              if (isSelected) ...[
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: () {
                      final edits = _getEditsForPage(_currentPageIndex);
                      setState(() {
                        edits.images.removeWhere((i) => i.id == imgItem.id);
                        _selectedImageId = null;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: GestureDetector(
                    onPanUpdate: (details) {
                      setState(() {
                        final newW = (imgItem.size.width +
                                details.delta.dx / canvasW)
                            .clamp(0.1, 0.8);
                        final newH = (imgItem.size.height +
                                details.delta.dy / canvasH)
                            .clamp(0.05, 0.8);
                        imgItem.size = Size(newW, newH);
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.aspect_ratio,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // --- WATERMARK OVERLAY ---
  Widget _buildWatermarkWidget(WatermarkElement wm) {
    return Center(
      child: Transform.rotate(
        angle: wm.angleDegrees * 3.141592653589793 / 180,
        child: Opacity(
          opacity: wm.opacity,
          child: Text(
            wm.text,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: wm.fontSize,
              fontWeight: FontWeight.bold,
              color: wm.color,
            ),
          ),
        ),
      ),
    );
  }
}

// --- PAINTER: STATIC STROKES & REDACTIONS ---
class _CanvasAnnotationsPainter extends CustomPainter {
  final List<DrawingStroke> strokes;
  final List<RedactionElement> redactions;

  _CanvasAnnotationsPainter({
    required this.strokes,
    required this.redactions,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Redactions
    for (final r in redactions) {
      final rect = Rect.fromLTRB(
        r.rect.left * size.width,
        r.rect.top * size.height,
        r.rect.right * size.width,
        r.rect.bottom * size.height,
      );
      final paint = Paint()
        ..color = r.isWhiteout ? Colors.white : Colors.black
        ..style = PaintingStyle.fill;
      canvas.drawRect(rect, paint);
    }

    // 2. Freehand strokes
    for (final stroke in strokes) {
      if (stroke.points.length < 2) continue;
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path()
        ..moveTo(
          stroke.points.first.dx * size.width,
          stroke.points.first.dy * size.height,
        );

      for (var i = 1; i < stroke.points.length; i++) {
        path.lineTo(
          stroke.points[i].dx * size.width,
          stroke.points[i].dy * size.height,
        );
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasAnnotationsPainter oldDelegate) => true;
}

// --- PAINTER: ACTIVE GESTURE DRAWING ---
class _ActiveInteractionPainter extends CustomPainter {
  final List<Offset>? activeStroke;
  final Color strokeColor;
  final double strokeWidth;
  final Offset? redactStart;
  final Offset? redactCurrent;
  final bool isWhiteout;

  _ActiveInteractionPainter({
    required this.activeStroke,
    required this.strokeColor,
    required this.strokeWidth,
    required this.redactStart,
    required this.redactCurrent,
    required this.isWhiteout,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Active freehand stroke
    if (activeStroke != null && activeStroke!.length > 1) {
      final paint = Paint()
        ..color = strokeColor
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path()
        ..moveTo(
          activeStroke!.first.dx * size.width,
          activeStroke!.first.dy * size.height,
        );

      for (var i = 1; i < activeStroke!.length; i++) {
        path.lineTo(
          activeStroke![i].dx * size.width,
          activeStroke![i].dy * size.height,
        );
      }
      canvas.drawPath(path, paint);
    }

    // Active redaction rectangle
    if (redactStart != null && redactCurrent != null) {
      final l = redactStart!.dx < redactCurrent!.dx
          ? redactStart!.dx
          : redactCurrent!.dx;
      final t = redactStart!.dy < redactCurrent!.dy
          ? redactStart!.dy
          : redactCurrent!.dy;
      final r = redactStart!.dx > redactCurrent!.dx
          ? redactStart!.dx
          : redactCurrent!.dx;
      final b = redactStart!.dy > redactCurrent!.dy
          ? redactStart!.dy
          : redactCurrent!.dy;

      final rect = Rect.fromLTRB(
        l * size.width,
        t * size.height,
        r * size.width,
        b * size.height,
      );

      final paint = Paint()
        ..color = isWhiteout
            ? Colors.white.withValues(alpha: 0.8)
            : Colors.black.withValues(alpha: 0.7)
        ..style = PaintingStyle.fill;

      canvas.drawRect(rect, paint);

      final borderPaint = Paint()
        ..color = Colors.blue
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      canvas.drawRect(rect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ActiveInteractionPainter oldDelegate) => true;
}

// --- SIGNATURE PAD PAINTER ---
class _SignaturePadPainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final Color color;

  _SignaturePadPainter({required this.strokes, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.length < 2) continue;
      final path = Path()..moveTo(stroke.first.dx, stroke.first.dy);
      for (var i = 1; i < stroke.length; i++) {
        path.lineTo(stroke[i].dx, stroke[i].dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SignaturePadPainter oldDelegate) => true;
}

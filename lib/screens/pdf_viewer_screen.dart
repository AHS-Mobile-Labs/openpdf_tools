import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:openpdf_tools/widgets/in_app_file_picker.dart';
import 'package:openpdf_tools/services/file_history_service.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'history_screen.dart';

class PdfViewerScreen extends StatefulWidget {
  final File? externalFile;

  const PdfViewerScreen({super.key, this.externalFile});

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  File? _pdfFile;
  String? _password;
  double _zoom = 1.0;
  bool _isFavorite = false;
  bool _showControls = true;
  final PdfViewerController _pdfViewerController = PdfViewerController();

  @override
  void initState() {
    super.initState();

    // If app is opened via "Open with → OpenPDF Tools"
    if (widget.externalFile != null) {
      _pdfFile = widget.externalFile;
      _addToHistoryAndCheckFavorite();
    }
  }

  void _addToHistoryAndCheckFavorite() async {
    if (_pdfFile != null) {
      await FileHistoryService.addToHistory(_pdfFile!.path);
      final isFav = await FileHistoryService.isFavorite(_pdfFile!.path);
      setState(() {
        _isFavorite = isFav;
      });
    }
  }

  @override
  void dispose() {
    _pdfViewerController.dispose();
    super.dispose();
  }

  Future<void> _pickPdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.single.path != null) {
        setState(() {
          _pdfFile = File(result.files.single.path!);
          _password = null;
          _zoom = 1.0;
        });
        _addToHistoryAndCheckFavorite();
      }
    } catch (e) {
      // FilePicker on Linux requires `zenity`. Offer a fallback that includes an in-app picker.
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
        final selected = await showInAppFilePicker(
          context,
          initialDirectory: Directory.current.path,
          allowedExtensions: ['pdf'],
        );
        if (selected != null) {
          setState(() {
            _pdfFile = File(selected);
            _password = null;
            _zoom = 1.0;
          });
          // ignore: use_build_context_synchronously
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Selected: $selected')));
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
              _pdfFile = file;
              _password = null;
              _zoom = 1.0;
            });
            _addToHistoryAndCheckFavorite();
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Selected: $path')));
          } else {
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text('File not found')));
          }
        }
      }
    }
  }

  void _askPassword() {
    final controller = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('PDF Password'),
        content: TextField(
          controller: controller,
          obscureText: true,
          decoration: const InputDecoration(hintText: 'Enter password'),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _password = controller.text;
              });
              Navigator.pop(context);
            },
            child: const Text('Open'),
          ),
        ],
      ),
    );
  }

  Future<void> _sharePdf() async {
    if (_pdfFile == null) return;

    try {
      await Process.run('xdg-open', [_pdfFile!.parent.path]);
    } catch (e) {
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to open folder: $e')));
    }
  }

  Future<void> _downloadPdf() async {
    if (_pdfFile == null) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = _pdfFile!.path.split('/').last;
      final savePath = '${dir.path}/$fileName';

      if (await _pdfFile!.exists()) {
        await _pdfFile!.copy(savePath);

        if (!mounted) return;
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('✓ Saved to $savePath')));
      }
    } catch (e) {
      if (!mounted) return;
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
    }
  }

  Future<void> _renamePdf() async {
    if (_pdfFile == null) return;

    final currentName = _pdfFile!.path.split('/').last.replaceAll('.pdf', '');
    final controller = TextEditingController(text: currentName);

    // ignore: use_build_context_synchronously
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename PDF'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'Enter new name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Rename'),
          ),
        ],
      ),
    );

    if (newName != null && newName.isNotEmpty) {
      try {
        final oldPath = _pdfFile!.path;
        final directory = _pdfFile!.parent;
        final newPath = '${directory.path}/$newName.pdf';
        final renamedFile = await _pdfFile!.rename(newPath);

        // Update history and favorites with new path
        await FileHistoryService.updateHistoryPath(oldPath, newPath);
        await FileHistoryService.updateFavoritePath(oldPath, newPath);

        setState(() {
          _pdfFile = renamedFile;
        });

        if (!mounted) return;
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('✓ PDF renamed successfully')),
        );
      } catch (e) {
        if (!mounted) return;
        // ignore: use_build_context_synchronously
        // ignore: use_build_context_synchronously

        // ignore: use_build_context_synchronously

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Rename failed: $e')));
      }
    }
  }

  void _zoomIn() {
    setState(() {
      // ignore: use_build_context_synchronously

      _zoom = (_zoom + 0.1).clamp(0.5, 3.0);
      _pdfViewerController.zoomLevel = _zoom;
    });
  }

  void _zoomOut() {
    setState(() {
      // ignore: use_build_context_synchronously

      _zoom = (_zoom - 0.1).clamp(0.5, 3.0);
      _pdfViewerController.zoomLevel = _zoom;
    });
  }

  void _resetZoom() {
    setState(() {
      // ignore: use_build_context_synchronously

      _zoom = 1.0;
      _pdfViewerController.zoomLevel = _zoom;
    });
  }

  void _showMoreMenu() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('History & Favorites'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: const Text('Open Folder'),
              onTap: () {
                Navigator.pop(context);
                _sharePdf();
              },
            ),
            ListTile(
              leading: const Icon(Icons.download),
              title: const Text('Download'),
              onTap: () {
                Navigator.pop(context);
                _downloadPdf();
              },
            ),
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline),
              title: const Text('Rename'),
              onTap: () {
                Navigator.pop(context);
                _renamePdf();
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fileName = _pdfFile != null ? p.basename(_pdfFile!.path) : 'View PDF';
    final fileSize = _pdfFile != null
        ? (_pdfFile!.lengthSync() / (1024 * 1024)).toStringAsFixed(2)
        : '0';

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F0F)
          : const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1C1C1C) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              fileName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            if (_pdfFile != null)
              Text(
                '$fileSize MB',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
          ],
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.star : Icons.star_outline,
              color: _isFavorite ? Colors.amber : null,
            ),
            tooltip: _isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
            onPressed: _pdfFile == null
                ? null
                : () async {
                    await FileHistoryService.toggleFavorite(_pdfFile!.path);
                    setState(() {
                      // ignore: use_build_context_synchronously

                      _isFavorite = !_isFavorite;
                    });
                  },
          ),
          IconButton(
            icon: const Icon(Icons.folder_open),
            tooltip: 'Open PDF',
            onPressed: _pickPdf,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: _pdfFile == null ? null : _showMoreMenu,
          ),
        ],
      ),
      body: _pdfFile == null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.picture_as_pdf,
                    size: 80,
                    color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'No PDF selected',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tap the folder icon to select a PDF',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _pickPdf,
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Select PDF'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                    ),
                  ),
                ],
              ),
            )
          : GestureDetector(
              onDoubleTap: _resetZoom,
              onTap: () {
                setState(() {
                  _showControls = !_showControls;
                });
              },
              child: Stack(
                children: [
                  SfPdfViewer.file(
                    _pdfFile!,
                    controller: _pdfViewerController,
                    password: _password,
                    initialZoomLevel: _zoom,
                    enableTextSelection: true,
                    onDocumentLoadFailed: (_) {
                      _askPassword();
                    },
                  ),
                  // Bottom zoom/control bar
                  if (_showControls)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Zoom controls
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.zoom_out,
                                    color: Colors.white,
                                  ),
                                  onPressed: _zoomOut,
                                  iconSize: 20,
                                  constraints: const BoxConstraints(
                                    minWidth: 40,
                                    minHeight: 40,
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white12,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${(_zoom * 100).toStringAsFixed(0)}%',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.zoom_in,
                                    color: Colors.white,
                                  ),
                                  onPressed: _zoomIn,
                                  iconSize: 20,
                                  constraints: const BoxConstraints(
                                    minWidth: 40,
                                    minHeight: 40,
                                  ),
                                  padding: EdgeInsets.zero,
                                ),
                              ],
                            ),
                            // Reset zoom
                            TextButton.icon(
                              onPressed: _resetZoom,
                              icon: const Icon(
                                Icons.refresh,
                                size: 18,
                                color: Colors.white,
                              ),
                              label: const Text(
                                'Reset',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  // Page indicator
                  if (_showControls && _pdfViewerController.pageCount > 0)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_pdfViewerController.pageNumber} / ${_pdfViewerController.pageCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  // Tap to show/hide controls hint
                  if (!_showControls)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Tap to show controls',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
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
}

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:openpdf_tools/widgets/in_app_file_picker.dart';
import 'package:openpdf_tools/widgets/web_pdf_viewer.dart'
    if (dart.library.html) 'package:openpdf_tools/widgets/web_pdf_viewer_web.dart';
import 'package:openpdf_tools/services/file_history_service.dart';
import 'package:openpdf_tools/utils/platform_file_handler.dart';
import 'package:openpdf_tools/utils/platform_helper.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import 'package:openpdf_tools/widgets/theme_switcher.dart';
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
  Uint8List? _pdfBytes;
  bool _isLoadingBytes = false;
  final PdfViewerController _pdfViewerController = PdfViewerController();
  double _brightness = 1.0;
  bool _isNightMode = false;
  int _rotationAngle = 0;
  String _viewMode = 'fit';
  String? _webFileName;
  int? _webFileSize;
  @override
  void initState() {
    super.initState();
    _pdfViewerController.addListener(_onPdfViewerControllerChanged);
    if (widget.externalFile != null) {
      _pdfFile = widget.externalFile;
      _loadPdfBytes();
      _addToHistoryAndCheckFavorite();
    }
  }

  void _onPdfViewerControllerChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  void _addToHistoryAndCheckFavorite() async {
    if (kIsWeb) return;
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
    _pdfViewerController.removeListener(_onPdfViewerControllerChanged);
    _pdfViewerController.dispose();
    super.dispose();
  }

  void _handleHyperlinkClicked(PdfHyperlinkClickedDetails details) {
    final String url = details.uri;
    _openUrl(url);
  }

  Future<void> _openUrl(String url) async {
    try {
      final Uri uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Cannot open link: $url')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error opening link: $e')));
    }
  }

  Future<void> _loadPdfBytes() async {
    if (_pdfFile == null) {
      setState(() {
        _pdfBytes = null;
      });
      return;
    }
    if (kIsWeb) {
      setState(() {
        _isLoadingBytes = true;
      });
      try {
        final bytes = await _getFileBytes();
        if (mounted) {
          setState(() {
            _pdfBytes = bytes;
            _isLoadingBytes = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoadingBytes = false;
          });
        }
      }
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
        withData: kIsWeb,
      );
      if (result != null && result.files.single.path != null) {
        if (kIsWeb) {
          setState(() {
            _pdfFile = null;
            _webFileName = result.files.single.name;
            _webFileSize = result.files.single.size;
            _pdfBytes = result.files.single.bytes;
            _zoom = 1.0;
            _rotationAngle = 0;
            _brightness = 1.0;
            _isNightMode = false;
            _viewMode = 'fit';
            _isLoadingBytes = false;
          });
        } else {
          setState(() {
            _pdfFile = File(result.files.single.path!);
            _webFileName = null;
            _webFileSize = null;
            _zoom = 1.0;
            _rotationAngle = 0;
            _brightness = 1.0;
            _isNightMode = false;
            _viewMode = 'fit';
          });
          _loadPdfBytes();
          _addToHistoryAndCheckFavorite();
        }
      }
    } catch (e) {
      if (kIsWeb) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('File picker failed: $e')));
        }
        return;
      }
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
        if (!mounted) return;
        final selected = await showInAppFilePicker(
          context,
          initialDirectory: Directory.current.path,
          allowedExtensions: ['pdf'],
        );
        if (selected != null) {
          setState(() {
            _pdfFile = File(selected);
            _webFileName = null;
            _webFileSize = null;
            _zoom = 1.0;
            _rotationAngle = 0;
            _brightness = 1.0;
            _isNightMode = false;
            _viewMode = 'fit';
          });
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Selected: $selected')));
        }
      } else if (choice == 'enter') {
        if (!mounted) return;
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
            setState(() {
              _pdfFile = file;
              _webFileName = null;
              _webFileSize = null;
              _zoom = 1.0;
              _rotationAngle = 0;
              _brightness = 1.0;
              _isNightMode = false;
              _viewMode = 'fit';
            });
            _loadPdfBytes();
            _addToHistoryAndCheckFavorite();
            if (!mounted) return;
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

  Future<void> _sharePdf() async {
    if (_pdfFile == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No PDF loaded')));
      return;
    }
    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Share not available on web')),
      );
      return;
    }
    try {
      if (Platform.isAndroid || Platform.isIOS) {
        await share_plus.SharePlus.instance.share(
          share_plus.ShareParams(files: [share_plus.XFile(_pdfFile!.path)]),
        );
      } else {
        await Process.run('xdg-open', [_pdfFile!.parent.path]);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to open folder: $e')));
    }
  }

  Future<void> _downloadPdf() async {
    if (_pdfFile == null && _pdfBytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No PDF loaded')));
      return;
    }
    if (kIsWeb) {
      if (_pdfBytes == null) return;
      try {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'PDF ready to download: ${_webFileName ?? "document.pdf"}',
            ),
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
      return;
    }
    try {
      final dir = await getApplicationDocumentsDirectory();
      final fileName = _pdfFile!.path.split('/').last;
      final savePath = '${dir.path}/$fileName';
      if (await _pdfFile!.exists()) {
        await _pdfFile!.copy(savePath);
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('✓ Saved to $savePath')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
    }
  }

  Future<void> _renamePdf() async {
    if (_pdfFile == null && _pdfBytes == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No PDF loaded')));
      return;
    }
    if (kIsWeb) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rename not available on web')),
      );
      return;
    }
    final currentName = _pdfFile!.path.split('/').last.replaceAll('.pdf', '');
    final controller = TextEditingController(text: currentName);
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
        await FileHistoryService.updateHistoryPath(oldPath, newPath);
        await FileHistoryService.updateFavoritePath(oldPath, newPath);
        setState(() {
          _pdfFile = renamedFile;
        });
        _loadPdfBytes();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: const Text('✓ PDF renamed successfully')),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Rename failed: $e')));
      }
    }
  }

  void _zoomIn() {
    setState(() {
      _zoom = (_zoom + 0.1).clamp(0.5, 3.0);
      _pdfViewerController.zoomLevel = _zoom;
    });
  }

  void _zoomOut() {
    setState(() {
      _zoom = (_zoom - 0.1).clamp(0.5, 3.0);
      _pdfViewerController.zoomLevel = _zoom;
    });
  }

  void _resetZoom() {
    setState(() {
      _zoom = 1.0;
      _rotationAngle = 0;
      _brightness = 1.0;
      _isNightMode = false;
      _viewMode = 'fit';
      _pdfViewerController.zoomLevel = _zoom;
    });
  }

  void _rotateClockwise() {
    setState(() {
      _rotationAngle = (_rotationAngle + 90) % 360;
    });
  }

  void _jumpToPage() {
    if (_pdfViewerController.pageCount <= 0) return;
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Jump to Page'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            hintText: 'Enter page number (1-${_pdfViewerController.pageCount})',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final pageNum = int.tryParse(controller.text);
              if (pageNum != null &&
                  pageNum >= 1 &&
                  pageNum <= _pdfViewerController.pageCount) {
                _pdfViewerController.jumpToPage(pageNum);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Go'),
          ),
        ],
      ),
    );
  }

  void _setViewMode(String mode) {
    setState(() {
      _viewMode = mode;
      switch (mode) {
        case 'width':
          _zoom = 1.5;
          break;
        case 'height':
          _zoom = 1.2;
          break;
        default:
          _zoom = 1.0;
      }
      _pdfViewerController.zoomLevel = _zoom;
    });
  }

  void _toggleNightMode() {
    setState(() {
      _isNightMode = !_isNightMode;
      _brightness = _isNightMode ? 0.6 : 1.0;
    });
  }

  void _showViewModeMenu() {
    showModalBottomSheet(
      context: context,
      builder: (_) => Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'View Mode',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Fit Page'),
              trailing: _viewMode == 'fit'
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _setViewMode('fit');
              },
            ),
            ListTile(
              leading: const Icon(Icons.aspect_ratio),
              title: const Text('Fit Width'),
              trailing: _viewMode == 'width'
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _setViewMode('width');
              },
            ),
            ListTile(
              leading: const Icon(Icons.height),
              title: const Text('Fit Height'),
              trailing: _viewMode == 'height'
                  ? const Icon(Icons.check, color: Colors.blue)
                  : null,
              onTap: () {
                Navigator.pop(context);
                _setViewMode('height');
              },
            ),
          ],
        ),
      ),
    );
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

  Future<Uint8List?> _getFileBytes() async {
    try {
      if (kIsWeb) {
        return _pdfBytes;
      }
      if (_pdfFile != null) {
        return await _pdfFile!.readAsBytes();
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fileName = kIsWeb
        ? (_webFileName ?? 'View PDF')
        : (_pdfFile != null ? p.basename(_pdfFile!.path) : 'View PDF');
    final fileSize = kIsWeb
        ? (_webFileSize != null
              ? (_webFileSize! / (1024 * 1024)).toStringAsFixed(2)
              : '0')
        : (_pdfFile != null
              ? (_pdfFile!.lengthSync() / (1024 * 1024)).toStringAsFixed(2)
              : '0');
    return Scaffold(
      backgroundColor: _isNightMode
          ? const Color(0xFF0A0A0A)
          : (isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA)),
      appBar: kIsWeb
          ? null
          : AppBar(
              backgroundColor: _isNightMode
                  ? const Color(0xFF121212)
                  : (isDark ? const Color(0xFF1C1C1C) : Colors.white),
              foregroundColor: isDark ? Colors.white : Colors.black87,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_pdfFile != null)
                    Text(
                      '$fileSize MB${_pdfViewerController.pageCount > 0 ? ' • ${_pdfViewerController.pageCount} pages' : ''}',
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
                ThemeSwitcher(compact: true),
                const SizedBox(width: 4),
                IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.star : Icons.star_outline,
                    color: _isFavorite ? Colors.amber : null,
                  ),
                  tooltip: _isFavorite
                      ? 'Remove from Favorites'
                      : 'Add to Favorites',
                  onPressed: (_pdfFile == null && _pdfBytes == null)
                      ? null
                      : () async {
                          if (kIsWeb) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Favorites not available on web'),
                              ),
                            );
                            return;
                          }
                          await FileHistoryService.toggleFavorite(
                            _pdfFile!.path,
                          );
                          setState(() {
                            _isFavorite = !_isFavorite;
                          });
                        },
                ),
                if (_pdfFile != null)
                  IconButton(
                    icon: Icon(
                      _isNightMode ? Icons.brightness_5 : Icons.brightness_7,
                    ),
                    tooltip: _isNightMode ? 'Day Mode' : 'Night Mode',
                    onPressed: _toggleNightMode,
                  ),
                IconButton(
                  icon: const Icon(Icons.folder_open),
                  tooltip: 'Open PDF',
                  onPressed: _pickPdf,
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: (_pdfFile == null && _pdfBytes == null)
                      ? null
                      : _showMoreMenu,
                ),
              ],
            ),
      body: (_pdfFile == null && _pdfBytes == null)
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
              onTap: () {
                setState(() {
                  _showControls = !_showControls;
                });
              },
              child: Stack(
                children: [
                  ColorFiltered(
                    colorFilter: ColorFilter.matrix(<double>[
                      _brightness,
                      0,
                      0,
                      0,
                      0,
                      0,
                      _brightness,
                      0,
                      0,
                      0,
                      0,
                      0,
                      _brightness,
                      0,
                      0,
                      0,
                      0,
                      0,
                      1,
                      0,
                    ]),
                    child: Transform.rotate(
                      angle: (_rotationAngle * 3.14159) / 180,
                      child: kIsWeb
                          ? _isLoadingBytes
                                ? const Center(
                                    child: CircularProgressIndicator(),
                                  )
                                : (_pdfBytes != null
                                      ? WebPdfViewer(
                                          pdfBytes: _pdfBytes!,
                                          fileName: _webFileName,
                                        )
                                      : const Center(
                                          child: Text('Unable to load PDF'),
                                        ))
                          : _password != null
                          ? SfPdfViewer.file(
                              _pdfFile!,
                              controller: _pdfViewerController,
                              password: _password!,
                              initialZoomLevel: _zoom,
                              enableTextSelection: true,
                              onHyperlinkClicked: _handleHyperlinkClicked,
                            )
                          : SfPdfViewer.file(
                              _pdfFile!,
                              controller: _pdfViewerController,
                              initialZoomLevel: _zoom,
                              enableTextSelection: true,
                              onHyperlinkClicked: _handleHyperlinkClicked,
                            ),
                    ),
                  ),
                  if (_showControls)
                    Positioned(
                      bottom: MediaQuery.of(context).padding.bottom,
                      left: 0,
                      right: 0,
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _isNightMode
                                      ? Icons.brightness_low
                                      : Icons.brightness_high,
                                  color: Colors.white70,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Slider(
                                    value: _brightness,
                                    min: 0.3,
                                    max: 1.5,
                                    onChanged: (value) {
                                      setState(() {
                                        _brightness = value;
                                      });
                                    },
                                    divisions: 24,
                                  ),
                                ),
                                Text(
                                  '${(_brightness * 100).toInt()}%',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
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
                            padding: EdgeInsets.only(
                              left: 12,
                              right: 12,
                              top: 8,
                              bottom: 8 + MediaQuery.of(context).padding.bottom,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                    Icons.zoom_out,
                                    color: Colors.white,
                                  ),
                                  onPressed: _zoomOut,
                                  iconSize: 20,
                                  tooltip: 'Zoom Out',
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
                                      fontSize: 12,
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
                                  tooltip: 'Zoom In',
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(
                                    Icons.image,
                                    color: Colors.white,
                                  ),
                                  onPressed: _showViewModeMenu,
                                  tooltip: 'View Mode',
                                  iconSize: 20,
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.rotate_right,
                                    color: Colors.white,
                                  ),
                                  onPressed: _rotateClockwise,
                                  tooltip: 'Rotate',
                                  iconSize: 20,
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.skip_next,
                                    color: Colors.white,
                                  ),
                                  onPressed: _jumpToPage,
                                  tooltip: 'Jump to Page',
                                  iconSize: 20,
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.refresh,
                                    color: Colors.white,
                                  ),
                                  onPressed: _resetZoom,
                                  tooltip: 'Reset View',
                                  iconSize: 20,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  if (_showControls && _pdfViewerController.pageCount > 0)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black87,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 6,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.description,
                              color: Colors.white70,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '${_pdfViewerController.pageNumber} / ${_pdfViewerController.pageCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (_showControls && _rotationAngle != 0)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '$_rotationAngle°',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  if (!_showControls)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.3),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                          child: const Text(
                            'Tap to show controls',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ),
                  if (_showControls && _viewMode != 'fit')
                    Positioned(
                      top: 56,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _viewMode == 'width' ? 'Fit Width' : 'Fit Height',
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
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

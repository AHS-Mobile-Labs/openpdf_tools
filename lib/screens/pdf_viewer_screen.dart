import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:openpdf_tools/config/premium_theme.dart';
import 'package:openpdf_tools/widgets/in_app_file_picker.dart';
import 'package:openpdf_tools/widgets/web_pdf_viewer.dart'
    if (dart.library.html) 'package:openpdf_tools/widgets/web_pdf_viewer_web.dart';
import 'package:openpdf_tools/services/file_history_service.dart';
import 'package:openpdf_tools/utils/platform_file_handler.dart';
import 'package:openpdf_tools/utils/platform_helper.dart';
import 'package:openpdf_tools/utils/uri_to_file.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import 'package:openpdf_tools/widgets/theme_switcher.dart';
import 'package:openpdf_tools/utils/output_path_helper.dart';
import 'history_screen.dart';

class PdfViewerScreen extends StatefulWidget {
  final File? externalFile;
  const PdfViewerScreen({super.key, this.externalFile});
  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _SheetHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDark;
  const _SheetHeader({
    required this.title,
    required this.subtitle,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: PremiumTypography.headlineMedium.copyWith(
              color: isDark ? PremiumColors.darkText : PremiumColors.lightText,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: PremiumTypography.bodySmall.copyWith(
              color: isDark
                  ? PremiumColors.darkTextSecondary
                  : PremiumColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewModeTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  const _ViewModeTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _ActionTileBase(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: selected
          ? const Icon(Icons.check_circle, color: PremiumColors.luxuryRed)
          : null,
      selected: selected,
      onTap: onTap,
      isDark: isDark,
    );
  }
}

class _ActionSheetTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _ActionSheetTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return _ActionTileBase(
      icon: icon,
      title: title,
      subtitle: subtitle,
      trailing: const Icon(Icons.chevron_right),
      selected: false,
      onTap: onTap,
      isDark: isDark,
    );
  }
}

class _ActionTileBase extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;
  const _ActionTileBase({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? PremiumColors.darkText : PremiumColors.lightText;
    final mutedColor = isDark
        ? PremiumColors.darkTextSecondary
        : PremiumColors.lightTextSecondary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: selected
                ? PremiumColors.luxuryRed.withValues(alpha: 0.10)
                : (isDark
                      ? PremiumColors.darkSurfaceSecondary
                      : PremiumColors.lightSurfaceSecondary),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected
                  ? PremiumColors.luxuryRed.withValues(alpha: 0.32)
                  : (isDark
                        ? PremiumColors.darkDivider
                        : PremiumColors.lightDivider),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: PremiumColors.luxuryRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: PremiumColors.luxuryRed, size: 21),
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
                      subtitle,
                      style: PremiumTypography.bodySmall.copyWith(
                        color: mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            ],
          ),
        ),
      ),
    );
  }
}

class _ReaderStatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;
  const _ReaderStatusChip({
    required this.icon,
    required this.label,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.10)
            : PremiumColors.lightSurfaceSecondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isDark ? Colors.white70 : PremiumColors.lightTextSecondary,
            size: 15,
          ),
          const SizedBox(width: 5),
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

class _ReaderToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  const _ReaderToolButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          minimumSize: const Size(54, 46),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: PremiumTypography.labelSmall.copyWith(
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZoomReadout extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  const _ZoomReadout({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    final child = Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: PremiumTypography.labelSmall.copyWith(color: Colors.white),
      ),
    );
    if (onTap == null) {
      return child;
    }
    return Tooltip(
      message: 'Custom zoom',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: child,
      ),
    );
  }
}

class _ToolbarDivider extends StatelessWidget {
  const _ToolbarDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      color: Colors.white.withValues(alpha: 0.14),
    );
  }
}

class _ViewerFeatureTile extends StatelessWidget {
  final IconData icon;
  final String label;
  const _ViewerFeatureTile({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          Icon(icon, size: 16, color: PremiumColors.luxuryRed),
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

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  static const double _minZoom = 0.5;
  static const double _maxZoom = 3.0;
  static const double _syncfusionMinZoom = 1.0;

  File? _pdfFile;
  String? _password;
  double _zoom = 1.0;
  bool _isFavorite = false;
  bool _showControls = true;
  Uint8List? _pdfBytes;
  bool _isLoadingBytes = false;
  final PdfViewerController _pdfViewerController = PdfViewerController();
  PdfTextSearchResult _searchResult = PdfTextSearchResult();
  double _brightness = 1.0;
  bool _isNightMode = false;
  int _rotationAngle = 0;
  String _viewMode = 'fit';
  String? _webFileName;
  int? _webFileSize;
  String? _viewerError;
  List<Size> _pageSizes = <Size>[];
  Size? _viewerViewportSize;
  bool _isApplyingControllerZoom = false;
  int _lastPageNumber = 0;
  final Map<int, Offset> _activePointers = <int, Offset>{};
  double? _pinchStartDistance;
  double _pinchStartZoom = 1.0;
  bool _suppressNextTapToggle = false;
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
    if (!mounted) return;
    final pageNumber = _pdfViewerController.pageNumber;
    final pageChanged = pageNumber > 0 && pageNumber != _lastPageNumber;
    if (pageChanged) {
      _lastPageNumber = pageNumber;
      _scheduleViewModeRefresh();
    }

    if (!_isApplyingControllerZoom) {
      final controllerZoom = _normaliseZoom(_pdfViewerController.zoomLevel);
      final shouldSyncControllerZoom =
          controllerZoom > _syncfusionMinZoom || _zoom >= _syncfusionMinZoom;
      if (shouldSyncControllerZoom && (controllerZoom - _zoom).abs() > 0.005) {
        _zoom = controllerZoom;
        _viewMode = 'custom';
      }
    }
    setState(() {});
  }

  void _onSearchResultChanged() {
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
    _searchResult.removeListener(_onSearchResultChanged);
    _searchResult.clear();
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

  void _resetReaderStateForNewDocument() {
    _zoom = 1.0;
    _rotationAngle = 0;
    _brightness = 1.0;
    _isNightMode = false;
    _viewMode = 'fit';
    _viewerError = null;
    _pageSizes = <Size>[];
    _lastPageNumber = 0;
    _activePointers.clear();
    _pinchStartDistance = null;
    _suppressNextTapToggle = false;
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
            _isLoadingBytes = false;
            _resetReaderStateForNewDocument();
          });
        } else {
          final realPath = await resolveToRealPath(result.files.single.path!);
          if (!mounted) return;
          setState(() {
            _pdfFile = File(realPath);
            _webFileName = null;
            _webFileSize = null;
            _resetReaderStateForNewDocument();
          });
          _setControllerZoom(1.0);
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
            _resetReaderStateForNewDocument();
          });
          _setControllerZoom(1.0);
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
              _resetReaderStateForNewDocument();
            });
            _setControllerZoom(1.0);
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
      } else if (PlatformHelper.isMacOS) {
        await Process.run('open', [_pdfFile!.parent.path]);
      } else if (PlatformHelper.isWindows) {
        await Process.run('explorer', [_pdfFile!.parent.path]);
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
      if (await _pdfFile!.exists()) {
        final savedFile = await OutputPathHelper.exportGeneratedFile(
          sourcePath: _pdfFile!.path,
          fileName: p.basename(_pdfFile!.path),
          category: OutputCategory.downloads,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to ${savedFile.displayPath}')),
        );
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

  Future<void> _toggleFavorite() async {
    if (!_hasDocument) return;
    if (kIsWeb || _pdfFile == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Favorites not available on web')),
      );
      return;
    }
    await FileHistoryService.toggleFavorite(_pdfFile!.path);
    if (!mounted) return;
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  double _normaliseZoom(double zoom) {
    if (!zoom.isFinite) return _syncfusionMinZoom;
    return zoom.clamp(_minZoom, _maxZoom).toDouble();
  }

  double get _pdfRenderZoom => math.max(_zoom, _syncfusionMinZoom);

  double get _viewerScale => _zoom < _syncfusionMinZoom ? _zoom : 1.0;

  String get _zoomLabel => '${(_zoom * 100).round()}%';

  void _setControllerZoom(double zoom) {
    if (kIsWeb) return;
    final renderZoom = math.max(_normaliseZoom(zoom), _syncfusionMinZoom);
    if ((_pdfViewerController.zoomLevel - renderZoom).abs() <= 0.001) return;
    _isApplyingControllerZoom = true;
    try {
      _pdfViewerController.zoomLevel = renderZoom;
    } finally {
      _isApplyingControllerZoom = false;
    }
  }

  void _setZoom(
    double zoom, {
    String viewMode = 'custom',
    bool updateViewMode = true,
  }) {
    final displayZoom = _normaliseZoom(zoom);
    setState(() {
      _zoom = displayZoom;
      if (updateViewMode) {
        _viewMode = viewMode;
      }
    });
    _setControllerZoom(_pdfRenderZoom);
  }

  void _zoomIn() {
    _setZoom(_zoom + 0.1);
  }

  void _zoomOut() {
    _setZoom(_zoom - 0.1);
  }

  void _resetZoom() {
    setState(() {
      _rotationAngle = 0;
      _brightness = 1.0;
      _isNightMode = false;
    });
    _setViewMode('fit');
  }

  void _rotateClockwise() {
    setState(() {
      _rotationAngle = (_rotationAngle + 90) % 360;
    });
    _scheduleViewModeRefresh();
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

  Future<void> _showSearchDialog() async {
    if (_pdfFile == null && _pdfBytes == null) return;
    final controller = TextEditingController();
    final query = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Search PDF'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search text',
            border: OutlineInputBorder(),
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: (value) => Navigator.of(ctx).pop(value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('Search'),
          ),
        ],
      ),
    );
    final trimmedQuery = query?.trim();
    if (trimmedQuery == null || trimmedQuery.isEmpty) return;
    _searchResult.removeListener(_onSearchResultChanged);
    _searchResult.clear();
    _searchResult = _pdfViewerController.searchText(trimmedQuery);
    _searchResult.addListener(_onSearchResultChanged);
    setState(() {});
  }

  void _clearSearch() {
    _searchResult.removeListener(_onSearchResultChanged);
    _searchResult.clear();
    _searchResult = PdfTextSearchResult();
    setState(() {});
  }

  void _handleDocumentLoaded(PdfDocumentLoadedDetails details) {
    final pages = details.document.pages;
    final pageSizes = <Size>[];
    for (var index = 0; index < pages.count; index++) {
      pageSizes.add(pages[index].size);
    }
    if (!mounted) return;
    setState(() {
      _viewerError = null;
      _pageSizes = pageSizes;
      _lastPageNumber = _pdfViewerController.pageNumber;
    });
    _scheduleViewModeRefresh(force: true);
  }

  void _handleDocumentLoadFailed(PdfDocumentLoadFailedDetails details) {
    final message = details.description.isNotEmpty
        ? details.description
        : details.error;
    debugPrint('[PdfViewer] Document load failed: ${details.error} $message');
    if (!mounted) return;
    setState(() {
      _viewerError = message.isEmpty
          ? 'Unable to load this PDF. It may be corrupt or password protected.'
          : message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unable to load PDF: $_viewerError')),
    );
  }

  void _handlePdfZoomLevelChanged(PdfZoomDetails details) {
    if (_isApplyingControllerZoom || !mounted) return;
    final controllerZoom = _normaliseZoom(details.newZoomLevel);
    if (controllerZoom < _syncfusionMinZoom) return;
    setState(() {
      _zoom = controllerZoom;
      _viewMode = 'custom';
    });
  }

  Size? get _activePageSize {
    if (_pageSizes.isEmpty) return null;
    final pageNumber = _pdfViewerController.pageNumber <= 0
        ? 1
        : _pdfViewerController.pageNumber;
    final index = (pageNumber - 1).clamp(0, _pageSizes.length - 1).toInt();
    final pageSize = _pageSizes[index];
    if (_rotationAngle % 180 == 0) {
      return pageSize;
    }
    return Size(pageSize.height, pageSize.width);
  }

  double? _zoomForViewMode(String mode) {
    final viewport = _viewerViewportSize;
    final pageSize = _activePageSize;
    if (viewport == null ||
        pageSize == null ||
        viewport.width <= 0 ||
        viewport.height <= 0 ||
        pageSize.width <= 0 ||
        pageSize.height <= 0) {
      return null;
    }
    final availableWidth = math.max(1.0, viewport.width - 24);
    final availableHeight = math.max(1.0, viewport.height - 32);
    switch (mode) {
      case 'width':
        return _normaliseZoom(availableWidth / pageSize.width);
      case 'height':
        return _normaliseZoom(availableHeight / pageSize.height);
      default:
        return _normaliseZoom(
          math.min(
            availableWidth / pageSize.width,
            availableHeight / pageSize.height,
          ),
        );
    }
  }

  void _setViewMode(String mode) {
    final targetZoom = _zoomForViewMode(mode) ?? _syncfusionMinZoom;
    _setZoom(targetZoom, viewMode: mode);
  }

  void _scheduleViewModeRefresh({bool force = false}) {
    if (!force && _viewMode == 'custom') return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _viewMode == 'custom') return;
      final targetZoom = _zoomForViewMode(_viewMode);
      if (targetZoom == null || (targetZoom - _zoom).abs() <= 0.005) return;
      _setZoom(targetZoom, viewMode: _viewMode);
    });
  }

  void _toggleNightMode() {
    setState(() {
      _isNightMode = !_isNightMode;
      _brightness = _isNightMode ? 0.6 : 1.0;
    });
  }

  Future<void> _showCustomZoomDialog() async {
    final controller = TextEditingController(
      text: (_zoom * 100).round().toString(),
    );
    try {
      final zoom = await showDialog<double>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Custom Zoom'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Zoom percentage',
              suffixText: '%',
              helperText: 'Supported range: 50% to 300%',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _submitCustomZoom(ctx, controller),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => _submitCustomZoom(ctx, controller),
              child: const Text('Apply'),
            ),
          ],
        ),
      );
      if (zoom != null && mounted) {
        _setZoom(zoom);
      }
    } finally {
      controller.dispose();
    }
  }

  void _submitCustomZoom(
    BuildContext dialogContext,
    TextEditingController controller,
  ) {
    final percent = double.tryParse(controller.text.trim());
    if (percent == null) return;
    Navigator.of(dialogContext).pop(_normaliseZoom(percent / 100));
  }

  void _showViewModeMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      backgroundColor: isDark
          ? PremiumColors.darkSurfacePrimary
          : PremiumColors.lightSurfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetHeader(
                title: 'View Mode',
                subtitle: 'Choose the page scale that feels best for reading.',
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _ViewModeTile(
                icon: Icons.image_outlined,
                title: 'Fit Page',
                subtitle: 'Show the full page in the viewport.',
                selected: _viewMode == 'fit',
                onTap: () {
                  Navigator.pop(context);
                  _setViewMode('fit');
                },
              ),
              _ViewModeTile(
                icon: Icons.aspect_ratio,
                title: 'Fit Width',
                subtitle: 'Make text wider and easier to scan.',
                selected: _viewMode == 'width',
                onTap: () {
                  Navigator.pop(context);
                  _setViewMode('width');
                },
              ),
              _ViewModeTile(
                icon: Icons.height,
                title: 'Fit Height',
                subtitle: 'Keep page height visible when reviewing layouts.',
                selected: _viewMode == 'height',
                onTap: () {
                  Navigator.pop(context);
                  _setViewMode('height');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSheetSectionTitle(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(2, 14, 2, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: PremiumTypography.labelLarge.copyWith(
            color: isDark ? PremiumColors.darkText : PremiumColors.lightText,
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedZoomPanel(
    bool isDark,
    StateSetter setSheetState,
    BuildContext sheetContext,
  ) {
    final textColor = isDark ? PremiumColors.darkText : PremiumColors.lightText;
    final mutedColor = isDark
        ? PremiumColors.darkTextSecondary
        : PremiumColors.lightTextSecondary;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark
            ? PremiumColors.darkSurfaceSecondary
            : PremiumColors.lightSurfaceSecondary,
        borderRadius: BorderRadius.circular(14),
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Zoom & Layout',
                      style: PremiumTypography.labelLarge.copyWith(
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '50% to 300%, synced with pinch and fit presets.',
                      style: PremiumTypography.bodySmall.copyWith(
                        color: mutedColor,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  _zoomOut();
                  setSheetState(() {});
                },
                icon: const Icon(Icons.remove),
                tooltip: 'Zoom out',
              ),
              Text(
                _zoomLabel,
                style: PremiumTypography.labelLarge.copyWith(color: textColor),
              ),
              IconButton(
                onPressed: () {
                  _zoomIn();
                  setSheetState(() {});
                },
                icon: const Icon(Icons.add),
                tooltip: 'Zoom in',
              ),
            ],
          ),
          Slider(
            value: _zoom,
            min: _minZoom,
            max: _maxZoom,
            divisions: 25,
            activeColor: PremiumColors.luxuryRed,
            onChanged: (value) {
              _setZoom(value);
              setSheetState(() {});
            },
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Fit Page'),
                selected: _viewMode == 'fit',
                onSelected: (_) {
                  _setViewMode('fit');
                  setSheetState(() {});
                },
              ),
              ChoiceChip(
                label: const Text('Fit Width'),
                selected: _viewMode == 'width',
                onSelected: (_) {
                  _setViewMode('width');
                  setSheetState(() {});
                },
              ),
              ChoiceChip(
                label: const Text('Fit Height'),
                selected: _viewMode == 'height',
                onSelected: (_) {
                  _setViewMode('height');
                  setSheetState(() {});
                },
              ),
              ActionChip(
                label: const Text('100%'),
                onPressed: () {
                  _setZoom(1.0);
                  setSheetState(() {});
                },
              ),
              ActionChip(
                label: const Text('Custom %'),
                onPressed: () {
                  Navigator.pop(sheetContext);
                  _showCustomZoomDialog();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedBrightnessPanel(bool isDark, StateSetter setSheetState) {
    final textColor = isDark ? PremiumColors.darkText : PremiumColors.lightText;
    final mutedColor = isDark
        ? PremiumColors.darkTextSecondary
        : PremiumColors.lightTextSecondary;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark
            ? PremiumColors.darkSurfaceSecondary
            : PremiumColors.lightSurfaceSecondary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? PremiumColors.darkDivider
              : PremiumColors.lightDivider,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isNightMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
            color: PremiumColors.luxuryRed,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Brightness',
                  style: PremiumTypography.labelLarge.copyWith(
                    color: textColor,
                  ),
                ),
                Slider(
                  value: _brightness,
                  min: 0.3,
                  max: 1.5,
                  divisions: 24,
                  activeColor: PremiumColors.luxuryRed,
                  onChanged: (value) {
                    setState(() => _brightness = value);
                    setSheetState(() {});
                  },
                ),
              ],
            ),
          ),
          SizedBox(
            width: 46,
            child: Text(
              '${(_brightness * 100).round()}%',
              textAlign: TextAlign.right,
              style: PremiumTypography.labelSmall.copyWith(color: mutedColor),
            ),
          ),
        ],
      ),
    );
  }

  void _showAdvancedTools() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rootContext = context;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: isDark
          ? PremiumColors.darkSurfacePrimary
          : PremiumColors.lightSurfacePrimary,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SheetHeader(
                    title: 'Advanced Tools',
                    subtitle:
                        'Open only when you need search, layout, or document actions.',
                    isDark: isDark,
                  ),
                  _buildAdvancedZoomPanel(isDark, setSheetState, sheetContext),
                  _buildSheetSectionTitle('Reading', isDark),
                  _buildAdvancedBrightnessPanel(isDark, setSheetState),
                  _ActionSheetTile(
                    icon: Icons.search,
                    title: 'Search PDF',
                    subtitle: 'Find text in the current document.',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _showSearchDialog();
                    },
                  ),
                  if (_searchResult.hasResult) ...[
                    _ActionSheetTile(
                      icon: Icons.keyboard_arrow_up,
                      title: 'Previous Result',
                      subtitle: 'Move to the previous search match.',
                      onTap: _searchResult.previousInstance,
                    ),
                    _ActionSheetTile(
                      icon: Icons.keyboard_arrow_down,
                      title: 'Next Result',
                      subtitle: 'Move to the next search match.',
                      onTap: _searchResult.nextInstance,
                    ),
                    _ActionSheetTile(
                      icon: Icons.close,
                      title: 'Clear Search',
                      subtitle: 'Remove search highlights.',
                      onTap: () {
                        _clearSearch();
                        setSheetState(() {});
                      },
                    ),
                  ],
                  _ActionSheetTile(
                    icon: Icons.find_in_page_outlined,
                    title: 'Jump to Page',
                    subtitle: 'Go directly to a page number.',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _jumpToPage();
                    },
                  ),
                  _ActionSheetTile(
                    icon: _isNightMode
                        ? Icons.light_mode
                        : Icons.dark_mode_outlined,
                    title: _isNightMode ? 'Day Mode' : 'Night Mode',
                    subtitle: 'Switch the reader color treatment.',
                    onTap: () {
                      _toggleNightMode();
                      setSheetState(() {});
                    },
                  ),
                  _ActionSheetTile(
                    icon: Icons.rotate_right,
                    title: 'Rotate Clockwise',
                    subtitle: _rotationAngle == 0
                        ? 'Rotate the document view.'
                        : 'Current rotation: $_rotationAngle degrees.',
                    onTap: () {
                      _rotateClockwise();
                      setSheetState(() {});
                    },
                  ),
                  _ActionSheetTile(
                    icon: Icons.refresh,
                    title: 'Reset View',
                    subtitle:
                        'Restore fit page, rotation, brightness, and mode.',
                    onTap: () {
                      _resetZoom();
                      setSheetState(() {});
                    },
                  ),
                  _buildSheetSectionTitle('Document', isDark),
                  _ActionSheetTile(
                    icon: _isFavorite ? Icons.star : Icons.star_outline,
                    title: _isFavorite ? 'Remove Favorite' : 'Add to Favorites',
                    subtitle: 'Keep this file easy to find later.',
                    onTap: () async {
                      await _toggleFavorite();
                      setSheetState(() {});
                    },
                  ),
                  _ActionSheetTile(
                    icon: Icons.folder_open,
                    title: 'Open PDF',
                    subtitle: 'Choose a different document.',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _pickPdf();
                    },
                  ),
                  _ActionSheetTile(
                    icon: Icons.history,
                    title: 'History & Favorites',
                    subtitle: 'Open recent files and starred documents.',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      Navigator.push(
                        rootContext,
                        MaterialPageRoute(
                          builder: (_) => const HistoryScreen(),
                        ),
                      );
                    },
                  ),
                  _ActionSheetTile(
                    icon: Icons.drive_folder_upload_outlined,
                    title: 'Open Folder',
                    subtitle: 'Reveal the file location on this device.',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _sharePdf();
                    },
                  ),
                  _ActionSheetTile(
                    icon: Icons.download,
                    title: 'Save a Copy',
                    subtitle: 'Export this PDF into the downloads location.',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _downloadPdf();
                    },
                  ),
                  _ActionSheetTile(
                    icon: Icons.drive_file_rename_outline,
                    title: 'Rename',
                    subtitle: 'Update the file name and history record.',
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _renamePdf();
                    },
                  ),
                ],
              ),
            ),
          ),
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

  String _safeFileSizeMb(File? file) {
    if (file == null) return '0';
    try {
      if (!file.existsSync()) return '0';
      return (file.lengthSync() / (1024 * 1024)).toStringAsFixed(2);
    } catch (_) {
      return '0';
    }
  }

  bool get _hasDocument => _pdfFile != null || _pdfBytes != null;

  String get _viewModeLabel {
    switch (_viewMode) {
      case 'width':
        return 'Fit width';
      case 'height':
        return 'Fit height';
      default:
        return 'Fit page';
    }
  }

  String get _pageLabel {
    final pageCount = _pdfViewerController.pageCount;
    if (pageCount <= 0) return 'Loading';
    final pageNumber = _pdfViewerController.pageNumber <= 0
        ? 1
        : _pdfViewerController.pageNumber;
    return '$pageNumber / $pageCount';
  }

  void _rememberViewerViewport(Size size) {
    if (!size.width.isFinite ||
        !size.height.isFinite ||
        size.width <= 0 ||
        size.height <= 0) {
      return;
    }
    final oldSize = _viewerViewportSize;
    if (oldSize != null &&
        (oldSize.width - size.width).abs() < 0.5 &&
        (oldSize.height - size.height).abs() < 0.5) {
      return;
    }
    _viewerViewportSize = size;
    _scheduleViewModeRefresh(force: true);
  }

  double? _activePointerDistance() {
    if (_activePointers.length < 2) return null;
    final points = _activePointers.values.take(2).toList();
    return (points[0] - points[1]).distance;
  }

  void _startExternalPinch() {
    _pinchStartDistance = _activePointerDistance();
    _pinchStartZoom = _zoom;
  }

  void _handleViewerPointerDown(PointerDownEvent event) {
    _activePointers[event.pointer] = event.localPosition;
    if (_activePointers.length == 2) {
      _startExternalPinch();
    }
  }

  void _handleViewerPointerMove(PointerMoveEvent event) {
    if (!_activePointers.containsKey(event.pointer)) return;
    _activePointers[event.pointer] = event.localPosition;
    final startDistance = _pinchStartDistance;
    final currentDistance = _activePointerDistance();
    if (startDistance == null ||
        currentDistance == null ||
        startDistance <= 0 ||
        currentDistance <= 0) {
      return;
    }
    final targetZoom = _normaliseZoom(
      _pinchStartZoom * (currentDistance / startDistance),
    );
    if (_pinchStartZoom < _syncfusionMinZoom ||
        targetZoom < _syncfusionMinZoom) {
      _suppressNextTapToggle = true;
      _setZoom(
        _pinchStartZoom < _syncfusionMinZoom
            ? math.min(targetZoom, _syncfusionMinZoom)
            : targetZoom,
      );
    }
  }

  void _handleViewerPointerEnd(PointerEvent event) {
    _activePointers.remove(event.pointer);
    if (_activePointers.length < 2) {
      _pinchStartDistance = null;
    } else {
      _startExternalPinch();
    }
  }

  void _toggleControlsFromTap() {
    if (_suppressNextTapToggle) {
      _suppressNextTapToggle = false;
      return;
    }
    setState(() => _showControls = !_showControls);
  }

  Widget _buildPdfContent() {
    if (kIsWeb) {
      if (_isLoadingBytes) {
        return const Center(child: CircularProgressIndicator());
      }
      if (_pdfBytes != null) {
        return WebPdfViewer(pdfBytes: _pdfBytes!, fileName: _webFileName);
      }
      return const Center(child: Text('Unable to load PDF'));
    }

    if (_pdfFile == null) {
      return const Center(child: Text('Unable to load PDF'));
    }

    if (_password != null) {
      return SfPdfViewer.file(
        _pdfFile!,
        controller: _pdfViewerController,
        password: _password!,
        initialZoomLevel: _pdfRenderZoom,
        maxZoomLevel: _maxZoom,
        enableTextSelection: true,
        onHyperlinkClicked: _handleHyperlinkClicked,
        onDocumentLoaded: _handleDocumentLoaded,
        onDocumentLoadFailed: _handleDocumentLoadFailed,
        onZoomLevelChanged: _handlePdfZoomLevelChanged,
        currentSearchTextHighlightColor: Colors.amber,
        otherSearchTextHighlightColor: Colors.yellowAccent,
      );
    }

    return SfPdfViewer.file(
      _pdfFile!,
      controller: _pdfViewerController,
      initialZoomLevel: _pdfRenderZoom,
      maxZoomLevel: _maxZoom,
      enableTextSelection: true,
      onHyperlinkClicked: _handleHyperlinkClicked,
      onDocumentLoaded: _handleDocumentLoaded,
      onDocumentLoadFailed: _handleDocumentLoadFailed,
      onZoomLevelChanged: _handlePdfZoomLevelChanged,
      currentSearchTextHighlightColor: Colors.amber,
      otherSearchTextHighlightColor: Colors.yellowAccent,
    );
  }

  Widget _buildScaledPdfContent() {
    final content = _buildPdfContent();
    final scale = _viewerScale;
    if (kIsWeb || scale >= _syncfusionMinZoom) {
      return content;
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;
        if (!width.isFinite || !height.isFinite || width <= 0 || height <= 0) {
          return content;
        }
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: width / scale,
                height: height / scale,
                child: content,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildViewerWorkspace({
    required bool isDark,
    required String fileName,
    required String fileSize,
  }) {
    final surfaceColor = _isNightMode
        ? const Color(0xFF050505)
        : (isDark ? PremiumColors.darkBg : const Color(0xFFEFF1F5));
    return LayoutBuilder(
      builder: (context, constraints) {
        _rememberViewerViewport(
          Size(constraints.maxWidth, constraints.maxHeight),
        );
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleControlsFromTap,
          child: Stack(
            children: [
              Positioned.fill(
                child: Listener(
                  onPointerDown: _handleViewerPointerDown,
                  onPointerMove: _handleViewerPointerMove,
                  onPointerUp: _handleViewerPointerEnd,
                  onPointerCancel: _handleViewerPointerEnd,
                  child: Container(
                    color: surfaceColor,
                    child: ColorFiltered(
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
                        angle: (_rotationAngle * math.pi) / 180,
                        child: _buildScaledPdfContent(),
                      ),
                    ),
                  ),
                ),
              ),
              if (_viewerError != null) _buildViewerErrorOverlay(),
              if (_showControls)
                Positioned(
                  top: 12,
                  left: 12,
                  right: 12,
                  child: _buildViewerStatusBar(
                    isDark: isDark,
                    fileName: fileName,
                    fileSize: fileSize,
                  ),
                ),
              if (_showControls)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: _buildReaderControls(isDark),
                ),
              if (!_showControls)
                Positioned(
                  bottom: 18 + MediaQuery.of(context).padding.bottom,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.62),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Tap to show controls',
                        style: TextStyle(color: Colors.white, fontSize: 13),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildViewerStatusBar({
    required bool isDark,
    required String fileName,
    required String fileSize,
  }) {
    final pageCount = _pdfViewerController.pageCount;
    final textColor = isDark || _isNightMode
        ? PremiumColors.darkText
        : PremiumColors.lightText;
    final mutedColor = isDark || _isNightMode
        ? PremiumColors.darkTextSecondary
        : PremiumColors.lightTextSecondary;
    return GestureDetector(
      onTap: () {},
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _isNightMode || isDark
              ? Colors.black.withValues(alpha: 0.78)
              : Colors.white.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isNightMode || isDark
                ? Colors.white.withValues(alpha: 0.10)
                : PremiumColors.lightDivider,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.26 : 0.10),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: PremiumColors.luxuryRed.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.picture_as_pdf,
                color: PremiumColors.luxuryRed,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PremiumTypography.labelLarge.copyWith(
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    pageCount > 0
                        ? '$fileSize MB - $pageCount pages'
                        : '$fileSize MB',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: PremiumTypography.bodySmall.copyWith(
                      color: mutedColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _ReaderStatusChip(
              icon: Icons.description_outlined,
              label: _pageLabel,
              isDark: isDark || _isNightMode,
            ),
            const SizedBox(width: 6),
            _ReaderStatusChip(
              icon: Icons.zoom_in,
              label: _zoomLabel,
              isDark: isDark || _isNightMode,
            ),
            if (_searchResult.hasResult) ...[
              const SizedBox(width: 6),
              _ReaderStatusChip(
                icon: Icons.search,
                label: 'Search',
                isDark: isDark || _isNightMode,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReaderControls(bool isDark) {
    return GestureDetector(
      onTap: () {},
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          0,
          12,
          12 + MediaQuery.of(context).padding.bottom,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: _buildReaderToolbar(isDark),
          ),
        ),
      ),
    );
  }

  Widget _buildReaderToolbar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: _isNightMode ? 0.92 : 0.82),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _ReaderToolButton(
              icon: Icons.zoom_out,
              label: 'Out',
              onPressed: _zoomOut,
            ),
            _ZoomReadout(label: _zoomLabel, onTap: _showCustomZoomDialog),
            _ReaderToolButton(
              icon: Icons.zoom_in,
              label: 'In',
              onPressed: _zoomIn,
            ),
            const _ToolbarDivider(),
            _ReaderToolButton(
              icon: Icons.fit_screen,
              label: _viewModeLabel,
              onPressed: _showViewModeMenu,
            ),
            _ReaderToolButton(
              icon: Icons.tune,
              label: 'Advanced',
              onPressed: _showAdvancedTools,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewerErrorOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.74),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 44),
                const SizedBox(height: 16),
                Text(
                  _viewerError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pickPdf,
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Open Another PDF'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildViewerEmptyState(bool isDark) {
    final textColor = isDark ? PremiumColors.darkText : PremiumColors.lightText;
    final mutedColor = isDark
        ? PremiumColors.darkTextSecondary
        : PremiumColors.lightTextSecondary;
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: isDark
                    ? PremiumColors.darkSurfaceSecondary
                    : PremiumColors.lightSurfacePrimary,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark
                      ? PremiumColors.darkDivider
                      : PremiumColors.lightDivider,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.24 : 0.07),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (kIsWeb)
                    Align(
                      alignment: Alignment.centerRight,
                      child: ThemeSwitcher(compact: true),
                    ),
                  Container(
                    width: 82,
                    height: 82,
                    decoration: BoxDecoration(
                      color: PremiumColors.luxuryRed.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.picture_as_pdf_outlined,
                      size: 42,
                      color: PremiumColors.luxuryRed,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Open a PDF to read',
                    textAlign: TextAlign.center,
                    style: PremiumTypography.headlineLarge.copyWith(
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Search text, adjust brightness, rotate pages, jump around, and save or share from one focused reader.',
                    textAlign: TextAlign.center,
                    style: PremiumTypography.bodyMedium.copyWith(
                      color: mutedColor,
                    ),
                  ),
                  const SizedBox(height: 22),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 10,
                    runSpacing: 10,
                    children: const [
                      _ViewerFeatureTile(icon: Icons.search, label: 'Search'),
                      _ViewerFeatureTile(
                        icon: Icons.dark_mode_outlined,
                        label: 'Night mode',
                      ),
                      _ViewerFeatureTile(
                        icon: Icons.fit_screen,
                        label: 'Fit modes',
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _pickPdf,
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Select PDF'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                        ),
                      ),
                      if (!kIsWeb)
                        OutlinedButton.icon(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const HistoryScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.history),
                          label: const Text('History'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isCompact = MediaQuery.of(context).size.width < 460;
    final fileName = kIsWeb
        ? (_webFileName ?? 'View PDF')
        : (_pdfFile != null ? p.basename(_pdfFile!.path) : 'View PDF');
    final fileSize = kIsWeb
        ? (_webFileSize != null
              ? (_webFileSize! / (1024 * 1024)).toStringAsFixed(2)
              : '0')
        : _safeFileSizeMb(_pdfFile);
    return Scaffold(
      backgroundColor: _isNightMode
          ? const Color(0xFF0A0A0A)
          : (isDark ? PremiumColors.darkBg : PremiumColors.lightBg),
      appBar: kIsWeb
          ? null
          : AppBar(
              backgroundColor: _isNightMode
                  ? const Color(0xFF121212)
                  : (isDark
                        ? PremiumColors.darkSurfacePrimary
                        : PremiumColors.lightSurfacePrimary),
              foregroundColor: isDark
                  ? PremiumColors.darkText
                  : PremiumColors.lightText,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    fileName,
                    style: PremiumTypography.labelLarge.copyWith(
                      color: isDark
                          ? PremiumColors.darkText
                          : PremiumColors.lightText,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_hasDocument)
                    Text(
                      _pdfViewerController.pageCount > 0
                          ? '$fileSize MB - ${_pdfViewerController.pageCount} pages'
                          : '$fileSize MB',
                      style: PremiumTypography.bodySmall.copyWith(
                        color: isDark
                            ? PremiumColors.darkTextSecondary
                            : PremiumColors.lightTextSecondary,
                      ),
                    ),
                ],
              ),
              elevation: 0,
              actions: [
                ThemeSwitcher(compact: true),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.folder_open),
                  tooltip: 'Open PDF',
                  onPressed: _pickPdf,
                ),
                if (_hasDocument)
                  isCompact
                      ? IconButton(
                          icon: const Icon(Icons.tune),
                          tooltip: 'Advanced Tools',
                          onPressed: _showAdvancedTools,
                        )
                      : Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: TextButton.icon(
                            onPressed: _showAdvancedTools,
                            icon: const Icon(Icons.tune, size: 18),
                            label: const Text('Advanced Tools'),
                          ),
                        ),
              ],
            ),
      body: _hasDocument
          ? SafeArea(
              top: kIsWeb,
              bottom: false,
              child: _buildViewerWorkspace(
                isDark: isDark,
                fileName: fileName,
                fileSize: fileSize,
              ),
            )
          : _buildViewerEmptyState(isDark),
    );
  }
}

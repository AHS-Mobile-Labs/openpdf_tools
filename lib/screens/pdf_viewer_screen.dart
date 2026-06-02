import 'dart:io';
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
  const _ZoomReadout({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
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
          final realPath = await resolveToRealPath(result.files.single.path!);
          if (!mounted) return;
          setState(() {
            _pdfFile = File(realPath);
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
    if (mounted && _viewerError != null) {
      setState(() => _viewerError = null);
    }
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

  void _showMoreMenu() {
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
                title: 'Document Actions',
                subtitle: 'Manage the current PDF without leaving the reader.',
                isDark: isDark,
              ),
              const SizedBox(height: 10),
              _ActionSheetTile(
                icon: Icons.history,
                title: 'History & Favorites',
                subtitle: 'Open recent files and starred documents.',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  );
                },
              ),
              _ActionSheetTile(
                icon: Icons.folder_open,
                title: 'Open Folder',
                subtitle: 'Reveal the file location on this device.',
                onTap: () {
                  Navigator.pop(context);
                  _sharePdf();
                },
              ),
              _ActionSheetTile(
                icon: Icons.download,
                title: 'Save a Copy',
                subtitle: 'Export this PDF into the downloads location.',
                onTap: () {
                  Navigator.pop(context);
                  _downloadPdf();
                },
              ),
              _ActionSheetTile(
                icon: Icons.drive_file_rename_outline,
                title: 'Rename',
                subtitle: 'Update the file name and history record.',
                onTap: () {
                  Navigator.pop(context);
                  _renamePdf();
                },
              ),
            ],
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
        initialZoomLevel: _zoom,
        enableTextSelection: true,
        onHyperlinkClicked: _handleHyperlinkClicked,
        onDocumentLoaded: _handleDocumentLoaded,
        onDocumentLoadFailed: _handleDocumentLoadFailed,
        currentSearchTextHighlightColor: Colors.amber,
        otherSearchTextHighlightColor: Colors.yellowAccent,
      );
    }

    return SfPdfViewer.file(
      _pdfFile!,
      controller: _pdfViewerController,
      initialZoomLevel: _zoom,
      enableTextSelection: true,
      onHyperlinkClicked: _handleHyperlinkClicked,
      onDocumentLoaded: _handleDocumentLoaded,
      onDocumentLoadFailed: _handleDocumentLoadFailed,
      currentSearchTextHighlightColor: Colors.amber,
      otherSearchTextHighlightColor: Colors.yellowAccent,
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
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => _showControls = !_showControls),
      child: Stack(
        children: [
          Positioned.fill(
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
                  angle: (_rotationAngle * 3.14159) / 180,
                  child: _buildPdfContent(),
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
            constraints: const BoxConstraints(maxWidth: 760),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildBrightnessControl(isDark),
                const SizedBox(height: 10),
                _buildReaderToolbar(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrightnessControl(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: _isNightMode ? 0.86 : 0.72),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Icon(
            _isNightMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
            color: Colors.white70,
            size: 19,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: PremiumColors.luxuryRed,
                inactiveTrackColor: Colors.white24,
                thumbColor: Colors.white,
                overlayColor: PremiumColors.luxuryRed.withValues(alpha: 0.14),
                trackHeight: 3,
              ),
              child: Slider(
                value: _brightness,
                min: 0.3,
                max: 1.5,
                divisions: 24,
                onChanged: (value) => setState(() => _brightness = value),
              ),
            ),
          ),
          SizedBox(
            width: 42,
            child: Text(
              '${(_brightness * 100).toInt()}%',
              textAlign: TextAlign.right,
              style: PremiumTypography.labelSmall.copyWith(
                color: Colors.white70,
              ),
            ),
          ),
        ],
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
            _ZoomReadout(label: '${(_zoom * 100).toStringAsFixed(0)}%'),
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
              icon: _isNightMode ? Icons.light_mode : Icons.dark_mode,
              label: _isNightMode ? 'Day' : 'Night',
              onPressed: _toggleNightMode,
            ),
            _ReaderToolButton(
              icon: Icons.rotate_right,
              label: _rotationAngle == 0 ? 'Rotate' : '$_rotationAngle deg',
              onPressed: _rotateClockwise,
            ),
            _ReaderToolButton(
              icon: Icons.find_in_page_outlined,
              label: 'Page',
              onPressed: _jumpToPage,
            ),
            _ReaderToolButton(
              icon: Icons.refresh,
              label: 'Reset',
              onPressed: _resetZoom,
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
                  icon: const Icon(Icons.search),
                  tooltip: 'Search',
                  onPressed: _hasDocument ? _showSearchDialog : null,
                ),
                if (_searchResult.hasResult) ...[
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_up),
                    tooltip: 'Previous result',
                    onPressed: _searchResult.previousInstance,
                  ),
                  IconButton(
                    icon: const Icon(Icons.keyboard_arrow_down),
                    tooltip: 'Next result',
                    onPressed: _searchResult.nextInstance,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: 'Clear search',
                    onPressed: _clearSearch,
                  ),
                ],
                IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.star : Icons.star_outline,
                    color: _isFavorite ? Colors.amber : null,
                  ),
                  tooltip: _isFavorite
                      ? 'Remove from Favorites'
                      : 'Add to Favorites',
                  onPressed: _hasDocument
                      ? () async {
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
                        }
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.folder_open),
                  tooltip: 'Open PDF',
                  onPressed: _pickPdf,
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  onPressed: _hasDocument ? _showMoreMenu : null,
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

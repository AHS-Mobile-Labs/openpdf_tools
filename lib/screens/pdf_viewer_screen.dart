import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'package:openpdf_tools/config/premium_theme.dart';
import 'package:openpdf_tools/widgets/in_app_file_picker.dart';
import 'package:openpdf_tools/services/file_history_service.dart';
import 'package:openpdf_tools/utils/platform_file_handler.dart';
import 'package:openpdf_tools/utils/platform_helper.dart';
import 'package:openpdf_tools/utils/uri_to_file.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:syncfusion_flutter_core/theme.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import 'package:openpdf_tools/utils/output_path_helper.dart';
import 'package:openpdf_tools/utils/web_file_saver.dart';
import 'history_screen.dart';

class PdfViewerScreen extends StatefulWidget {
  final File? externalFile;
  final Uint8List? externalBytes;
  final String? externalFileName;
  const PdfViewerScreen({
    super.key,
    this.externalFile,
    this.externalBytes,
    this.externalFileName,
  });
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
  final bool isCompact;
  const _ReaderStatusChip({
    required this.icon,
    required this.label,
    required this.isDark,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 7 : 9,
        vertical: isCompact ? 4 : 7,
      ),
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
            size: isCompact ? 13 : 15,
          ),
          SizedBox(width: isCompact ? 4 : 5),
          Text(
            label,
            style: (isCompact
                    ? PremiumTypography.labelSmall.copyWith(fontSize: 11)
                    : PremiumTypography.labelSmall)
                .copyWith(
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
  final VoidCallback? onPressed;
  final bool isMobile;
  const _ReaderToolButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: Colors.white,
          minimumSize: Size(isMobile ? 48 : 54, isMobile ? 40 : 46),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 6 : 10,
            vertical: isMobile ? 4 : 6,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: isMobile ? 18 : 20, color: Colors.white),
            const SizedBox(height: 2),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: (isMobile
                      ? PremiumTypography.labelSmall.copyWith(fontSize: 10)
                      : PremiumTypography.labelSmall)
                  .copyWith(
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
  final bool isMobile;
  const _ZoomReadout({
    required this.label,
    this.onTap,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = Container(
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 2 : 4),
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 8 : 12,
        vertical: isMobile ? 6 : 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: (isMobile
                ? PremiumTypography.labelSmall.copyWith(fontSize: 11)
                : PremiumTypography.labelSmall)
            .copyWith(color: Colors.white),
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
  final bool isMobile;
  const _ToolbarDivider({this.isMobile = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: isMobile ? 26 : 34,
      margin: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 6),
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
  static const double _minZoom = 1.0;
  static const double _maxZoom = 5.0;

  File? _pdfFile;
  String? _password;
  double _zoom = 1.0;
  final ValueNotifier<double> _zoomNotifier = ValueNotifier<double>(1.0);
  final ValueNotifier<int> _pageNumberNotifier = ValueNotifier<int>(1);
  final ValueNotifier<int> _pageCountNotifier = ValueNotifier<int>(0);
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
  PdfPageLayoutMode _pageLayoutMode = PdfPageLayoutMode.single;
  bool _isPasswordProtected = false;
  bool _isDocumentLoaded = false;
  String? _webFileName;
  int? _webFileSize;
  String? _viewerError;
  Size? _viewerViewportSize;
  bool _isApplyingControllerZoom = false;
  int _lastPageNumber = 0;

  @override
  void initState() {
    super.initState();
    _pdfViewerController.addListener(_onPdfViewerControllerChanged);
    if (widget.externalBytes != null) {
      _pdfBytes = widget.externalBytes;
      _webFileName = widget.externalFileName ?? 'Document.pdf';
      _webFileSize = widget.externalBytes!.length;
    } else if (widget.externalFile != null) {
      _pdfFile = widget.externalFile;
      _loadPdfBytes();
      _addToHistoryAndCheckFavorite();
    }
  }

  void _onPdfViewerControllerChanged() {
    if (!mounted) return;
    final pageNumber = _pdfViewerController.pageNumber;
    if (pageNumber > 0 && pageNumber != _lastPageNumber) {
      _lastPageNumber = pageNumber;
      _pageNumberNotifier.value = pageNumber;
    }
    final controllerZoom = _pdfViewerController.zoomLevel;
    if ((controllerZoom - _zoomNotifier.value).abs() > 0.01) {
      _zoom = controllerZoom;
      _zoomNotifier.value = controllerZoom;
      _viewMode = 'custom';
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
    _zoomNotifier.dispose();
    _pageNumberNotifier.dispose();
    _pageCountNotifier.dispose();
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
    _zoomNotifier.value = 1.0;
    _pageNumberNotifier.value = 1;
    _pageCountNotifier.value = 0;
    _rotationAngle = 0;
    _brightness = 1.0;
    _isNightMode = false;
    _viewMode = 'fit';
    _pageLayoutMode = PdfPageLayoutMode.single;
    _isPasswordProtected = false;
    _isDocumentLoaded = false;
    _password = null;
    _viewerError = null;
    _lastPageNumber = 0;
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
      if (result != null && result.files.isNotEmpty) {
        final pickedFile = result.files.single;
        if (kIsWeb) {
          setState(() {
            _pdfFile = null;
            _webFileName = pickedFile.name;
            _webFileSize = pickedFile.size;
            _pdfBytes = pickedFile.bytes;
            _isLoadingBytes = false;
            _resetReaderStateForNewDocument();
          });
        } else if (pickedFile.path != null && pickedFile.path!.isNotEmpty) {
          final realPath = await resolveToRealPath(pickedFile.path!);
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
      if (PlatformHelper.isAndroid || PlatformHelper.isIOS) {
        await share_plus.SharePlus.instance.share(
          share_plus.ShareParams(files: [share_plus.XFile(_pdfFile!.path)]),
        );
      } else if (PlatformHelper.isMacOS) {
        await Process.run('open', [_pdfFile!.parent.path]);
      } else if (PlatformHelper.isWindows) {
        await Process.run('explorer', [_pdfFile!.parent.path]);
      } else if (PlatformHelper.isLinux) {
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
        final fileName = _webFileName ?? 'document.pdf';
        await WebFileSaver.saveFile(
          bytes: _pdfBytes!,
          fileName: fileName,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloaded: $fileName'),
            backgroundColor: Colors.green,
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
    if (!zoom.isFinite) return 1.0;
    return zoom.clamp(_minZoom, _maxZoom).toDouble();
  }

  void _setControllerZoom(double zoom) {
    final renderZoom = _normaliseZoom(zoom);
    if ((_pdfViewerController.zoomLevel - renderZoom).abs() <= 0.001) return;
    _isApplyingControllerZoom = true;
    try {
      _pdfViewerController.zoomLevel = renderZoom;
    } catch (e) {
      debugPrint('Error applying zoom: $e');
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
    _zoom = displayZoom;
    _zoomNotifier.value = displayZoom;
    if (updateViewMode) {
      _viewMode = viewMode;
    }
    _setControllerZoom(displayZoom);
  }

  void _zoomIn() {
    _setZoom(_zoomNotifier.value + 0.25);
  }

  void _zoomOut() {
    _setZoom(_zoomNotifier.value - 0.25);
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
    if (!mounted) return;
    final pageCount = details.document.pages.count;
    _pageCountNotifier.value = pageCount;
    _pageNumberNotifier.value =
        _pdfViewerController.pageNumber > 0 ? _pdfViewerController.pageNumber : 1;
    setState(() {
      _viewerError = null;
      _isPasswordProtected = false;
      _isDocumentLoaded = true;
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

    final isPasswordError = details.error.toLowerCase().contains('password') ||
        details.description.toLowerCase().contains('password');
    if (isPasswordError) {
      final isInvalid = details.error.toLowerCase().contains('invalid') ||
          details.description.toLowerCase().contains('invalid');
      setState(() {
        _isPasswordProtected = true;
      });
      if (isInvalid) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Incorrect password. Please try again.'),
            backgroundColor: PremiumColors.brandRed,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    setState(() {
      _viewerError = message.isEmpty
          ? 'Unable to load this PDF. It may be corrupt or unreadable.'
          : message;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unable to load PDF: $_viewerError')),
    );
  }

  void _handlePdfZoomLevelChanged(PdfZoomDetails details) {
    if (_isApplyingControllerZoom || !mounted) return;
    final controllerZoom = _normaliseZoom(details.newZoomLevel);
    _zoom = controllerZoom;
    _zoomNotifier.value = controllerZoom;
    _viewMode = 'custom';
  }

  double? _zoomForViewMode(String mode) {
    return 1.0;
  }

  void _setViewMode(String mode) {
    if (mode == 'fit') {
      setState(() {
        _pageLayoutMode = PdfPageLayoutMode.single;
        _viewMode = 'fit';
      });
      _setZoom(1.0, viewMode: 'fit');
      return;
    } else if (mode == 'continuous') {
      setState(() {
        _pageLayoutMode = PdfPageLayoutMode.continuous;
        _viewMode = 'continuous';
      });
      _setZoom(1.0, viewMode: 'continuous');
      return;
    } else if (mode == 'width') {
      setState(() {
        _pageLayoutMode = PdfPageLayoutMode.continuous;
        _viewMode = 'width';
      });
      _setZoom(1.0, viewMode: 'width');
      return;
    } else if (mode == 'height') {
      setState(() {
        _pageLayoutMode = PdfPageLayoutMode.single;
        _viewMode = 'height';
      });
      _setZoom(1.0, viewMode: 'height');
      return;
    }
    final targetZoom = _zoomForViewMode(mode) ?? 1.0;
    _setZoom(targetZoom, viewMode: mode);
  }

  void _scheduleViewModeRefresh({bool force = false}) {
    if (!force && _viewMode == 'custom') return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _viewMode == 'custom') return;
      if (_viewMode == 'fit') {
        _setZoom(1.0, viewMode: 'fit');
        return;
      }
      final targetZoom = _zoomForViewMode(_viewMode);
      if (targetZoom == null || (targetZoom - _zoom).abs() <= 0.01) return;
      _setZoom(targetZoom, viewMode: _viewMode);
    });
  }

  void _toggleNightMode() {
    setState(() {
      _isNightMode = !_isNightMode;
    });
  }

  Future<void> _showCustomZoomDialog() async {
    final controller = TextEditingController(
      text: (_zoomNotifier.value * 100).round().toString(),
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
              helperText: 'Supported range: 100% to 500%',
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
    final bottomInset = MediaQuery.of(context).padding.bottom;
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
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
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
                icon: Icons.fit_screen,
                title: 'Fit Page (Single)',
                subtitle: 'Show one full page fitted to screen with no scrolling required.',
                selected: _pageLayoutMode == PdfPageLayoutMode.single,
                onTap: () {
                  Navigator.pop(context);
                  _setViewMode('fit');
                },
              ),
              _ViewModeTile(
                icon: Icons.view_stream_outlined,
                title: 'Continuous Scroll',
                subtitle: 'Scroll continuously vertically across all pages.',
                selected: _pageLayoutMode == PdfPageLayoutMode.continuous && _viewMode != 'width',
                onTap: () {
                  Navigator.pop(context);
                  _setViewMode('continuous');
                },
              ),
              _ViewModeTile(
                icon: Icons.aspect_ratio,
                title: 'Fit Width',
                subtitle: 'Expand document width to fill the reading viewport.',
                selected: _pageLayoutMode == PdfPageLayoutMode.continuous && _viewMode == 'width',
                onTap: () {
                  Navigator.pop(context);
                  _setViewMode('width');
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
              ValueListenableBuilder<double>(
                valueListenable: _zoomNotifier,
                builder: (context, currentZoom, _) {
                  return Text(
                    '${(currentZoom * 100).round()}%',
                    style: PremiumTypography.labelLarge.copyWith(color: textColor),
                  );
                },
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
          ValueListenableBuilder<double>(
            valueListenable: _zoomNotifier,
            builder: (context, currentZoom, _) {
              return Slider(
                value: currentZoom.clamp(_minZoom, _maxZoom),
                min: _minZoom,
                max: _maxZoom,
                divisions: 16,
                activeColor: PremiumColors.luxuryRed,
                onChanged: (value) {
                  _setZoom(value);
                  setSheetState(() {});
                },
              );
            },
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Fit Page'),
                selected: _pageLayoutMode == PdfPageLayoutMode.single,
                onSelected: (_) {
                  _setViewMode('fit');
                  setSheetState(() {});
                },
              ),
              ChoiceChip(
                label: const Text('Continuous'),
                selected: _pageLayoutMode == PdfPageLayoutMode.continuous && _viewMode != 'width',
                onSelected: (_) {
                  _setViewMode('continuous');
                  setSheetState(() {});
                },
              ),
              ChoiceChip(
                label: const Text('Fit Width'),
                selected: _pageLayoutMode == PdfPageLayoutMode.continuous && _viewMode == 'width',
                onSelected: (_) {
                  _setViewMode('width');
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
    final bottomInset = MediaQuery.of(context).padding.bottom;
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
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottomInset),
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
                  if (!kIsWeb)
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
      if (kIsWeb || !file.existsSync()) return '0';
      return (file.lengthSync() / (1024 * 1024)).toStringAsFixed(2);
    } catch (_) {
      return '0';
    }
  }

  bool get _hasDocument => _pdfFile != null || _pdfBytes != null;

  String get _viewModeLabel {
    if (_pageLayoutMode == PdfPageLayoutMode.single) {
      return 'Fit page';
    }
    switch (_viewMode) {
      case 'width':
        return 'Fit width';
      case 'continuous':
        return 'Continuous';
      case 'height':
        return 'Fit height';
      default:
        return 'Continuous';
    }
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
        (oldSize.width - size.width).abs() < 20.0 &&
        (oldSize.height - size.height).abs() < 20.0) {
      return;
    }
    _viewerViewportSize = size;
    if (_viewMode != 'custom') {
      _scheduleViewModeRefresh(force: false);
    }
  }

  Widget _buildPdfContent(bool isDark) {
    if (_isLoadingBytes) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_pdfBytes == null && _pdfFile == null) {
      return const Center(child: Text('Unable to load PDF'));
    }

    final surfaceColor = _isNightMode
        ? const Color(0xFF050505)
        : (isDark ? PremiumColors.darkBg : const Color(0xFFEFF1F5));

    final isMobile = MediaQuery.of(context).size.width < 600;

    final Widget viewer;
    if (_pdfBytes != null) {
      viewer = SfPdfViewer.memory(
        _pdfBytes!,
        key: ValueKey(
          'sf_pdf_mem_${_webFileName ?? "doc"}_${_password ?? ''}_$_pageLayoutMode',
        ),
        controller: _pdfViewerController,
        password: _password,
        pageLayoutMode: _pageLayoutMode,
        scrollDirection: _pageLayoutMode == PdfPageLayoutMode.single
            ? PdfScrollDirection.horizontal
            : PdfScrollDirection.vertical,
        initialZoomLevel: 1.0,
        maxZoomLevel: _maxZoom,
        enableDoubleTapZooming: true,
        enableTextSelection: true,
        interactionMode: PdfInteractionMode.pan,
        canShowScrollHead: false,
        canShowScrollStatus: false,
        canShowPaginationDialog: false,
        pageSpacing: isMobile ? 10.0 : 8.0,
        onTap: (_) => setState(() => _showControls = !_showControls),
        onPageChanged: (PdfPageChangedDetails details) {
          if (details.newPageNumber > 0 &&
              details.newPageNumber != _lastPageNumber) {
            _lastPageNumber = details.newPageNumber;
            _pageNumberNotifier.value = details.newPageNumber;
          }
        },
        onHyperlinkClicked: _handleHyperlinkClicked,
        onDocumentLoaded: _handleDocumentLoaded,
        onDocumentLoadFailed: _handleDocumentLoadFailed,
        onZoomLevelChanged: _handlePdfZoomLevelChanged,
        currentSearchTextHighlightColor: Colors.amber,
        otherSearchTextHighlightColor: Colors.yellowAccent,
      );
    } else {
      viewer = SfPdfViewer.file(
        _pdfFile!,
        key: ValueKey(
          'sf_pdf_${_pdfFile!.path}_${_password ?? ''}_$_pageLayoutMode',
        ),
        controller: _pdfViewerController,
        password: _password,
        pageLayoutMode: _pageLayoutMode,
        scrollDirection: _pageLayoutMode == PdfPageLayoutMode.single
            ? PdfScrollDirection.horizontal
            : PdfScrollDirection.vertical,
        initialZoomLevel: 1.0,
        maxZoomLevel: _maxZoom,
        enableDoubleTapZooming: true,
        enableTextSelection: true,
        interactionMode: PdfInteractionMode.pan,
        canShowScrollHead: false,
        canShowScrollStatus: false,
        canShowPaginationDialog: false,
        pageSpacing: isMobile ? 10.0 : 8.0,
        onTap: (_) => setState(() => _showControls = !_showControls),
        onPageChanged: (PdfPageChangedDetails details) {
          if (details.newPageNumber > 0 &&
              details.newPageNumber != _lastPageNumber) {
            _lastPageNumber = details.newPageNumber;
            _pageNumberNotifier.value = details.newPageNumber;
          }
        },
        onHyperlinkClicked: _handleHyperlinkClicked,
        onDocumentLoaded: _handleDocumentLoaded,
        onDocumentLoadFailed: _handleDocumentLoadFailed,
        onZoomLevelChanged: _handlePdfZoomLevelChanged,
        currentSearchTextHighlightColor: Colors.amber,
        otherSearchTextHighlightColor: Colors.yellowAccent,
      );
    }

    return RepaintBoundary(
      child: SfPdfViewerTheme(
        data: SfPdfViewerThemeData(
          backgroundColor: surfaceColor,
        ),
        child: viewer,
      ),
    );
  }

  Widget _buildTransformedAndFilteredPdfContent(bool isDark) {
    Widget content = _buildPdfContent(isDark);

    if (_rotationAngle != 0) {
      content = Transform.rotate(
        angle: (_rotationAngle * math.pi) / 180,
        child: content,
      );
    }

    if (_isNightMode) {
      final b = _brightness;
      content = ColorFiltered(
        colorFilter: ColorFilter.matrix(<double>[
          -0.85 * b, 0, 0, 0, 235 * b,
          0, -0.85 * b, 0, 0, 235 * b,
          0, 0, -0.85 * b, 0, 235 * b,
          0, 0, 0, 1, 0,
        ]),
        child: content,
      );
    } else if ((_brightness - 1.0).abs() >= 0.01) {
      content = ColorFiltered(
        colorFilter: ColorFilter.matrix(<double>[
          _brightness, 0, 0, 0, 0,
          0, _brightness, 0, 0, 0,
          0, 0, _brightness, 0, 0,
          0, 0, 0, 1, 0,
        ]),
        child: content,
      );
    }

    return content;
  }

  Widget _buildViewerWorkspace({
    required bool isDark,
    required String fileName,
    required String fileSize,
  }) {
    final surfaceColor = _isNightMode
        ? const Color(0xFF050505)
        : (isDark ? PremiumColors.darkBg : const Color(0xFFEFF1F5));
    final isMobile = MediaQuery.of(context).size.width < 600;

    return LayoutBuilder(
      builder: (context, constraints) {
        _rememberViewerViewport(
          Size(constraints.maxWidth, constraints.maxHeight),
        );
        return Stack(
          children: [
            Positioned.fill(
              child: Container(
                color: surfaceColor,
                padding: EdgeInsets.only(
                  left: isMobile ? 8.0 : 16.0,
                  right: isMobile ? 8.0 : 16.0,
                  top: isMobile ? (kIsWeb ? 60.0 : 8.0) : 10.0,
                  bottom: _showControls ? (isMobile ? 70.0 : 66.0) : 10.0,
                ),
                child: RepaintBoundary(
                  child: _buildTransformedAndFilteredPdfContent(isDark),
                ),
              ),
            ),
            if (_isPasswordProtected && !_isDocumentLoaded)
              _buildPasswordUnlockCard(isDark)
            else if (_viewerError != null)
              _buildViewerErrorOverlay(),
            if (isMobile)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                top: _showControls ? 8.0 : -100,
                left: 8.0,
                right: 8.0,
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _showControls ? 1.0 : 0.0,
                  child: RepaintBoundary(
                    child: _buildViewerStatusBar(
                      isDark: isDark,
                      fileName: fileName,
                      fileSize: fileSize,
                      isMobile: true,
                    ),
                  ),
                ),
              ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              bottom: _showControls ? 0 : -120,
              left: 0,
              right: 0,
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 200),
                opacity: _showControls ? 1.0 : 0.0,
                child: RepaintBoundary(
                  child: _buildReaderControls(isDark),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildViewerStatusBar({
    required bool isDark,
    required String fileName,
    required String fileSize,
    bool isMobile = false,
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
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 10 : 12,
          vertical: isMobile ? 8 : 12,
        ),
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
              width: isMobile ? 32 : 38,
              height: isMobile ? 32 : 38,
              decoration: BoxDecoration(
                color: PremiumColors.luxuryRed.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(isMobile ? 10 : 12),
              ),
              child: Icon(
                Icons.picture_as_pdf,
                color: PremiumColors.luxuryRed,
                size: isMobile ? 18 : 22,
              ),
            ),
            SizedBox(width: isMobile ? 8 : 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    fileName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: (isMobile
                            ? PremiumTypography.labelMedium
                            : PremiumTypography.labelLarge)
                        .copyWith(
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
                      fontSize: isMobile ? 11 : null,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            ValueListenableBuilder<int>(
              valueListenable: _pageNumberNotifier,
              builder: (context, page, _) {
                final pageCount = _pageCountNotifier.value;
                final label = pageCount > 0 ? '$page / $pageCount' : 'Loading';
                return _ReaderStatusChip(
                  icon: Icons.description_outlined,
                  label: label,
                  isDark: isDark || _isNightMode,
                  isCompact: isMobile,
                );
              },
            ),
            if (!isMobile) ...[
              const SizedBox(width: 6),
              ValueListenableBuilder<double>(
                valueListenable: _zoomNotifier,
                builder: (context, zoom, _) {
                  return _ReaderStatusChip(
                    icon: Icons.zoom_in,
                    label: '${(zoom * 100).round()}%',
                    isDark: isDark || _isNightMode,
                  );
                },
              ),
            ],
            if (_searchResult.hasResult) ...[
              const SizedBox(width: 6),
              _ReaderStatusChip(
                icon: Icons.search,
                label: 'Search',
                isDark: isDark || _isNightMode,
                isCompact: isMobile,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildReaderControls(bool isDark) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    return GestureDetector(
      onTap: () {},
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isMobile ? 10 : 12,
          0,
          isMobile ? 10 : 12,
          (isMobile ? 10 : 12) + MediaQuery.of(context).padding.bottom,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: _buildReaderToolbar(isDark, isMobile: isMobile),
          ),
        ),
      ),
    );
  }

  Widget _buildReaderToolbar(bool isDark, {bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 6 : 8,
        vertical: isMobile ? 6 : 8,
      ),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ValueListenableBuilder<int>(
              valueListenable: _pageCountNotifier,
              builder: (context, pageCount, _) {
                if (pageCount <= 1) return const SizedBox.shrink();
                return ValueListenableBuilder<int>(
                  valueListenable: _pageNumberNotifier,
                  builder: (context, currentPage, _) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _ReaderToolButton(
                          icon: Icons.chevron_left_rounded,
                          label: 'Prev',
                          onPressed: currentPage > 1
                              ? () {
                                  if (kIsWeb) {
                                    _pdfViewerController.jumpToPage(currentPage - 1);
                                  } else {
                                    _pdfViewerController.previousPage();
                                  }
                                }
                              : null,
                          isMobile: isMobile,
                        ),
                        GestureDetector(
                          onTap: _jumpToPage,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '$currentPage / $pageCount',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                        _ReaderToolButton(
                          icon: Icons.chevron_right_rounded,
                          label: 'Next',
                          onPressed: currentPage < pageCount
                              ? () {
                                  if (kIsWeb) {
                                    _pdfViewerController.jumpToPage(currentPage + 1);
                                  } else {
                                    _pdfViewerController.nextPage();
                                  }
                                }
                              : null,
                          isMobile: isMobile,
                        ),
                        _ToolbarDivider(isMobile: isMobile),
                      ],
                    );
                  },
                );
              },
            ),
            _ReaderToolButton(
              icon: Icons.zoom_out,
              label: 'Out',
              onPressed: _zoomOut,
              isMobile: isMobile,
            ),
            ValueListenableBuilder<double>(
              valueListenable: _zoomNotifier,
              builder: (context, zoom, _) {
                return _ZoomReadout(
                  label: '${(zoom * 100).round()}%',
                  onTap: _showCustomZoomDialog,
                  isMobile: isMobile,
                );
              },
            ),
            _ReaderToolButton(
              icon: Icons.zoom_in,
              label: 'In',
              onPressed: _zoomIn,
              isMobile: isMobile,
            ),
            _ToolbarDivider(isMobile: isMobile),
            _ReaderToolButton(
              icon: Icons.fit_screen,
              label: _viewModeLabel,
              onPressed: _showViewModeMenu,
              isMobile: isMobile,
            ),
            _ReaderToolButton(
              icon: Icons.tune,
              label: 'Advanced',
              onPressed: _showAdvancedTools,
              isMobile: isMobile,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showPasswordPromptDialog() async {
    final controller = TextEditingController(text: _password ?? '');
    bool obscure = true;
    final entered = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: PremiumColors.brandRed.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.lock_rounded,
                  color: PremiumColors.brandRed,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Password Protected',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter the password to decrypt this PDF document:',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                obscureText: obscure,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter password',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setDialogState(() => obscure = !obscure),
                  ),
                ),
                onSubmitted: (val) => Navigator.pop(ctx, val),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: PremiumColors.brandRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Unlock'),
            ),
          ],
        ),
      ),
    );
    if (entered != null && entered.isNotEmpty) {
      setState(() {
        _password = entered;
        _viewerError = null;
      });
    }
  }

  Widget _buildPasswordUnlockCard(bool isDark) {
    return Positioned.fill(
      child: Container(
        color: isDark ? const Color(0xFF141518) : const Color(0xFFF7F8FA),
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              decoration: BoxDecoration(
                color: isDark
                    ? PremiumColors.darkSurfacePrimary
                    : PremiumColors.lightSurfacePrimary,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark
                      ? PremiumColors.darkDivider
                      : PremiumColors.lightDivider,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      color: PremiumColors.brandRed.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_outline_rounded,
                      color: PremiumColors.brandRed,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Password Protected PDF',
                    textAlign: TextAlign.center,
                    style: PremiumTypography.headlineSmall.copyWith(
                      color: isDark
                          ? PremiumColors.darkText
                          : PremiumColors.lightText,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'This document is encrypted. Enter the password to unlock and read.',
                    textAlign: TextAlign.center,
                    style: PremiumTypography.bodyMedium.copyWith(
                      color: isDark
                          ? PremiumColors.darkTextSecondary
                          : PremiumColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickPdf,
                        icon: const Icon(Icons.folder_open, size: 18),
                        label: const Text('Open Another'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: _showPasswordPromptDialog,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PremiumColors.brandRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        icon: const Icon(Icons.key, size: 18),
                        label: const Text('Enter Password'),
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
    final isMobile = MediaQuery.of(context).size.width < 600;
    final textColor = isDark ? PremiumColors.darkText : PremiumColors.lightText;
    final mutedColor = isDark
        ? PremiumColors.darkTextSecondary
        : PremiumColors.lightTextSecondary;
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 16 : 24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Container(
              padding: EdgeInsets.all(isMobile ? 18 : 22),
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
      body: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent) {
            if (event.logicalKey == LogicalKeyboardKey.arrowLeft ||
                event.logicalKey == LogicalKeyboardKey.pageUp) {
              if (_pageNumberNotifier.value > 1) {
                if (kIsWeb) {
                  _pdfViewerController.jumpToPage(_pageNumberNotifier.value - 1);
                } else {
                  _pdfViewerController.previousPage();
                }
                return KeyEventResult.handled;
              }
            } else if (event.logicalKey == LogicalKeyboardKey.arrowRight ||
                event.logicalKey == LogicalKeyboardKey.pageDown) {
              if (_pageNumberNotifier.value < _pageCountNotifier.value) {
                if (kIsWeb) {
                  _pdfViewerController.jumpToPage(_pageNumberNotifier.value + 1);
                } else {
                  _pdfViewerController.nextPage();
                }
                return KeyEventResult.handled;
              }
            } else if (event.logicalKey == LogicalKeyboardKey.equal ||
                event.logicalKey == LogicalKeyboardKey.numpadAdd) {
              _zoomIn();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.minus ||
                event.logicalKey == LogicalKeyboardKey.numpadSubtract) {
              _zoomOut();
              return KeyEventResult.handled;
            } else if (event.logicalKey == LogicalKeyboardKey.digit0 ||
                event.logicalKey == LogicalKeyboardKey.numpad0) {
              _resetZoom();
              return KeyEventResult.handled;
            }
          }
          return KeyEventResult.ignored;
        },
        child: _hasDocument
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
      ),
    );
  }
}

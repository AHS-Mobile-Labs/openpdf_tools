import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../config/premium_theme.dart';
import '../services/file_history_service.dart';
import '../screens/pdf_viewer_screen.dart';
import '../screens/edit_pdf_screen.dart';
import '../screens/merge_pdf_screen.dart';
import '../screens/split_pdf_screen.dart';
import '../screens/compress_pdf_screen.dart';
import '../screens/convert_to_pdf_screen.dart';
import '../screens/convert_from_pdf_screen.dart';
import '../screens/pdf_from_images_screen.dart';
import '../screens/sign_pdf_screen_refactored.dart';
import '../screens/repair_pdf_screen.dart';
import '../screens/history_screen.dart';

enum ToolCategory {
  all('All Tools', Icons.grid_view_rounded, Color(0xFFE1251B)),
  viewAnnotate('View & Annotate', Icons.menu_book_rounded, Color(0xFFE1251B)),
  combineOrganize('Combine & Organize', Icons.layers_rounded, Color(0xFF1473E6)),
  convertExport('Convert & Export', Icons.swap_horiz_rounded, Color(0xFF00796B)),
  optimizeFix('Optimize & Protect', Icons.tune_rounded, Color(0xFFE58300));

  final String label;
  final IconData icon;
  final Color color;
  const ToolCategory(this.label, this.icon, this.color);
}

class ToolItem {
  final String id;
  final String title;
  final String shortTitle;
  final ToolCategory category;
  final String description;
  final IconData icon;
  final Color accentColor;
  final String? badge;
  final Widget Function() screenBuilder;

  const ToolItem({
    required this.id,
    required this.title,
    required this.shortTitle,
    required this.category,
    required this.description,
    required this.icon,
    required this.accentColor,
    this.badge,
    required this.screenBuilder,
  });

  static List<ToolItem> get allTools => [
    ToolItem(
      id: 'viewer',
      title: 'View PDF',
      shortTitle: 'View',
      category: ToolCategory.viewAnnotate,
      description: 'High-performance offline reader with search, zoom & bookmarks',
      icon: Icons.picture_as_pdf_rounded,
      accentColor: const Color(0xFFE1251B),
      badge: 'Core',
      screenBuilder: () => const PdfViewerScreen(),
    ),
    ToolItem(
      id: 'edit',
      title: 'Edit PDF',
      shortTitle: 'Edit',
      category: ToolCategory.viewAnnotate,
      description: 'Add text annotations, watermarks, stamps & rotate pages',
      icon: Icons.edit_note_rounded,
      accentColor: const Color(0xFFE1251B),
      badge: 'Popular',
      screenBuilder: () => const EditPdfScreen(),
    ),
    ToolItem(
      id: 'sign',
      title: 'Fill & Sign',
      shortTitle: 'Sign',
      category: ToolCategory.viewAnnotate,
      description: 'Add visual signatures and cryptographic PKCS#7 digital certificates',
      icon: Icons.draw_rounded,
      accentColor: const Color(0xFF7E57C2),
      badge: 'PKCS#7',
      screenBuilder: () => const SignPdfScreenRefactored(),
    ),
    ToolItem(
      id: 'merge',
      title: 'Merge PDFs',
      shortTitle: 'Merge',
      category: ToolCategory.combineOrganize,
      description: 'Combine multiple PDF documents in any custom sequence',
      icon: Icons.call_merge_rounded,
      accentColor: const Color(0xFF1473E6),
      badge: 'Popular',
      screenBuilder: () => const MergePdfScreen(),
    ),
    ToolItem(
      id: 'split',
      title: 'Split PDF',
      shortTitle: 'Split',
      category: ToolCategory.combineOrganize,
      description: 'Extract individual pages or split into custom page ranges',
      icon: Icons.content_cut_rounded,
      accentColor: const Color(0xFF028575),
      screenBuilder: () => const SplitPdfScreen(),
    ),
    ToolItem(
      id: 'compress',
      title: 'Compress PDF',
      shortTitle: 'Compress',
      category: ToolCategory.optimizeFix,
      description: 'Shrink PDF file size with customizable quality levels',
      icon: Icons.compress_rounded,
      accentColor: const Color(0xFFE58300),
      badge: 'Fast',
      screenBuilder: () => const CompressPdfScreen(),
    ),
    ToolItem(
      id: 'repair',
      title: 'Repair PDF',
      shortTitle: 'Repair',
      category: ToolCategory.optimizeFix,
      description: 'Fix corrupt xref tables and salvage unreadable PDF files',
      icon: Icons.healing_rounded,
      accentColor: const Color(0xFFD32F2F),
      screenBuilder: () => const RepairPdfScreen(),
    ),
    ToolItem(
      id: 'convert_to',
      title: 'Convert to PDF',
      shortTitle: 'To PDF',
      category: ToolCategory.convertExport,
      description: 'Convert DOCX, images, text, and html documents to PDF',
      icon: Icons.file_upload_outlined,
      accentColor: const Color(0xFF00796B),
      screenBuilder: () => const ConvertToPdfScreen(),
    ),
    ToolItem(
      id: 'convert_from',
      title: 'Export from PDF',
      shortTitle: 'Export',
      category: ToolCategory.convertExport,
      description: 'Extract pages to PNG, JPEG, SVG, TXT and other formats',
      icon: Icons.transform_rounded,
      accentColor: const Color(0xFF1473E6),
      screenBuilder: () => const ConvertFromPdfScreen(),
    ),
    ToolItem(
      id: 'images_to_pdf',
      title: 'PDF from Images',
      shortTitle: 'From Images',
      category: ToolCategory.convertExport,
      description: 'Assemble photo galleries and scans into multi-page PDFs',
      icon: Icons.photo_library_rounded,
      accentColor: const Color(0xFFE65100),
      screenBuilder: () => const PdfFromImagesScreen(),
    ),
    ToolItem(
      id: 'history',
      title: 'History & Favorites',
      shortTitle: 'Recent',
      category: ToolCategory.all,
      description: 'Quickly access recent documents, bookmarks, and favorite files',
      icon: Icons.history_rounded,
      accentColor: const Color(0xFF6B5B95),
      screenBuilder: () => const HistoryScreen(),
    ),
  ];

  static List<ToolItem> get spotlightTools => [
    allTools.firstWhere((t) => t.id == 'viewer'),
    allTools.firstWhere((t) => t.id == 'edit'),
    allTools.firstWhere((t) => t.id == 'merge'),
    allTools.firstWhere((t) => t.id == 'compress'),
    allTools.firstWhere((t) => t.id == 'sign'),
    allTools.firstWhere((t) => t.id == 'convert_from'),
  ];
}

class AppBrandLogo extends StatelessWidget {
  final double size;
  final bool showText;
  final bool isDark;

  const AppBrandLogo({
    super.key,
    this.size = 32,
    this.showText = true,
    this.isDark = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: PremiumColors.brandRed,
            borderRadius: BorderRadius.circular(size * 0.25),
            boxShadow: [
              BoxShadow(
                color: PremiumColors.brandRed.withValues(alpha: 0.35),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: EdgeInsets.all(size * 0.15),
          child: Image.asset(
            'asset/app_img/OpenPDF Tools.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const Icon(
              Icons.picture_as_pdf_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
        ),
        if (showText) ...[
          const SizedBox(width: 10),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'OpenPDF',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                ),
              ),
              Text(
                ' Tools',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  letterSpacing: -0.2,
                  color: PremiumColors.brandRed,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class HeroDropZone extends StatefulWidget {
  final VoidCallback onFileSelected;
  final bool isCompact;

  const HeroDropZone({
    super.key,
    required this.onFileSelected,
    this.isCompact = false,
  });

  @override
  State<HeroDropZone> createState() => _HeroDropZoneState();
}

class _HeroDropZoneState extends State<HeroDropZone> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: widget.isCompact ? 16 : 28,
          vertical: widget.isCompact ? 18 : 26,
        ),
        decoration: BoxDecoration(
          color: isDark
              ? (_isHovered
                  ? const Color(0xFF24272D)
                  : PremiumColors.darkSurfacePrimary)
              : (_isHovered
                  ? const Color(0xFFF0F3F7)
                  : PremiumColors.lightSurfacePrimary),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHovered
                ? PremiumColors.brandRed
                : (isDark
                    ? PremiumColors.darkDivider
                    : PremiumColors.lightDivider),
            width: _isHovered ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: isDark
                    ? (_isHovered ? 0.35 : 0.20)
                    : (_isHovered ? 0.08 : 0.03),
              ),
              blurRadius: _isHovered ? 14 : 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Container(
                  width: widget.isCompact ? 44 : 52,
                  height: widget.isCompact ? 44 : 52,
                  decoration: BoxDecoration(
                    color: PremiumColors.brandRed.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.upload_file_rounded,
                      size: 28,
                      color: PremiumColors.brandRed,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Open a PDF Document',
                        style: TextStyle(
                          fontSize: widget.isCompact ? 15 : 17,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                          color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Select a PDF to view, edit, sign, or compress immediately',
                        style: TextStyle(
                          fontSize: 12.5,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: widget.onFileSelected,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PremiumColors.brandRed,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.symmetric(
                      horizontal: widget.isCompact ? 14 : 20,
                      vertical: widget.isCompact ? 10 : 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.folder_open_rounded, size: 18),
                  label: const Text(
                    'Select PDF',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _buildBadge(
                  icon: Icons.lock_outline_rounded,
                  label: '100% Offline & Private',
                  isDark: isDark,
                ),
                _buildBadge(
                  icon: Icons.bolt_rounded,
                  label: 'Zero Cloud Upload',
                  isDark: isDark,
                ),
                if (!widget.isCompact)
                  _buildBadge(
                    icon: Icons.shield_outlined,
                    label: 'Client-Side Security',
                    isDark: isDark,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge({
    required IconData icon,
    required String label,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class ToolCard extends StatefulWidget {
  final ToolItem tool;
  final VoidCallback onTap;
  final bool isCompact;

  const ToolCard({
    super.key,
    required this.tool,
    required this.onTap,
    this.isCompact = false,
  });

  @override
  State<ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<ToolCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: isDark
                  ? (_isHovered
                      ? const Color(0xFF26282E)
                      : PremiumColors.darkSurfacePrimary)
                  : (_isHovered
                      ? const Color(0xFFF1F3F6)
                      : PremiumColors.lightSurfacePrimary),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _isHovered
                    ? widget.tool.accentColor.withValues(alpha: 0.7)
                    : (isDark
                        ? PremiumColors.darkDivider
                        : PremiumColors.lightDivider),
                width: _isHovered ? 1.4 : 1.0,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: isDark
                        ? (_isHovered ? 0.30 : 0.12)
                        : (_isHovered ? 0.08 : 0.03),
                  ),
                  blurRadius: _isHovered ? 10 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: widget.tool.accentColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(
                        widget.tool.icon,
                        size: 19,
                        color: widget.tool.accentColor,
                      ),
                    ),
                    const Spacer(),
                    if (widget.tool.badge != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: widget.tool.accentColor.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.tool.badge!,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: widget.tool.accentColor,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.tool.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                            color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.tool.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.5,
                            height: 1.25,
                            color: isDark
                                ? Colors.grey.shade400
                                : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      'Launch',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: _isHovered
                            ? widget.tool.accentColor
                            : (isDark
                                ? Colors.grey.shade500
                                : Colors.grey.shade600),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 12,
                      color: _isHovered
                          ? widget.tool.accentColor
                          : (isDark
                              ? Colors.grey.shade500
                              : Colors.grey.shade600),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RecentFilesSection extends StatefulWidget {
  final Function(String path) onOpenFile;
  final VoidCallback onViewAll;

  const RecentFilesSection({
    super.key,
    required this.onOpenFile,
    required this.onViewAll,
  });

  @override
  State<RecentFilesSection> createState() => _RecentFilesSectionState();
}

class _RecentFilesSectionState extends State<RecentFilesSection> {
  late Future<List<HistoryItem>> _historyFuture;
  Set<String> _favorites = {};

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    setState(() {
      _historyFuture = FileHistoryService.getHistory();
    });
    FileHistoryService.getFavorites().then((favs) {
      if (mounted) {
        setState(() {
          _favorites = Set.from(favs);
        });
      }
    });
  }

  void _toggleFavorite(String path) async {
    final isFav = await FileHistoryService.toggleFavorite(path);
    if (mounted) {
      setState(() {
        if (isFav) {
          _favorites.add(path);
        } else {
          _favorites.remove(path);
        }
      });
    }
  }

  void _removeItem(String path) async {
    await FileHistoryService.removeFromHistory(path);
    _loadHistory();
  }

  String _formatItemSize(String filePath) {
    try {
      final file = File(filePath);
      if (!kIsWeb && file.existsSync()) {
        final sizeInBytes = file.lengthSync();
        if (sizeInBytes < 1024) return '$sizeInBytes B';
        if (sizeInBytes < 1024 * 1024) {
          return '${(sizeInBytes / 1024).toStringAsFixed(1)} KB';
        }
        return '${(sizeInBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (_) {}
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return FutureBuilder<List<HistoryItem>>(
      future: _historyFuture,
      builder: (context, snapshot) {
        final items = snapshot.data ?? [];
        final displayItems = items.take(4).toList();

        return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark
                ? PremiumColors.darkSurfacePrimary
                : PremiumColors.lightSurfacePrimary,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? PremiumColors.darkDivider
                  : PremiumColors.lightDivider,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule_rounded,
                      size: 18,
                      color: PremiumColors.brandRed,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Recent Documents',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: widget.onViewAll,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: const Size(0, 32),
                      ),
                      child: Row(
                        children: [
                          Text(
                            'View All',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: PremiumColors.brandRed,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 16,
                            color: PremiumColors.brandRed,
                          ),
                        ],
                      ),
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
              if (displayItems.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(
                          Icons.folder_open_outlined,
                          size: 36,
                          color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'No recent documents',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Open any PDF to view it here for rapid access',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: displayItems.length,
                  separatorBuilder: (context, index) => Divider(
                    height: 1,
                    indent: 48,
                    color: isDark
                        ? PremiumColors.darkDivider.withValues(alpha: 0.6)
                        : PremiumColors.lightDivider.withValues(alpha: 0.6),
                  ),
                  itemBuilder: (context, index) {
                    final item = displayItems[index];
                    final isFav = _favorites.contains(item.filePath);
                    final dateFormatted = item.timestamp > 0
                        ? DateFormat('MMM d, yyyy \u2022 h:mm a').format(
                            DateTime.fromMillisecondsSinceEpoch(item.timestamp),
                          )
                        : '';
                    final sizeStr = _formatItemSize(item.filePath);

                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => widget.onOpenFile(item.filePath),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: PremiumColors.brandRed.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.picture_as_pdf_rounded,
                                  size: 18,
                                  color: PremiumColors.brandRed,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.fileName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isDark
                                            ? Colors.white
                                            : const Color(0xFF1E1E1E),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      sizeStr.isNotEmpty
                                          ? '$sizeStr \u2022 $dateFormatted'
                                          : dateFormatted,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark
                                            ? Colors.grey.shade400
                                            : Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  isFav
                                      ? Icons.star_rounded
                                      : Icons.star_outline_rounded,
                                  size: 20,
                                  color: isFav
                                      ? PremiumColors.luxuryGold
                                      : (isDark
                                          ? Colors.grey.shade500
                                          : Colors.grey.shade400),
                                ),
                                tooltip: isFav
                                    ? 'Remove from Favorites'
                                    : 'Add to Favorites',
                                onPressed: () => _toggleFavorite(item.filePath),
                              ),
                              IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  size: 16,
                                  color: isDark
                                      ? Colors.grey.shade500
                                      : Colors.grey.shade400,
                                ),
                                tooltip: 'Remove from Recent',
                                onPressed: () => _removeItem(item.filePath),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class ToolSearchDialog extends StatefulWidget {
  final Function(ToolItem tool) onSelectTool;

  const ToolSearchDialog({
    super.key,
    required this.onSelectTool,
  });

  @override
  State<ToolSearchDialog> createState() => _ToolSearchDialogState();
}

class _ToolSearchDialogState extends State<ToolSearchDialog> {
  final TextEditingController _searchController = TextEditingController();
  List<ToolItem> _filteredTools = ToolItem.allTools;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredTools = ToolItem.allTools;
      } else {
        _filteredTools = ToolItem.allTools.where((t) {
          return t.title.toLowerCase().contains(query) ||
              t.description.toLowerCase().contains(query) ||
              t.category.label.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: isDark
          ? PremiumColors.darkSurfacePrimary
          : PremiumColors.lightSurfacePrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 24,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560, maxHeight: 520),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    color: PremiumColors.brandRed,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      autofocus: true,
                      style: TextStyle(
                        fontSize: 15,
                        color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Search tools (e.g. Merge, Compress, Sign)...',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        filled: false,
                      ),
                    ),
                  ),
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 18),
                      onPressed: () => _searchController.clear(),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'ESC',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
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
            Expanded(
              child: _filteredTools.isEmpty
                  ? Center(
                      child: Text(
                        'No tools found for "${_searchController.text}"',
                        style: TextStyle(
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredTools.length,
                      itemBuilder: (context, index) {
                        final tool = _filteredTools[index];
                        return ListTile(
                          leading: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: tool.accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              tool.icon,
                              size: 20,
                              color: tool.accentColor,
                            ),
                          ),
                          title: Text(
                            tool.title,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1E1E1E),
                            ),
                          ),
                          subtitle: Text(
                            tool.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: isDark
                                  ? Colors.grey.shade400
                                  : Colors.grey.shade600,
                            ),
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withValues(alpha: 0.06)
                                  : Colors.black.withValues(alpha: 0.04),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              tool.category.label,
                              style: TextStyle(
                                fontSize: 10,
                                color: isDark
                                    ? Colors.grey.shade400
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            widget.onSelectTool(tool);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../config/premium_theme.dart';
import '../services/file_history_service.dart';
import '../utils/platform_file_handler.dart';
import '../utils/platform_helper.dart';
import '../widgets/workspace_components.dart';
import 'pdf_viewer_screen.dart';

class DashboardHomeScreen extends StatefulWidget {
  final Function(ToolItem tool)? onSelectTool;
  final Function(String path)? onOpenPdfPath;

  const DashboardHomeScreen({
    super.key,
    this.onSelectTool,
    this.onOpenPdfPath,
  });

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  Future<void> _launchGitHub() async {
    try {
      final uri = Uri.parse(AppConfig.githubUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open GitHub: $e')),
        );
      }
    }
  }

  Future<void> _handlePickPdf() async {
    try {
      final file = await PlatformFileHandler.pickFile(
        dialogTitle: 'Select PDF Document',
      );
      if (!mounted) return;
      if (file != null) {
        await FileHistoryService.addToHistory(file.path);
        _openPdfFile(file.path);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error opening file: $e')),
        );
      }
    }
  }

  void _openPdfFile(String path) {
    if (widget.onOpenPdfPath != null) {
      widget.onOpenPdfPath!(path);
    } else {
      final file = File(path);
      if (kIsWeb || file.existsSync()) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PdfViewerScreen(externalFile: file),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File does not exist')),
        );
      }
    }
  }

  void _navigateToTool(ToolItem tool) {
    if (widget.onSelectTool != null) {
      widget.onSelectTool!(tool);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => tool.screenBuilder()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 768;

    return Scaffold(
      backgroundColor: isDark
          ? PremiumColors.darkBg
          : PremiumColors.lightBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 28,
            vertical: isMobile ? 16 : 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeBanner(isDark, isMobile),
              const SizedBox(height: 20),
              HeroDropZone(
                onFileSelected: _handlePickPdf,
                isCompact: isMobile,
              ),
              const SizedBox(height: 28),
              _buildSpotlightSection(isDark, isMobile),
              const SizedBox(height: 28),
              _buildCategorizedToolsSection(isDark, isMobile),
              const SizedBox(height: 28),
              RecentFilesSection(
                onOpenFile: _openPdfFile,
                onViewAll: () {
                  final historyTool = ToolItem.allTools.firstWhere(
                    (t) => t.id == 'history',
                  );
                  _navigateToTool(historyTool);
                },
              ),
              const SizedBox(height: 24),
              _buildSecurityBanner(isDark),
              const SizedBox(height: 24),
              _buildFooter(isDark),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(bool isDark, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppBrandLogo(
              size: isMobile ? 28 : 34,
              showText: false,
              isDark: isDark,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'Welcome to OpenPDF Tools',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: isMobile ? 18 : 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: PremiumColors.brandRed.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: PremiumColors.brandRed.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          'v${AppConfig.appVersion}',
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: PremiumColors.brandRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'All-in-one PDF workspace \u2022 100% offline & client-side \u2022 Enterprise security',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isMobile ? 11.5 : 13,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSpotlightSection(bool isDark, bool isMobile) {
    final spotlight = ToolItem.spotlightTools;
    final width = MediaQuery.of(context).size.width;

    int cols = 2;
    double ratio = 1.15;
    if (width >= 1200) {
      cols = 6;
      ratio = 1.05;
    } else if (width >= 850) {
      cols = 3;
      ratio = 1.25;
    } else if (width >= 600) {
      cols = 2;
      ratio = 1.45;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3.5,
              height: 16,
              decoration: BoxDecoration(
                color: PremiumColors.brandRed,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Spotlight Workflows',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: isDark ? Colors.white : const Color(0xFF1E1E1E),
              ),
            ),
            const Spacer(),
            Text(
              'Frequently used',
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: spotlight.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: ratio,
          ),
          itemBuilder: (context, index) {
            final tool = spotlight[index];
            return ToolCard(
              tool: tool,
              onTap: () => _navigateToTool(tool),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategorizedToolsSection(bool isDark, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3.5,
              height: 16,
              decoration: BoxDecoration(
                color: PremiumColors.brandRed,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'PDF Tools Directory',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
                color: isDark ? Colors.white : const Color(0xFF1E1E1E),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildCategoryGroup(
          category: ToolCategory.viewAnnotate,
          isDark: isDark,
          isMobile: isMobile,
        ),
        const SizedBox(height: 16),
        _buildCategoryGroup(
          category: ToolCategory.combineOrganize,
          isDark: isDark,
          isMobile: isMobile,
        ),
        const SizedBox(height: 16),
        _buildCategoryGroup(
          category: ToolCategory.convertExport,
          isDark: isDark,
          isMobile: isMobile,
        ),
        const SizedBox(height: 16),
        _buildCategoryGroup(
          category: ToolCategory.optimizeFix,
          isDark: isDark,
          isMobile: isMobile,
        ),
      ],
    );
  }

  Widget _buildCategoryGroup({
    required ToolCategory category,
    required bool isDark,
    required bool isMobile,
  }) {
    final tools = ToolItem.allTools.where((t) => t.category == category).toList();
    final width = MediaQuery.of(context).size.width;

    int cols = 1;
    double ratio = 3.2;
    if (width >= 1200) {
      cols = tools.length > 2 ? 3 : 2;
      ratio = 2.6;
    } else if (width >= 700) {
      cols = 2;
      ratio = 2.8;
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? PremiumColors.darkSurfacePrimary.withValues(alpha: 0.6)
            : PremiumColors.lightSurfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? PremiumColors.darkDivider
              : PremiumColors.lightDivider,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(category.icon, size: 17, color: category.color),
              const SizedBox(width: 8),
              Text(
                category.label,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: category.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${tools.length}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: category.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tools.length,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: cols,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: ratio,
            ),
            itemBuilder: (context, index) {
              final tool = tools[index];
              return _buildHorizontalToolTile(tool, isDark);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalToolTile(ToolItem tool, bool isDark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToTool(tool),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? PremiumColors.darkSurfaceSecondary
                : PremiumColors.lightSurfaceSecondary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark
                  ? PremiumColors.darkDivider
                  : PremiumColors.lightDivider,
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: tool.accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(tool.icon, size: 20, color: tool.accentColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            tool.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                            ),
                          ),
                        ),
                        if (tool.badge != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(
                              color: tool.accentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(3),
                            ),
                            child: Text(
                              tool.badge!,
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: tool.accentColor,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tool.description,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 13,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSecurityBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PremiumColors.brandRed.withValues(alpha: isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: PremiumColors.brandRed.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: PremiumColors.brandRed.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.verified_user_rounded,
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
                  '100% Client-Side Privacy Guarantee',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your PDF documents never leave this device. All reading, editing, cryptographic signing, compression, and format conversion occur locally.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              'OpenPDF Tools v${AppConfig.appVersion}  \u2022  ${PlatformHelper.platformName}',
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
        GestureDetector(
          onTap: _launchGitHub,
          child: Row(
            children: [
              Icon(
                FontAwesomeIcons.github,
                size: 15,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              const SizedBox(width: 6),
              Text(
                'GitHub',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

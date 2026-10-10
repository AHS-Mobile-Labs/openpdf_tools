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
import 'compress_pdf_screen.dart';
import 'convert_to_pdf_screen.dart';
import 'convert_from_pdf_screen.dart';
import 'edit_pdf_screen.dart';
import 'pdf_from_images_screen.dart';
import 'merge_pdf_screen.dart';
import 'split_pdf_screen.dart';
import 'sign_pdf_screen_refactored.dart';
import 'repair_pdf_screen.dart';

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
      final picked = await PlatformFileHandler.pickPlatformFile(
        dialogTitle: 'Select PDF Document',
      );
      if (!mounted || picked == null) return;
      if (kIsWeb) {
        if (picked.bytes != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PdfViewerScreen(
                externalBytes: picked.bytes,
                externalFileName: picked.name,
              ),
            ),
          );
        }
        return;
      }
      if (picked.ioFile != null) {
        await FileHistoryService.addToHistory(picked.ioFile!.path);
        _openPdfFile(picked.ioFile!.path);
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

    // Classic Mobile UI/UX for Android & iOS
    if (PlatformHelper.isMobile) {
      return _buildClassicMobileDashboard(context, isDark);
    }

    // Modern Workspace UI/UX for Windows, macOS, Linux, and Web
    return _buildDesktopWorkspaceDashboard(context, isDark);
  }

  // ===========================================================================
  // CLASSIC MOBILE UI/UX (FOR ANDROID & IOS)
  // ===========================================================================

  Widget _buildClassicMobileDashboard(BuildContext context, bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : const Color(0xFFFAFAFA),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _buildClassicHeader(isDark),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildClassicQuickActions(context, isDark),
                    const SizedBox(height: 20),
                    _buildClassicFeatures(context, isDark),
                    const SizedBox(height: 20),
                    _buildClassicTips(isDark),
                    const SizedBox(height: 20),
                    _buildClassicFooter(isDark),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassicHeader(bool isDark) {
    return Container(
      width: double.infinity,
      height: 150.0,
      clipBehavior: Clip.hardEdge,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFB71C1C), Color(0xFFC6302C), Color(0xFFD84315)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -30,
            right: -20,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -40,
            right: 60,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            top: 10,
            left: -30,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                      width: 2,
                    ),
                  ),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                    padding: const EdgeInsets.all(6),
                    child: Image.asset(
                      'asset/app_img/OpenPDF Tools.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  AppConfig.appTitle,
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Fast \u2022 Secure \u2022 Offline',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.75),
                        letterSpacing: 0.4,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'v${AppConfig.appVersion}',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassicQuickActions(BuildContext context, bool isDark) {
    return Row(
      children: [
        _buildQA(
          context,
          'View PDF',
          Icons.picture_as_pdf,
          const PdfViewerScreen(),
          Colors.blue,
          isDark,
        ),
        const SizedBox(width: 8),
        _buildQA(
          context,
          'Edit',
          Icons.edit,
          const EditPdfScreen(),
          Colors.purple,
          isDark,
        ),
        const SizedBox(width: 8),
        _buildQA(
          context,
          'Compress',
          Icons.compress,
          const CompressPdfScreen(),
          Colors.orange,
          isDark,
        ),
        const SizedBox(width: 8),
        _buildQA(
          context,
          'Convert',
          Icons.transform,
          const ConvertFromPdfScreen(),
          Colors.green,
          isDark,
        ),
      ],
    );
  }

  Widget _buildQA(
    BuildContext context,
    String label,
    IconData icon,
    Widget screen,
    Color color,
    bool isDark,
  ) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => screen),
          ),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
              border: Border.all(
                color: isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade200,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.12),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(height: 6),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClassicFeatures(BuildContext context, bool isDark) {
    final features = [
      _ClassicFeatureItem(
        title: 'Merge PDF',
        description: 'Combine PDFs in order',
        icon: Icons.merge,
        color: const Color(0xFF1565C0),
        screen: const MergePdfScreen(),
      ),
      _ClassicFeatureItem(
        title: 'Split PDF',
        description: 'Separate pages into PDFs',
        icon: Icons.cut,
        color: const Color(0xFF7E57C2),
        screen: const SplitPdfScreen(),
      ),
      _ClassicFeatureItem(
        title: 'Convert to PDF',
        description: 'From images, docs, and more',
        icon: Icons.file_present,
        color: const Color(0xFF00796B),
        screen: const ConvertToPdfScreen(),
      ),
      _ClassicFeatureItem(
        title: 'PDF from Images',
        description: 'Create from photo gallery',
        icon: Icons.image,
        color: const Color(0xFFE65100),
        screen: const PdfFromImagesScreen(),
      ),
      _ClassicFeatureItem(
        title: 'Convert from PDF',
        description: 'Export to 19+ formats',
        icon: Icons.transform,
        color: const Color(0xFF1565C0),
        screen: const ConvertFromPdfScreen(),
      ),
      _ClassicFeatureItem(
        title: 'Fill & Sign',
        description: 'Sign & fill forms',
        icon: Icons.edit_document,
        color: const Color(0xFF0D47A1),
        screen: const SignPdfScreenRefactored(),
      ),
      _ClassicFeatureItem(
        title: 'Repair PDF',
        description: 'Fix corrupted PDFs',
        icon: Icons.healing,
        color: const Color(0xFFC62828),
        screen: const RepairPdfScreen(),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _classicLabel('All Features', isDark),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          childAspectRatio: 1.18,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          children: features
              .map((f) => _buildFeatureCard(context, f, isDark))
              .toList(),
        ),
      ],
    );
  }

  Widget _classicLabel(String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: AppConfig.primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
              letterSpacing: 0.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context,
    _ClassicFeatureItem feature,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => feature.screen),
        ),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
            border: Border.all(
              color: isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade200,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: feature.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(feature.icon, size: 24, color: feature.color),
              ),
              const SizedBox(height: 8),
              Text(
                feature.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                feature.description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  height: 1.25,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildClassicTips(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: AppConfig.primaryColor.withValues(alpha: 0.07),
        border: Border.all(
          color: AppConfig.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.lightbulb_outline,
            size: 16,
            color: AppConfig.primaryColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Compress, convert, edit and merge PDFs \u2014 all offline, all free.',
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassicFooter(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'v${AppConfig.appVersion}  \u00b7  Made with \u2764\ufe0f',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
          ),
        ),
        GestureDetector(
          onTap: _launchGitHub,
          child: Icon(
            FontAwesomeIcons.github,
            size: 16,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // MODERN DESKTOP WORKSPACE UI/UX (FOR WINDOWS, MAC, LINUX, WEB)
  // ===========================================================================

  Widget _buildDesktopWorkspaceDashboard(BuildContext context, bool isDark) {
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 768;

    return Scaffold(
      backgroundColor: isDark ? PremiumColors.darkBg : PremiumColors.lightBg,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 16 : 28,
            vertical: isCompact ? 16 : 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeBanner(isDark, isCompact),
              const SizedBox(height: 20),
              HeroDropZone(
                onFileSelected: _handlePickPdf,
                isCompact: isCompact,
              ),
              const SizedBox(height: 28),
              _buildSpotlightSection(isDark, isCompact),
              const SizedBox(height: 28),
              _buildCategorizedToolsSection(isDark, isCompact),
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
              _buildDesktopFooter(isDark),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeBanner(bool isDark, bool isCompact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            AppBrandLogo(
              size: isCompact ? 28 : 34,
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
                            fontSize: isCompact ? 18 : 22,
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
                      fontSize: isCompact ? 11.5 : 13,
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
      padding: const EdgeInsets.all(16),
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
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.lock_outline_rounded,
              color: Colors.green,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Air-Gapped Local Privacy',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'All PDF processing executes 100% locally on your device. No files are uploaded to remote servers or third-party clouds.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.4,
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

  Widget _buildDesktopFooter(bool isDark) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        Text(
          'OpenPDF Tools v${AppConfig.appVersion} \u2022 Open-Source PDF Suite',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
          ),
        ),
        InkWell(
          onTap: _launchGitHub,
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  FontAwesomeIcons.github,
                  size: 14,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                ),
                const SizedBox(width: 6),
                Text(
                  'GitHub',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ClassicFeatureItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Widget screen;

  _ClassicFeatureItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.screen,
  });
}

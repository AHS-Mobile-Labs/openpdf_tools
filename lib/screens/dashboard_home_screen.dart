import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/app_config.dart';
import 'pdf_viewer_screen.dart';
import 'compress_pdf_screen.dart';
import 'convert_to_pdf_screen.dart';
import 'convert_from_pdf_screen.dart';
import 'history_screen.dart';
import 'edit_pdf_screen.dart';
import 'pdf_from_images_screen.dart';
import 'merge_pdf_screen.dart';
import 'split_pdf_screen.dart';

/// Modern, clean dashboard home screen with improved UX
class DashboardHomeScreen extends StatefulWidget {
  const DashboardHomeScreen({super.key});

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  Future<void> _launchGitHub() async {
    try {
      if (await canLaunchUrl(Uri.parse(AppConfig.githubUrl))) {
        await launchUrl(Uri.parse(AppConfig.githubUrl));
      }
    } catch (e) {
      debugPrint('Error launching GitHub URL: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    final isDesktop = width >= 600;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F0F)
          : const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // scrollable content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildHeader(isDark, isMobile),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          const SizedBox(height: 16),
                          _buildQuickActions(context, isDark),
                          const SizedBox(height: 20),
                          _buildFeatures(context, isDark, isDesktop),
                          const SizedBox(height: 20),
                          _buildTips(isDark),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // pinned bottom
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _buildFooter(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, bool isMobile) {
    return Container(
      width: double.infinity,
      height: isMobile ? 150.0 : 72.0,
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
          // Decorative background circles
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
          // Mobile: centered stacked layout
          if (isMobile)
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
                      _versionBadge(),
                    ],
                  ),
                ],
              ),
            ),
          // Desktop: compact horizontal row
          if (!isMobile)
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    // Logo
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.15),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      padding: const EdgeInsets.all(5),
                      child: Image.asset(
                        'asset/app_img/OpenPDF Tools.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Title + tagline
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          AppConfig.appTitle,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Fast \u2022 Secure \u2022 Offline',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.7),
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    _versionBadge(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _versionBadge() {
    return Container(
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
    );
  }

  Widget _label(String text, bool isDark) {
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
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
              border: Border.all(
                color: isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade200,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20, color: color),
                const SizedBox(height: 5),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
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

  Widget _buildQuickActions(BuildContext context, bool isDark) {
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

  Widget _buildFeatures(BuildContext context, bool isDark, bool isDesktop) {
    final features = [
      FeatureItem(
        title: 'Merge PDF',
        description: 'Combine PDFs in order',
        icon: Icons.merge,
        color: const Color(0xFF1565C0),
        screen: const MergePdfScreen(),
      ),
      FeatureItem(
        title: 'Split PDF',
        description: 'Separate pages into PDFs',
        icon: Icons.cut,
        color: const Color(0xFF7E57C2),
        screen: const SplitPdfScreen(),
      ),
      FeatureItem(
        title: 'Convert to PDF',
        description: 'From images, docs, and more',
        icon: Icons.file_present,
        color: const Color(0xFF00796B),
        screen: const ConvertToPdfScreen(),
      ),
      FeatureItem(
        title: 'PDF from Images',
        description: 'Create from photo gallery',
        icon: Icons.image,
        color: const Color(0xFFE65100),
        screen: const PdfFromImagesScreen(),
      ),
      FeatureItem(
        title: 'Convert from PDF',
        description: 'Export to 19+ formats',
        icon: Icons.transform,
        color: const Color(0xFF1565C0),
        screen: const ConvertFromPdfScreen(),
      ),
      FeatureItem(
        title: 'History',
        description: 'Recent & favorite files',
        icon: Icons.history,
        color: const Color(0xFF7E57C2),
        screen: const HistoryScreen(),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label('All Features', isDark),
        if (isDesktop)
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: features.length,
            separatorBuilder: (context, index) => const SizedBox(height: 6),
            itemBuilder: (context, index) =>
                _buildFeatureDesktop(context, features[index], isDark),
          )
        else
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.35,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: features
                .map((f) => _buildFeatureMobile(context, f, isDark))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildFeatureMobile(
    BuildContext context,
    FeatureItem feature,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => feature.screen),
        ),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
            border: Border.all(
              color: isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade200,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: feature.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(feature.icon, size: 22, color: feature.color),
              ),
              const SizedBox(height: 7),
              Text(
                feature.title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                feature.description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureDesktop(
    BuildContext context,
    FeatureItem feature,
    bool isDark,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => feature.screen),
        ),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
            border: Border.all(
              color: isDark ? const Color(0xFF2E2E2E) : Colors.grey.shade200,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: feature.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(feature.icon, size: 18, color: feature.color),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature.title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      feature.description,
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
              Icon(
                Icons.arrow_forward_ios,
                size: 12,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTips(bool isDark) {
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

  Widget _buildFooter(bool isDark) {
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
}

class FeatureItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Widget screen;

  FeatureItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.screen,
  });
}

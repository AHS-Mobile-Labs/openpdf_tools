import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../config/premium_theme.dart';
import '../services/release_download_service.dart';
import '../utils/platform_helper.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  late Future<ReleaseInfo> _releaseFuture;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _loadReleaseData();
  }

  void _loadReleaseData({bool forceRefresh = false}) {
    setState(() {
      _isRefreshing = forceRefresh;
      _releaseFuture = ReleaseDownloadService.getLatestRelease(
        forceRefresh: forceRefresh,
      );
    });
  }

  Future<void> _openDownloadUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open download link: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final width = MediaQuery.of(context).size.width;
    final isCompact = width < 768;

    return Scaffold(
      backgroundColor: isDark ? PremiumColors.darkBg : PremiumColors.lightBg,
      body: SafeArea(
        child: FutureBuilder<ReleaseInfo>(
          future: _releaseFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !_isRefreshing) {
              return const Center(
                child: CircularProgressIndicator(color: PremiumColors.brandRed),
              );
            }

            final release = snapshot.data;
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(
                horizontal: isCompact ? 16 : 32,
                vertical: isCompact ? 16 : 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, isDark, isCompact, release),
                  const SizedBox(height: 24),
                  if (release != null && release.isFallback)
                    _buildFallbackNotice(isDark),
                  if (release != null && release.isFallback)
                    const SizedBox(height: 16),
                  _buildHeroRecommendedDownload(
                    context,
                    isDark,
                    isCompact,
                    release,
                  ),
                  const SizedBox(height: 32),
                  _buildSectionTitle(
                    title: 'Available Platform Downloads',
                    subtitle:
                        'Native standalone binaries & web builds — no sign-up or tracking',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildPlatformGrid(context, isDark, width, release),
                  const SizedBox(height: 32),
                  _buildSecurityAndSigningCard(isDark),
                  const SizedBox(height: 24),
                  _buildGitHubReleaseFooter(isDark, release),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    bool isDark,
    bool isCompact,
    ReleaseInfo? release,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (Navigator.canPop(context))
          Padding(
            padding: const EdgeInsets.only(right: 12, top: 4),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: () => Navigator.pop(context),
              tooltip: 'Back',
            ),
          ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: PremiumColors.brandRed.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.download_rounded,
                      color: PremiumColors.brandRed,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Download OpenPDF Tools',
                          style: TextStyle(
                            fontSize: isCompact ? 20 : 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1E1E1E),
                          ),
                        ),
                        if (release != null)
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: PremiumColors.brandRed.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: PremiumColors.brandRed.withValues(
                                      alpha: 0.35,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  release.versionDisplay,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: PremiumColors.brandRed,
                                  ),
                                ),
                              ),
                              if (release.dateDisplay.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Text(
                                  'Released ${release.dateDisplay}',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark
                                        ? Colors.grey.shade400
                                        : Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.refresh_rounded,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                    ),
                    tooltip: 'Check for updates',
                    onPressed: () => _loadReleaseData(forceRefresh: true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFallbackNotice(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: Colors.amber, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Showing verified release builds. Connect to internet or refresh to verify real-time GitHub release assets.',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroRecommendedDownload(
    BuildContext context,
    bool isDark,
    bool isCompact,
    ReleaseInfo? release,
  ) {
    // Detect recommended platform based on current device / OS
    String currentPlatform = 'Web';
    if (!kIsWeb) {
      if (PlatformHelper.isAndroid) {
        currentPlatform = 'Android';
      } else if (PlatformHelper.isWindows) {
        currentPlatform = 'Windows';
      } else if (PlatformHelper.isLinux) {
        currentPlatform = 'Linux';
      } else if (PlatformHelper.isMacOS) {
        currentPlatform = 'macOS';
      } else if (PlatformHelper.isIOS) {
        currentPlatform = 'iOS';
      }
    }

    final recommendedBuild = release?.downloads.firstWhere(
      (d) => d.platform == currentPlatform,
      orElse: () => release.downloads.first,
    );

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isCompact ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            PremiumColors.brandRed.withValues(alpha: 0.95),
            const Color(0xFF8B0000),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: PremiumColors.brandRed.withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  recommendedBuild?.icon ?? Icons.download_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recommended for your device',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    Text(
                      recommendedBuild?.title ?? 'OpenPDF Tools',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              if (recommendedBuild?.sizeFormatted != null &&
                  recommendedBuild!.sizeFormatted!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    recommendedBuild.sizeFormatted!,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            recommendedBuild?.description ??
                'Offline, secure PDF suite for editing, conversion, compression, and viewing.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.white.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed:
                    recommendedBuild != null &&
                        recommendedBuild.isAvailable &&
                        recommendedBuild.downloadUrl != null
                    ? () => _openDownloadUrl(recommendedBuild.downloadUrl!)
                    : null,
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text(
                  recommendedBuild != null && recommendedBuild.isAvailable
                      ? 'Download ${recommendedBuild.packageFormat}'
                      : 'Unavailable for this release',
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF9A0000),
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () =>
                    _openDownloadUrl(release?.htmlUrl ?? AppConfig.githubUrl),
                icon: const FaIcon(FontAwesomeIcons.github, size: 15),
                label: const Text('View on GitHub'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.6),
                    width: 1.2,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.3,
            color: isDark ? Colors.white : const Color(0xFF1E1E1E),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: TextStyle(
            fontSize: 12.5,
            color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildPlatformGrid(
    BuildContext context,
    bool isDark,
    double screenWidth,
    ReleaseInfo? release,
  ) {
    if (release == null || release.downloads.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'No download assets found for this release.',
            style: TextStyle(
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
        ),
      );
    }

    int crossAxisCount = 1;
    if (screenWidth >= 1100) {
      crossAxisCount = 3;
    } else if (screenWidth >= 700) {
      crossAxisCount = 2;
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth =
            (constraints.maxWidth - ((crossAxisCount - 1) * 16)) /
            crossAxisCount;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: release.downloads.map((item) {
            return SizedBox(
              width: itemWidth,
              child: _buildPlatformCard(context, item, isDark),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildPlatformCard(
    BuildContext context,
    PlatformDownload item,
    bool isDark,
  ) {
    final cardBg = isDark
        ? PremiumColors.darkSurfacePrimary
        : PremiumColors.lightSurfacePrimary;
    final borderColor = isDark
        ? PremiumColors.darkDivider
        : PremiumColors.lightDivider;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: PremiumColors.brandRed.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, size: 24, color: PremiumColors.brandRed),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.packageFormat,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: isDark
                            ? Colors.grey.shade400
                            : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (item.sizeFormatted != null && item.sizeFormatted!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    item.sizeFormatted!,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: isDark
                          ? Colors.grey.shade300
                          : Colors.grey.shade700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          // Description
          Text(
            item.description,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          // Signing badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: item.isSigned
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.amber.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: item.isSigned
                    ? Colors.green.withValues(alpha: 0.3)
                    : Colors.amber.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  item.isSigned
                      ? Icons.verified_user_rounded
                      : Icons.info_outline,
                  size: 13,
                  color: item.isSigned ? Colors.green : Colors.amber.shade700,
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    item.signingInfo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: item.isSigned
                          ? (isDark
                                ? Colors.greenAccent
                                : Colors.green.shade800)
                          : (isDark
                                ? Colors.amber.shade300
                                : Colors.amber.shade900),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Action button
          SizedBox(
            width: double.infinity,
            child: item.isAvailable && item.downloadUrl != null
                ? ElevatedButton.icon(
                    onPressed: () => _openDownloadUrl(item.downloadUrl!),
                    icon: Icon(
                      item.platform == 'Web'
                          ? Icons.launch_rounded
                          : Icons.download_rounded,
                      size: 16,
                    ),
                    label: Text(
                      item.platform == 'Web'
                          ? 'Open Web App'
                          : 'Download (${item.packageFormat})',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: PremiumColors.brandRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : OutlinedButton(
                    onPressed: null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Build unavailable for this release',
                      style: TextStyle(fontSize: 11),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityAndSigningCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161616) : const Color(0xFFF8F9FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? PremiumColors.darkDivider : Colors.grey.shade300,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shield_outlined, color: Colors.green, size: 20),
              const SizedBox(width: 8),
              Text(
                'Security, Privacy & Signing Policy',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1E1E1E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '• 100% Client-Side: All PDF parsing, compression, merging, conversion, and signing happens entirely on your local device. Files are NEVER uploaded to any remote server.\n'
            '• Verifiable Binaries: Official release binaries are generated automatically in GitHub Actions from public source code.\n'
            '• iOS Distribution: Unsigned IPAs require Apple Developer signing, AltStore, or TestFlight.\n'
            '• Android Installation: The release APK is ready for direct sideloading and manual installation.',
            style: TextStyle(
              fontSize: 11.5,
              height: 1.6,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGitHubReleaseFooter(bool isDark, ReleaseInfo? release) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'OpenPDF Tools • Open Source PDF Suite',
          style: TextStyle(
            fontSize: 11.5,
            color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
          ),
        ),
        TextButton.icon(
          onPressed: () => _openDownloadUrl(
            release?.htmlUrl ??
                'https://github.com/AHS-Mobile-Labs/openpdf_tools/releases',
          ),
          icon: const FaIcon(FontAwesomeIcons.github, size: 14),
          label: const Text('View All Releases'),
          style: TextButton.styleFrom(
            foregroundColor: PremiumColors.brandRed,
            textStyle: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

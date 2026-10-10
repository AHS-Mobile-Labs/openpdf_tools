import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../config/premium_theme.dart';
import '../services/theme_service.dart' as theme_service;
import '../services/pdf_opener_service.dart';
import '../utils/platform_helper.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final PDFOpenerService _pdfOpenerService = PDFOpenerService();
  bool _isRegisteringOpener = false;

  Future<void> _handleRegisterOpener(BuildContext context) async {
    setState(() => _isRegisteringOpener = true);
    try {
      final success = await _pdfOpenerService.registerAsPdfOpener();
      if (!mounted || !context.mounted) return;
      final info = _pdfOpenerService.getPlatformOpenerDetails();

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              Icon(
                success ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                color: success ? Colors.green : Colors.amber,
              ),
              const SizedBox(width: 10),
              Text('${info.platformName} PDF Association'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                info.status,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Text(
                info.instructions,
                style: const TextStyle(fontSize: 13, height: 1.4),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not register PDF opener: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRegisteringOpener = false);
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<theme_service.ThemeService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = PlatformHelper.isMobile;

    return Scaffold(
      backgroundColor: isDark
          ? (themeService.trueBlack ? Colors.black : PremiumColors.darkBg)
          : PremiumColors.lightBg,
      appBar: AppBar(
        title: const Text('Settings & Preferences'),
        backgroundColor: isDark
            ? (themeService.trueBlack ? Colors.black : PremiumColors.darkSurfacePrimary)
            : PremiumColors.lightSurfacePrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 32,
            vertical: 16,
          ),
          children: [
            _buildSectionHeader('Appearance & Theme', Icons.palette_outlined, isDark),
            _buildThemeSelectorCard(themeService, isDark),
            const SizedBox(height: 12),
            _buildSwitchTile(
              title: 'True Black (OLED Mode)',
              subtitle: 'Use absolute pure black backgrounds when dark mode is enabled',
              icon: Icons.contrast_rounded,
              value: themeService.trueBlack,
              enabled: themeService.isDarkMode,
              isDark: isDark,
              onChanged: (val) => themeService.setTrueBlack(val),
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('Accessibility', Icons.accessibility_new_rounded, isDark),
            _buildSwitchTile(
              title: 'High Contrast Mode',
              subtitle: 'Enhance card borders, dividers, and icon contrast for easier visibility',
              icon: Icons.filter_b_and_w_rounded,
              value: themeService.highContrast,
              isDark: isDark,
              onChanged: (val) => themeService.setHighContrast(val),
            ),
            const SizedBox(height: 8),
            _buildTextScaleCard(themeService, isDark),
            const SizedBox(height: 8),
            _buildSwitchTile(
              title: 'Reduce Motion',
              subtitle: 'Minimize animations, screen transitions, and layout sliding effects',
              icon: Icons.motion_photos_off_rounded,
              value: themeService.reduceMotion,
              isDark: isDark,
              onChanged: (val) => themeService.setReduceMotion(val),
            ),
            if (isMobile) ...[
              const SizedBox(height: 8),
              _buildSwitchTile(
                title: 'Haptic Feedback',
                subtitle: 'Subtle vibration taps when selecting tools and toggles',
                icon: Icons.vibration_rounded,
                value: themeService.hapticFeedback,
                isDark: isDark,
                onChanged: (val) {
                  HapticFeedback.lightImpact();
                  themeService.setHapticFeedback(val);
                },
              ),
            ],

            const SizedBox(height: 24),
            _buildSectionHeader('PDF Viewer Defaults', Icons.menu_book_rounded, isDark),
            _buildPageLayoutCard(themeService, isDark),
            const SizedBox(height: 8),
            _buildSwitchTile(
              title: 'Default Night Mode in Viewer',
              subtitle: 'Invert document content colors to reduce eye fatigue at night',
              icon: Icons.nightlight_round,
              value: themeService.defaultNightMode,
              isDark: isDark,
              onChanged: (val) => themeService.setDefaultNightMode(val),
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('System Integration', Icons.open_in_new_rounded, isDark),
            _buildOpenerCard(context, isDark),

            const SizedBox(height: 24),
            _buildSectionHeader('History & Storage', Icons.storage_rounded, isDark),
            _buildSwitchTile(
              title: 'Record Recent Files',
              subtitle: 'Automatically store opened PDF paths in local history for fast access',
              icon: Icons.history_rounded,
              value: themeService.recordRecentFiles,
              isDark: isDark,
              onChanged: (val) => themeService.setRecordRecentFiles(val),
            ),
            const SizedBox(height: 8),
            _buildActionCard(
              title: 'Clear Recent Files History',
              subtitle: 'Remove all document shortcuts from recent history',
              icon: Icons.delete_outline_rounded,
              actionLabel: 'Clear History',
              isDestructive: true,
              isDark: isDark,
              onTap: () => _confirmClearHistory(context, themeService),
            ),
            const SizedBox(height: 8),
            _buildActionCard(
              title: 'Clear Temporary App Cache',
              subtitle: 'Remove temporary export files and scratch conversions',
              icon: Icons.cleaning_services_rounded,
              actionLabel: 'Clear Cache',
              isDestructive: false,
              isDark: isDark,
              onTap: () => _handleClearCache(context, themeService),
            ),

            const SizedBox(height: 24),
            _buildPrivacyCard(isDark),

            const SizedBox(height: 24),
            _buildSectionHeader('About OpenPDF Tools', Icons.info_outline_rounded, isDark),
            _buildAboutCard(isDark),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: PremiumColors.luxuryRed),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThemeSelectorCard(theme_service.ThemeService themeService, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? PremiumColors.darkSurfacePrimary : PremiumColors.lightSurfacePrimary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? PremiumColors.darkDivider : PremiumColors.lightDivider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Theme Mode',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Select your preferred color theme across the application',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildThemeOption(
                label: 'System',
                icon: Icons.brightness_auto_rounded,
                selected: themeService.themeMode == theme_service.ThemeMode.system,
                isDark: isDark,
                onTap: () => themeService.setThemeMode(theme_service.ThemeMode.system),
              ),
              const SizedBox(width: 10),
              _buildThemeOption(
                label: 'Light',
                icon: Icons.light_mode_rounded,
                selected: themeService.themeMode == theme_service.ThemeMode.light,
                isDark: isDark,
                onTap: () => themeService.setThemeMode(theme_service.ThemeMode.light),
              ),
              const SizedBox(width: 10),
              _buildThemeOption(
                label: 'Dark',
                icon: Icons.dark_mode_rounded,
                selected: themeService.themeMode == theme_service.ThemeMode.dark,
                isDark: isDark,
                onTap: () => themeService.setThemeMode(theme_service.ThemeMode.dark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption({
    required String label,
    required IconData icon,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? PremiumColors.luxuryRed.withValues(alpha: 0.12)
                : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? PremiumColors.luxuryRed
                  : (isDark ? Colors.transparent : Colors.grey.shade200),
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected
                    ? PremiumColors.luxuryRed
                    : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected
                      ? PremiumColors.luxuryRed
                      : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required bool isDark,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? PremiumColors.darkSurfacePrimary : PremiumColors.lightSurfacePrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? PremiumColors.darkDivider : PremiumColors.lightDivider,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: enabled
                  ? (isDark ? Colors.white : Colors.black87)
                  : Colors.grey.shade400,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: enabled
                        ? (isDark ? Colors.white : Colors.black87)
                        : Colors.grey.shade400,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: enabled ? onChanged : null,
            activeTrackColor: PremiumColors.luxuryRed,
          ),
        ],
      ),
    );
  }

  Widget _buildTextScaleCard(theme_service.ThemeService themeService, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? PremiumColors.darkSurfacePrimary : PremiumColors.lightSurfacePrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? PremiumColors.darkDivider : PremiumColors.lightDivider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.format_size_rounded, size: 20, color: isDark ? Colors.white : Colors.black87),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Text Scaling & Readability',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Scale application typography for enhanced readability',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildScaleOption(
                label: 'Default (100%)',
                scale: 1.0,
                selected: (themeService.textScaleFactor - 1.0).abs() < 0.05,
                isDark: isDark,
                onTap: () => themeService.setTextScaleFactor(1.0),
              ),
              const SizedBox(width: 8),
              _buildScaleOption(
                label: 'Large (115%)',
                scale: 1.15,
                selected: (themeService.textScaleFactor - 1.15).abs() < 0.05,
                isDark: isDark,
                onTap: () => themeService.setTextScaleFactor(1.15),
              ),
              const SizedBox(width: 8),
              _buildScaleOption(
                label: 'XL (130%)',
                scale: 1.30,
                selected: (themeService.textScaleFactor - 1.30).abs() < 0.05,
                isDark: isDark,
                onTap: () => themeService.setTextScaleFactor(1.30),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScaleOption({
    required String label,
    required double scale,
    required bool selected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: selected
                ? PremiumColors.luxuryRed.withValues(alpha: 0.12)
                : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? PremiumColors.luxuryRed : Colors.transparent,
              width: selected ? 1.5 : 1.0,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? PremiumColors.luxuryRed
                    : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPageLayoutCard(theme_service.ThemeService themeService, bool isDark) {
    final isFitPage = themeService.defaultPageLayout == 'single';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? PremiumColors.darkSurfacePrimary : PremiumColors.lightSurfacePrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? PremiumColors.darkDivider : PremiumColors.lightDivider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.auto_stories_rounded, size: 20, color: isDark ? Colors.white : Colors.black87),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Default PDF View Mode',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Choose how documents are displayed when initially opened',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildScaleOption(
                label: 'Fit Page (Single)',
                scale: 1.0,
                selected: isFitPage,
                isDark: isDark,
                onTap: () => themeService.setDefaultPageLayout('single'),
              ),
              const SizedBox(width: 10),
              _buildScaleOption(
                label: 'Continuous Scroll',
                scale: 1.0,
                selected: !isFitPage,
                isDark: isDark,
                onTap: () => themeService.setDefaultPageLayout('continuous'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOpenerCard(BuildContext context, bool isDark) {
    final info = _pdfOpenerService.getPlatformOpenerDetails();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? PremiumColors.darkSurfacePrimary : PremiumColors.lightSurfacePrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? PremiumColors.darkDivider : PremiumColors.lightDivider,
        ),
      ),
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
                child: const Icon(Icons.picture_as_pdf_rounded, size: 20, color: PremiumColors.brandRed),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Open with OpenPDF Tools',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            info.platformName,
                            style: const TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.green,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      info.status,
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            info.instructions,
            style: TextStyle(
              fontSize: 11.5,
              height: 1.35,
              color: isDark ? Colors.grey.shade300 : Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isRegisteringOpener ? null : () => _handleRegisterOpener(context),
              icon: _isRegisteringOpener
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.link_rounded, size: 16),
              label: Text(
                _isRegisteringOpener
                    ? 'Configuring...'
                    : 'Set as Default PDF Opener (${info.platformName})',
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: PremiumColors.luxuryRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required String actionLabel,
    required bool isDestructive,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? PremiumColors.darkSurfacePrimary : PremiumColors.lightSurfacePrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? PremiumColors.darkDivider : PremiumColors.lightDivider,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDestructive
                  ? Colors.red.withValues(alpha: 0.1)
                  : (isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04)),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isDestructive ? Colors.red : (isDark ? Colors.white : Colors.black87),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              foregroundColor: isDestructive ? Colors.red : (isDark ? Colors.white : Colors.black87),
              side: BorderSide(
                color: isDestructive ? Colors.red.withValues(alpha: 0.5) : (isDark ? Colors.white24 : Colors.black26),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(actionLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacyCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.shield_rounded, size: 22, color: Colors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '100% Offline & Private',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Your PDF documents never leave your device. All rendering, compression, conversions, and cryptographic signatures are executed completely on-device without any cloud processing.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.35,
                    color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? PremiumColors.darkSurfacePrimary : PremiumColors.lightSurfacePrimary,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? PremiumColors.darkDivider : PremiumColors.lightDivider,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                height: 38,
                width: 38,
                child: Image.asset('asset/app_img/OpenPDF Tools.png', fit: BoxFit.contain),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppConfig.appTitle,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Version ${AppConfig.appVersion} \u2022 Open-Source PDF Suite',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1),
          const SizedBox(height: 12),
          InkWell(
            onTap: _launchGitHub,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  const FaIcon(FontAwesomeIcons.github, size: 16),
                  const SizedBox(width: 10),
                  const Text('GitHub Repository', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmClearHistory(BuildContext context, theme_service.ThemeService themeService) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Recent History?'),
        content: const Text('This will remove all document shortcuts from your recent files history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await themeService.clearRecentHistory();
              if (ctx.mounted) Navigator.of(ctx).pop();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Recent files history cleared')),
                );
              }
            },
            child: const Text('Clear', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _handleClearCache(BuildContext context, theme_service.ThemeService themeService) async {
    final deleted = await themeService.clearAppCache();
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cleared $deleted temporary cache files')),
      );
    }
  }
}

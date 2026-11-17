import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ReleaseAsset {
  final String name;
  final String downloadUrl;
  final int size;
  final String contentType;

  ReleaseAsset({
    required this.name,
    required this.downloadUrl,
    required this.size,
    required this.contentType,
  });

  String get sizeFormatted {
    if (size <= 0) return '';
    if (size >= 1024 * 1024 * 1024) {
      return '${(size / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
    if (size >= 1024 * 1024) {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    if (size >= 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    }
    return '$size B';
  }

  factory ReleaseAsset.fromJson(Map<String, dynamic> json) {
    return ReleaseAsset(
      name: json['name'] as String? ?? '',
      downloadUrl: json['browser_download_url'] as String? ?? '',
      size: (json['size'] as num?)?.toInt() ?? 0,
      contentType: json['content_type'] as String? ?? '',
    );
  }
}

class PlatformDownload {
  final String platform;
  final String title;
  final IconData icon;
  final String fileName;
  final String packageFormat;
  final String? downloadUrl;
  final String? sizeFormatted;
  final bool isAvailable;
  final bool isSigned;
  final String signingInfo;
  final String description;
  final List<String> installGuide;

  PlatformDownload({
    required this.platform,
    required this.title,
    required this.icon,
    required this.fileName,
    required this.packageFormat,
    this.downloadUrl,
    this.sizeFormatted,
    required this.isAvailable,
    required this.isSigned,
    required this.signingInfo,
    required this.description,
    required this.installGuide,
  });
}

class ReleaseInfo {
  final String tagName;
  final String name;
  final DateTime? publishedAt;
  final String htmlUrl;
  final String body;
  final List<PlatformDownload> downloads;
  final bool isFallback;

  ReleaseInfo({
    required this.tagName,
    required this.name,
    this.publishedAt,
    required this.htmlUrl,
    required this.body,
    required this.downloads,
    this.isFallback = false,
  });

  String get versionDisplay {
    if (tagName.startsWith('v')) return tagName;
    return 'v$tagName';
  }

  String get dateDisplay {
    if (publishedAt == null) return '';
    final dt = publishedAt!;
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }
}

class ReleaseDownloadService {
  static const String _repoOwner = 'AHS-Mobile-Labs';
  static const String _repoName = 'openpdf_tools';
  static const String _githubLatestApi =
      'https://api.github.com/repos/$_repoOwner/$_repoName/releases/latest';
  static const String _webAppUrl =
      'https://ahs-mobile-labs.github.io/openpdf_tools/';

  static ReleaseInfo? _cachedRelease;
  static DateTime? _cacheTimestamp;
  static const Duration _cacheDuration = Duration(minutes: 10);

  /// Fetch the latest stable release metadata with caching and bundled fallback.
  static Future<ReleaseInfo> getLatestRelease({
    bool forceRefresh = false,
  }) async {
    if (!forceRefresh &&
        _cachedRelease != null &&
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < _cacheDuration) {
      return _cachedRelease!;
    }

    try {
      final response = await http
          .get(
            Uri.parse(_githubLatestApi),
            headers: {'Accept': 'application/vnd.github.v3+json'},
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data =
            jsonDecode(response.body) as Map<String, dynamic>;
        final release = _parseGitHubRelease(data, isFallback: false);
        _cachedRelease = release;
        _cacheTimestamp = DateTime.now();
        return release;
      }
    } catch (e) {
      debugPrint(
        '[ReleaseDownloadService] Failed to fetch live GitHub release: $e',
      );
    }

    // Load from bundled asset
    final fallback = await _loadBundledReleaseFallback();
    _cachedRelease = fallback;
    _cacheTimestamp = DateTime.now();
    return fallback;
  }

  static ReleaseInfo _parseGitHubRelease(
    Map<String, dynamic> data, {
    required bool isFallback,
  }) {
    final tagName = data['tag_name'] as String? ?? 'v${AppConfig.appVersion}';
    final name = data['name'] as String? ?? 'OpenPDF Tools $tagName';
    final publishedStr = data['published_at'] as String?;
    final publishedAt = publishedStr != null
        ? DateTime.tryParse(publishedStr)
        : null;
    final htmlUrl =
        data['html_url'] as String? ??
        'https://github.com/$_repoOwner/$_repoName/releases';
    final body = data['body'] as String? ?? '';

    final rawAssets = (data['assets'] as List<dynamic>?) ?? [];
    final List<ReleaseAsset> assets = rawAssets
        .map((a) => ReleaseAsset.fromJson(a as Map<String, dynamic>))
        .toList();

    final downloads = _buildPlatformDownloads(assets, tagName);

    return ReleaseInfo(
      tagName: tagName,
      name: name,
      publishedAt: publishedAt,
      htmlUrl: htmlUrl,
      body: body,
      downloads: downloads,
      isFallback: isFallback,
    );
  }

  static Future<ReleaseInfo> _loadBundledReleaseFallback() async {
    try {
      final jsonString = await rootBundle.loadString('asset/releases.json');
      final Map<String, dynamic> data =
          jsonDecode(jsonString) as Map<String, dynamic>;
      return _parseGitHubRelease(data, isFallback: true);
    } catch (e) {
      debugPrint(
        '[ReleaseDownloadService] Error loading asset/releases.json: $e',
      );
      return _createStaticOfflineRelease();
    }
  }

  static ReleaseInfo _createStaticOfflineRelease() {
    const version = 'v${AppConfig.appVersion}';
    return ReleaseInfo(
      tagName: version,
      name: 'OpenPDF Tools $version',
      publishedAt: DateTime.now(),
      htmlUrl: 'https://github.com/$_repoOwner/$_repoName/releases/latest',
      body: 'Production multi-platform builds for OpenPDF Tools.',
      downloads: _buildPlatformDownloads([], version),
      isFallback: true,
    );
  }

  static List<PlatformDownload> _buildPlatformDownloads(
    List<ReleaseAsset> assets,
    String tag,
  ) {
    // 1. Android APK
    final apkAsset = _findAsset(assets, ['.apk'], exclude: []);
    // 1b. Android AAB
    final aabAsset = _findAsset(assets, ['.aab'], exclude: []);

    // 2. Windows ZIP
    final winAsset = _findAsset(assets, [
      'windows.zip',
      'win.zip',
      '.exe',
    ], exclude: []);

    // 3. Linux
    final linuxAsset = _findAsset(assets, [
      'linux.tar.gz',
      '.deb',
      '.appimage',
    ], exclude: []);

    // 4. macOS
    final macAsset = _findAsset(assets, [
      'macos.zip',
      'mac.zip',
      '.dmg',
    ], exclude: []);

    // 5. iOS
    final iosAsset = _findAsset(assets, ['ios.zip', '.ipa'], exclude: []);

    return [
      PlatformDownload(
        platform: 'Android',
        title: 'Android (APK)',
        icon: Icons.android_rounded,
        fileName: apkAsset?.name ?? 'OpenPDF-Tools-$tag-Android.apk',
        packageFormat: 'Release APK',
        downloadUrl: apkAsset?.downloadUrl,
        sizeFormatted: apkAsset?.sizeFormatted,
        isAvailable: apkAsset != null,
        isSigned:
            apkAsset != null &&
            !apkAsset.name.toLowerCase().contains('unsigned'),
        signingInfo:
            apkAsset != null &&
                !apkAsset.name.toLowerCase().contains('unsigned')
            ? 'Signed Release'
            : 'Unsigned / Self-signed APK',
        description:
            'Direct installer for Android smartphones and tablets (Android 8.0+).',
        installGuide: [
          'Download the APK directly to your Android device.',
          'Open your file manager or browser downloads.',
          'Allow "Install from unknown sources" if prompted.',
          'Complete installation and launch OpenPDF Tools.',
        ],
      ),
      if (aabAsset != null)
        PlatformDownload(
          platform: 'Android Bundle',
          title: 'Android App Bundle (AAB)',
          icon: Icons.shop_two_rounded,
          fileName: aabAsset.name,
          packageFormat: 'AAB',
          downloadUrl: aabAsset.downloadUrl,
          sizeFormatted: aabAsset.sizeFormatted,
          isAvailable: true,
          isSigned: true,
          signingInfo: 'Google Play Release Bundle',
          description:
              'Optimized package format for Google Play Store publishing.',
          installGuide: [
            'Use bundletool or Google Play Console to generate device-specific APKs.',
          ],
        ),
      PlatformDownload(
        platform: 'Windows',
        title: 'Windows (64-bit)',
        icon: Icons.window_rounded,
        fileName: winAsset?.name ?? 'OpenPDF-Tools-$tag-Windows.zip',
        packageFormat: 'ZIP Portable',
        downloadUrl: winAsset?.downloadUrl,
        sizeFormatted: winAsset?.sizeFormatted,
        isAvailable: winAsset != null,
        isSigned: false,
        signingInfo: 'Packaged Release',
        description:
            'Native Windows desktop application with full offline capabilities.',
        installGuide: [
          'Download and extract the ZIP archive to any folder.',
          'Run openpdf_tools.exe directly (no installation needed).',
          'Create a desktop shortcut if desired.',
        ],
      ),
      PlatformDownload(
        platform: 'Linux',
        title: 'Linux (x86_64)',
        icon: Icons.terminal_rounded,
        fileName: linuxAsset?.name ?? 'OpenPDF-Tools-$tag-Linux.tar.gz',
        packageFormat: linuxAsset != null && linuxAsset.name.endsWith('.deb')
            ? 'DEB'
            : (linuxAsset != null && linuxAsset.name.endsWith('.AppImage')
                  ? 'AppImage'
                  : 'TAR.GZ'),
        downloadUrl: linuxAsset?.downloadUrl,
        sizeFormatted: linuxAsset?.sizeFormatted,
        isAvailable: linuxAsset != null,
        isSigned: false,
        signingInfo: 'Packaged Tarball / Binary',
        description:
            'Native Linux application for Ubuntu, Debian, Fedora, Arch, and derivatives.',
        installGuide: [
          'Extract the archive: tar -xzf OpenPDF-Tools-*-Linux.tar.gz',
          'Navigate to bundle folder and ensure binary is executable: chmod +x openpdf_tools',
          'Execute ./openpdf_tools',
        ],
      ),
      PlatformDownload(
        platform: 'macOS',
        title: 'macOS (Universal / x64)',
        icon: Icons.laptop_mac_rounded,
        fileName: macAsset?.name ?? 'OpenPDF-Tools-$tag-macOS.zip',
        packageFormat: macAsset != null && macAsset.name.endsWith('.dmg')
            ? 'DMG'
            : 'ZIP Bundle',
        downloadUrl: macAsset?.downloadUrl,
        sizeFormatted: macAsset?.sizeFormatted,
        isAvailable: macAsset != null,
        isSigned: false,
        signingInfo: 'Packaged App Bundle (Unnotarized)',
        description:
            'Native macOS application bundle for Apple Silicon and Intel Macs.',
        installGuide: [
          'Download and extract the macOS archive.',
          'Move OpenPDF Tools.app to your Applications folder.',
          'If Gatekeeper blocks execution on first launch, open via Right Click -> Open or System Settings -> Privacy & Security.',
        ],
      ),
      PlatformDownload(
        platform: 'iOS',
        title: 'Apple iOS (Signing Required)',
        icon: Icons.phone_iphone_rounded,
        fileName: iosAsset?.name ?? 'OpenPDF-Tools-$tag-iOS.zip',
        packageFormat: iosAsset != null
            ? 'Unsigned IPA / Archive'
            : 'Signing Required',
        downloadUrl: iosAsset?.downloadUrl,
        sizeFormatted: iosAsset?.sizeFormatted,
        isAvailable: iosAsset != null,
        isSigned: false,
        signingInfo: 'Unsigned Build — Apple Provisioning Required',
        description:
            'iOS builds require an active Apple Developer Certificate and provisioning profile for on-device installation.',
        installGuide: [
          'iOS distribution requires an Apple Developer Account or ad-hoc sideloading tool.',
          'Use Xcode, AltStore, Sideloadly, or Apple TestFlight with your own signing credentials.',
          'An unsigned IPA cannot be installed directly without a valid Apple certificate.',
        ],
      ),
      PlatformDownload(
        platform: 'Web',
        title: 'Web Application (Instant)',
        icon: Icons.language_rounded,
        fileName: 'Live Web Edition',
        packageFormat: 'PWA Web App',
        downloadUrl: _webAppUrl,
        sizeFormatted: 'Runs in Browser',
        isAvailable: true,
        isSigned: true,
        signingInfo: 'HTTPS Protected & Client-Side',
        description:
            'Run OpenPDF Tools directly in Chrome, Firefox, Safari, or Edge without installation.',
        installGuide: [
          'Open directly in any modern browser.',
          'All PDF processing is 100% offline & client-side.',
          'Optionally click "Install App" in your browser bar for PWA mode.',
        ],
      ),
    ];
  }

  static ReleaseAsset? _findAsset(
    List<ReleaseAsset> assets,
    List<String> extensions, {
    required List<String> exclude,
  }) {
    for (final ext in extensions) {
      for (final asset in assets) {
        final lower = asset.name.toLowerCase();
        final matchesExt = lower.contains(ext.toLowerCase());
        final isExcluded = exclude.any(
          (ex) => lower.contains(ex.toLowerCase()),
        );
        if (matchesExt && !isExcluded) {
          return asset;
        }
      }
    }
    return null;
  }
}

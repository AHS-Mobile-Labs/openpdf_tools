import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:provider/provider.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import 'screens/splash_screen.dart';
import 'screens/pdf_viewer_screen.dart';
import 'screens/compress_pdf_screen.dart';
import 'screens/convert_to_pdf_screen.dart';
import 'screens/convert_from_pdf_screen.dart';
import 'screens/history_screen.dart';
import 'screens/edit_pdf_screen.dart';
import 'screens/pdf_from_images_screen.dart';
import 'screens/dashboard_home_screen.dart';
import 'screens/repair_pdf_screen.dart';
import 'screens/merge_pdf_screen.dart';
import 'screens/split_pdf_screen.dart';
import 'screens/sign_pdf_screen_refactored.dart';
import 'screens/all_tools_screen.dart';
import 'screens/settings_screen.dart';
import 'widgets/modern_navigation.dart';
import 'widgets/workspace_components.dart';
import 'config/app_config.dart';
import 'config/premium_theme.dart';
import 'utils/platform_helper.dart';
import 'utils/platform_file_handler.dart';
import 'utils/responsive_helper.dart';
import 'utils/uri_to_file.dart';
import 'services/pdf_opener_service.dart';
import 'services/file_history_service.dart';
import 'services/theme_service.dart' as theme_service;

const String _appTitle = AppConfig.appTitle;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[main] Flutter binding initialized, starting app initialization');
  if (PlatformHelper.isMobile) {
    try {
      debugPrint(
        '[main] Requesting file permissions for ${PlatformHelper.platformName}',
      );
      final granted = await PlatformFileHandler.requestFilePermissions();
      if (granted) {
        debugPrint('[main] File permissions granted successfully');
      } else {
        debugPrint(
          '[main] File permissions denied - app will attempt limited functionality',
        );
      }
    } catch (e) {
      debugPrint('[main] Error requesting permissions: $e');
    }
  }
  final themeService = theme_service.ThemeService();
  try {
    await themeService.initialize();
    debugPrint('[main] Theme service initialized');
  } catch (e) {
    debugPrint('[main] Error initializing theme service: $e');
  }
  debugPrint('[main] Starting app with safe initialization');
  runApp(
    ChangeNotifierProvider<theme_service.ThemeService>.value(
      value: themeService,
      child: const OpenPDFToolsApp(),
    ),
  );
}

class OpenPDFToolsApp extends StatefulWidget {
  const OpenPDFToolsApp({super.key});
  @override
  State<OpenPDFToolsApp> createState() => _OpenPDFToolsAppState();
}

class _OpenPDFToolsAppState extends State<OpenPDFToolsApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<List<SharedMediaFile>>? _intentSub;
  late PDFOpenerService _pdfOpenerService;
  bool _pdfOpenerServiceInitialized = false;
  @override
  void initState() {
    super.initState();
    debugPrint('[_OpenPDFToolsAppState] initState called');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('[_OpenPDFToolsAppState] addPostFrameCallback triggered');
      Future.delayed(const Duration(milliseconds: 100), () {
        _initializePlatformServices();
      });
    });
    if (!kIsWeb && PlatformHelper.isAndroid) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 150), () {
          _initAndroidShareHandling();
        });
      });
    }
  }

  Future<void> _initializePlatformServices() async {
    try {
      debugPrint('[_OpenPDFToolsAppState] Initializing platform services');
      if (PlatformHelper.isDesktop) {
        try {
          debugPrint(
            '[_OpenPDFToolsAppState] Skipping desktop initialization to avoid native callback crashes',
          );
        } catch (e) {
          debugPrint(
            '[_OpenPDFToolsAppState] Error in desktop initialization: $e',
          );
        }
      }
      if (!kIsWeb && (PlatformHelper.isIOS || PlatformHelper.isAndroid)) {
        try {
          debugPrint(
            '[_OpenPDFToolsAppState] Initializing PDF opener service (mobile)',
          );
          _pdfOpenerService = PDFOpenerService();
          await _pdfOpenerService.initialize(
            onPdfFileReceived: _handlePdfFileFromSystem,
          );
          _pdfOpenerServiceInitialized = true;
          debugPrint(
            '[_OpenPDFToolsAppState] PDF opener service initialized (mobile)',
          );
        } catch (e) {
          _pdfOpenerServiceInitialized = false;
          debugPrint(
            '[_OpenPDFToolsAppState] Failed to initialize PDF opener (mobile): $e',
          );
        }
      }
    } catch (e) {
      debugPrint(
        '[_OpenPDFToolsAppState] Error in platform initialization: $e',
      );
    }
  }

  void _handlePdfFileFromSystem(String filePath) {
    _openPdfFileFromSystem(filePath);
  }

  Future<void> _openPdfFileFromSystem(String filePath) async {
    debugPrint('PDF file received from system: $filePath');
    final resolvedPath = await resolveToRealPath(filePath);
    final file = File(resolvedPath);
    if (file.existsSync() && resolvedPath.toLowerCase().endsWith('.pdf')) {
      _navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => PdfViewerScreen(externalFile: file)),
      );
    } else {
      debugPrint('File does not exist or is not a PDF: $resolvedPath');
    }
  }

  void _initAndroidShareHandling() {
    ReceiveSharingIntent.instance.getInitialMedia().then(_handleIncomingFiles);
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      _handleIncomingFiles,
    );
  }

  void _handleIncomingFiles(List<SharedMediaFile> files) {
    if (files.isEmpty) return;
    final file = files.first;
    _openPdfFileFromSystem(file.path);
  }

  @override
  void dispose() {
    try {
      if (!kIsWeb && PlatformHelper.isAndroid) {
        _intentSub?.cancel();
        ReceiveSharingIntent.instance.reset();
      }
      if (_pdfOpenerServiceInitialized) {
        _pdfOpenerService.dispose();
      }
    } catch (e) {
      debugPrint('[_OpenPDFToolsAppState] Error during dispose: $e');
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<theme_service.ThemeService>(
      builder: (context, themeService, _) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          title: _appTitle,
          debugShowCheckedModeBanner: false,
          theme: createLightTheme(highContrast: themeService.highContrast),
          darkTheme: createDarkTheme(
            trueBlack: themeService.trueBlack,
            highContrast: themeService.highContrast,
          ),
          themeMode: _convertThemeMode(themeService),
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(themeService.textScaleFactor),
              ),
              child: child!,
            );
          },
          home: const _SplashAndHomeWrapper(),
        );
      },
    );
  }

  ThemeMode _convertThemeMode(theme_service.ThemeService themeService) {
    switch (themeService.themeMode) {
      case theme_service.ThemeMode.light:
        return ThemeMode.light;
      case theme_service.ThemeMode.dark:
        return ThemeMode.dark;
      case theme_service.ThemeMode.system:
        return ThemeMode.system;
    }
  }
}

class _SplashAndHomeWrapper extends StatefulWidget {
  const _SplashAndHomeWrapper();
  @override
  State<_SplashAndHomeWrapper> createState() => _SplashAndHomeWrapperState();
}

class _SplashAndHomeWrapperState extends State<_SplashAndHomeWrapper> {
  bool _showSplash = !kIsWeb;
  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) {
          setState(() {
            _showSplash = false;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const SplashScreen();
    }
    return const ResponsiveHomeScreen();
  }
}

class ResponsiveHomeScreen extends StatefulWidget {
  const ResponsiveHomeScreen({super.key});
  @override
  State<ResponsiveHomeScreen> createState() => _ResponsiveHomeScreenState();
}

class _ResponsiveHomeScreenState extends State<ResponsiveHomeScreen> {
  int _selectedIndex = 0;
  bool _isSidebarExpanded = true;
  late List<ModernNavigationItem> _navigationItems;
  late List<ModernNavigationItem> _mobileNavItems;
  late Map<String, int> _toolIdToIndex;

  @override
  void initState() {
    super.initState();

    _toolIdToIndex = {
      'home': 0,
      'all_tools': 1,
      'viewer': 2,
      'edit': 3,
      'merge': 4,
      'split': 5,
      'compress': 6,
      'convert_to': 7,
      'convert_from': 8,
      'images_to_pdf': 9,
      'sign': 10,
      'repair': 11,
      if (!kIsWeb) 'history': 12,
      'settings': kIsWeb ? 12 : 13,
    };

    _mobileNavItems = [
      ModernNavigationItem(
        icon: Icons.home_rounded,
        label: 'Home',
        screen: DashboardHomeScreen(
          onSelectTool: _handleToolSelected,
          onOpenPdfPath: _openPdfFile,
        ),
      ),
      ModernNavigationItem(
        icon: Icons.picture_as_pdf_rounded,
        label: 'View PDF',
        screen: const PdfViewerScreen(),
      ),
      ModernNavigationItem(
        icon: Icons.swap_horiz_rounded,
        label: 'Convert',
        screen: const ConvertToPdfScreen(),
      ),
      if (!kIsWeb)
        ModernNavigationItem(
          icon: Icons.history_rounded,
          label: 'History',
          screen: const HistoryScreen(),
        ),
      ModernNavigationItem(
        icon: Icons.settings_rounded,
        label: 'Settings',
        screen: const SettingsScreen(),
      ),
    ];

    _navigationItems = [
      ModernNavigationItem(
        icon: Icons.home_rounded,
        label: 'Home',
        section: 'Workspace',
        screen: DashboardHomeScreen(
          onSelectTool: _handleToolSelected,
          onOpenPdfPath: _openPdfFile,
        ),
      ),
      ModernNavigationItem(
        icon: Icons.grid_view_rounded,
        label: 'All Tools',
        section: 'Workspace',
        screen: AllToolsScreen(onSelectTool: _handleToolSelected),
      ),
      ModernNavigationItem(
        icon: Icons.picture_as_pdf_rounded,
        label: 'View PDF',
        section: 'Workspace',
        screen: const PdfViewerScreen(),
      ),
      ModernNavigationItem(
        icon: Icons.edit_note_rounded,
        label: 'Edit PDF',
        section: 'Document Tools',
        screen: const EditPdfScreen(),
      ),
      ModernNavigationItem(
        icon: Icons.call_merge_rounded,
        label: 'Merge PDFs',
        section: 'Document Tools',
        badge: 'Hot',
        screen: const MergePdfScreen(),
      ),
      ModernNavigationItem(
        icon: Icons.content_cut_rounded,
        label: 'Split PDF',
        section: 'Document Tools',
        screen: const SplitPdfScreen(),
      ),
      ModernNavigationItem(
        icon: Icons.compress_rounded,
        label: 'Compress PDF',
        section: 'Document Tools',
        screen: const CompressPdfScreen(),
      ),
      ModernNavigationItem(
        icon: Icons.file_upload_outlined,
        label: 'Convert to PDF',
        section: 'Document Tools',
        screen: const ConvertToPdfScreen(),
      ),
      ModernNavigationItem(
        icon: Icons.transform_rounded,
        label: 'Export from PDF',
        section: 'Document Tools',
        screen: const ConvertFromPdfScreen(),
      ),
      ModernNavigationItem(
        icon: Icons.photo_library_rounded,
        label: 'PDF from Images',
        section: 'Document Tools',
        screen: const PdfFromImagesScreen(),
      ),
      ModernNavigationItem(
        icon: Icons.draw_rounded,
        label: 'Fill & Sign',
        section: 'Document Tools',
        badge: 'PKCS#7',
        screen: const SignPdfScreenRefactored(),
      ),
      ModernNavigationItem(
        icon: Icons.healing_rounded,
        label: 'Repair PDF',
        section: 'Document Tools',
        screen: const RepairPdfScreen(),
      ),
      if (!kIsWeb)
        ModernNavigationItem(
          icon: Icons.history_rounded,
          label: 'Recent & History',
          section: 'Library',
          screen: const HistoryScreen(),
        ),
      ModernNavigationItem(
        icon: Icons.settings_rounded,
        label: 'Settings',
        section: 'System',
        screen: const SettingsScreen(),
      ),
    ];
  }

  void _handleToolSelected(ToolItem tool) {
    final targetIndex = _toolIdToIndex[tool.id];
    if (context.isMobile || targetIndex == null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => tool.screenBuilder()),
      );
    } else {
      setState(() {
        _selectedIndex = targetIndex;
      });
    }
  }

  void _openPdfFile(String filePath) {
    final file = File(filePath);
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

  Future<void> _handleGlobalOpenPdf() async {
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
          SnackBar(content: Text('Error selecting PDF: $e')),
        );
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

  void _openToolSearch() {
    showDialog(
      context: context,
      builder: (ctx) => ToolSearchDialog(
        onSelectTool: _handleToolSelected,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyK, control: true):
            _openToolSearch,
        const SingleActivator(LogicalKeyboardKey.keyK, meta: true):
            _openToolSearch,
      },
      child: Focus(
        autofocus: true,
        child: isMobile ? _buildMobileLayout() : _buildDesktopLayout(),
      ),
    );
  }

  Widget _buildMobileLayout() {
    final effectiveIndex = _selectedIndex.clamp(0, _mobileNavItems.length - 1);

    return Scaffold(
      body: IndexedStack(
        index: effectiveIndex,
        children: _mobileNavItems.map((item) => item.screen).toList(),
      ),
      bottomNavigationBar: ModernBottomNavigation(
        selectedIndex: effectiveIndex,
        onIndexChanged: (index) => setState(() => _selectedIndex = index),
        items: _mobileNavItems,
      ),
    );
  }

  Widget _buildDesktopLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveIndex = _selectedIndex.clamp(0, _navigationItems.length - 1);
    final currentItem = _navigationItems[effectiveIndex];

    return Scaffold(
      backgroundColor: isDark ? PremiumColors.darkBg : PremiumColors.lightBg,
      body: Column(
        children: [
          _buildDesktopTopBar(isDark, currentItem),
          Expanded(
            child: Row(
              children: [
                ModernNavigationRail(
                  selectedIndex: effectiveIndex,
                  onIndexChanged: (index) => setState(() => _selectedIndex = index),
                  items: _navigationItems,
                  isExpanded: _isSidebarExpanded,
                  onToggleExpanded: () {
                    setState(() => _isSidebarExpanded = !_isSidebarExpanded);
                  },
                ),
                Expanded(
                  child: IndexedStack(
                    index: effectiveIndex,
                    children:
                        _navigationItems.map((item) => item.screen).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopTopBar(bool isDark, ModernNavigationItem currentItem) {
    final isHome = _selectedIndex == 0;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark
            ? PremiumColors.darkSurfacePrimary
            : PremiumColors.lightSurfacePrimary,
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? PremiumColors.darkDivider
                : PremiumColors.lightDivider,
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        children: [
          AppBrandLogo(size: 28, showText: true, isDark: isDark),
          const SizedBox(width: 16),
          Container(
            height: 20,
            width: 1,
            color: isDark
                ? PremiumColors.darkDivider
                : PremiumColors.lightDivider,
          ),
          const SizedBox(width: 16),
          if (isHome)
            Text(
              'Home',
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.grey.shade300 : const Color(0xFF1E1E1E),
              ),
            )
          else ...[
            TextButton.icon(
              onPressed: () => setState(() => _selectedIndex = 0),
              icon: Icon(
                Icons.arrow_back_rounded,
                size: 14,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              label: Text(
                'Home',
                style: TextStyle(
                  fontSize: 12.5,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 32),
              ),
            ),
            Text(
              ' / ',
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
              ),
            ),
            Text(
              currentItem.label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E1E1E),
              ),
            ),
          ],
          const Spacer(),
          // Omnisearch Box
          if (MediaQuery.of(context).size.width >= 960)
            InkWell(
              onTap: _openToolSearch,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 34,
                width: 260,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? PremiumColors.darkSurfaceSecondary
                      : PremiumColors.lightSurfaceSecondary,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? PremiumColors.darkDivider
                        : PremiumColors.lightDivider,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search_rounded,
                      size: 16,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade500,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Search tools (Ctrl+K)...',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade500,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.08)
                            : Colors.black.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Ctrl+K',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            IconButton(
              icon: Icon(
                Icons.search_rounded,
                size: 20,
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
              tooltip: 'Search tools (Ctrl+K)',
              onPressed: _openToolSearch,
            ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: _handleGlobalOpenPdf,
            icon: const Icon(Icons.folder_open_rounded, size: 16),
            label: const Text('Open PDF'),
            style: ElevatedButton.styleFrom(
              backgroundColor: PremiumColors.brandRed,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: const Size(0, 34),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(7),
              ),
              textStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              size: 19,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            tooltip: 'Settings & Preferences',
            onPressed: () {
              setState(() => _selectedIndex = 13);
            },
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: FaIcon(
              FontAwesomeIcons.github,
              size: 16,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            tooltip: 'GitHub Repository',
            onPressed: _launchGitHub,
          ),
        ],
      ),
    );
  }
}

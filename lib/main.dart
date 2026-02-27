import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdfrx_engine/pdfrx_engine.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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

// Import widgets
import 'widgets/theme_switcher.dart';
import 'widgets/modern_navigation.dart';

// Import app configuration
import 'config/app_config.dart';
import 'config/premium_theme.dart';

// Import optimization utilities
import 'utils/platform_helper.dart';
import 'utils/platform_file_handler.dart';
import 'utils/responsive_helper.dart';

// Import services
import 'services/pdf_opener_service.dart';
import 'services/theme_service.dart' as theme_service;

// Constants for app configuration
const String _appTitle = AppConfig.appTitle;
const Color _primaryColor = AppConfig.primaryColor;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Platform-specific initialization
  if (PlatformHelper.isDesktop) {
    // Initialize desktop-specific features
    try {
      await pdfrxInitialize();
    } catch (e) {
      debugPrint('PDFRx initialization failed: $e');
    }
  }

  // Request permissions for mobile
  if (PlatformHelper.isMobile) {
    await PlatformFileHandler.requestFilePermissions();
  }

  // Initialize theme service
  final themeService = theme_service.ThemeService();
  await themeService.initialize();

  // Initialize PDF opener service for handling system PDF opening
  _initializePDFOpener();

  runApp(
    ChangeNotifierProvider<theme_service.ThemeService>.value(
      value: themeService,
      child: const OpenPDFToolsApp(),
    ),
  );
}

/// Initialize the PDF opener service to handle system file opening
void _initializePDFOpener() {
  try {
    // This will be set to the actual handler in the app state
    debugPrint('PDF opener service initialized');
  } catch (e) {
    debugPrint('Failed to initialize PDF opener: $e');
  }
}

class OpenPDFToolsApp extends StatefulWidget {
  /// Main application widget that handles external file intents.
  ///
  /// On Android, this widget listens for incoming PDF files shared
  /// from other applications and navigates to the PDF viewer screen.
  const OpenPDFToolsApp({super.key});

  @override
  State<OpenPDFToolsApp> createState() => _OpenPDFToolsAppState();
}

class _OpenPDFToolsAppState extends State<OpenPDFToolsApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<List<SharedMediaFile>>? _intentSub;
  late PDFOpenerService _pdfOpenerService;

  @override
  void initState() {
    super.initState();

    // Initialize PDF opener service
    _pdfOpenerService = PDFOpenerService();
    _pdfOpenerService.initialize(onPdfFileReceived: _handlePdfFileFromSystem);

    // Share intents only exist on Android
    if (!kIsWeb && PlatformHelper.isAndroid) {
      _initAndroidShareHandling();
    }
  }

  /// Handle PDF files opened through the system "Open with" dialog
  void _handlePdfFileFromSystem(String filePath) {
    debugPrint('PDF file received from system: $filePath');

    final file = File(filePath);
    if (file.existsSync() && filePath.toLowerCase().endsWith('.pdf')) {
      _navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (_) => PdfViewerScreen(externalFile: file)),
      );
    } else {
      debugPrint('File does not exist or is not a PDF: $filePath');
    }
  }

  /// Initialize handling of shared files on Android.
  ///
  /// Sets up listeners for both cold start (app not running) and
  /// warm start (app running in background) file sharing intents.
  void _initAndroidShareHandling() {
    // Cold start
    ReceiveSharingIntent.instance.getInitialMedia().then(_handleIncomingFiles);

    // Warm start: keep subscription to cancel on dispose
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      _handleIncomingFiles,
    );
  }

  /// Process incoming shared files and navigate to viewer if PDF.
  ///
  /// Only handles PDF files; other formats are ignored.
  /// Opens the PDF viewer screen with the first file found.
  void _handleIncomingFiles(List<SharedMediaFile> files) {
    if (files.isEmpty) return;

    final file = files.first;
    if (!file.path.toLowerCase().endsWith('.pdf')) return;

    _navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(externalFile: File(file.path)),
      ),
    );
  }

  @override
  void dispose() {
    if (!kIsWeb && PlatformHelper.isAndroid) {
      _intentSub?.cancel();
      ReceiveSharingIntent.instance.reset();
    }
    _pdfOpenerService.dispose();
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
          theme: createLightTheme(),
          darkTheme: createDarkTheme(),
          themeMode: _convertThemeMode(themeService),
          home: const _SplashAndHomeWrapper(),
        );
      },
    );
  }

  /// Convert custom ThemeMode to Material ThemeMode
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

/* ============= SPLASH AND HOME WRAPPER ============= */

/// Manages splash screen display and transition to home screen
class _SplashAndHomeWrapper extends StatefulWidget {
  const _SplashAndHomeWrapper();

  @override
  State<_SplashAndHomeWrapper> createState() => _SplashAndHomeWrapperState();
}

class _SplashAndHomeWrapperState extends State<_SplashAndHomeWrapper> {
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return const SplashScreen();
    }
    return const ResponsiveHomeScreen();
  }
}

/* ============= RESPONSIVE HOME SCREEN ============= */

class ResponsiveHomeScreen extends StatefulWidget {
  const ResponsiveHomeScreen({super.key});

  @override
  State<ResponsiveHomeScreen> createState() => _ResponsiveHomeScreenState();
}

class _ResponsiveHomeScreenState extends State<ResponsiveHomeScreen> {
  int _selectedIndex = 0;

  late List<ModernNavigationItem> _navigationItems;

  @override
  void initState() {
    super.initState();
    _navigationItems = [
      ModernNavigationItem(
        icon: Icons.home,
        label: 'Home',
        screen: const DashboardHomeScreen(),
      ),
      ModernNavigationItem(
        icon: Icons.picture_as_pdf,
        label: 'View PDF',
        screen: const PdfViewerScreen(),
      ),
      ModernNavigationItem(
        icon: Icons.compress,
        label: 'Compress',
        screen: const CompressPdfScreen(),
      ),
      ModernNavigationItem(
        icon: Icons.history,
        label: 'History',
        screen: const HistoryScreen(),
      ),
      ModernNavigationItem(
        icon: Icons.file_present,
        label: 'Convert to PDF',
        screen: const ConvertToPdfScreen(),
      ),
      ModernNavigationItem(
        icon: Icons.transform,
        label: 'Convert from PDF',
        screen: const ConvertFromPdfScreen(),
      ),
      ModernNavigationItem(
        icon: Icons.edit,
        label: 'Edit PDF',
        screen: const EditPdfScreen(),
      ),
      ModernNavigationItem(
        icon: Icons.image,
        label: 'PDF from Images',
        screen: const PdfFromImagesScreen(),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = context.isMobile;
    final isTablet = context.isTablet;

    if (isMobile) {
      return _buildMobileLayout();
    } else if (isTablet) {
      return _buildTabletLayout();
    } else {
      return _buildDesktopLayout();
    }
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      body: _navigationItems[_selectedIndex].screen,
      bottomNavigationBar: ModernBottomNavigation(
        selectedIndex: _selectedIndex,
        onIndexChanged: (index) => setState(() => _selectedIndex = index),
        items: _navigationItems,
      ),
    );
  }

  Widget _buildTabletLayout() {
    return Scaffold(
      body: Row(
        children: [
          ModernNavigationRail(
            selectedIndex: _selectedIndex,
            onIndexChanged: (index) => setState(() => _selectedIndex = index),
            items: _navigationItems,
            header: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 40,
                  width: 40,
                  child: Image.asset(
                    'asset/app_img/OpenPDF Tools.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  _appTitle,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            footer: ThemeSwitcher(compact: true),
          ),
          Expanded(child: _navigationItems[_selectedIndex].screen),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          ModernNavigationRail(
            selectedIndex: _selectedIndex,
            onIndexChanged: (index) => setState(() => _selectedIndex = index),
            items: _navigationItems,
            header: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 48,
                  width: 48,
                  child: Image.asset(
                    'asset/app_img/OpenPDF Tools.png',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _appTitle,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            footer: ThemeSwitcher(compact: true),
          ),
          Expanded(child: _navigationItems[_selectedIndex].screen),
        ],
      ),
    );
  }
}

/* ============= HOME SCREEN ============= */

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
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
    final isMobile = context.isMobile;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // final screenWidth = MediaQuery.of(context).size.width;

    // Dynamic grid columns based on screen size
    int gridColumns = 2;
    if (context.isDesktop) {
      gridColumns = 4;
    } else if (context.isTablet) {
      gridColumns = 3;
    }

    final tools = [
      ToolCardData(
        icon: Icons.picture_as_pdf,
        title: 'View PDF',
        subtitle: 'Read & Review',
        color: _primaryColor,
        screen: const PdfViewerScreen(),
      ),
      ToolCardData(
        icon: Icons.compress,
        title: 'Compress PDF',
        subtitle: 'Reduce Size',
        color: const Color(0xFF1565C0),
        screen: const CompressPdfScreen(),
      ),
      ToolCardData(
        icon: Icons.history,
        title: 'History',
        subtitle: 'Recent & Favorites',
        color: const Color(0xFF7E57C2),
        screen: const HistoryScreen(),
      ),
      ToolCardData(
        icon: Icons.file_present,
        title: 'Convert to PDF',
        subtitle: 'Multiple Formats',
        color: const Color(0xFF00796B),
        screen: const ConvertToPdfScreen(),
      ),
      ToolCardData(
        icon: Icons.transform,
        title: 'Convert from PDF',
        subtitle: '19+ Formats',
        color: _primaryColor,
        screen: const ConvertFromPdfScreen(),
      ),
      ToolCardData(
        icon: Icons.edit,
        title: 'Edit PDF',
        subtitle: 'Add Text & More',
        color: const Color(0xFF6A1B9A),
        screen: const EditPdfScreen(),
      ),
      ToolCardData(
        icon: Icons.image,
        title: 'PDF from Images',
        subtitle: 'Create PDFs',
        color: const Color(0xFFE65100),
        screen: const PdfFromImagesScreen(),
      ),
    ];

    return CustomScrollView(
      slivers: [
        // Modern AppBar with Hero Header
        SliverAppBar(
          expandedHeight: isMobile ? 160 : 200,
          floating: false,
          pinned: true,
          backgroundColor: _primaryColor,
          elevation: 0,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFC6302C), Color(0xFF9A0000)],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: isMobile ? 60 : 80,
                    height: isMobile ? 60 : 80,
                    child: Image.asset(
                      'asset/app_img/OpenPDF Tools.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _appTitle,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isMobile ? 18 : 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Professional PDF Management',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: isMobile ? 11 : 13,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
            titlePadding: const EdgeInsets.symmetric(vertical: 16),
            title: const Text(
              _appTitle,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        // Content Grid with responsive layout
        SliverPadding(
          padding: EdgeInsets.all(isMobile ? 0 : 4),
          sliver: SliverGrid(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: gridColumns,
              childAspectRatio: 0.95,
              crossAxisSpacing: isMobile ? 8 : 12,
              mainAxisSpacing: isMobile ? 8 : 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) =>
                  _ToolCard(tool: tools[index], isMobile: isMobile),
              childCount: tools.length,
            ),
          ),
        ),
        // Footer Info
        SliverPadding(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.all(isMobile ? 12 : 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color: _primaryColor.withValues(alpha: 0.1),
                            ),
                            child: const Icon(
                              Icons.info,
                              color: _primaryColor,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Features',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        '✓ Multi-format support\n'
                        '✓ Fast & secure processing\n'
                        '✓ Optimized for all platforms\n'
                        '✓ Responsive design',
                        style: TextStyle(fontSize: 12, height: 1.8),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Version ${AppConfig.appVersion}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                // GitHub Icon Link
                GestureDetector(
                  onTap: _launchGitHub,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _primaryColor.withValues(alpha: 0.1),
                    ),
                    child: const Icon(
                      FontAwesomeIcons.github,
                      color: _primaryColor,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class ToolCardData {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final Widget screen;

  ToolCardData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.screen,
  });
}

// Responsive Tool Card Widget
class _ToolCard extends StatefulWidget {
  final ToolCardData tool;
  final bool isMobile;

  const _ToolCard({required this.tool, required this.isMobile});

  @override
  State<_ToolCard> createState() => _ToolCardState();
}

class _ToolCardState extends State<_ToolCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => widget.tool.screen),
          );
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.tool.color.withValues(
                  alpha: _isHovered ? 0.3 : 0.15,
                ),
                blurRadius: _isHovered ? 16 : 8,
                offset: Offset(0, _isHovered ? 8 : 4),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  widget.tool.color,
                  widget.tool.color.withValues(alpha: 0.8),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Background Pattern
                Positioned(
                  right: -30,
                  top: -30,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                Positioned(
                  left: -20,
                  bottom: -20,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        child: Icon(
                          widget.tool.icon,
                          color: Colors.white,
                          size: widget.isMobile ? 20 : 24,
                        ),
                      ),
                      Expanded(child: Container()),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.tool.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: widget.isMobile ? 14 : 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            widget.tool.subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: widget.isMobile ? 10 : 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Hover Effect Arrow
                if (_isHovered && !widget.isMobile)
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.3),
                      ),
                      child: const Icon(
                        Icons.arrow_forward,
                        color: Colors.white,
                        size: 14,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

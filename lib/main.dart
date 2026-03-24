import 'dart:io' show File;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:provider/provider.dart';
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
import 'widgets/theme_switcher.dart';
import 'widgets/modern_navigation.dart';
import 'config/app_config.dart';
import 'config/premium_theme.dart';
import 'utils/platform_helper.dart';
import 'utils/platform_file_handler.dart';
import 'utils/responsive_helper.dart';
import 'services/pdf_opener_service.dart';
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
      if (PlatformHelper.isAndroid) {
        debugPrint('[main] Requesting camera permission');
        await PlatformFileHandler.requestCameraPermission();
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

  void _initAndroidShareHandling() {
    ReceiveSharingIntent.instance.getInitialMedia().then(_handleIncomingFiles);
    _intentSub = ReceiveSharingIntent.instance.getMediaStream().listen(
      _handleIncomingFiles,
    );
  }

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
          theme: createLightTheme(),
          darkTheme: createDarkTheme(),
          themeMode: _convertThemeMode(themeService),
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
      ModernNavigationItem(
        icon: Icons.healing,
        label: 'Repair PDF',
        screen: const RepairPdfScreen(),
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
    final isHome = _selectedIndex == 0;
    return Scaffold(
      appBar: isHome
          ? AppBar(
              title: Text(_appTitle),
              elevation: 0,
              actions: [ThemeSwitcher(compact: true), const SizedBox(width: 8)],
            )
          : null,
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

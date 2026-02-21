import 'dart:io';
import 'package:flutter/material.dart';
import 'package:pdfrx_engine/pdfrx_engine.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'dart:async';

import 'screens/pdf_viewer_screen.dart';
import 'screens/compress_pdf_screen.dart';
import 'screens/convert_to_pdf_screen.dart';
import 'screens/convert_from_pdf_screen.dart';
import 'screens/history_screen.dart';
import 'screens/edit_pdf_screen.dart';

// Constants for app configuration
const String _appTitle = 'OpenPDF Tools';
const Color _primaryColor = Color(0xFFC6302C);
const Color _darkRedColor = Color(0xFF9A0000);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize pdfrx engine for desktop PDF rendering
  try {
    await pdfrxInitialize();
  } catch (_) {}
  runApp(const OpenPDFToolsApp());
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
  final GlobalKey<NavigatorState> _navigatorKey =
      GlobalKey<NavigatorState>();
  StreamSubscription<List<SharedMediaFile>>? _intentSub;

  @override
  void initState() {
    super.initState();

    // Share intents only exist on Android
    if (Platform.isAndroid) {
      _initAndroidShareHandling();
    }
  }

  /// Initialize handling of shared files on Android.
  ///
  /// Sets up listeners for both cold start (app not running) and
  /// warm start (app running in background) file sharing intents.
  void _initAndroidShareHandling() {
    // Cold start
    ReceiveSharingIntent.instance.getInitialMedia()
      .then(_handleIncomingFiles);

    // Warm start: keep subscription to cancel on dispose
    _intentSub = ReceiveSharingIntent.instance.getMediaStream()
      .listen(_handleIncomingFiles);
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
        builder: (_) => PdfViewerScreen(
          externalFile: File(file.path),
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (Platform.isAndroid) {
      _intentSub?.cancel();
      ReceiveSharingIntent.instance.reset();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: _appTitle,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        primaryColor: _primaryColor,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: const ColorScheme.light(
          primary: _primaryColor,
          onPrimary: Colors.white,
          secondary: Colors.white,
          onSecondary: Colors.black,
          surface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: _primaryColor,
          foregroundColor: Colors.white,
          elevation: 4,
          centerTitle: false,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}

/* ---------------- HOME SCREEN ---------------- */

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Modern AppBar with Hero Header
          SliverAppBar(
            expandedHeight: 200,
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
                    colors: [
                      Color(0xFFC6302C),
                      Color(0xFF9A0000),
                    ],
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: Image.asset(
                        'asset/app_img/OpenPDF Tools.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'OpenPDF Tools',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Professional PDF Management',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontSize: 13,
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
          // Content Grid
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.9,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildListDelegate.fixed([
                _ToolCard(
                  icon: Icons.picture_as_pdf,
                  title: 'View PDF',
                  subtitle: 'Read & Review',
                  color: _primaryColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PdfViewerScreen(),
                      ),
                    );
                  },
                ),
                _ToolCard(
                  icon: Icons.compress,
                  title: 'Compress PDF',
                  subtitle: 'Reduce Size',
                  color: const Color(0xFF1565C0),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const CompressPdfScreen(),
                      ),
                    );
                  },
                ),
                _ToolCard(
                  icon: Icons.history,
                  title: 'History',
                  subtitle: 'Recent & Favorites',
                  color: const Color(0xFF7E57C2),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HistoryScreen(),
                      ),
                    );
                  },
                ),
                _ToolCard(
                  icon: Icons.file_present,
                  title: 'Convert to PDF',
                  subtitle: 'Multiple Formats',
                  color: const Color(0xFF00796B),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ConvertToPdfScreen(),
                      ),
                    );
                  },
                ),
                _ToolCard(
                  icon: Icons.transform,
                  title: 'Convert from PDF',
                  subtitle: '19+ Formats',
                  color: _primaryColor,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ConvertFromPdfScreen(),
                      ),
                    );
                  },
                ),
                _ToolCard(
                  icon: Icons.edit,
                  title: 'Edit PDF',
                  subtitle: 'Add Text & More',
                  color: const Color(0xFF6A1B9A),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const EditPdfScreen(),
                      ),
                    );
                  },
                ),
              ]),
            ),
          ),
          // Footer Info
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: isDark 
                        ? Colors.grey.shade900 
                        : Colors.grey.shade100,
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
                                'Pro Tips',
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
                          '• Convert documents, images, and more to PDF\n'
                          '• Compress large PDFs to save storage\n'
                          '• Support for 13+ file formats\n'
                          '• Fast and secure processing',
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Version 1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Modern Tool Card Widget
class _ToolCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ToolCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

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
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: _isHovered ? 0.3 : 0.15),
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
                  widget.color,
                  widget.color.withValues(alpha: 0.8),
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
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.1),
                        ),
                        child: Icon(
                          widget.icon,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      Expanded(child: Container()),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Hover Effect Arrow
                if (_isHovered)
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
                        size: 16,
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

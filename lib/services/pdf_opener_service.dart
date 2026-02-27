import 'dart:io' as io;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';

/// Service for handling PDF file opening from the system
/// Handles intent filters on Android and URL schemes on iOS/macOS
class PDFOpenerService {
  static const platform = MethodChannel('com.openpdf.tools/pdfOpener');
  static const String _pdfScheme = 'openpdf';

  static final PDFOpenerService _instance = PDFOpenerService._internal();

  late AppLinks _appLinks;
  Function(String pdfPath)? _onPdfFileReceived;

  PDFOpenerService._internal();

  factory PDFOpenerService() {
    return _instance;
  }

  /// Initialize the PDF opener service
  /// Call this in your main.dart or app initialization
  /// Safe to call after widget is mounted
  Future<void> initialize({
    required Function(String pdfPath) onPdfFileReceived,
  }) async {
    try {
      _onPdfFileReceived = onPdfFileReceived;
      debugLog('[PDFOpenerService] Initializing service');

      // Initialize app links for deep linking (safe to call anytime)
      try {
        _appLinks = AppLinks();
        debugLog('[PDFOpenerService] AppLinks initialized');

        // Listen for app links (URLs like openpdf://path/to/file.pdf)
        _appLinks.uriLinkStream.listen(
          (uri) {
            _handleDeepLink(uri);
          },
          onError: (err) {
            debugLog('[PDFOpenerService] Error listening to app links: $err');
          },
        );
        debugLog('[PDFOpenerService] App links stream listener attached');
      } catch (e) {
        debugLog('[PDFOpenerService] Error with AppLinks: $e');
        // Continue - app links not critical
      }

      // Set up platform channel for receiving files from intent
      // Wrapped in safety checks to prevent isolate errors
      try {
        platform.setMethodCallHandler((call) async {
          debugLog('[PDFOpenerService] Platform method called: ${call.method}');

          if (call.method == 'openPdf') {
            final filePath = call.arguments as String?;
            if (filePath != null && filePath.isNotEmpty) {
              debugLog('[PDFOpenerService] Opening PDF: $filePath');
              _onPdfFileReceived?.call(filePath);
            }
          } else if (call.method == 'getPdfPath') {
            // Called when app receives a file via intent
            return await _getReceivedPdfPath();
          }
          return null;
        });
        debugLog('[PDFOpenerService] Platform method handler set');
      } catch (e) {
        debugLog('[PDFOpenerService] Error setting platform handler: $e');
        // Continue - platform channel not critical for all operations
      }

      debugLog('[PDFOpenerService] Initialization complete');
    } catch (e) {
      debugLog('[PDFOpenerService] Fatal error during initialization: $e');
      rethrow;
    }
  }

  /// Handle deep links in the format: openpdf://file/{path}
  void _handleDeepLink(Uri uri) {
    try {
      if (uri.scheme == _pdfScheme) {
        final pathSegments = uri.pathSegments;

        if (pathSegments.contains('file') && pathSegments.length > 1) {
          final fileIndex = pathSegments.indexOf('file');
          final filePath = '/${pathSegments.sublist(fileIndex + 1).join('/')}';

          if (filePath.isNotEmpty) {
            _onPdfFileReceived?.call(filePath);
          }
        }
      }
    } catch (e) {
      debugLog('Error handling deep link: $e');
    }
  }

  /// Get the PDF file path that was received via intent
  Future<String?> _getReceivedPdfPath() async {
    try {
      final result = await platform.invokeMethod<String>('getReceivedPdfPath');
      return result;
    } catch (e) {
      debugLog('Error getting received PDF path: $e');
      return null;
    }
  }

  /// Register the app as PDF opener (platform-specific)
  Future<bool> registerAsPdfOpener() async {
    try {
      if (kIsWeb) {
        return false; // PDFs cannot be registered as default opener on web
      }

      if (io.Platform.isAndroid) {
        return await _registerAndroidPdfOpener();
      } else if (io.Platform.isIOS) {
        return await _registerIOSPdfOpener();
      } else if (io.Platform.isMacOS) {
        return await _registerMacOSPdfOpener();
      } else if (io.Platform.isWindows) {
        return await _registerWindowsPdfOpener();
      } else if (io.Platform.isLinux) {
        return await _registerLinuxPdfOpener();
      }
      return false;
    } catch (e) {
      debugLog('Error registering PDF opener: $e');
      return false;
    }
  }

  /// Android: Request to register as PDF opener
  Future<bool> _registerAndroidPdfOpener() async {
    try {
      final result = await platform.invokeMethod<bool>('registerPdfOpener');
      return result ?? false;
    } catch (e) {
      debugLog('Error registering Android PDF opener: $e');
      return false;
    }
  }

  /// iOS: Register as PDF opener (handled in Info.plist)
  Future<bool> _registerIOSPdfOpener() async {
    debugLog('iOS PDF opener registration handled in Info.plist');
    return true;
  }

  /// macOS: Register as PDF opener (handled in Info.plist)
  Future<bool> _registerMacOSPdfOpener() async {
    debugLog('macOS PDF opener registration handled in Info.plist');
    return true;
  }

  /// Windows: Register as PDF opener in registry
  Future<bool> _registerWindowsPdfOpener() async {
    try {
      final result = await platform.invokeMethod<bool>('registerPdfOpener');
      return result ?? false;
    } catch (e) {
      debugLog('Error registering Windows PDF opener: $e');
      return false;
    }
  }

  /// Linux: Register as PDF opener (handled in .desktop file)
  Future<bool> _registerLinuxPdfOpener() async {
    debugLog('Linux PDF opener registration handled in .desktop file');
    return true;
  }

  /// Check if a file is a PDF
  static bool isPdfFile(String filePath) {
    return filePath.toLowerCase().endsWith('.pdf');
  }

  /// Debug logging utility
  static void debugLog(String message) {
    debugPrint('[PDFOpenerService] $message');
  }

  /// Dispose resources
  void dispose() {
    _onPdfFileReceived = null;
  }
}

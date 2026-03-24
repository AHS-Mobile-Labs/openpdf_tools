import 'dart:io' as io;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:app_links/app_links.dart';

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
  Future<void> initialize({
    required Function(String pdfPath) onPdfFileReceived,
  }) async {
    try {
      _onPdfFileReceived = onPdfFileReceived;
      debugLog('[PDFOpenerService] Initializing service');
      try {
        _appLinks = AppLinks();
        debugLog('[PDFOpenerService] AppLinks initialized');
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
      }
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
            return await _getReceivedPdfPath();
          }
          return null;
        });
        debugLog('[PDFOpenerService] Platform method handler set');
      } catch (e) {
        debugLog('[PDFOpenerService] Error setting platform handler: $e');
      }
      debugLog('[PDFOpenerService] Initialization complete');
    } catch (e) {
      debugLog('[PDFOpenerService] Fatal error during initialization: $e');
      rethrow;
    }
  }

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

  Future<String?> _getReceivedPdfPath() async {
    try {
      final result = await platform.invokeMethod<String>('getReceivedPdfPath');
      return result;
    } catch (e) {
      debugLog('Error getting received PDF path: $e');
      return null;
    }
  }

  Future<bool> registerAsPdfOpener() async {
    try {
      if (kIsWeb) {
        return false;
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

  Future<bool> _registerAndroidPdfOpener() async {
    try {
      final result = await platform.invokeMethod<bool>('registerPdfOpener');
      return result ?? false;
    } catch (e) {
      debugLog('Error registering Android PDF opener: $e');
      return false;
    }
  }

  Future<bool> _registerIOSPdfOpener() async {
    debugLog('iOS PDF opener registration handled in Info.plist');
    return true;
  }

  Future<bool> _registerMacOSPdfOpener() async {
    debugLog('macOS PDF opener registration handled in Info.plist');
    return true;
  }

  Future<bool> _registerWindowsPdfOpener() async {
    try {
      final result = await platform.invokeMethod<bool>('registerPdfOpener');
      return result ?? false;
    } catch (e) {
      debugLog('Error registering Windows PDF opener: $e');
      return false;
    }
  }

  Future<bool> _registerLinuxPdfOpener() async {
    debugLog('Linux PDF opener registration handled in .desktop file');
    return true;
  }

  static bool isPdfFile(String filePath) {
    return filePath.toLowerCase().endsWith('.pdf');
  }

  static void debugLog(String message) {
    debugPrint('[PDFOpenerService] $message');
  }

  void dispose() {
    _onPdfFileReceived = null;
  }
}
